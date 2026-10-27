import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import '../../domain/master_document_page.dart';
import 'document_list_tab.dart';
import 'document_tab_bar.dart';

/// Satu tab pada [DocumentTabbedView]: label chip + pengambil halaman
/// daftarnya.
class DocumentTabSpec {
  const DocumentTabSpec({required this.label, required this.fetcher});

  final String label;
  final MasterDocumentFetcher fetcher;
}

/// Badan halaman dokumen bertab: kolom search, deret chip tab, lalu daftar
/// dokumen tab yang aktif.
///
/// Dipakai bersama oleh `MasterDocumentFileScreen` (6 tab) dan
/// `MasterEditedFileScreen` (4 tab) — keduanya cukup memberi [tabs] dan
/// membungkusnya dengan Scaffold + `BackHeader` sendiri.
class DocumentTabbedView extends StatefulWidget {
  const DocumentTabbedView({
    super.key,
    required this.tabs,
    this.searchHint = 'Nomor dokumen, judul, atau departemen',
    this.pdfHeaders = const {},
  });

  final List<DocumentTabSpec> tabs;
  final String searchHint;

  /// Diteruskan ke viewer PDF (mis. `Authorization`).
  final Map<String, String> pdfHeaders;

  @override
  State<DocumentTabbedView> createState() => _DocumentTabbedViewState();
}

class _DocumentTabbedViewState extends State<DocumentTabbedView> {
  int _tabIndex = 0;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: AppTextField(
            controller: _searchController,
            hint: widget.searchHint,
            icon: Icons.search,
            label: 'Search',
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        DocumentTabBar(
          labels: [for (final tab in tabs) tab.label],
          selectedIndex: _tabIndex,
          onChanged: (index) => setState(() => _tabIndex = index),
        ),
        const SizedBox(height: 12),
        // Catatan di muka: dokumen tidak bisa diunduh di aplikasi, jadi user
        // tahu sebelum menekan tombolnya.
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: _WebDownloadNote(),
        ),
        Expanded(
          child: DocumentListTab(
            // Ganti key tiap pindah tab supaya BlocProvider di dalamnya
            // dibuat ulang (fetch dokumen tab yang baru), bukan
            // mempertahankan bloc/data tab sebelumnya.
            key: ValueKey(_tabIndex),
            fetcher: tabs[_tabIndex].fetcher,
            searchQuery: _searchQuery,
            pdfHeaders: widget.pdfHeaders,
          ),
        ),
      ],
    );
  }
}

/// Catatan kecil: unduh dokumen hanya lewat website IMS.
class _WebDownloadNote extends StatelessWidget {
  const _WebDownloadNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dokumen hanya dapat diunduh melalui website IMS '
              '(memerlukan approval).',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
