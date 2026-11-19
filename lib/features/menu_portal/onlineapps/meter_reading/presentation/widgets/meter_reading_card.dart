import 'package:material_ui/material_ui.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../domain/meter_reading_state.dart';
import '../../domain/meter_reading_summary.dart';
import '../../domain/meter_value_format.dart';
import 'meter_reading_state_badge.dart';
import 'meter_type_avatar.dart';

/// Satu meter di daftar — angka terakhir sebagai fokus.
///
/// Hierarki kartu: identitas (perusahaan + lokasi) di kiri, angka terakhir
/// besar di kanan, lalu satu baris meta (periode + status). Meter yang BELUM
/// dicatat diberi garis aksen kuning di tepi kiri dan tombol "Record reading"
/// penuh-lebar, supaya pekerjaan yang tersisa terbaca sekilas saat menggulir.
/// Yang sudah dicatat tampil tenang di kartu putih.
class MeterReadingCard extends StatelessWidget {
  const MeterReadingCard({
    super.key,
    required this.reading,
    this.onTap,
    this.onRecord,
  });

  final MeterReadingSummary reading;
  final VoidCallback? onTap;

  /// Hanya dipakai bila [MeterReadingSummary.canRecord].
  final VoidCallback? onRecord;

  @override
  Widget build(BuildContext context) {
    final pending = reading.state == MeterReadingState.pending;
    final value = reading.lastValue;
    final unit = reading.type.unit;
    final period = '${DateFormatter.shortDate(reading.period.start)} – '
        '${DateFormatter.shortDate(reading.period.end)}';
    final showRecord = reading.canRecord && onRecord != null;

    return Semantics(
      container: true,
      label: '${reading.company}, ${reading.location}, ${reading.state.label}',
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
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MeterTypeAvatar(
                                      type: reading.type, size: 44, soft: true),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.place_outlined,
                                              size: 14,
                                              color: AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                reading.location,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.caption,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _LastValue(
                                      value: value,
                                      unit: unit,
                                      reading: reading),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.border),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.event_outlined,
                                      size: 15, color: AppColors.textMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      period,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  MeterReadingStateBadge(state: reading.state),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showRecord) _RecordButton(onTap: onRecord!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Angka terakhir + satuan, rata kanan. Satuan memakai warna jenis meter.
class _LastValue extends StatelessWidget {
  const _LastValue(
      {required this.value, required this.unit, required this.reading});

  final num? value;
  final String unit;
  final MeterReadingSummary reading;

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

/// Aksi di dasar kartu yang belum dicatat: tonal (hijau pucat + teks hijau),
/// bukan blok hijau penuh — dengan banyak kartu belum dicatat, blok penuh
/// yang berulang terlalu berat. Tombol utama yang tegas ada di form.
class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.edit_note_rounded,
                    size: 20, color: AppColors.primaryText),
                const SizedBox(width: 8),
                Text(
                  'Record reading',
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

/// Skeleton satu [MeterReadingCard]: ikon, dua baris keterangan, angka di
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
