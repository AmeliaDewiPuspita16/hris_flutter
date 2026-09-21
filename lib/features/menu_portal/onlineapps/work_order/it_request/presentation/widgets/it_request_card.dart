import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../domain/it_request_item.dart';

/// Satu baris di tab "Form IT & Media" — mengemas kolom tabel web
/// (Requestor, Request Type, Description, Approval Status) jadi satu kartu
/// ringkas, sama polanya dengan `EstRequestRow` di EST Request.
class ItRequestCard extends StatelessWidget {
  const ItRequestCard({super.key, required this.item});

  final ItRequestItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${item.requesterName} · ${item.department}',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: item.status.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: item.status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.neutralBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.category.label} (${item.supportType.label})',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMid,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(item.date, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
