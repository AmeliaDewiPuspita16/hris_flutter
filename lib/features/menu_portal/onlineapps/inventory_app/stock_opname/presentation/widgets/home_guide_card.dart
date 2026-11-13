import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import 'opname_text_styles.dart';

/// The "How to use" guide card on the home screen.
/// To change the steps, edit the [_steps] list below.
class HomeGuideCard extends StatelessWidget {
  const HomeGuideCard({super.key});

  static const _steps = <_GuideStep>[
    _GuideStep(
      icon: Icons.warehouse_outlined,
      title: 'Scan a rack',
      desc: 'The items on that rack appear right away.',
    ),
    _GuideStep(
      icon: Icons.sell_outlined,
      title: 'Scan an item',
      desc: 'Opens the item detail directly, skipping the list.',
    ),
    _GuideStep(
      icon: Icons.edit_outlined,
      title: 'Enter quantity',
      desc: 'Tap an item card to enter the counted quantity.',
    ),
    _GuideStep(
      icon: Icons.check_circle_outline,
      title: 'Confirm',
      desc: 'Tap Confirm once everything has been counted.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOW TO USE', style: OpnameTextStyles.sectionLabel),
          const SizedBox(height: 14),
          for (var i = 0; i < _steps.length; i++)
            _GuideStepRow(
              number: i + 1,
              step: _steps[i],
              isLast: i == _steps.length - 1,
            ),
        ],
      ),
    );
  }
}

/// Data for a single step.
class _GuideStep {
  final IconData icon;
  final String title;
  final String desc;

  const _GuideStep({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

/// A single step row: round icon + connecting line on the left,
/// number + title + description on the right.
class _GuideStepRow extends StatelessWidget {
  final int number;
  final _GuideStep step;
  final bool isLast;

  const _GuideStepRow({
    required this.number,
    required this.step,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle
                  ),
                  child: Icon(step.icon, size: 18, color: AppColors.primaryText),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    )
                  )
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 12 : 18, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$number. ${step.title}', style: OpnameTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(step.desc, style: AppTextStyles.label),
                ],
              ),
            )
          )
        ],
      ),
    );
  }
}
