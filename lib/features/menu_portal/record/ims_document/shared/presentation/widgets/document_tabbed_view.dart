import 'package:flutter/material.dart';

import '../../../../../../../core/widgets/app_text_field.dart';
import '../../domain/master_document_page.dart';
import 'document_list_tab.dart';
import 'document_tab_bar.dart';

/// Satu tab pada [DocumentTabbedView]: label chip, jumlah dokumen (opsional),
/// dan pengambil halaman daftarnya.
class DocumentTabSpec {
  const DocumentTabSpec({required this.label, required this.fetcher, this.count});

  final String label;
  final int? count;
  final MasterDocumentFetcher fetcher;
}

/// Badan halaman dokumen bertab: kolom search, deret chip tab, lalu daftar
/// dokumen tab yang aktif. Dokumen hanya bisa dilihat di aplikasi.
///
/// Dipakai bersama oleh `MasterDocumentFileScreen` (6 tab) dan
/// `MasterEditedFileScreen` (4 tab) — keduanya cukup memberi [tabs] dan
/// membungkusnya dengan Scaffold + `BackHeader` sendiri.
class DocumentTabbedView extends StatefulWidget {
  const DocumentTabbedView({
    super.key,
    required this.tabs,
    this.searchHint = 'Search document number, title, or department',
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: AppTextField(
            controller: _searchController,
            hint: widget.searchHint,
            icon: Icons.search,
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        DocumentTabBar(
          labels: [for (final tab in tabs) tab.label],
          counts: [for (final tab in tabs) tab.count],
          selectedIndex: _tabIndex,
          onChanged: (index) => setState(() => _tabIndex = index),
        ),
        const SizedBox(height: 12),
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
