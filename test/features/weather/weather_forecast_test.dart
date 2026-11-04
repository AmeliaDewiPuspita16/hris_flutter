import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_config.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/weather/data/weather_repository.dart';
import 'package:hris_mobile/features/weather/domain/weather_forecast.dart';
import 'package:hris_mobile/features/weather/presentation/screens/weather_forecast_screen.dart';

Map<String, dynamic> _slot(String time, int temp, String code, String label) => {
      'time': time,
      'temp_c': temp,
      'condition': {'code': code, 'label': label},
      'humidity': 88,
      'wind_kmh': 5.9,
      'wind_from': 'E',
      'wind_to': 'W',
    };

Map<String, dynamic> _envelope({bool stale = false}) => {
      'data': {
        'location': {'name': 'Teluk Lobam', 'area': 'Seri Kuala Lobam, Bintan'},
        'slots': [
          // Sengaja tidak urut — harus diurutkan.
          _slot('2026-11-04T18:00:00+07:00', 27, 'cloudy', 'Cloudy'),
          _slot('2026-11-04T15:00:00+07:00', 29, 'light_rain', 'Light rain'),
          _slot('2026-11-04T21:00:00+07:00', 26, 'heavy_rain', 'Heavy rain'),
          {'time': 'bukan-tanggal', 'temp_c': 1},
        ],
        'updated_at': '2026-11-04T14:34:07+07:00',
      },
      'meta': {
        'source': 'BMKG',
        'source_url': 'https://www.bmkg.go.id/',
        'stale': stale,
      },
    };

void main() {
  group('WeatherForecast.fromEnvelope', () {
    final forecast = WeatherForecast.fromEnvelope(_envelope());

    test('reads location, meta and sorted slots, skipping broken ones', () {
      expect(forecast.locationName, 'Teluk Lobam');
      expect(forecast.area, 'Seri Kuala Lobam, Bintan');
      expect(forecast.source, 'BMKG');
      expect(forecast.sourceUrl, 'https://www.bmkg.go.id/');
      expect(forecast.isStale, isFalse);
      expect(forecast.slots.map((s) => s.time.hour), [15, 18, 21]);
    });

    test('keeps location wall-clock time regardless of phone time zone', () {
      final first = forecast.slots.first;
      expect(first.time, DateTime(2026, 11, 4, 15));
      expect(first.time.isUtc, isFalse);
      expect(forecast.updatedAt, DateTime(2026, 11, 4, 14, 34, 7));
      expect(forecast.utcOffset, const Duration(hours: 7));
      // 08:00 UTC = 15:00 WIB.
      expect(
        forecast.nowAtLocation(DateTime.utc(2026, 11, 4, 8)),
        DateTime(2026, 11, 4, 15),
      );
    });

    test('maps condition codes and keeps server labels', () {
      final s = forecast.slots;
      expect(s[0].condition, WeatherCondition.lightRain);
      expect(s[0].conditionLabel, 'Light rain');
      expect(s[1].condition, WeatherCondition.cloudy);
      // Kode tak dikenal ditebak dari kata kuncinya.
      expect(s[2].condition, WeatherCondition.rain);
      expect(s[2].conditionLabel, 'Heavy rain');
      expect(s[0].windKmh, 5.9);
      expect(s[0].windFrom, 'E');
    });

    test('current/upcoming pick the slot in effect', () {
      final now = DateTime(2026, 11, 4, 16, 10);
      expect(forecast.current(now)!.time.hour, 15);
      expect(forecast.upcoming(now).map((s) => s.time.hour), [15, 18, 21]);
      expect(forecast.current(DateTime(2026, 11, 4, 9))!.time.hour, 15);
    });
  });

  group('WeatherRepository', () {
    test('GETs the weather endpoint and parses the envelope', () async {
      late Uri requested;
      final repo = WeatherRepository(
        apiClient: ApiClient(
          httpClient: MockClient((req) async {
            requested = req.url;
            return http.Response(jsonEncode(_envelope(stale: true)), 200);
          }),
        ),
      );

      final forecast = await repo.fetchForecast();
      expect(requested.path, ApiConfig.weather);
      expect(forecast.isStale, isTrue);
      expect(forecast.slots, hasLength(3));
    });

    test('throws ApiException when data is not an object', () async {
      final repo = WeatherRepository(
        apiClient: ApiClient(
          httpClient: MockClient(
            (_) async => http.Response(jsonEncode({'data': []}), 200),
          ),
        ),
      );
      expect(repo.fetchForecast(), throwsA(isA<ApiException>()));
    });
  });

  testWidgets('screen shows now card, rain notice and stale label', (t) async {
    final forecast = WeatherForecast.fromEnvelope(_envelope(stale: true));
    await t.pumpWidget(MaterialApp(
      home: WeatherForecastScreen(
        forecast: forecast,
        now: DateTime(2026, 11, 4, 16, 10),
      ),
    ));

    expect(find.text('Teluk Lobam'), findsOneWidget);
    expect(find.text('Now · 15.00'), findsOneWidget);
    expect(find.textContaining('Light rain expected at 15.00'), findsOneWidget);
    await t.scrollUntilVisible(
      find.text('Forecast may be out of date'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Forecast may be out of date'), findsOneWidget);
  });
}
