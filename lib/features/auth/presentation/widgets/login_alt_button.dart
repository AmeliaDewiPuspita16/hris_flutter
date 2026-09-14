import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Tombol alternatif login (mis. "Use Face ID"): dasar putih, border tipis.
///
/// AppButton belum punya varian putih-berbingkai seperti ini, jadi dibuat
/// terpisah agar varian di AppButton tidak bertambah hanya demi satu layar.
class LoginAltButton extends StatelessWidget {
  const LoginAltButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card,
          // Padding & radius disamakan dengan AppButton supaya tinggi tombol
          // ini sejajar dengan tombol "Sign in" tepat di atasnya.
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}
