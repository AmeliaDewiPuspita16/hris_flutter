import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../domain/meter_reading_summary.dart';
import '../../domain/meter_record_action.dart';
import '../../domain/meter_value_format.dart';
import 'meter_approval_badge.dart';
import 'meter_type_avatar.dart';

/// Satu record (satu meter) di daftar — angka terakhir sebagai fokus.
///
/// Hierarki kartu: identitas (perusahaan, lokasi, nomor seri) di kiri, angka
/// terakhir besar di kanan, lalu satu baris meta (periode + status). Tombol
/// aksi penuh-lebar hanya muncul untuk pekerjaan yang MENUNGGU petugas
/// (`record` dan `new_reading`); mengedit cukup lewat detail, supaya kartu
/// yang sudah dicatat tampil tenang.
class MeterReadingCard extends StatelessWidget {
  const MeterReadingCard({
    super.key,
    required this.reading,
    this.onTap,
    this.onRecord,
  });

  final MeterReadingSummary reading;
  final VoidCallback? onTap;

  /// Dipanggil tombol aksi di dasar kartu (hanya untuk `record` / `new_reading`).
  final VoidCallback? onRecord;

  bool get _showAction =>
      onRecord != null &&
      (reading.action == MeterRecordAction.record ||
          reading.action == MeterRecordAction.newReading);

  @override
  Widget build(BuildContext context) {
    final value = reading.lastValue;
    final unit = reading.type.unit;

    return Semantics(
      container: true,
      label: '${reading.company}, ${reading.location}, '
          'S/N ${reading.serialNumber}, ${reading.approval.label}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: AppColors.card,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MeterTypeAvatar(type: reading.type, size: 44, soft: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reading.company,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 15,
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _MetaLine(
                                  icon: Icons.place_outlined,
                                  text: reading.location,
                                ),
                                const SizedBox(height: 3),
                                // Nomor seri bisa berupa teks panjang
                                // ("Solar Panel Puja Sera - Electrical").
                                _MetaLine(
                                  icon: Icons.tag_rounded,
                                  text: 'S/N ${reading.serialNumber}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _LastValue(value: value, unit: unit),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(height: 1, thickness: 1, color: AppColors.border),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.event_outlined, size: 15, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reading.period.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                          const SizedBox(width: 8),
                          MeterStatusBadge(reading: reading),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_showAction) _ActionButton(action: reading.action, onTap: onRecord!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}

/// Angka terakhir + satuan, rata kanan. Satuan memakai warna jenis meter.
class _LastValue extends StatelessWidget {
  const _LastValue({required this.value, required this.unit});

  final num? value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'LAST',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value == null ? '—' : formatMeterValue(value!),
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 20,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryText,
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            unit,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Aksi di dasar kartu: tonal (hijau pucat + teks hijau), bukan blok hijau
/// penuh — dengan banyak kartu menunggu, blok penuh yang berulang terlalu
/// berat. Tombol utama yang tegas ada di form.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onTap});

  final MeterRecordAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = action == MeterRecordAction.newReading
        ? Icons.add_circle_outline_rounded
        : Icons.edit_note_rounded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.primaryText),
                const SizedBox(width: 8),
                Text(
                  action.buttonLabel,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton satu [MeterReadingCard]: ikon, tiga baris keterangan, angka di
/// kanan, lalu baris periode + status.
class MeterReadingCardSkeleton extends StatelessWidget {
  const MeterReadingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 44, height: 44, borderRadius: 14),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLine(width: 140, height: 14),
                    SizedBox(height: 8),
                    ShimmerLine(width: 90, height: 10),
                    SizedBox(height: 6),
                    ShimmerLine(width: 110, height: 10),
                  ],
                ),
              ),
              SizedBox(width: 10),
              ShimmerLine(width: 54, height: 20),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              ShimmerLine(width: 150, height: 10),
              Spacer(),
              ShimmerBox(width: 72, height: 22, borderRadius: 20),
            ],
          ),
        ],
      ),
    );
  }
}
