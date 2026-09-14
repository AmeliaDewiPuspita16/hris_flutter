import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Baris "Keep me signed in" beserta tautan "Forgot?" di sisi kanan.
class KeepSignedInRow extends StatelessWidget {
  const KeepSignedInRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onForgotPressed,
  });

  final bool value;
  final VoidCallback onChanged;
  final VoidCallback onForgotPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Checkbox dibuat manual agar sudutnya membulat seperti desain —
        // Checkbox bawaan Material sulit disesuaikan sejauh itu.
        GestureDetector(
          onTap: onChanged,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onChanged,
            behavior: HitTestBehavior.opaque,
            child: const Text(
              'Keep me signed in on this phone',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: AppColors.textMid,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: onForgotPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Forgot?',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryMid,
            ),
          ),
        ),
      ],
    );
  }
}
