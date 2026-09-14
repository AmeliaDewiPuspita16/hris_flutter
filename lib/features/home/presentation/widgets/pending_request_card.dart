import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';

/// Ringkasan pengajuan yang masih menunggu keputusan.
///
/// Ikut hilang sendiri kalau [count] nol.
class PendingRequestCard extends StatelessWidget {
  const PendingRequestCard({
    super.key,
    required this.count,
    required this.description,
    required this.onTap,
  });

  final int count;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Requests',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.primaryMid,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: AppColors.primaryMid),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
