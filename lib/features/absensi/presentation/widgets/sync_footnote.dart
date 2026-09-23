import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Catatan kecil di bawah daftar, mengingatkan absensi disinkron otomatis
/// dari mesin fingerprint, bukan diinput lewat aplikasi.
class SyncFootnote extends StatelessWidget {
  const SyncFootnote({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 13, color: AppColors.textMuted),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Data tercatat otomatis dari mesin fingerprint kantor dan tersinkron dari HRIS web. Absensi tidak dilakukan lewat aplikasi ini.',
              style: TextStyle(
                  fontSize: 10.5, color: AppColors.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
