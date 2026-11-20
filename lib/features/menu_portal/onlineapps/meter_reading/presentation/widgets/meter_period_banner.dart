import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/meter_period.dart';

/// Keterangan periode di atas daftar.
///
/// - Tidak ada periode aktif -> banner peringatan (tidak ada yang bisa dicatat).
/// - User tanpa hak tulis -> banner "hanya-baca".
/// - Selain itu -> satu baris kecil berisi label periode aktif.
///
/// [MeterPeriod.label] ditampilkan apa adanya, tidak diformat ulang.
class MeterPeriodBanner extends StatelessWidget {
  const MeterPeriodBanner({
    super.key,
    required this.activePeriod,
    required this.canWrite,
  });

  final MeterPeriod? activePeriod;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final period = activePeriod;

    if (period == null) {
      return _notice(
        icon: Icons.event_busy_outlined,
        title: 'No active reading period',
        message: 'Readings cannot be recorded until a period is activated.',
      );
    }

    if (!canWrite) {
      return _notice(
        icon: Icons.visibility_outlined,
        title: 'View only',
        message: 'You do not have permission to record readings. '
            'Active period: ${period.label}',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Row(
        children: [
          Icon(Icons.event_outlined, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Active period · ${period.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accentBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(message, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
