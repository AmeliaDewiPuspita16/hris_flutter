/// Kelompok kondisi cuaca — menentukan ikon & pengingat hujan. Teks yang
/// ditampilkan memakai label dari server ([WeatherSlot.conditionLabel]).
enum WeatherCondition {
  clear('clear', 'Clear'),
  partlyCloudy('partly_cloudy', 'Partly cloudy'),
  cloudy('cloudy', 'Cloudy'),
  haze('haze', 'Haze'),
  lightRain('light_rain', 'Light rain'),
  rain('rain', 'Rain'),
  thunderstorm('thunderstorm', 'Thunderstorm');

  const WeatherCondition(this.code, this.label);

  /// Kode dari server, mis. `light_rain`.
  final String code;
  final String label;

  /// Kode yang tidak dikenal ditebak dari kata kuncinya (mis. `heavy_rain`
  /// → [rain], `fog`/`smoke` → [haze]); sisanya jatuh ke [cloudy].
  static WeatherCondition fromCode(String? code) {
    final c = (code ?? '').toLowerCase().trim();
    for (final v in values) {
      if (v.code == c) return v;
    }
    if (c.contains('thunder') || c.contains('storm')) return thunderstorm;
    if (c.contains('light') && (c.contains('rain') || c.contains('drizzle'))) {
      return lightRain;
    }
    if (c.contains('rain') || c.contains('shower')) return rain;
    if (c.contains('fog') ||
        c.contains('haze') ||
        c.contains('smoke') ||
        c.contains('mist')) {
      return haze;
    }
    if (c.contains('partly') || c.contains('mostly_clear')) return partlyCloudy;
    if (c.contains('clear') || c.contains('sunny')) return clear;
    return cloudy;
  }

  /// Kondisi "basah" — dipakai untuk peringatan "bawa payung".
  bool get isRainy => this == lightRain || this == rain || this == thunderstorm;
}

/// Satu slot prakiraan (BMKG: per 3 jam).
class WeatherSlot {
  const WeatherSlot({
    required this.time,
    required this.tempC,
    required this.condition,
    String? conditionLabel,
    required this.humidity,
    required this.windKmh,
    required this.windFrom,
    required this.windTo,
  }) : _conditionLabel = conditionLabel;

  /// `slots[]` dari `GET /api/portal/apps/weather`. Melempar
  /// [FormatException] bila `time` tidak ada/tidak terbaca.
  factory WeatherSlot.fromJson(Map<String, dynamic> json) {
    final condition = json['condition'];
    final code = condition is Map ? condition['code'] as String? : null;
    final label = condition is Map ? condition['label'] as String? : null;

    return WeatherSlot(
      time: parseLocationTime(json['time']),
      tempC: (json['temp_c'] as num?)?.round() ?? 0,
      condition: WeatherCondition.fromCode(code),
      conditionLabel: label,
      humidity: (json['humidity'] as num?)?.round() ?? 0,
      windKmh: (json['wind_kmh'] as num?)?.toDouble() ?? 0,
      windFrom: (json['wind_from'] as String?)?.trim() ?? '-',
      windTo: (json['wind_to'] as String?)?.trim() ?? '-',
    );
  }

  /// Jam dinding di LOKASI prakiraan (mis. WIB untuk "…+07:00"), bukan jam
  /// zona HP — supaya "15.00" tetap 15.00 walau HP sedang di zona lain.
  final DateTime time;
  final int tempC;
  final WeatherCondition condition;
  final String? _conditionLabel;

  /// Label dari server bila ada (mis. "Light rain"), kalau tidak dari enum.
  String get conditionLabel {
    final l = _conditionLabel?.trim() ?? '';
    return l.isEmpty ? condition.label : l;
  }

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
    this.utcOffset = const Duration(hours: 7),
    this.source = 'BMKG',
    this.sourceUrl,
    this.isStale = false,
  });

  /// Seluruh amplop `GET /api/portal/apps/weather` (`data` + `meta`).
  /// Slot yang rusak dilewati; melempar [FormatException] bila `data`
  /// bukan objek.
  factory WeatherForecast.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('weather: data is not an object');
    }
    final meta = envelope['meta'] is Map ? envelope['meta'] as Map : const {};
    final location =
        data['location'] is Map ? data['location'] as Map : const {};

    final slots = <WeatherSlot>[];
    Duration? offset;
    for (final item in (data['slots'] as List? ?? const [])) {
      if (item is! Map<String, dynamic>) continue;
      try {
        slots.add(WeatherSlot.fromJson(item));
        offset ??= _offsetOf(item['time']);
      } on FormatException {
        // Satu slot rusak tidak boleh menghilangkan seluruh prakiraan.
      }
    }
    slots.sort((a, b) => a.time.compareTo(b.time));

    final updatedRaw = data['updated_at'];
    final sourceUrl = (meta['source_url'] as String?)?.trim();

    return WeatherForecast(
      locationName: (location['name'] as String?)?.trim() ?? '',
      area: (location['area'] as String?)?.trim() ?? '',
      slots: slots,
      updatedAt:
          updatedRaw == null ? DateTime.now() : parseLocationTime(updatedRaw),
      utcOffset: offset ?? _offsetOf(updatedRaw) ?? const Duration(hours: 7),
      source: (meta['source'] as String?)?.trim().isNotEmpty == true
          ? (meta['source'] as String).trim()
          : 'BMKG',
      sourceUrl: sourceUrl == null || sourceUrl.isEmpty ? null : sourceUrl,
      isStale: meta['stale'] == true,
    );
  }

  /// Mis. "Teluk Lobam".
  final String locationName;

  /// Mis. "Seri Kuala Lobam, Bintan".
  final String area;

  /// Urut naik berdasarkan [WeatherSlot.time].
  final List<WeatherSlot> slots;

  /// Jam dinding lokasi, sama seperti [WeatherSlot.time].
  final DateTime updatedAt;

  /// Zona waktu lokasi (dari offset di `time`, mis. +07:00).
  final Duration utcOffset;

  /// Nama sumber untuk atribusi, mis. "BMKG".
  final String source;
  final String? sourceUrl;

  /// `meta.stale`: server memakai cache lama karena gagal menyegarkan.
  final bool isStale;

  /// "Sekarang" dalam jam dinding lokasi — pembanding untuk [current] dan
  /// [upcoming] supaya tidak meleset bila zona HP berbeda.
  DateTime nowAtLocation([DateTime? now]) {
    final utc = (now ?? DateTime.now()).toUtc().add(utcOffset);
    return DateTime(
        utc.year, utc.month, utc.day, utc.hour, utc.minute, utc.second);
  }

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

/// Membaca ISO-8601 dan mengembalikan jam dinding sesuai offset di teksnya
/// (mis. "2026-11-04T15:00:00+07:00" → 15.00), sebagai DateTime lokal
/// tanpa konversi ke zona HP. Teks tanpa offset dibaca apa adanya.
DateTime parseLocationTime(Object? raw) {
  if (raw is! String || raw.trim().isEmpty) {
    throw const FormatException('weather: missing time');
  }
  final text = raw.trim();
  final parsed = DateTime.parse(text);
  final offset = _offsetOf(text);
  if (offset == null) return parsed;
  final wall = parsed.toUtc().add(offset);
  return DateTime(
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
    wall.second,
  );
}

final _offsetPattern = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

Duration? _offsetOf(Object? raw) {
  if (raw is! String) return null;
  final m = _offsetPattern.firstMatch(raw.trim());
  if (m == null) return null;
  final o = m.group(1)!;
  if (o == 'Z') return Duration.zero;
  final sign = o.startsWith('-') ? -1 : 1;
  final digits = o.substring(1).replaceAll(':', '');
  return Duration(
    hours: sign * int.parse(digits.substring(0, 2)),
    minutes: sign * int.parse(digits.substring(2, 4)),
  );
}
