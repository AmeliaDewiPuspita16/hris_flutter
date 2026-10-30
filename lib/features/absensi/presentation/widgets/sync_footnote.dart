import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Catatan kecil di bawah daftar, mengingatkan absensi disinkron otomatis
/// dari mesin fingerprint, bukan diinput lewat aplikasi.
class SyncFootnote extends StatelessWidget {
  const SyncFootnote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline, size: 13, color: AppColors.textMuted),
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Data is recorded automatically from the office fingerprint machine and synced from the HRIS web. Attendance is not done through this app.',
              style: TextStyle(
                  fontSize: 10.5, color: AppColors.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
