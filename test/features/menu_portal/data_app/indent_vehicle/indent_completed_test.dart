import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/features/menu_portal/data_app/indent_vehicle/data/indent_vehicle_repository.dart';
import 'package:hris_mobile/features/menu_portal/data_app/indent_vehicle/domain/indent_completed_item.dart';
import 'package:hris_mobile/features/menu_portal/data_app/indent_vehicle/presentation/bloc/driver/indent_completed_cubit.dart';
import 'package:hris_mobile/features/menu_portal/data_app/indent_vehicle/presentation/widgets/indent_completed_tab.dart';

Map<String, dynamic> _row({
  int id = 1,
  int status = 3,
  int rating = 5,
  String? feedback = 'Very punctual',
}) =>
    {
      'id': id,
      'id_user': 3,
      'name': 'Heriyanto',
      'tanggal_pemakaian': '2026-11-04',
      'jam_pergi': '13:30:00',
      'jam_pulang': '16:00:00',
      'tujuan': 'Bionesia',
      'keperluan': 'Meeting',
      'kendaraan': 'BP 1509 FB',
      'rating': rating,
      'status': status,
      'feedback_user': feedback,
    };

IndentVehicleRepository _repository(
  Map<int, List<Map<String, dynamic>>> pages, {
  int statusCode = 200,
}) {
  final client = MockClient((request) async {
    expect(request.url.path, '/api/indent/driver/history');
    final page = int.parse(request.url.queryParameters['page']!);
    return http.Response(
      jsonEncode({
        'message': 'success',
        'status': statusCode,
        'data': {
          'current_page': page,
          'last_page': pages.length,
          'per_page': 20,
          'total': pages.values.expand((rows) => rows).length,
          'data': pages[page],
        },
      }),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  });

  return IndentVehicleRepository(apiClient: ApiClient(httpClient: client));
}

void main() {
  group('IndentCompletedItem.fromJson', () {
    test('sudah diberi feedback', () {
      final item = IndentCompletedItem.fromJson(_row());

      expect(item.waitingFeedback, isFalse);
      expect(item.rating, 5);
      expect(item.feedback, 'Very punctual');
      expect(item.name, 'Heriyanto');
      expect(item.vehicle, 'BP 1509 FB');
    });

    test('status 1 masih menunggu feedback dan rating 0 berarti kosong', () {
      final item = IndentCompletedItem.fromJson(
        _row(status: 1, rating: 0, feedback: ''),
      );

      expect(item.waitingFeedback, isTrue);
      expect(item.rating, isNull);
      expect(item.feedback, isNull);
    });

    test('tanpa id ditolak', () {
      expect(
        () => IndentCompletedItem.fromJson({'status': 3}),
        throwsFormatException,
      );
    });
  });

  group('IndentCompletedCubit', () {
    test('memuat halaman pertama lalu menyambung tanpa duplikat', () async {
      final cubit = IndentCompletedCubit(
        repository: _repository({
          1: [_row(id: 2), _row(id: 1)],
          2: [_row(id: 1), _row(id: 0)],
        }),
      );
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.status, IndentCompletedStatus.success);
      expect(cubit.state.items.map((i) => i.id), ['2', '1']);
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();
      expect(cubit.state.items.map((i) => i.id), ['2', '1', '0']);
      expect(cubit.state.hasMore, isFalse);

      await cubit.loadMore();
      expect(cubit.state.items.length, 3);
    });

    test('gagal memuat menjadi status failure', () async {
      final cubit = IndentCompletedCubit(
        repository: _repository({1: const []}, statusCode: 500),
      );
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.status, IndentCompletedStatus.failure);
      expect(cubit.state.errorMessage, isNotNull);
    });
  });

  group('IndentCompletedTab', () {
    Widget tab(List<IndentCompletedItem> items) => MaterialApp(
          home: Scaffold(
            body: IndentCompletedTab(
              items: items,
              loadingMore: false,
              onRefresh: () async {},
              onNearEnd: () {},
            ),
          ),
        );

    testWidgets('menampilkan feedback dan label menunggu', (tester) async {
      await tester.pumpWidget(tab([
        IndentCompletedItem.fromJson(_row()),
        IndentCompletedItem.fromJson(
          _row(id: 2, status: 1, rating: 0, feedback: null),
        ),
      ]));
      await tester.pump();

      expect(find.text('Very punctual'), findsOneWidget);
      expect(find.text('Waiting for feedback'), findsOneWidget);
      expect(find.text('Heriyanto'), findsNWidgets(2));
    });

    testWidgets('daftar kosong', (tester) async {
      await tester.pumpWidget(tab(const []));

      expect(find.text('No completed trips yet'), findsOneWidget);
    });
  });
}
