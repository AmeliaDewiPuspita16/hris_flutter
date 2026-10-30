import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/est_progress_step.dart';

/// Timeline vertikal langkah-langkah Work Order (kolom `progress` dari
/// `GET /est_work_order/{id}`): titik per langkah yang disambung garis,
/// dengan nama langkah, siapa dan kapan, serta catatan bila ada.
///
/// Warna titik mengikuti [EstProgressStep.state]:
/// `done` hijau bercentang, `current` oranye, `rejected` merah, selain itu
/// (`pending`, `skipped`, atau nilai yang tidak dikenal) abu-abu kosong.
class EstProgressTimeline extends StatelessWidget {
  const EstProgressTimeline({super.key, required this.steps});

  final List<EstProgressStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final EstProgressStep step;
  final bool isLast;

  bool get _isDone => step.state == EstProgressStep.stateDone;
  bool get _isCurrent => step.state == EstProgressStep.stateCurrent;
  bool get _isRejected => step.state == EstProgressStep.stateRejected;

  /// Belum dicapai: `pending`, `skipped`, atau nilai tak dikenal.
  bool get _isMuted => !_isDone && !_isCurrent && !_isRejected;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (step.by != null) step.by!,
      if (step.at != null) step.at!,
    ].join(' · ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                _Dot(step: step),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: _isDone ? AppColors.primaryMid : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: _isCurrent ? FontWeight.w700 : FontWeight.w600,
                      color: _isMuted ? AppColors.textMuted : AppColors.text,
                    ),
                  ),
                  if (meta.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(meta, style: AppTextStyles.caption),
                    ),
                  if (step.note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        step.note!,
                        style: AppTextStyles.caption.copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.step});

  final EstProgressStep step;

  @override
  Widget build(BuildContext context) {
    switch (step.state) {
      case EstProgressStep.stateDone:
        return _filled(AppColors.primaryMid, Icons.check);
      case EstProgressStep.stateRejected:
        return _filled(AppColors.rejected, Icons.close);
      case EstProgressStep.stateCurrent:
        return Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2.5),
          ),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        );
      default:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
        );
    }
  }

  Widget _filled(Color color, IconData icon) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 11, color: Colors.white),
    );
  }
}
