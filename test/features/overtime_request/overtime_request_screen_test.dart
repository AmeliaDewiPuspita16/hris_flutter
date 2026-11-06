import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/features/overtime_request/data/overtime_repository.dart';
import 'package:hris_mobile/features/overtime_request/presentation/screens/overtime_request_screen.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    int listStatus = 200,
  }) async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/overtime/request')) {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'NIGHT',
                'date': '2026-09-26',
                'start_time': '09:00',
                'end_time': '01:00',
                'crosses_midnight': true,
                'duration_hours': 13,
                'reason': 'Support Night Run',
                'status_code': 'CO',
                'status_label': 'Approved',
              },
            ],
          }),
          listStatus,
        );
      }
      return http.Response(
        jsonEncode({
          'data': {'month': '2026-11', 'summary': {}, 'days': []},
        }),
        200,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: OvertimeRequestScreen(
          repository: OvertimeRepository(apiClient: ApiClient(httpClient: client)),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('Status tab shows requests from the API', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Status'));
    await settle(tester);

    expect(find.text('Support Night Run'), findsOneWidget);
    expect(find.textContaining('09:00 – 01:00 (+1 day)'), findsOneWidget);
    expect(find.textContaining('13h'), findsOneWidget);
    expect(find.text('Approved'), findsWidgets);
  });

  testWidgets('Status tab offers a retry when loading fails', (tester) async {
    await pumpScreen(tester, listStatus: 502);

    await tester.tap(find.text('Status'));
    await settle(tester);

    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Submit tab asks for overtime hours and all required fields',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Submit'));
    await settle(tester);

    expect(find.textContaining('Overtime Hours', findRichText: true), findsOneWidget);

    await tester.ensureVisible(find.text('Submit Request'));
    await tester.tap(find.text('Submit Request'));
    await settle(tester);

    expect(find.text('Please complete all required fields.'), findsOneWidget);
  });
}
