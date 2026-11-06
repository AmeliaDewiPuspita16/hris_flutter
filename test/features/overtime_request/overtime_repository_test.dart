import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/core/widgets/status_badge.dart';
import 'package:hris_mobile/features/overtime_request/data/overtime_repository.dart';
import 'package:hris_mobile/features/overtime_request/domain/overtime_format.dart';
import 'package:hris_mobile/features/overtime_request/domain/overtime_submission.dart';

void main() {
  Map<String, dynamic> row({
    String code = 'CO',
    String label = 'Approved',
    String start = '17:00',
    String end = '01:57',
    bool crossesMidnight = true,
    num hours = 6,
  }) =>
      {
        'id': 'ABC',
        'date': '2025-06-23',
        'start_time': start,
        'end_time': end,
        'crosses_midnight': crossesMidnight,
        'duration_hours': hours,
        'span_hours': 8.95,
        'reason': 'Anniversary preparation',
        'status_code': code,
        'status_label': label,
      };

  OvertimeRepository repositoryReturning(
    Object body, {
    int status = 200,
    void Function(http.Request)? onRequest,
  }) {
    final client = MockClient((request) async {
      onRequest?.call(request);
      return http.Response(jsonEncode(body), status);
    });

    return OvertimeRepository(apiClient: ApiClient(httpClient: client));
  }

  group('fetchRequests', () {
    test('maps a row from the API', () async {
      final requests = await repositoryReturning({
        'data': [row()],
      }).fetchRequests();

      final entry = requests.single;
      expect(entry.date, DateTime(2025, 6, 23));
      expect(entry.start, const TimeOfDay(hour: 17, minute: 0));
      expect(entry.durationHours, 6.0);
      expect(entry.status, AppStatus.present);
      expect(entry.statusLabel, 'Approved');
      expect(entry.timeRange, '17:00 – 01:57 (+1 day)');
    });

    test('maps the status codes without guessing a rejection', () async {
      final requests = await repositoryReturning({
        'data': [
          row(code: 'OEZ_RELEASE', label: 'Pending'),
          row(code: 'VO', label: 'VO'),
        ],
      }).fetchRequests();

      expect(requests[0].status, AppStatus.pending);
      expect(requests[1].status, AppStatus.neutral);
      expect(requests[1].statusLabel, 'VO');
    });

    test('tolerates a row with missing values', () async {
      final requests = await repositoryReturning({
        'data': [
          {'id': 'X', 'start_time': null, 'duration_hours': null},
        ],
      }).fetchRequests();

      expect(requests.single.date, isNull);
      expect(requests.single.timeRange, '-');
    });
  });

  group('submitRequest', () {
    final submission = OvertimeSubmission(
      date: DateTime(2026, 10, 25),
      start: const TimeOfDay(hour: 17, minute: 0),
      end: const TimeOfDay(hour: 1, minute: 30),
      durationHours: 7.5,
      reason: 'Server migration',
    );

    test('posts the fields the API expects', () async {
      late http.Request sent;

      await repositoryReturning(
        {'message': 'Overtime request submitted.', 'data': row()},
        status: 201,
        onRequest: (request) => sent = request,
      ).submitRequest(submission);

      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/portal/apps/hris/overtime/request');
      expect(jsonDecode(sent.body), {
        'date': '2026-10-25',
        'start_time': '17:00',
        'end_time': '01:30',
        'duration_hours': 7.5,
        'reason': 'Server migration',
      });
    });

    test('surfaces the server message for a duplicate', () async {
      const message = 'An overtime request for this date and time already exists.';

      expect(
        repositoryReturning({'message': message}, status: 409)
            .submitRequest(submission),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', message)),
      );
    });
  });

  group('overtime_format', () {
    test('a later end time is a plain difference', () {
      expect(
        overtimeMinutesBetween(
          const TimeOfDay(hour: 17, minute: 0),
          const TimeOfDay(hour: 19, minute: 30),
        ),
        150,
      );
    });

    test('an earlier end time crosses midnight', () {
      expect(
        overtimeMinutesBetween(
          const TimeOfDay(hour: 17, minute: 0),
          const TimeOfDay(hour: 1, minute: 0),
        ),
        480,
      );
    });

    test('equal times give no duration', () {
      const time = TimeOfDay(hour: 9, minute: 0);
      expect(overtimeMinutesBetween(time, time), 0);
    });

    test('hours accept a decimal comma and refuse non-positive input', () {
      expect(parseOvertimeHours('2,5'), 2.5);
      expect(parseOvertimeHours(' 8 '), 8);
      expect(parseOvertimeHours('0'), isNull);
      expect(parseOvertimeHours('-1'), isNull);
      expect(parseOvertimeHours('abc'), isNull);
    });
  });
}
