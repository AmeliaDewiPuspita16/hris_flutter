import 'package:flutter/material.dart';

import '../../domain/weather_forecast.dart';

/// Ikon cuaca berwarna dari ikon Material. "Partly cloudy" disusun dari
/// matahari/bulan + awan; "clear" berganti bulan pada malam hari.
///
/// Warnanya tetap (tidak ikut tema) supaya terbaca di kartu putih maupun
/// di header hijau.
class WeatherIcon extends StatelessWidget {
  const WeatherIcon({
    super.key,
    required this.condition,
    this.isNight = false,
    this.size = 32,
  });

  final WeatherCondition condition;
  final bool isNight;
  final double size;

  static const _sun = Color(0xFFFFB300);
  static const _moon = Color(0xFFB4C2EA);
  static const _cloud = Color(0xFFB0BEC5);
  static const _cloudLight = Color(0xFFE3EEF7);
  static const _rain = Color(0xFF42A5F5);
  static const _storm = Color(0xFF7E57C2);

  @override
  Widget build(BuildContext context) {
    final sky = isNight
        ? Icon(Icons.nightlight_round, size: size, color: _moon)
        : Icon(Icons.wb_sunny_rounded, size: size, color: _sun);

    final Widget icon = switch (condition) {
      WeatherCondition.clear => sky,
      WeatherCondition.partlyCloudy => Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: isNight
                  ? Icon(Icons.nightlight_round, size: size * 0.66, color: _moon)
                  : Icon(Icons.wb_sunny_rounded, size: size * 0.66, color: _sun),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(Icons.cloud_rounded, size: size * 0.78, color: _cloudLight),
            ),
          ],
        ),
      WeatherCondition.cloudy =>
        Icon(Icons.cloud_rounded, size: size, color: _cloud),
      WeatherCondition.haze => Icon(Icons.foggy, size: size, color: _cloud),
      WeatherCondition.lightRain =>
        Icon(Icons.grain_rounded, size: size, color: _rain),
      WeatherCondition.rain =>
        Icon(Icons.water_drop_rounded, size: size, color: _rain),
      WeatherCondition.thunderstorm =>
        Icon(Icons.thunderstorm_rounded, size: size, color: _storm),
    };

    return Semantics(
      label: condition.label,
      child: SizedBox.square(dimension: size, child: icon),
    );
  }
}
