import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

/// Kontak bantuan di bagian bawah halaman login.
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Trouble signing in? Contact Admin Dept',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 2),
        Text(
          'ext. 214 · hr@biie.co.id',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
