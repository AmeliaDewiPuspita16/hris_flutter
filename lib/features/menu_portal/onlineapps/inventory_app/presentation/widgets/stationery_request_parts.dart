import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Potongan kecil yang dipakai bersama oleh kartu request
/// ([StationeryRequestRow]) dan kartu verifikasi ([StationeryVerificationCard]).

/// Kartu dengan border tipis berwarna sesuai status (hijau = approved, emas =
/// pending, merah = rejected), supaya kartu-kartu yang bertumpuk mudah
/// dibedakan sekilas tanpa menambah blok warna di dalamnya.
class StationeryCard extends StatelessWidget {
  const StationeryCard({
    super.key,
    required this.child,
    required this.borderColor,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 12, 12),
  });

  final Widget child;
  final Color borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withAlpha(95), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Jumlah yang diminta, mis. "6 PCS": teks tebal TANPA latar warna, supaya
/// tidak menumpuk dengan badge status di dekatnya.
class StationeryQuantityText extends StatelessWidget {
  const StationeryQuantityText({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
      ),
    );
  }
}

/// Satu baris info kecil: "REQ00541 · Aditya Yudha Pratama", dengan penanda
/// "You" bila request milik sendiri. Nama panjang dipotong (ellipsis), bukan
/// membungkus ke baris baru.
class StationeryMetaLine extends StatelessWidget {
  const StationeryMetaLine({
    super.key,
    required this.code,
    required this.requester,
    this.isMine = false,
  });

  final String code;
  final String requester;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            '$code · $requester',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryMid),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'You',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryMidText,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
