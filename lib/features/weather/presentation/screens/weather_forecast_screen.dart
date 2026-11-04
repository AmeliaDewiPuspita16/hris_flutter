import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/back_header.dart';
import '../../domain/weather_forecast.dart';
import '../widgets/temperature_chart.dart';
import '../widgets/weather_icon.dart';

/// Halaman prakiraan cuaca lengkap (dibuka dari chip cuaca di Beranda):
/// kartu "sekarang", strip per 3 jam, grafik suhu, dan ringkasan harian.
class WeatherForecastScreen extends StatelessWidget {
  const WeatherForecastScreen({
    super.key,
    required this.forecast,
    this.now,
    this.isSampleData = false,
  });

  final WeatherForecast forecast;

  /// Untuk test; default [DateTime.now].
  final DateTime? now;

  /// Tampilkan label "Sample data" selama sumber asli belum dipasang.
  final bool isSampleData;

  @override
  Widget build(BuildContext context) {
    final at = now ?? DateTime.now();
    final current = forecast.current(at);
    final upcoming = forecast.upcoming(at);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Weather Forecast',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: current == null
          ? Center(
              child: Text('No forecast available.', style: AppTextStyles.bodyMuted),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _NowCard(forecast: forecast, slot: current),
                if (upcoming.any((s) => s.condition.isRainy)) ...[
                  const SizedBox(height: 12),
                  _RainNotice(
                    slot: upcoming.firstWhere((s) => s.condition.isRainy),
                    now: at,
                  ),
                ],
                const SizedBox(height: 22),
                const _SectionTitle('Next hours'),
                const SizedBox(height: 10),
                _HourStrip(slots: upcoming, currentTime: current.time),
                const SizedBox(height: 22),
                const _SectionTitle('Temperature'),
                const SizedBox(height: 10),
                _Panel(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 10),
                  child: TemperatureChart(slots: forecast.slots, now: at),
                ),
                const SizedBox(height: 22),
                const _SectionTitle('Next days'),
                const SizedBox(height: 10),
                _DaysPanel(days: forecast.days, now: at),
                const SizedBox(height: 18),
                _SourceNote(updatedAt: forecast.updatedAt, isSample: isSampleData),
              ],
            ),
    );
  }
}

final _hourFmt = DateFormat('HH.mm', 'en_US');
final _dayFmt = DateFormat('EEE, d MMM', 'en_US');

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dayLabel(DateTime date, DateTime now) {
  if (_sameDay(date, now)) return 'Today';
  if (_sameDay(date, now.add(const Duration(days: 1)))) return 'Tomorrow';
  return _dayFmt.format(date);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.sectionTitle.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Kartu hijau besar: lokasi, suhu sekarang, kondisi, dan tiga metrik.
class _NowCard extends StatelessWidget {
  const _NowCard({required this.forecast, required this.slot});

  final WeatherForecast forecast;
  final WeatherSlot slot;

  @override
  Widget build(BuildContext context) {
    final white70 = Colors.white.withValues(alpha: 0.75);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  forecast.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'Now · ${_hourFmt.format(slot.time)}',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: white70,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              forecast.area,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: white70,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: '${slot.tempC}',
                        children: const [
                          TextSpan(
                            text: '°C',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 54,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      slot.condition.label,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: WeatherIcon(
                  condition: slot.condition,
                  isNight: slot.isNight,
                  size: 60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.air_rounded,
                  value: '${slot.windKmh.toStringAsFixed(1)} km/h',
                  label: 'Wind',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                  icon: Icons.water_drop_outlined,
                  value: '${slot.humidity}%',
                  label: 'Humidity',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                  icon: Icons.explore_outlined,
                  value: '${slot.windFrom} – ${slot.windTo}',
                  label: 'Direction',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Light rain expected at 09.00 tomorrow — bring an umbrella."
class _RainNotice extends StatelessWidget {
  const _RainNotice({required this.slot, required this.now});

  final WeatherSlot slot;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final day = _dayLabel(slot.time, now).toLowerCase();
    final when = day == 'today'
        ? 'at ${_hourFmt.format(slot.time)}'
        : '$day at ${_hourFmt.format(slot.time)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inProgressBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.beach_access_rounded, size: 20, color: AppColors.inProgress),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${slot.condition.label} expected $when. Bring an umbrella.',
              style: AppTextStyles.body.copyWith(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourStrip extends StatelessWidget {
  const _HourStrip({required this.slots, required this.currentTime});

  final List<WeatherSlot> slots;
  final DateTime currentTime;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: slots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final slot = slots[i];
          return _HourTile(slot: slot, isNow: slot.time == currentTime);
        },
      ),
    );
  }
}

class _HourTile extends StatelessWidget {
  const _HourTile({required this.slot, required this.isNow});

  final WeatherSlot slot;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final fg = isNow ? Colors.white : AppColors.text;
    final sub = isNow ? Colors.white.withValues(alpha: 0.8) : AppColors.textMuted;
    final isMidnight = slot.time.hour == 0;

    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isNow ? AppColors.primary : AppColors.card,
        gradient: isNow ? AppColors.primaryGradient : null,
        borderRadius: BorderRadius.circular(18),
        border: isNow ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isNow
                ? 'Now'
                : isMidnight
                    ? DateFormat('EEE', 'en_US').format(slot.time)
                    : _hourFmt.format(slot.time),
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              fontWeight: isNow || isMidnight ? FontWeight.w700 : FontWeight.w500,
              color: sub,
            ),
          ),
          WeatherIcon(condition: slot.condition, isNight: slot.isNight, size: 30),
          Text(
            '${slot.tempC}°',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop_rounded, size: 11, color: sub),
              const SizedBox(width: 2),
              Text(
                '${slot.humidity}%',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 10.5,
                  color: sub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DaysPanel extends StatelessWidget {
  const _DaysPanel({required this.days, required this.now});

  final List<WeatherDay> days;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final lo = days.map((d) => d.minC).reduce((a, b) => a < b ? a : b);
    final hi = days.map((d) => d.maxC).reduce((a, b) => a > b ? a : b);

    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (final (i, day) in days.indexed) ...[
            if (i > 0) Divider(height: 1, color: AppColors.border),
            _DayRow(day: day, now: now, rangeMin: lo, rangeMax: hi),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.now,
    required this.rangeMin,
    required this.rangeMax,
  });

  final WeatherDay day;
  final DateTime now;
  final int rangeMin;
  final int rangeMax;

  @override
  Widget build(BuildContext context) {
    final tempStyle = TextStyle(
      fontFamily: AppTextStyles.fontFamily,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dayLabel(day.date, now),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  day.condition.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          WeatherIcon(condition: day.condition, size: 28),
          const SizedBox(width: 14),
          Text('${day.minC}°', style: tempStyle.copyWith(color: AppColors.textMuted)),
          const SizedBox(width: 8),
          Expanded(
            child: _RangeBar(
              min: day.minC,
              max: day.maxC,
              rangeMin: rangeMin,
              rangeMax: rangeMax,
            ),
          ),
          const SizedBox(width: 8),
          Text('${day.maxC}°', style: tempStyle),
        ],
      ),
    );
  }
}

/// Batang rentang suhu harian relatif terhadap rentang semua hari.
class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.min,
    required this.max,
    required this.rangeMin,
    required this.rangeMax,
  });

  final int min;
  final int max;
  final int rangeMin;
  final int rangeMax;

  @override
  Widget build(BuildContext context) {
    final span = (rangeMax - rangeMin).clamp(1, 100);
    final start = (min - rangeMin) / span;
    final end = (max - rangeMin) / span;

    return LayoutBuilder(
      builder: (context, c) {
        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.neutralBg,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              Positioned(
                left: c.maxWidth * start,
                width: (c.maxWidth * (end - start)).clamp(6, c.maxWidth),
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFFFFB300)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SourceNote extends StatelessWidget {
  const _SourceNote({required this.updatedAt, required this.isSample});

  final DateTime updatedAt;
  final bool isSample;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(fontSize: 11.5);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('Source: ', style: style),
            Text(
              'BMKG',
              style: style.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            Text(' · Updated ${_hourFmt.format(updatedAt)}', style: style),
          ],
        ),
        if (isSample) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.pendingBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Sample data, not live yet',
              style: style.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.pending,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
