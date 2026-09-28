import 'package:flutter/material.dart';

import '../../../../../../../core/widgets/app_text_field.dart';
import '../../domain/master_document.dart';
import 'document_list_tab.dart';
import 'document_tab_bar.dart';

/// Satu tab pada [DocumentTabbedView]: label chip + method repository yang
/// mengisi daftarnya.
class DocumentTabSpec {
  const DocumentTabSpec({required this.label, required this.fetcher});

  final String label;
  final Future<List<MasterDocument>> Function() fetcher;
}

/// Badan halaman dokumen bertab: kolom search, deret chip tab, lalu daftar
/// dokumen tab yang aktif.
///
/// Dipakai bersama oleh `MasterDocumentFileScreen` (6 tab) dan
/// `MasterEditedFileScreen` (4 tab) — keduanya cukup memberi [tabs] dan
/// membungkusnya dengan Scaffold + `BackHeader` sendiri.
class DocumentTabbedView extends StatefulWidget {
  const DocumentTabbedView({super.key, required this.tabs});

  final List<DocumentTabSpec> tabs;

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
            hint: 'Nomor dokumen, judul, atau departemen',
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
        Expanded(
          child: DocumentListTab(
            // Ganti key tiap pindah tab supaya BlocProvider di dalamnya
            // dibuat ulang (fetch dokumen tab yang baru), bukan
            // mempertahankan bloc/data tab sebelumnya.
            key: ValueKey(_tabIndex),
            fetcher: tabs[_tabIndex].fetcher,
            searchQuery: _searchQuery,
          ),
        ),
      ],
    );
  }
}
