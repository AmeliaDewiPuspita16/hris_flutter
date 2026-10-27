import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_config.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../domain/master_document.dart';

/// Layar baca dokumen master di dalam aplikasi — hanya untuk dilihat.
///
/// Sengaja tanpa tombol simpan/bagikan/cetak dan seleksi teks dimatikan —
/// dokumen master hanya boleh dibaca, tidak diunduh.
///
/// Byte PDF diambil sendiri lewat `http` lalu dirender dari memori dengan
/// `PdfViewer.data`, bukan `PdfViewer.uri` — yang terakhir menyimpan salinan
/// berkasnya ke cache di disk HP. Sekalian, pesan galat JSON `{message}` dari
/// server (401/403/404/422) bisa ditampilkan apa adanya.
///
/// Selama [MasterDocument.viewUrl] masih null (data demo Master Edited
/// File), yang tampil adalah [_sampleAsset].
class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key, required this.document, this.headers = const {}});

  final MasterDocument document;

  /// Header request PDF, mis. `Authorization: Bearer <token>`.
  final Map<String, String> headers;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  /// TODO(api): hapus begitu Master Edited File punya endpoint PDF.
  static const _sampleAsset = 'assets/documents/sample_document.pdf';

  static const _params = PdfViewerParams(
    backgroundColor: AppColors.bg,
    margin: 12,
    textSelectionParams: PdfTextSelectionParams(enabled: false),
    errorBannerBuilder: _buildRenderError,
  );

  late Future<Uint8List> _bytes = _load();

  Future<Uint8List> _load() async {
    final uri = _resolveViewUri(widget.document.viewUrl);
    if (uri == null) {
      final data = await rootBundle.load(_sampleAsset);
      return data.buffer.asUint8List();
    }

    AppLogger.info('GET $uri');
    final http.Response response;
    try {
      response = await http.get(uri, headers: widget.headers).timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const _ViewerError('The server took too long to respond. Please try again.');
    } on SocketException {
      throw const _ViewerError('Unable to reach the server. Check your connection.');
    } on http.ClientException {
      throw const _ViewerError('Unable to reach the server. Check your connection.');
    }

    AppLogger.info('GET $uri -> ${response.statusCode}');
    if (response.statusCode == 200) return response.bodyBytes;

    throw _ViewerError(_messageFor(response));
  }

  /// Pesan `{message}` dari server kalau ada; kalau tidak, pesan umum per
  /// status.
  static String _messageFor(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) return body['message'] as String;
    } on FormatException {
      // Bukan JSON — jatuh ke pesan umum di bawah.
    }

    return switch (response.statusCode) {
      401 => 'Your session has expired. Please log in again.',
      403 => 'This account does not have access to IMS documents.',
      404 => 'Document file not found.',
      422 => 'This document is not a PDF and cannot be viewed in the app.',
      _ => 'Failed to load the document. Please try again.',
    };
  }

  /// Hanya http(s) yang dimuat dari jaringan; selain itu dianggap belum ada.
  static Uri? _resolveViewUri(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return null;
    return uri;
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: document.docNo,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: FutureBuilder<Uint8List>(
        future: _bytes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error;
            return AppErrorView(
              message: error is _ViewerError ? error.message : 'Failed to load the document. Please try again.',
              onRetry: () => setState(() => _bytes = _load()),
            );
          }

          final bytes = snapshot.data;
          if (bytes == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return PdfViewer.data(
            bytes,
            // Wajib unik per sumber (lihat dokumentasi `PdfViewer.data`).
            sourceName: document.viewUrl ?? '${document.docNo}-sample',
            params: _params,
          );
        },
      ),
    );
  }

  /// Byte sudah sampai tapi tidak bisa dibaca sebagai PDF.
  static Widget _buildRenderError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    PdfDocumentRef documentRef,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'The document file is corrupted or not a PDF.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
      ),
    );
  }
}

class _ViewerError implements Exception {
  const _ViewerError(this.message);

  final String message;
}
