import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/request_category.dart';

/// Dua kartu pilihan "Request type" (IT / Media).
class RequestCategorySelector extends StatelessWidget {
  const RequestCategorySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RequestCategory? value;
  final ValueChanged<RequestCategory> onChanged;

  IconData _iconFor(RequestCategory category) => switch (category) {
        RequestCategory.it => Icons.desktop_windows_outlined,
        RequestCategory.media => Icons.image_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final category in RequestCategory.values) ...[
          if (category != RequestCategory.values.first) const SizedBox(width: 10),
          Expanded(
            child: _CategoryCard(
              category: category,
              icon: _iconFor(category),
              selected: value == category,
              onTap: () => onChanged(category),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final RequestCategory category;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              category.label,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(category.description, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}