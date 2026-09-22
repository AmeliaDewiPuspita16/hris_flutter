import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/date_formatter.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../../../../../../core/widgets/status_badge.dart';
import '../../domain/hse_work_request.dart';
import '../../domain/hse_request_status.dart';
import '../../domain/hse_request_category.dart';

// Satu baris tabel web ("ID Register, Name, Dept, Category, Date,
/// Location, Acknowledge, Approval, Status") diringkas jadi satu card
class HseRequestCard extends StatelessWidget {
  const HseRequestCard({super.key, required this.request, required this.onTap});

  final HseWorkRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categories = [
      ...request.typeOfWorks,
      if (request.otherTypeOfWork != null) request.otherTypeOfWork!,
    ];
    final visibleCategories = categories.take(2).toList();
    final extraCount = categories.length - visibleCategories.length;

    final dateLabel = request.dateStart == request.dateEnd ||
            DateFormatter.shortDateID(request.dateStart) ==
                DateFormatter.shortDateID(request.dateEnd)
        ? DateFormatter.shortDateID(request.dateStart)
        : '${DateFormatter.shortDateID(request.dateStart)} – '
            '${DateFormatter.shortDateID(request.dateEnd)}';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.idRegister ?? 'Draft belum tersimpan',
                  style: AppTextStyles.sectionTitle.copyWith(color: AppColors.primary),
                ),
              ),
              StatusBadge(status: request.status.appStatus, label: request.status.label),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.pic,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            request.department,
            style: AppTextStyles.caption,
          ),
          if (visibleCategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final category in visibleCategories) _CategoryTag(label: category),
                if (extraCount > 0) _CategoryTag(label: '+$extraCount lainnya'),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(dateLabel, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.hseRequestBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.hseRequest),
      ),
    );
  }
}
