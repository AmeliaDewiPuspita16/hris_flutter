import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Baris label field bergaya "Label ... REQUIRED" di bagian atas form.
class FieldLabelRow extends StatelessWidget {
  const FieldLabelRow({
    super.key, 
    required this.label, 
    this.required = false
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
