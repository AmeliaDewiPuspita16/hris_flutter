import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../domain/meter_reading.dart';
import '../../domain/meter_reading_summary.dart';
import '../../domain/meter_value_format.dart';
import 'meter_reading_state_badge.dart';

/// Kepala layar detail: siapa, di mana, angka terakhir, dan pemakaian
/// periode ini — di atas kartu hijau bergradasi.
///
/// [reading] bisa berupa ringkasan dari daftar (langsung tergambar selagi
/// rincian diambil); [detail] baru ada setelah rincian datang, dan hanya
/// dari situ pemakaian bisa dihitung.
class MeterDetailHero extends StatelessWidget {
  const MeterDetailHero({super.key, required this.reading, this.detail});

  final MeterReadingSummary reading;
  final MeterReading? detail;

  @override
  Widget build(BuildContext context) {
    final value = reading.lastValue;
    final unit = reading.type.unit;
    final usage = detail?.totalConsumption;
    final period = '${DateFormatter.shortDate(reading.period.start)} – '
        '${DateFormatter.shortDate(reading.period.end)}';

    final onDark = AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.78));

    // Ringkas: satu blok datar (tanpa gradasi/lingkaran dekor), angka 30pt,
    // pemakaian sebaris dengan angka, periode di baris terakhir.
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(reading.type.icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reading.company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      reading.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: onDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              MeterReadingStateBadge(state: reading.state),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAST READING',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value == null ? '—' : formatMeterValue(value),
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                        if (unit.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text(
                            unit,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.80),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (usage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        '${formatMeterValue(usage)}${unit.isEmpty ? '' : ' $unit'}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 14, color: Colors.white.withValues(alpha: 0.78)),
              const SizedBox(width: 6),
              Text(period, style: onDark),
            ],
          ),
        ],
      ),
    );
  }
}
