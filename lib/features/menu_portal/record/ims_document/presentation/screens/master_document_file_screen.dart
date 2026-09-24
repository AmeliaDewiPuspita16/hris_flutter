import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../data/master_document_repository.dart';
import '../../domain/master_document.dart';
import '../bloc/master_document_list_bloc.dart';
import '../bloc/master_document_list_event.dart';
import '../bloc/master_document_list_state.dart';
import '../widgets/master_document_tile.dart';

/// Index 0 (Manual) dan 1 (SOP) sudah tersambung ke data — lihat
/// [MasterDocumentRepository]. Tab lain menyusul.
const _tabLabels = [
  'Manual',
  'Standart Operational Procedure',
  'Work Instruction',
  'Form',
  'ANNEX',
  'Form Template',
];

/// Halaman "Document File" — 6 tab kategori dokumen master IMS, dibuka dari
/// opsi "Master Document File" di bottom sheet `ImsDocumentMenuSheet`.
///
/// [repository] masih data demo statis (belum tersambung API), jadi dibuat
/// sendiri lewat konstruktor bila tidak diisi — pola sama dengan
/// `HseWorkRequestListScreen` — bukan lewat `context.read` yang butuh
/// `RepositoryProvider` di `main.dart`.
class MasterDocumentFileScreen extends StatefulWidget {
  MasterDocumentFileScreen({super.key, MasterDocumentRepository? repository})
      : repository = repository ?? MasterDocumentRepository();

  final MasterDocumentRepository repository;

  @override
  State<MasterDocumentFileScreen> createState() => _MasterDocumentFileScreenState();
}

class _MasterDocumentFileScreenState extends State<MasterDocumentFileScreen> {
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
    final repository = widget.repository;
    final fetcher = _fetcherFor(repository, _tabIndex);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Document File',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
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
          _buildTabBar(),
          const SizedBox(height: 12),
          Expanded(
            child: fetcher != null
                ? _DocumentTab(
                    // Ganti key tiap pindah tab supaya BlocProvider di
                    // dalamnya dibuat ulang (fetch dokumen tab yang baru),
                    // bukan mempertahankan bloc/data tab sebelumnya.
                    key: ValueKey(_tabIndex),
                    fetcher: fetcher,
                    searchQuery: _searchQuery,
                  )
                : _ComingSoonTab(label: _tabLabels[_tabIndex]),
          ),
        ],
      ),
    );
  }

  /// Method repository untuk tab ke-[index], atau null kalau tabnya belum
  /// dikerjakan (masih tampil [_ComingSoonTab]).
  Future<List<MasterDocument>> Function()? _fetcherFor(
    MasterDocumentRepository repository,
    int index,
  ) {
    return switch (index) {
      0 => repository.fetchManualDocuments,
      1 => repository.fetchSopDocuments,
      2 => repository.fetchWiDocuments,
      3 => repository.fetchFormDocuments,
      4 => repository.fetchAnnexDocuments,
      5 => repository.fetchFormTemplateDocuments,
      _ => null,
    };
  }

  /// Deret chip tab, pola sama dengan `PrStatusFilterBar` di Procurement:
  /// duduk langsung di atas `AppColors.bg`, tanpa dibungkus container putih
  /// + garis bawah seperti sebelumnya — supaya search box di atasnya terasa
  /// menyatu dengan tab, bukan dua panel terpisah.
  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < _tabLabels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _TabChip(
              label: _tabLabels[i],
              active: _tabIndex == i,
              onTap: () => setState(() => _tabIndex = i),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Isi satu tab dokumen (Manual, SOP, dst) — daftar dokumen dari [fetcher]
/// yang mana pun, disaring lokal oleh [searchQuery].
///
/// Dipakai ulang untuk tiap tab yang sudah tersambung data, tinggal beda
/// [fetcher]-nya (`repository.fetchManualDocuments`,
/// `repository.fetchSopDocuments`, dst) — sama seperti `MasterDocumentListBloc`
/// yang sudah didesain generik per kategori.
class _DocumentTab extends StatelessWidget {
  const _DocumentTab({super.key, required this.fetcher, required this.searchQuery});

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
  /// termuat sekaligus)
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

/// Placeholder untuk tab yang belum dikerjakan (ANNEX, Form Template) —
/// sama pola dengan `RecordScreen._showComingSoon`, tapi sebagai isi tab,
/// bukan snackbar, karena tab tetap harus menampilkan sesuatu saat dipilih.
class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_empty, size: 32, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              '$label belum tersedia',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
