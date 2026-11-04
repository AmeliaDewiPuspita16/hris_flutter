import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Stepper bernomor untuk wizard Add Permit Request: lingkaran 1–4 yang
/// tersambung garis, label pendek di bawahnya, lalu judul + keterangan
/// step aktif. Step yang sudah lewat bertanda centang.
class HseWizardHeader extends StatelessWidget {
  const HseWizardHeader({
    super.key,
    required this.stepIndex,
    required this.labels,
    required this.title,
    required this.subtitle,
  });

  final int stepIndex;

  /// Label pendek tiap step, mis. "Job", "Checklist".
  final List<String> labels;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                Expanded(
                  child: _StepNode(
                    index: i,
                    label: labels[i],
                    current: stepIndex,
                    isLast: i == labels.length - 1,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.presentBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${stepIndex + 1} of ${labels.length} · $title',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.label,
    required this.current,
    required this.isLast,
  });

  final int index;
  final bool isLast;
  final String label;
  final int current;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    final reached = index <= current;
    final lineColor = AppColors.border;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: index == 0
                  ? const SizedBox.shrink()
                  : Container(
                      height: 3,
                      color: reached ? AppColors.primary : lineColor,
                    ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: reached ? AppColors.primary : AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(
                  color: reached ? AppColors.primary : lineColor,
                  width: 2,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 0,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: reached ? Colors.white : AppColors.textMuted,
                      ),
                    ),
            ),
            Expanded(
              child: Container(
                height: 3,
                color: isLast
                    ? Colors.transparent
                    : (index < current ? AppColors.primary : lineColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            fontSize: 10.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: reached ? AppColors.primaryText : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
