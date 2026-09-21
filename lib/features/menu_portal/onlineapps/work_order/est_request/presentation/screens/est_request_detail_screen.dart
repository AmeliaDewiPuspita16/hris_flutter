import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../../../../../../core/widgets/detail_field_tile.dart';
import '../../domain/est_request_item.dart';
import '../../domain/est_request_status.dart';
import '../widgets/est_request_feedback_sheet.dart';

/// Layar detail EST Request — pengganti PDF report ("Show Details") di
/// web, sementara isinya jadi layar rapi ala app, bukan generate/buka PDF.
///
/// Menyusun ulang semua bagian PDF aslinya: identitas request, method &
/// material/tools, durasi & approval, work implementation, dan feedback
/// user. Kalau statusnya [EstRequestStatus.waitVerifyUser], ada CTA
/// "Verifikasi & Beri Feedback" di bawah — mengembalikan rating lewat
/// Navigator.pop supaya pemanggil (EstRequestScreen) bisa update status.
class EstRequestDetailScreen extends StatelessWidget {
  const EstRequestDetailScreen({super.key, required this.item});

  final EstRequestItem item;

  Future<void> _verifyAndGiveFeedback(BuildContext context) async {
    final rating = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EstRequestFeedbackSheet(description: item.description),
    );

    if (rating == null || !context.mounted) return;
    Navigator.of(context).pop(rating);
  }

  @override
  Widget build(BuildContext context) {
    final plan = item.plan;
    final detail = item.workDetail;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'EST Work Order',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionCard(
            title: 'Request',
            child: Column(
              children: [
                DetailFieldTile(label: 'Name', value: item.requesterName),
                DetailFieldTile(label: 'Date', value: item.date),
                DetailFieldTile(label: 'Type of Request', value: item.type.label),
                DetailFieldTile(label: 'Location', value: item.location, showDivider: false),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Description of request',
            child: Text(item.description, style: AppTextStyles.body.copyWith(height: 1.5)),
          ),
          if (plan != null) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Method & Material',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Method', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(plan.workingMethod, style: AppTextStyles.body),
                  const SizedBox(height: 14),
                  Text('Material and Tools', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(plan.materialAndTools, style: AppTextStyles.body),
                ],
              ),
            ),
          ],
          if (detail != null) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Approval',
              child: Column(
                children: [
                  DetailFieldTile(label: 'Duration', value: detail.duration),
                  DetailFieldTile(label: 'Man Power', value: detail.manPower),
                  DetailFieldTile(label: 'Approve By', value: detail.approvedBy),
                  DetailFieldTile(label: 'Date Approve', value: detail.dateApprove, showDivider: false),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Work Implementation',
              child: Column(
                children: [
                  DetailFieldTile(label: 'Start Date', value: detail.startDate),
                  DetailFieldTile(label: 'End Date', value: detail.endDate),
                  DetailFieldTile(label: 'Work By', value: detail.workBy),
                  DetailFieldTile(label: 'Verification', value: detail.verification, showDivider: false),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Feedback User',
              child: Text(
                detail.feedbackUser ?? 'Belum ada feedback dari requester.',
                style: AppTextStyles.body.copyWith(
                  color: detail.feedbackUser == null ? AppColors.textMuted : AppColors.text,
                  fontStyle: detail.feedbackUser == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ],
          if (item.status == EstRequestStatus.waitVerifyUser) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _verifyAndGiveFeedback(context),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  'Verifikasi & Beri Feedback',
                  style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
