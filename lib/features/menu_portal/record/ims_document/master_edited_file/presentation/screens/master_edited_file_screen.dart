import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../data/master_edited_document_repository.dart';
import '../../../shared/presentation/widgets/document_tabbed_view.dart';

/// Halaman "Edited File" — 4 tab kategori dokumen edited IMS (Manual, SOP,
/// WI, ANNEX), dibuka dari opsi "Master Edited File" di bottom sheet
/// `ImsDocumentMenuSheet`.
///
/// Tampilannya sama dengan `MasterDocumentFileScreen`: yang beda hanya
/// jumlah tab, dan dokumen edited hanya punya aksi "Download" (tanpa
/// "Obsolete").
///
/// [repository] masih data demo statis (endpoint Record belum tersedia),
/// jadi dibuat sendiri lewat konstruktor bila tidak diisi — pola sama dengan
/// `MasterDocumentFileScreen`.
class MasterEditedFileScreen extends StatelessWidget {
  MasterEditedFileScreen({super.key, MasterEditedDocumentRepository? repository})
      : repository = repository ?? MasterEditedDocumentRepository();

  final MasterEditedDocumentRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Edited File',
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
          DocumentTabSpec(label: 'ANNEX', fetcher: repository.fetchAnnexDocuments),
        ],
      ),
    );
  }
}
