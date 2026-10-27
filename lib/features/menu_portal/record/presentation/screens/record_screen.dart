import 'package:flutter/material.dart';

import '../../domain/record_demo_data.dart';
import '../../ims_document/domain/ims_document_menu_data.dart';
import '../../ims_document/master_document_file/presentation/screens/master_document_file_screen.dart';
import '../../ims_document/master_edited_file/presentation/screens/master_edited_file_screen.dart';
import '../../ims_document/presentation/widgets/ims_document_menu_sheet.dart';
import '../../../shared/presentation/widgets/portal_category_page.dart';
import '../widgets/record_tile.dart';

/// Halaman daftar Records, dibuka dari salah satu 4 menu utama di
/// Beranda ("Record", "Data", "Online Apps", "Dashboard").
class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  /// Placeholder untuk kategori yang belum punya halamannya sendiri.
  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label belum tersedia')),
    );
  }

  /// "IMS Document" punya 8 sub-menu, jadi tampil lewat bottom sheet dulu —
  /// pola sama dengan `_openWorkOrder` di [OnlineAppsScreen] — bukan halaman
  /// penuh dengan tombol "GO" di tiap baris seperti sebelumnya.
  void _openImsDocument(BuildContext context) {
    final items = ImsDocumentMenuData.items(
      onMasterDocumentFile: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MasterDocumentFileScreen()),
      ),
      onMasterEditedFile: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MasterEditedFileScreen()),
      ),
      onIsoAttachment: () => _showComingSoon(context, 'ISO Attachment'),
      onAddMasterDocument: () =>
          _showComingSoon(context, 'Add Master Document'),
      onAddMasterEdited: () => _showComingSoon(context, 'Add Master Edited'),
      onRequest: () => _showComingSoon(context, 'Request'),
      onHistoryRequestUser: () =>
          _showComingSoon(context, 'History Request User'),
      onImsDocumentRequest: () =>
          _showComingSoon(context, 'IMS Document Request'),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImsDocumentMenuSheet(items: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = RecordDemoData.items(
      // null = belum siap: tile tampil redup & tidak bisa diketuk.
      onCompanyProfile: null,
      onContract: null,
      onEngineeringDrawing: null,
      onImsDocument: () => _openImsDocument(context),
      onLicensePermitCertificate: null,
      onNewsClipping: null,
      onPhotoVideo: null,
    );

    return PortalCategoryPage(
      title: 'Records',
      subtitle: 'Access document and company archives by category.',
      children: [for (final item in items) RecordTile(item: item)],
    );
  }
}
