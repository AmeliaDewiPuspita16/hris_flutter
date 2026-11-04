/// Kondisi cuaca yang ditampilkan app. Dipetakan dari `weather_desc` BMKG
/// (Cerah, Cerah Berawan, Berawan, Kabut/Asap, Hujan Ringan, Hujan,
/// Hujan Petir) — pemetaan itu dibuat saat sumber data asli dipasang.
enum WeatherCondition {
  clear('Clear'),
  partlyCloudy('Partly cloudy'),
  cloudy('Cloudy'),
  haze('Haze'),
  lightRain('Light rain'),
  rain('Rain'),
  thunderstorm('Thunderstorm');

  const WeatherCondition(this.label);

  final String label;

  /// Kondisi "basah" — dipakai untuk peringatan "bawa payung".
  bool get isRainy => this == lightRain || this == rain || this == thunderstorm;
}

/// Satu slot prakiraan (BMKG: per 3 jam).
class WeatherSlot {
  const WeatherSlot({
    required this.time,
    required this.tempC,
    required this.condition,
    required this.humidity,
    required this.windKmh,
    required this.windFrom,
    required this.windTo,
  });

  /// Waktu lokal slot.
  final DateTime time;
  final int tempC;
  final WeatherCondition condition;

  /// Kelembapan relatif, persen.
  final int humidity;
  final double windKmh;

  /// Arah angin, mis. "SE" → "NW".
  final String windFrom;
  final String windTo;

  /// Malam hari: 18.00–05.59 — ikon cerah jadi bulan.
  bool get isNight => time.hour >= 18 || time.hour < 6;
}

/// Ringkasan satu hari dari slot-slotnya.
class WeatherDay {
  const WeatherDay({
    required this.date,
    required this.minC,
    required this.maxC,
    required this.condition,
  });

  final DateTime date;
  final int minC;
  final int maxC;

  /// Kondisi paling "berat" di siang hari (06.00–17.59) — kalau ada hujan
  /// siang, itu yang ditampilkan, karena itulah yang perlu diketahui.
  final WeatherCondition condition;
}

class WeatherForecast {
  const WeatherForecast({
    required this.locationName,
    required this.area,
    required this.slots,
    required this.updatedAt,
  });

  /// Mis. "Teluk Lobam".
  final String locationName;

  /// Mis. "Seri Kuala Lobam, Bintan".
  final String area;

  /// Urut naik berdasarkan [WeatherSlot.time].
  final List<WeatherSlot> slots;
  final DateTime updatedAt;

  /// Slot yang sedang berlaku: slot terakhir yang waktunya ≤ [now].
  /// Sebelum slot pertama → slot pertama.
  WeatherSlot? current(DateTime now) {
    if (slots.isEmpty) return null;
    WeatherSlot result = slots.first;
    for (final slot in slots) {
      if (slot.time.isAfter(now)) break;
      result = slot;
    }
    return result;
  }

  /// Slot berlaku saat ini beserta slot-slot sesudahnya.
  List<WeatherSlot> upcoming(DateTime now) {
    final cur = current(now);
    if (cur == null) return const [];
    return slots.where((s) => !s.time.isBefore(cur.time)).toList();
  }

  List<WeatherDay> get days {
    final byDay = <DateTime, List<WeatherSlot>>{};
    for (final slot in slots) {
      final key = DateTime(slot.time.year, slot.time.month, slot.time.day);
      byDay.putIfAbsent(key, () => []).add(slot);
    }

    return [
      for (final entry in byDay.entries)
        WeatherDay(
          date: entry.key,
          minC: entry.value.map((s) => s.tempC).reduce((a, b) => a < b ? a : b),
          maxC: entry.value.map((s) => s.tempC).reduce((a, b) => a > b ? a : b),
          condition: _dominant(entry.value),
        ),
    ];
  }

  static WeatherCondition _dominant(List<WeatherSlot> slots) {
    final daytime = slots.where((s) => !s.isNight).toList();
    final pool = daytime.isEmpty ? slots : daytime;
    return pool
        .map((s) => s.condition)
        .reduce((a, b) => a.index >= b.index ? a : b);
  }
}
