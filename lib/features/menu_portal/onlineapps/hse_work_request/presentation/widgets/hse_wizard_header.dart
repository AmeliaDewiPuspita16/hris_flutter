import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Judul step + progress dots untuk wizard Add Permit Request.
///
/// Form HSE punya 4 tab (Information/Items-nya di sini jadi
/// Detail Pekerjaan, General Checklist, Jenis Pekerjaan & APD, Review).
class HseWizardHeader extends StatelessWidget {
  const HseWizardHeader({
    super.key,
    required this.stepIndex,
    required this.stepCount,
    required this.title,
  });

  final int stepIndex;
  final int stepCount;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Langkah ${stepIndex + 1} dari $stepCount',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(title, style: AppTextStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < stepCount; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= stepIndex ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
