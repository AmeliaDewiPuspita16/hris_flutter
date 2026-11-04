import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/weather/data/weather_demo_data.dart';
import 'package:hris_mobile/features/weather/domain/weather_forecast.dart';
import 'package:hris_mobile/features/weather/presentation/screens/weather_forecast_screen.dart';

void main() {
  final now = DateTime(2026, 11, 4, 13, 20);
  final forecast = WeatherDemoData.forecast(now: now);

  test('current is the last slot at or before now', () {
    expect(forecast.current(now)!.time, DateTime(2026, 11, 4, 12));
    expect(forecast.current(DateTime(2026, 11, 3))!.time, forecast.slots.first.time);
  });

  test('upcoming starts from the current slot', () {
    final upcoming = forecast.upcoming(now);
    expect(upcoming.first.time, DateTime(2026, 11, 4, 12));
    expect(upcoming.length, forecast.slots.length - 4);
  });

  test('days summarise min/max and worst daytime condition', () {
    final days = forecast.days;
    expect(days, hasLength(3));
    final tomorrow = days[1];
    expect(tomorrow.condition, WeatherCondition.thunderstorm);
    expect(tomorrow.minC, lessThanOrEqualTo(tomorrow.maxC));
  });

  testWidgets('screen shows now card, rain notice and sample label', (t) async {
    await t.pumpWidget(MaterialApp(
      home: WeatherForecastScreen(forecast: forecast, now: now, isSampleData: true),
    ));
    expect(find.text('Teluk Lobam'), findsOneWidget);
    expect(find.text('Now · 12.00'), findsOneWidget);
    expect(find.textContaining('Bring an umbrella'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Sample data, not live yet'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Sample data, not live yet'), findsOneWidget);
  });
}
