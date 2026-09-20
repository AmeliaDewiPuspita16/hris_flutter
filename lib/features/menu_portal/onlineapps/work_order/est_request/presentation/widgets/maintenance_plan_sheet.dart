import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/est_request_item.dart';

/// Bottom sheet "Response Request" — dibuka lewat baris dengan status
/// [EstRequestStatus.maintenancePlan] (tombol hijau bermata di web).
///
/// Menampilkan ulang ringkasan request (Name/Type/Location/Description)
/// ditambah kartu rencana kerja (Working Method & Material and Tools) dan
/// catatan approval di bawahnya.
class MaintenancePlanSheet extends StatelessWidget {
  const MaintenancePlanSheet({super.key, required this.item});

  final EstRequestItem item;

  @override
  Widget build(BuildContext context) {
    final plan = item.plan;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Response Request', style: AppTextStyles.sectionTitle),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Name', value: item.requesterName),
                    _InfoRow(label: 'Type of Request', value: item.type.label.toUpperCase()),
                    _InfoRow(label: 'Location', value: item.location),
                    _InfoRow(label: 'Description', value: item.description, showDivider: false),
                    const SizedBox(height: 16),
                    const Text('Maintenance Plan :', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    if (plan != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(10),
                          border: const Border(
                            left: BorderSide(color: AppColors.present, width: 3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PlanField(
                              icon: Icons.build_circle_outlined,
                              title: 'Working Method',
                              value: plan.workingMethod,
                            ),
                            const SizedBox(height: 12),
                            _PlanField(
                              icon: Icons.construction_outlined,
                              title: 'Material and Tools',
                              value: plan.materialAndTools,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '— ${plan.approvalNote}',
                              style: AppTextStyles.caption.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Close', style: AppTextStyles.buttonText.copyWith(color: AppColors.text)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.showDivider = true});

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider ? const Border(bottom: BorderSide(color: AppColors.border)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _PlanField extends StatelessWidget {
  const _PlanField({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.presentMid),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.presentMid,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.body),
      ],
    );
  }
}
