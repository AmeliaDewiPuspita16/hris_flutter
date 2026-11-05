import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../domain/stationery_request_status.dart';

/// Potongan kecil yang dipakai bersama oleh kartu request
/// ([StationeryRequestRow]) dan kartu verifikasi ([StationeryVerificationCard]).

/// Kartu polos: border netral tanpa warna. Status cukup dibedakan lewat
/// badge [StationeryStatusPill], jadi kartu tidak perlu ikut berwarna.
class StationeryCard extends StatelessWidget {
  const StationeryCard({
    super.key,
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 12, 12),
  });

  final Widget child;

  /// Tidak dipakai lagi (kartu tanpa garis berwarna); dipertahankan supaya
  /// pemanggil lama tetap jalan.
  final Color? borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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

/// Badge status: titik berwarna + teks label dari server.
class StationeryStatusPill extends StatelessWidget {
  const StationeryStatusPill({super.key, required this.status});

  final StationeryRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Jumlah diminta dalam chip lembut, mis. "6 PCS".
class StationeryQuantityChip extends StatelessWidget {
  const StationeryQuantityChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}

/// Lingkaran inisial peminta ("Aditya Yudha" -> "AY").
class StationeryAvatar extends StatelessWidget {
  const StationeryAvatar({super.key, required this.name, this.size = 20});

  final String name;
  final double size;

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: AppColors.textMid,
        ),
      ),
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
