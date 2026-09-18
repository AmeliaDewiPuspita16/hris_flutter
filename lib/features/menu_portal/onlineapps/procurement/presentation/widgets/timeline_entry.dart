import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/progress_state.dart';

/// Satu baris timeline: titik di kiri, garis penyambung ke baris berikutnya,
/// isi bebas di kanan.
///
/// Dipakai dua timeline di layar detail — "Approval Progress" (titik
/// bernomor) dan "Progress Dokumen" (titik polos) — makanya nomornya
/// opsional.
class TimelineEntry extends StatelessWidget {
  const TimelineEntry({
    super.key,
    required this.state,
    required this.isLast,
    required this.child,
    this.number,
  });

  final ProgressState state;

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
                _Dot(state: state, number: number),
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
  const _Dot({required this.state, this.number});

  final ProgressState state;
  final int? number;

  @override
  Widget build(BuildContext context) {
    final filled = state.isFilled;

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? state.color : state.background,
        shape: BoxShape.circle,
        border: Border.all(color: filled ? state.color : AppColors.border),
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
