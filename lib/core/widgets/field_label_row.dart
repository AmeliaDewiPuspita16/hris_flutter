import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Baris label field bergaya "Label ... Required" di bagian atas tiap
/// section form.
///
/// Sebelumnya digandakan identik di 3 modul form (HSE Work Request, EST
/// Request, IT Request); disatukan ke sini karena isinya sama persis dan
/// tidak spesifik ke satu modul manapun.
class FieldLabelRow extends StatelessWidget {
  const FieldLabelRow({
    super.key,
    required this.label,
    this.required = false,
  });

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 11,
              letterSpacing: 0.3,
              color: AppColors.textMuted,
            ),
          ),
          if (required)
            const Text(
              'Required',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: AppColors.rejected,
              ),
            ),
        ],
      ),
    );
  }
}
