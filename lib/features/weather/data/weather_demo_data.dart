import '../domain/weather_forecast.dart';

/// Data contoh prakiraan cuaca Teluk Lobam — dipakai selama sumber data
/// asli (BMKG, langsung atau lewat backend) belum dipasang.
///
/// Slot per 3 jam selama 3 hari mulai pukul 00.00 hari ini, supaya slot
/// "sekarang" selalu ada kapan pun app dibuka.
abstract final class WeatherDemoData {
  static const _temps = [25, 24, 25, 28, 30, 30, 28, 26];

  static const _conditions = [
    // Hari ini
    WeatherCondition.cloudy,
    WeatherCondition.cloudy,
    WeatherCondition.partlyCloudy,
    WeatherCondition.clear,
    WeatherCondition.clear,
    WeatherCondition.partlyCloudy,
    WeatherCondition.cloudy,
    WeatherCondition.cloudy,
    // Besok
    WeatherCondition.haze,
    WeatherCondition.cloudy,
    WeatherCondition.partlyCloudy,
    WeatherCondition.lightRain,
    WeatherCondition.thunderstorm,
    WeatherCondition.rain,
    WeatherCondition.lightRain,
    WeatherCondition.cloudy,
    // Lusa
    WeatherCondition.cloudy,
    WeatherCondition.cloudy,
    WeatherCondition.clear,
    WeatherCondition.clear,
    WeatherCondition.partlyCloudy,
    WeatherCondition.partlyCloudy,
    WeatherCondition.cloudy,
    WeatherCondition.clear,
  ];

  static const _winds = [
    ('SE', 'NW'),
    ('S', 'N'),
    ('NW', 'SE'),
    ('N', 'S'),
  ];

  static WeatherForecast forecast({DateTime? now}) {
    final today = now ?? DateTime.now();
    final start = DateTime(today.year, today.month, today.day);

    final slots = <WeatherSlot>[
      for (var i = 0; i < _conditions.length; i++)
        () {
          final hourIndex = i % 8;
          final day = i ~/ 8;
          final condition = _conditions[i];
          // Hujan sedikit menurunkan suhu; tiap hari sedikit beda.
          final temp = _temps[hourIndex] +
              (day == 2 ? 1 : 0) -
              (condition.isRainy ? 2 : 0);
          final wind = _winds[(i ~/ 3) % _winds.length];

          return WeatherSlot(
            time: start.add(Duration(hours: i * 3)),
            tempC: temp,
            condition: condition,
            humidity: condition.isRainy ? 90 + (i % 3) * 2 : 70 + (i * 7) % 20,
            windKmh: [11.4, 5.3, 0.3, 8.6, 14.2, 3.1][i % 6],
            windFrom: wind.$1,
            windTo: wind.$2,
          );
        }(),
    ];

    return WeatherForecast(
      locationName: 'Teluk Lobam',
      area: 'Seri Kuala Lobam, Bintan',
      slots: slots,
      updatedAt: today,
    );
  }
}
