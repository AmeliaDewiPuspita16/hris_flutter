import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../domain/master_document.dart';

/// Layar baca dokumen master di dalam aplikasi — hanya untuk dilihat.
///
/// Sengaja tanpa tombol simpan/bagikan/cetak dan seleksi teks dimatikan,
/// karena unduhan resmi tetap lewat website IMS (file diberi cap & butuh
/// approval). PDF dirender langsung dari memori oleh `pdfrx`, tidak
/// disimpan ke penyimpanan HP.
///
/// Selama [MasterDocument.viewUrl] masih null (data demo), yang tampil adalah
/// [_sampleAsset].
class DocumentViewerScreen extends StatelessWidget {
  const DocumentViewerScreen({super.key, required this.document});

  final MasterDocument document;

  /// TODO(api): hapus begitu seluruh dokumen punya `viewUrl` dari server.
  static const _sampleAsset = 'assets/documents/sample_document.pdf';

  static const _params = PdfViewerParams(
    backgroundColor: AppColors.bg,
    margin: 12,
    textSelectionParams: PdfTextSelectionParams(enabled: false),
    loadingBannerBuilder: _buildLoading,
    errorBannerBuilder: _buildError,
  );

  @override
  Widget build(BuildContext context) {
    final viewUri = _resolveViewUri(document.viewUrl);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: document.docNo,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: viewUri != null
          ? PdfViewer.uri(viewUri, params: _params)
          : PdfViewer.asset(_sampleAsset, params: _params),
    );
  }

  /// Hanya http(s) yang dimuat dari jaringan; selain itu dianggap belum ada.
  static Uri? _resolveViewUri(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return null;
    return uri;
  }

  static Widget _buildLoading(BuildContext context, int bytesDownloaded, int? totalBytes) {
    return Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        value: totalBytes != null && totalBytes > 0 ? bytesDownloaded / totalBytes : null,
      ),
    );
  }

  static Widget _buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    PdfDocumentRef documentRef,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Dokumen gagal dimuat. Periksa koneksi lalu coba lagi.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
      ),
    );
  }
}
