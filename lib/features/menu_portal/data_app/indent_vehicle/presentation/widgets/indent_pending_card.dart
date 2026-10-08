import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/indent_pending_item.dart';
import 'indent_driver_badge.dart';

/// Kartu satu request di tab "Pending Vehicle Assignment" — mengemas kolom
/// web (Name, Destination, Date, Remark, With Driver, Action) jadi satu
/// kartu. Tombol "Assign" di kanan-bawah menggantikan kolom Action.
class IndentPendingCard extends StatelessWidget {
  const IndentPendingCard({
    super.key,
    required this.item,
    required this.onAssign,
  });

  final IndentPendingItem item;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              IndentDriverBadge(withDriver: item.withDriver),
            ],
          ),
          const SizedBox(height: 6),
          _InfoLine(icon: Icons.place_outlined, text: item.destination),
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.event_outlined,
            text: '${item.date}  ·  ${item.timeRange}',
          ),
          const SizedBox(height: 8),
          Text(
            item.remark,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: onAssign,
              icon: const Icon(Icons.directions_car_outlined, size: 16),
              label: Text(
                'Assign',
                style: AppTextStyles.buttonText.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
