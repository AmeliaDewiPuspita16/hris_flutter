import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/back_header.dart';
import '../../domain/record_demo_data.dart';
import '../../ims_document/domain/ims_document_menu_data.dart';
import '../../ims_document/presentation/screens/master_document_file_screen.dart';
import '../../ims_document/presentation/widgets/ims_document_menu_sheet.dart';
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
        MaterialPageRoute(builder: (_) => MasterDocumentFileScreen()),
      ),
      onMasterEditedFile: () => _showComingSoon(context, 'Master Edited File'),
      onIsoAttachment: () => _showComingSoon(context, 'ISO Attachment'),
      onAddMasterDocument: () => _showComingSoon(context, 'Add Master Document'),
      onAddMasterEdited: () => _showComingSoon(context, 'Add Master Edited'),
      onRequest: () => _showComingSoon(context, 'Request'),
      onHistoryRequestUser: () => _showComingSoon(context, 'History Request User'),
      onImsDocumentRequest: () => _showComingSoon(context, 'IMS Document Request'),
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
      onCompanyProfile: () => _showComingSoon(context, 'Company Profile'),
      onContract: () => _showComingSoon(context, 'Contract'),
      onEngineeringDrawing: () => _showComingSoon(context, 'Engineering Drawing'),
      onImsDocument: () => _openImsDocument(context),
      onLicensePermitCertificate: () =>
          _showComingSoon(context, 'License, Permit and Certificate'),
      onNewsClipping: () => _showComingSoon(context, 'News Clipping'),
      onPhotoVideo: () => _showComingSoon(context, 'Photo & Video'),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Records',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              'DOCUMENT CENTER',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16, left: 4),
            child: Text(
              'Akses dokumen dan arsip perusahaan berdasarkan kategori.',
              style: AppTextStyles.bodyMuted,
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            RecordTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}
