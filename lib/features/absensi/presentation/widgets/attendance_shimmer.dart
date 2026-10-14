import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';

/// Skeleton shimmer untuk isi kartu Log Absensi (ringkasan + kalender)
/// selagi [AbsensiBloc] masih memuat data bulan terpilih. Bentuknya meniru
/// [AttendanceSummaryCard] (3 kotak statistik) dan [AttendanceCalendar]
/// (baris label hari + grid tanggal), supaya layout tidak melompat begitu
/// data datang.
class AttendanceShimmer extends StatelessWidget {
  const AttendanceShimmer({super.key});

  static const _weekdayCount = 7;
  // 6 baris cukup untuk menampung bulan mana pun (28-31 hari + leading blank).
  static const _gridRows = 6;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                const Expanded(child: _ShimmerBox(height: 54, borderRadius: 12)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < _weekdayCount; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                const Expanded(
                  child: Center(
                    child: _ShimmerBox(width: 20, height: 10, borderRadius: 3),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _weekdayCount,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: _weekdayCount * _gridRows,
            itemBuilder: (context, index) =>
                const _ShimmerBox(borderRadius: 10),
          ),
        ],
      ),
    );
  }
}

/// Kotak abu-abu polos, dasar bentuk setiap bagian [AttendanceShimmer].
class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({this.width, this.height, this.borderRadius = 6});

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
