import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

/// Pembungkus shimmer bersama untuk semua skeleton loading di aplikasi.
///
/// Warnanya sama dengan shimmer yang sudah ada di Beranda
/// (banner jam kerja & approvals waiting): dasar [AppColors.border],
/// kilau [AppColors.bg]. Isi [child] cukup disusun dari [ShimmerBox] /
/// [ShimmerLine] — warna aslinya diabaikan, yang dipakai cuma bentuknya.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.bg,
      child: child,
    );
  }
}

/// Kotak polos pembentuk skeleton. Harus berada di dalam [AppShimmer].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 6,
  });

  /// Lingkaran (mis. avatar) dengan diameter [size].
  const ShimmerBox.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = size / 2;

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

/// Satu baris teks palsu. [width] null = selebar ruang yang tersedia.
class ShimmerLine extends StatelessWidget {
  const ShimmerLine({super.key, this.width, this.height = 12});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(width: width, height: height, borderRadius: 4);
  }
}

/// Kartu skeleton generik (kotak putih + border seperti [AppCard]) berisi
/// [child] yang disusun dari [ShimmerBox] / [ShimmerLine]. Kartunya sendiri
/// diam; hanya isinya yang berkilau.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: AppShimmer(child: child),
    );
  }
}

/// Daftar kartu skeleton — dipakai selagi halaman pertama sebuah list
/// masih dimuat dari API. [itemBuilder] membuat isi tiap kartu, jadi
/// bentuknya bisa disesuaikan dengan kartu aslinya per halaman.
///
/// Tidak bisa digulir sendiri ([NeverScrollableScrollPhysics]) dan
/// [shrinkWrap], supaya aman ditaruh di dalam Column / ListView induk.
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    required this.itemBuilder,
    this.itemCount = 5,
    this.spacing = 10,
    this.padding = EdgeInsets.zero,
  });

  final WidgetBuilder itemBuilder;
  final int itemCount;
  final double spacing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) => itemBuilder(context),
    );
  }
}

/// Skeleton halaman detail generik: [sections] bagian bertumpuk, tiap bagian
/// berupa judul kecil + kartu berisi pasangan label/nilai ([rowsPerSection]
/// jumlah baris di tiap kartu). Cocok dipakai selagi detail dimuat dari API.
class ShimmerDetailSections extends StatelessWidget {
  const ShimmerDetailSections({
    super.key,
    this.rowsPerSection = const [3, 2, 3],
  });

  final List<int> rowsPerSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var s = 0; s < rowsPerSection.length; s++) ...[
          if (s > 0) const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 8),
            child: AppShimmer(child: ShimmerLine(width: 90, height: 11)),
          ),
          ShimmerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rowsPerSection[s]; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  const ShimmerLine(width: 70, height: 9),
                  const SizedBox(height: 6),
                  const ShimmerLine(height: 13),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
