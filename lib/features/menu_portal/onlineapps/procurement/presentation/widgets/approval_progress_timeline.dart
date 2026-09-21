import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../domain/approval_step.dart';
import 'timeline_entry.dart';

/// Rantai approval PR, bernomor mengikuti `level` dari server.
class ApprovalProgressTimeline extends StatelessWidget {
  const ApprovalProgressTimeline({super.key, required this.steps});

  final List<ApprovalStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          TimelineEntry(
            color: steps[i].state.color,
            filled: steps[i].state.isFilled,
            number: steps[i].level,
            isLast: i == steps.length - 1,
            child: _StepContent(step: steps[i]),
          ),
      ],
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({required this.step});

  final ApprovalStep step;

  @override
  Widget build(BuildContext context) {
    // Nama pemberi keputusan dan waktunya digabung jadi satu baris: keduanya
    // hanya berarti bersama-sama, dan sering salah satunya kosong.
    final acted = [
      if (step.approver != null) step.approver!,
      if (step.actedAt != null) DateFormatter.dateTimeID(step.actedAt!),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step.label,
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: step.state.isFilled ? AppColors.text : AppColors.textMid,
          ),
        ),
        if (step.subtitle != null && step.subtitle != step.label) ...[
          const SizedBox(height: 1),
          Text(step.subtitle!, style: AppTextStyles.caption),
        ],
        const SizedBox(height: 3),
        Text(
          step.stateLabel,
          style: AppTextStyles.caption.copyWith(
            color: step.state.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (acted.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(acted, style: AppTextStyles.caption),
        ],
        if (step.comments != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.neutralBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              step.comments!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMid,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
