import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';

/// Lima ikon bintang, terisi sejumlah [rating]. Dipakai di layar detail —
/// rating null (belum dinilai) ditangani pemanggil, bukan di sini.
class ItRequestRatingStars extends StatelessWidget {
  const ItRequestRatingStars({super.key, required this.rating, this.size = 18});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i <= rating ? AppColors.accent : AppColors.border,
          ),
      ],
    );
  }
}
