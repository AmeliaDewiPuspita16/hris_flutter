import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Satu baris timeline: titik di kiri, garis penyambung ke baris berikutnya,
/// isi bebas di kanan.
///
/// Menerima warna dan "sudah tersentuh atau belum" secara langsung, bukan
/// enum tertentu, karena dipakai dua timeline dengan kumpulan keadaan yang
/// berbeda — `ApprovalState` (5 keadaan) dan `DocumentState` (4 keadaan).
class TimelineEntry extends StatelessWidget {
  const TimelineEntry({
    super.key,
    required this.color,
    required this.filled,
    required this.isLast,
    required this.child,
    this.number,
  });

  final Color color;

  /// Titik yang sudah tersentuh digambar padat; yang belum hanya lingkaran
  /// samar, supaya posisi PR terbaca tanpa membaca teksnya.
  final bool filled;

  /// Baris terakhir tidak menggambar garis penyambung.
  final bool isLast;

  final Widget child;

  /// Nomor urut di dalam titik. Null untuk titik polos.
  final int? number;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                _Dot(color: color, filled: filled, number: number),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1.5, color: AppColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.filled, this.number});

  final Color color;
  final bool filled;
  final int? number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: filled ? color : AppColors.border),
      ),
      child: number == null
          ? null
          : Text(
              '$number',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : AppColors.textMuted,
              ),
            ),
    );
  }
}
