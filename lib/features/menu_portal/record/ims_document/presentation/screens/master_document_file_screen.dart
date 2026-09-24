import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../data/master_document_repository.dart';
import '../bloc/master_document_list_bloc.dart';
import '../bloc/master_document_list_event.dart';
import '../bloc/master_document_list_state.dart';
import '../widgets/master_document_tile.dart';

/// Label tab, urutan & teksnya mengikuti tab di web persis.
///
/// Cuma index 0 (Manual) yang sudah tersambung ke data — lihat
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

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Document File',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabBar(),
          Expanded(
            child: _tabIndex == 0
                ? _ManualTab(repository: repository)
                : _ComingSoonTab(label: _tabLabels[_tabIndex]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

class _ManualTab extends StatelessWidget {
  const _ManualTab({required this.repository});

  final MasterDocumentRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MasterDocumentListBloc(fetcher: repository.fetchManualDocuments)
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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.documents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final document = state.documents[index];

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

  void _showDummyAction(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message (dummy, belum tersambung ke berkas asli)')),
    );
  }
}

/// Placeholder untuk tab yang belum dikerjakan (SOP, WI, Form, ANNEX, Form
/// Template) — sama pola dengan `RecordScreen._showComingSoon`, tapi
/// sebagai isi tab, bukan snackbar, karena tab tetap harus menampilkan
/// sesuatu saat dipilih.
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
