import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../menu_portal/onlineapps/hse_work_request/presentation/widgets/hse_page_chrome.dart';
import '../../domain/weather_forecast.dart';
import '../widgets/temperature_chart.dart';
import '../widgets/weather_icon.dart';

/// Halaman prakiraan cuaca lengkap (dibuka dari chip cuaca di Beranda):
/// kartu "sekarang", pengingat hujan, strip per 3 jam, grafik suhu, dan
/// ringkasan harian. Latar & tombol memakai gaya halaman portal (mint).
class WeatherForecastScreen extends StatefulWidget {
  const WeatherForecastScreen({
    super.key,
    required this.forecast,
    this.onRefresh,
    this.now,
  });

  /// Prakiraan yang sudah dimuat Beranda — tampil seketika tanpa loading.
  final WeatherForecast forecast;

  /// Tarik-untuk-refresh; null = tidak bisa di-refresh. Melempar
  /// [Exception] bila gagal (data lama tetap tampil).
  final Future<WeatherForecast> Function()? onRefresh;

  /// Untuk test, dalam jam dinding lokasi; default
  /// [WeatherForecast.nowAtLocation].
  final DateTime? now;

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> {
  late WeatherForecast forecast = widget.forecast;

  Future<void> _refresh() async {
    try {
      final fresh = await widget.onRefresh!();
      if (mounted) setState(() => forecast = fresh);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not refresh the forecast. Try again later.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final at = widget.now ?? forecast.nowAtLocation();
    final current = forecast.current(at);
    final upcoming = forecast.upcoming(at);
    final nextRain = upcoming.where((s) => s.condition.isRainy).firstOrNull;

    void openHourly() => _HourlySheet.show(context, slots: upcoming, now: at);

    return HsePageBackdrop(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: current == null
                  ? Center(
                      child: Text(
                        'No forecast available.',
                        style: AppTextStyles.bodyMuted,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh:
                          widget.onRefresh == null ? () async {} : _refresh,
                      notificationPredicate: (n) =>
                          widget.onRefresh != null && n.depth == 0,
                      color: AppColors.primaryText,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          _NowCard(forecast: forecast, slot: current),
                          if (nextRain != null) ...[
                            const SizedBox(height: 14),
                            _RainNotice(
                                slot: nextRain, now: at, onTap: openHourly),
                          ],
                          const SizedBox(height: 22),
                          _SectionTitle(
                            'Next hours',
                            trailing: _SeeMoreButton(onTap: openHourly),
                          ),
                          const SizedBox(height: 12),
                          _HourStrip(
                              slots: upcoming, currentTime: current.time),
                          const SizedBox(height: 22),
                          const _SectionTitle('Temperature'),
                          const SizedBox(height: 12),
                          _Panel(
                            padding: const EdgeInsets.fromLTRB(12, 14, 14, 10),
                            child: TemperatureChart(
                              slots: forecast.slots,
                              now: current.time,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const _SectionTitle('Next days'),
                          const SizedBox(height: 12),
                          _DaysPanel(days: forecast.days, now: at),
                          const SizedBox(height: 18),
                          _SourceNote(forecast: forecast),
                        ],
                      ),
                    ),
            ),
          ],
        ),
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

/// Gradasi hijau kartu "sekarang" & tile "Now" — sedikit lebih cerah dari
/// hijau utama supaya terasa seperti langit siang.
LinearGradient get _skyGradient => AppColors.isDark
    ? AppColors.heroGradient
    : const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2FA374), Color(0xFF117250)],
      );

List<BoxShadow> get _softShadow => [
      BoxShadow(
        color: Colors.black.withValues(alpha: AppColors.isDark ? 0 : 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          HseCircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: onBack,
          ),
          Expanded(
            child: Text(
              'Weather Forecast',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
              ),
            ),
          ),
          // Penyeimbang lebar tombol kembali supaya judul tetap di tengah.
          const SizedBox.square(dimension: 44),
        ],
      ),
    );
  }
}

/// Judul bagian dengan aksen batang hijau di kiri.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _SeeMoreButton extends StatelessWidget {
  const _SeeMoreButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.presentBg,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'See More',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.primaryText),
            ],
          ),
        ),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: _softShadow,
      ),
      child: child,
    );
  }
}

/// Kartu hijau besar: lokasi, suhu sekarang, kondisi, ikon besar dengan
/// hiasan awan + daun, lalu bilah metrik transparan.
class _NowCard extends StatelessWidget {
  const _NowCard({required this.forecast, required this.slot});

  final WeatherForecast forecast;
  final WeatherSlot slot;

  @override
  Widget build(BuildContext context) {
    final white75 = Colors.white.withValues(alpha: 0.78);

    return Container(
      decoration: BoxDecoration(
        gradient: _skyGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF117250)
                .withValues(alpha: AppColors.isDark ? 0 : 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Hiasan: awan samar & daun di kanan bawah.
            Positioned(
              right: 30,
              top: 92,
              child: Icon(
                Icons.cloud_rounded,
                size: 120,
                color: Colors.white.withValues(alpha: 0.13),
              ),
            ),
            Positioned(
              right: -18,
              top: 110,
              child: Transform.rotate(
                angle: -0.5,
                child: Icon(
                  Icons.eco_rounded,
                  size: 76,
                  color: const Color(0xFF5BD39A).withValues(alpha: 0.55),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_rounded,
                          size: 17, color: Colors.white),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          forecast.locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
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
                          color: white75,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 21),
                    child: Text(
                      forecast.area,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        color: white75,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 58,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              slot.conditionLabel,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10, top: 2),
                        child: WeatherIcon(
                          condition: slot.condition,
                          isNight: slot.isNight,
                          size: 76,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _MetricBar(slot: slot),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu bilah kaca berisi angin, kelembapan, dan arah — dipisah garis tipis.
class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.slot});

  final WeatherSlot slot;

  @override
  Widget build(BuildContext context) {
    Widget divider() => Container(
          width: 1,
          height: 40,
          color: Colors.white.withValues(alpha: 0.25),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              icon: Icons.air_rounded,
              value: '${slot.windKmh.toStringAsFixed(1)} km/h',
              label: 'Wind',
            ),
          ),
          divider(),
          Expanded(
            child: _Metric(
              icon: Icons.water_drop_outlined,
              value: '${slot.humidity}%',
              label: 'Humidity',
            ),
          ),
          divider(),
          Expanded(
            child: _Metric(
              icon: Icons.explore_outlined,
              value: '${slot.windFrom} – ${slot.windTo}',
              label: 'Direction',
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
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
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Light rain expected tomorrow at 09.00. Bring an umbrella." — ketuk
/// untuk melihat rincian per jam.
class _RainNotice extends StatelessWidget {
  const _RainNotice(
      {required this.slot, required this.now, required this.onTap});

  final WeatherSlot slot;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final day = _dayLabel(slot.time, now);
    final when = day == 'Today'
        ? 'at ${_hourFmt.format(slot.time)}'
        : '${day.toLowerCase()} at ${_hourFmt.format(slot.time)}';

    return Material(
      color: AppColors.inProgressBg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.inProgress.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.beach_access_rounded,
                  size: 22,
                  color: AppColors.inProgress,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${slot.conditionLabel} expected $when. Bring an umbrella.',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.text,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
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
      height: 138,
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
    final sub =
        isNow ? Colors.white.withValues(alpha: 0.85) : AppColors.textMuted;
    final isMidnight = slot.time.hour == 0;

    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isNow ? null : AppColors.card,
        gradient: isNow ? _skyGradient : null,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _softShadow,
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
              fontWeight:
                  isNow || isMidnight ? FontWeight.w700 : FontWeight.w500,
              color: isNow ? Colors.white : sub,
            ),
          ),
          WeatherIcon(
              condition: slot.condition, isNight: slot.isNight, size: 32),
          Text(
            '${slot.tempC}°',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
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
                  fontSize: 11,
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
          Text('${day.minC}°',
              style: tempStyle.copyWith(color: AppColors.textMuted)),
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
  const _SourceNote({required this.forecast});

  final WeatherForecast forecast;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(fontSize: 11.5);
    final url =
        forecast.sourceUrl == null ? null : Uri.tryParse(forecast.sourceUrl!);
    final updated = _sameDay(forecast.updatedAt, forecast.nowAtLocation())
        ? _hourFmt.format(forecast.updatedAt)
        : '${_dayFmt.format(forecast.updatedAt)}, ${_hourFmt.format(forecast.updatedAt)}';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('Source: ', style: style),
            GestureDetector(
              onTap: url == null
                  ? null
                  : () => launchUrl(url, mode: LaunchMode.externalApplication),
              child: Text(
                forecast.source,
                style: style.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                  decoration: url == null ? null : TextDecoration.underline,
                  decorationColor: AppColors.primaryText,
                ),
              ),
            ),
            Flexible(
              child: Text(
                ' · Updated $updated',
                style: style,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (forecast.isStale) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.pendingBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Forecast may be out of date',
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

/// Bottom sheet "See More": semua slot mendatang, dikelompokkan per hari,
/// lengkap dengan kondisi, kelembapan, dan angin.
class _HourlySheet extends StatelessWidget {
  const _HourlySheet({required this.slots, required this.now});

  final List<WeatherSlot> slots;
  final DateTime now;

  static Future<void> show(
    BuildContext context, {
    required List<WeatherSlot> slots,
    required DateTime now,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HourlySheet(slots: slots, now: now),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = <DateTime, List<WeatherSlot>>{};
    for (final s in slots) {
      groups
          .putIfAbsent(
              DateTime(s.time.year, s.time.month, s.time.day), () => [])
          .add(s);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _SectionTitle('Hourly forecast'),
              for (final entry in groups.entries) ...[
                const SizedBox(height: 16),
                Text(
                  _dayLabel(entry.key, now),
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                _Panel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Column(
                    children: [
                      for (final (i, s) in entry.value.indexed) ...[
                        if (i > 0) Divider(height: 1, color: AppColors.border),
                        _HourlyRow(slot: s),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HourlyRow extends StatelessWidget {
  const _HourlyRow({required this.slot});

  final WeatherSlot slot;

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.caption.copyWith(fontSize: 11.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              _hourFmt.format(slot.time),
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          WeatherIcon(
              condition: slot.condition, isNight: slot.isNight, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.conditionLabel,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '${slot.humidity}% · ${slot.windKmh.toStringAsFixed(1)} km/h '
                  '${slot.windFrom} – ${slot.windTo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
              ],
            ),
          ),
          Text(
            '${slot.tempC}°',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
