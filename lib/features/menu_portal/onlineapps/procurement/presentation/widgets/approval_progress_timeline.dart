import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/approval_step.dart';
import 'timeline_entry.dart';

/// Daftar tahap approval PR, bernomor 1..n dari HOD sampai GM.
class ApprovalProgressTimeline extends StatelessWidget {
  const ApprovalProgressTimeline({super.key, required this.steps});

  final List<ApprovalStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          TimelineEntry(
            state: steps[i].state,
            number: i + 1,
            isLast: i == steps.length - 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  steps[i].title,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: steps[i].state.isFilled
                        ? AppColors.text
                        : AppColors.textMid,
                  ),
                ),
                const SizedBox(height: 2),
                Text(steps[i].note, style: AppTextStyles.caption),
              ],
            ),
          ),
      ],
    );
  }
}
