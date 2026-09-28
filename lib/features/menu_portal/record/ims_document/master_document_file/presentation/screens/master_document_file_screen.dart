import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../data/master_document_repository.dart';
import '../../../shared/presentation/widgets/document_tabbed_view.dart';

/// Halaman "Document File" — 6 tab kategori dokumen master IMS, dibuka dari
/// opsi "Master Document File" di bottom sheet `ImsDocumentMenuSheet`.
///
/// [repository] masih data demo statis (endpoint Record belum tersedia),
/// jadi dibuat sendiri lewat konstruktor bila tidak diisi — pola sama dengan
/// `HseWorkRequestListScreen` — bukan lewat `context.read` yang butuh
/// `RepositoryProvider` di `main.dart`.
///
/// Search, chip tab, dan daftar dokumennya ada di [DocumentTabbedView]
/// (dipakai bersama `MasterEditedFileScreen`).
class MasterDocumentFileScreen extends StatelessWidget {
  MasterDocumentFileScreen({super.key, MasterDocumentRepository? repository})
      : repository = repository ?? MasterDocumentRepository();

  final MasterDocumentRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Document File',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: DocumentTabbedView(
        tabs: [
          DocumentTabSpec(label: 'Manual', fetcher: repository.fetchManualDocuments),
          DocumentTabSpec(
            label: 'Standart Operational Procedure',
            fetcher: repository.fetchSopDocuments,
          ),
          DocumentTabSpec(label: 'Work Instruction', fetcher: repository.fetchWiDocuments),
          DocumentTabSpec(label: 'Form', fetcher: repository.fetchFormDocuments),
          DocumentTabSpec(label: 'ANNEX', fetcher: repository.fetchAnnexDocuments),
          DocumentTabSpec(
            label: 'Form Template',
            fetcher: repository.fetchFormTemplateDocuments,
          ),
        ],
      ),
    );
  }
}
