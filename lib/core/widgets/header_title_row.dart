import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Judul di header hijau (Leave Request, Log Absensi), dengan tombol kembali
/// opsional.
///
/// Layar-layar itu dulu tab utama (tanpa tombol kembali). Sekarang dibuka
/// dari menu HRIS lewat push, jadi butuh cara kembali di dalam header.
class HeaderTitleRow extends StatelessWidget {
  const HeaderTitleRow({
    super.key,
    required this.title,
    this.showBack = false,
  });

  final String title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          if (showBack) ...[
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.arrow_back, size: 22, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
