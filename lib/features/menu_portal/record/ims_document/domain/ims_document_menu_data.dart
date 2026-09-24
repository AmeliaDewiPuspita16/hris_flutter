import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'ims_document_menu_item.dart';

/// Data daftar opsi pada bottom sheet IMS Document.
///
/// Disusun sebagai function (bukan konstanta statis) karena tiap item butuh
/// [VoidCallback] dari pemanggil — pola sama dengan `RecordDemoData`.
class ImsDocumentMenuData {
  ImsDocumentMenuData._();

  static List<ImsDocumentMenuItem> items({
    required VoidCallback onMasterDocumentFile,
    required VoidCallback onMasterEditedFile,
    required VoidCallback onIsoAttachment,
    required VoidCallback onAddMasterDocument,
    required VoidCallback onAddMasterEdited,
    required VoidCallback onRequest,
    required VoidCallback onHistoryRequestUser,
    required VoidCallback onImsDocumentRequest,
  }) =>
      [
        ImsDocumentMenuItem(
          icon: Icons.folder_open_outlined,
          label: 'Master Document File',
          description: 'Manual, SOP, WI, Form, ANNEX, Form Template',
          color: AppColors.primary,
          background: AppColors.primaryLight,
          onTap: onMasterDocumentFile,
        ),
        ImsDocumentMenuItem(
          icon: Icons.edit_document,
          label: 'Master Edited File',
          description: 'Manual, SOP, WI, ANNEX',
          color: AppColors.itRequest,
          background: AppColors.itRequestBg,
          onTap: onMasterEditedFile,
        ),
        ImsDocumentMenuItem(
          icon: Icons.attach_file_outlined,
          label: 'ISO Attachment',
          description: 'ISO Document',
          color: AppColors.teal,
          background: AppColors.tealBg,
          onTap: onIsoAttachment,
        ),
        ImsDocumentMenuItem(
          icon: Icons.note_add_outlined,
          label: 'Add Master Document',
          description: 'Add Document',
          color: AppColors.estRequest,
          background: AppColors.estRequestBg,
          onTap: onAddMasterDocument,
        ),
        ImsDocumentMenuItem(
          icon: Icons.post_add_outlined,
          label: 'Add Master Edited',
          description: 'Add Document',
          color: AppColors.accent,
          background: AppColors.accentBg,
          onTap: onAddMasterEdited,
        ),
        ImsDocumentMenuItem(
          icon: Icons.request_page_outlined,
          label: 'Request',
          description: 'Request Document',
          color: AppColors.violet,
          background: AppColors.violetBg,
          onTap: onRequest,
        ),
        ImsDocumentMenuItem(
          icon: Icons.history_outlined,
          label: 'History Request User',
          description: 'History Request',
          color: AppColors.orange,
          background: AppColors.orangeBg,
          onTap: onHistoryRequestUser,
        ),
        ImsDocumentMenuItem(
          icon: Icons.fact_check_outlined,
          label: 'IMS Document Request',
          description: 'Request, System Assurance, dashboard',
          color: AppColors.neutral,
          background: AppColors.neutralBg,
          onTap: onImsDocumentRequest,
        ),
      ];
}
