import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/master_document.dart';
import '../bloc/master_document_list_bloc.dart';
import '../bloc/master_document_list_event.dart';
import '../bloc/master_document_list_state.dart';
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
            return const Center(child: CircularProgressIndicator());
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
                onDownload: (doc) => _showDummyAction(context, 'Mengunduh ${doc.docNo}'),
                onObsolete: (doc) => _showDummyAction(context, 'Membuka versi obsolete ${doc.docNo}'),
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

  void _showDummyAction(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message (dummy, belum tersambung ke berkas asli)')),
    );
  }
}
