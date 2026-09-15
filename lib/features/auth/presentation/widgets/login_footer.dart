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
          'Crafted with extra ❤️',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 2),
        Text(
          'copyright © 2026 PT Bintan Inti Industrial Estate',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
