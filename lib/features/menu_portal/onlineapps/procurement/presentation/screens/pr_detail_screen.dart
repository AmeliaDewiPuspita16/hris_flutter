import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/currency_formatter.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../../core/widgets/detail_field_tile.dart';
import '../../domain/purchase_requisition.dart';
import '../widgets/approval_progress_timeline.dart';
import '../widgets/document_progress_timeline.dart';
import '../widgets/pr_attachment_tile.dart';
import '../widgets/pr_detail_hero.dart';
import '../widgets/pr_item_count_chip.dart';
import '../widgets/pr_item_tile.dart';
import '../widgets/pr_section_title.dart';

/// Layar detail satu Purchase Requisition — padanan modal "PR Detail" di web.
///
/// Dibuka sebagai halaman penuh, bukan bottom sheet: isinya panjang (info,
/// item, lampiran, dua timeline) dan modal setinggi itu jadi sesak di HP.
class PrDetailScreen extends StatelessWidget {
  const PrDetailScreen({super.key, required this.requisition});

  final PurchaseRequisition requisition;

  // TODO(eproc-export): ganti dengan export PDF asli begitu endpoint-nya ada.
  void _notYetAvailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature belum tersedia.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: requisition.prNumber,
        onBack: () => Navigator.of(context).pop(),
        trailing: InkWell(
          onTap: () => _notYetAvailable(context, 'Export PDF'),
          child: const Icon(
            Icons.picture_as_pdf_outlined,
            size: 20,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrDetailHero(requisition: requisition),
            const SizedBox(height: 20),
            _buildInformation(),
            const SizedBox(height: 18),
            _buildPurpose(),
            const SizedBox(height: 18),
            _buildItems(),
            if (requisition.attachments.isNotEmpty) ...[
              const SizedBox(height: 18),
              _buildAttachments(context),
            ],
            if (requisition.approvalSteps.isNotEmpty) ...[
              const SizedBox(height: 18),
              _buildApprovalProgress(),
            ],
            if (requisition.documentStages.isNotEmpty) ...[
              const SizedBox(height: 18),
              _buildDocumentProgress(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrSectionTitle(title: 'INFORMASI', icon: Icons.description_outlined),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              DetailFieldTile(
                label: 'Date',
                value: DateFormatter.shortDate(requisition.date),
              ),
              DetailFieldTile(label: 'Department', value: requisition.department),
              DetailFieldTile(label: 'Section', value: requisition.section),
              DetailFieldTile(label: 'Requestor', value: requisition.requestor),
              DetailFieldTile(
                label: 'Required Date',
                value: DateFormatter.shortDate(requisition.requiredDate),
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurpose() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrSectionTitle(title: 'PURPOSE', icon: Icons.flag_outlined),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Text(
            requisition.purpose,
            style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrSectionTitle(
          title: 'ITEMS',
          icon: Icons.list_alt_outlined,
          trailing: PrItemCountChip(label: requisition.itemCountLabel),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < requisition.items.length; i++)
                PrItemTile(
                  item: requisition.items[i],
                  number: i + 1,
                  showDivider: true,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    // Labelnya yang mengalah kalau ruang kurang — nominal
                    // total tidak boleh terpotong.
                    const Expanded(
                      child: Text(
                        'Estimated Total',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatRupiah(requisition.estimatedTotal),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrSectionTitle(title: 'ATTACHMENTS', icon: Icons.attach_file),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            children: [
              for (final attachment in requisition.attachments)
                PrAttachmentTile(
                  attachment: attachment,
                  onDownload: () => _notYetAvailable(context, 'Unduh lampiran'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrSectionTitle(
          title: 'APPROVAL PROGRESS',
          icon: Icons.checklist_outlined,
        ),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: ApprovalProgressTimeline(steps: requisition.approvalSteps),
        ),
      ],
    );
  }

  Widget _buildDocumentProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrSectionTitle(
          title: 'PROGRESS DOKUMEN',
          icon: Icons.account_tree_outlined,
        ),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: DocumentProgressTimeline(stages: requisition.documentStages),
        ),
      ],
    );
  }
}
