import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_shimmer.dart';
import '../../domain/master_document.dart';
import '../bloc/master_document_list_bloc.dart';
import '../bloc/master_document_list_event.dart';
import '../bloc/master_document_list_state.dart';
import '../../data/ims_web_links.dart';
import '../screens/document_viewer_screen.dart';
import 'ims_web_download_dialog.dart';
import 'master_document_tile.dart';

/// Isi satu tab dokumen (Manual, SOP, dst) — daftar dokumen dari [fetcher]
/// yang mana pun, disaring lokal oleh [searchQuery].
///
/// Dipakai ulang oleh Master Document File dan Master Edited File, tinggal
/// beda [fetcher]-nya (`repository.fetchManualDocuments`, dst) — sama seperti
/// `MasterDocumentListBloc` yang didesain generik per kategori. Dokumen tanpa
/// `obsoleteUrl` (seluruh Master Edited File) otomatis tidak menampilkan
/// tombol "Obsolete" karena diatur oleh [MasterDocumentTile].
class DocumentListTab extends StatelessWidget {
  const DocumentListTab({super.key, required this.fetcher, required this.searchQuery});

  final Future<List<MasterDocument>> Function() fetcher;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MasterDocumentListBloc(fetcher: fetcher)
        ..add(const MasterDocumentListStarted()),
      child: BlocBuilder<MasterDocumentListBloc, MasterDocumentListState>(
        builder: (context, state) {
          if (state.status == MasterDocumentListStatus.loading && state.documents.isEmpty) {
            return const _DocumentListSkeleton();
          }

          if (state.status == MasterDocumentListStatus.failure && state.documents.isEmpty) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Gagal memuat dokumen.',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          final documents = _filter(state.documents, searchQuery);

          if (documents.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada dokumen yang cocok dengan pencarian.',
                style: AppTextStyles.bodyMuted,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final document = documents[index];

              return MasterDocumentTile(
                document: document,
                onView: (doc) => _view(context, doc),
                onDownload: (doc) => _download(context, doc),
                onObsolete: (doc) => _openOnWeb(context, doc.obsoleteUrl ?? doc.downloadUrl),
              );
            },
          );
        },
      ),
    );
  }

  /// Filter lokal di client — datanya masih dummy statis (semua sudah
  /// termuat sekaligus).
  ///
  /// Ikut menyaring `hierarchy` (kode departemen) — berguna di tab SOP yang
  /// departemennya beragam, mis. ketik "SSD" langsung dapat semua dokumen
  /// SSD.
  List<MasterDocument> _filter(List<MasterDocument> documents, String query) {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return documents;

    return documents
        .where((doc) =>
            doc.docNo.toLowerCase().contains(keyword) ||
            doc.title.toLowerCase().contains(keyword) ||
            doc.hierarchy.toLowerCase().contains(keyword))
        .toList(growable: false);
  }

  /// Baca PDF di aplikasi, tanpa opsi simpan — lihat [DocumentViewerScreen].
  void _view(BuildContext context, MasterDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocumentViewerScreen(document: doc)),
    );
  }

  /// Dokumen tidak diunduh di aplikasi: tampilkan penjelasan dulu, lalu
  /// arahkan ke website IMS kalau user setuju.
  Future<void> _download(BuildContext context, MasterDocument doc) async {
    final confirmed = await showImsWebDownloadDialog(context);
    if (!confirmed || !context.mounted) return;
    await _openOnWeb(context, doc.downloadUrl);
  }

  /// Buka [url] di browser; kasih tahu user kalau gagal.
  ///
  /// TODO(api): [MasterDocument.downloadUrl] / `obsoleteUrl` masih dummy,
  /// jadi sementara jatuh ke `ImsWebLinks.documentsPage`.
  Future<void> _openOnWeb(BuildContext context, String url) async {
    final opened = await ImsWebLinks.open(url);
    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka website IMS.')),
    );
  }
}

/// Skeleton daftar dokumen selagi tab pertama dimuat. Meniru
/// [MasterDocumentTile]: judul + keterangan, lalu baris aksi file
/// (Download / Obsolete) berbentuk kotak memanjang.
class _DocumentListSkeleton extends StatelessWidget {
  const _DocumentListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerList(
          itemCount: 5,
          itemBuilder: (context) => const ShimmerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(width: 200, height: 14),
                SizedBox(height: 8),
                ShimmerLine(width: 130, height: 10),
                SizedBox(height: 12),
                ShimmerBox(height: 38, borderRadius: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
