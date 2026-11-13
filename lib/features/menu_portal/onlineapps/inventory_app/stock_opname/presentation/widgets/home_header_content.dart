import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import 'opname_text_styles.dart';

/// Stock opname start screen header content: back button and history button
/// on top, then title, subtitle, and item/rack count chips.
class HomeHeaderContent extends StatelessWidget {
  final int itemCount;
  final int rackCount;
  final VoidCallback onHistoryTap;

  const HomeHeaderContent({
    super.key,
    required this.itemCount,
    required this.rackCount,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.maybePop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Opname history',
              onPressed: onHistoryTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.history_rounded,
                  color: AppColors.primaryText),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Stock Opname',
          style: OpnameTextStyles.title.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Check physical stock by scanning barcodes.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textMid,
          ),
        ),
        const SizedBox(height: 18),
        // Wrap, not Row: with a large font size the chips move to a second
        // line instead of overflowing.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatChip(
              icon: Icons.inventory_2_outlined,
              label: itemCount == 1 ? '1 item' : '$itemCount items',
            ),
            _StatChip(
              icon: Icons.place_outlined,
              label: rackCount == 1 ? '1 rack' : '$rackCount racks',
            ),
          ],
        ),
      ],
    );
  }
}

/// A small chip in the header, e.g. "5 items" or "5 racks".
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryText),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
