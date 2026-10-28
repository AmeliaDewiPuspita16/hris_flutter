import 'package:flutter/material.dart';

import '../../../../../shared/presentation/widgets/portal_category_page.dart';
import '../../data/master_edited_document_repository.dart';
import '../../../shared/presentation/widgets/document_tabbed_view.dart';

/// Halaman "Edited File" — 4 tab kategori dokumen edited IMS (Manual, SOP,
/// WI, ANNEX), dibuka dari opsi "Master Edited File" di bottom sheet
/// `ImsDocumentMenuSheet`.
///
/// Tampilannya sama dengan `MasterDocumentFileScreen`; yang beda hanya
/// jumlah tab.
///
/// [repository] masih data demo statis (endpoint-nya belum tersedia), jadi
/// dibuat sendiri lewat konstruktor bila tidak diisi.
class MasterEditedFileScreen extends StatelessWidget {
  MasterEditedFileScreen({super.key, MasterEditedDocumentRepository? repository})
      : repository = repository ?? MasterEditedDocumentRepository();

  final MasterEditedDocumentRepository repository;

  @override
  Widget build(BuildContext context) {
    return PortalModulePage(
      eyebrow: 'IMS DOCUMENT',
      title: 'Edited File',
      subtitle: 'Browse IMS documents that are being revised.',
      illustrationAsset: PortalCategoryPage.folderIllustration,
      body: DocumentTabbedView(
        tabs: [
          DocumentTabSpec(
            label: 'Manual',
            count: repository.manualCount,
            fetcher: repository.fetchManualDocuments,
          ),
          DocumentTabSpec(
            label: 'Standart Operational Procedure',
            count: repository.sopCount,
            fetcher: repository.fetchSopDocuments,
          ),
          DocumentTabSpec(
            label: 'Work Instruction',
            count: repository.wiCount,
            fetcher: repository.fetchWiDocuments,
          ),
          DocumentTabSpec(
            label: 'ANNEX',
            count: repository.annexCount,
            fetcher: repository.fetchAnnexDocuments,
          ),
        ],
      ),
    );
  }
}
