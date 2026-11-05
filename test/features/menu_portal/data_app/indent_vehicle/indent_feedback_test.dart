import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/features/menu_portal/data_app/indent_vehicle/data/indent_vehicle_repository.dart';
import 'package:hris_mobile/features/menu_portal/data_app/indent_vehicle/domain/indent_request_item.dart';
import 'package:hris_mobile/features/menu_portal/data_app/indent_vehicle/presentation/bloc/list/indent_request_list_bloc.dart';
import 'package:hris_mobile/features/menu_portal/data_app/indent_vehicle/presentation/bloc/list/indent_request_list_event.dart';
import 'package:hris_mobile/features/menu_portal/data_app/indent_vehicle/presentation/bloc/list/indent_request_list_state.dart';

const _me = 3;

Map<String, dynamic> _row({
  required int id,
  int idUser = _me,
  int status = 1,
  int rating = 0,
  String? dateClose,
}) =>
    {
      'id': id,
      'id_user': idUser,
      'name': 'Requester $idUser',
      'tanggal_pemakaian': '2026-11-04',
      'jam_pergi': '13:30:00',
      'jam_pulang': '16:00:00',
      'tujuan': 'Bionesia',
      'keperluan': 'Rapat',
      'kendaraan': 'BP 1509 FB',
      'driver': 1,
      'id_driver': 143,
      'rating': rating,
      'status': status,
      'approval_hod': 1,
      'date_close': dateClose,
    };

Map<String, dynamic> _page(List<Map<String, dynamic>> rows) => {
      'message': 'success',
      'status': 200,
      'data': {
        'current_page': 1,
        'last_page': 2,
        'per_page': 100,
        'total': 101,
        'data': rows,
      },
    };

IndentVehicleRepository _repository({
  required List<Map<String, dynamic>> firstPage,
  List<Map<String, dynamic>> awaitingFeedback = const [],
  int feedbackStatusCode = 200,
}) {
  http.Response json(Object body, [int code = 200]) => http.Response(
        jsonEncode(body),
        code,
        headers: {'content-type': 'application/json'},
      );

  final client = MockClient((request) async {
    return switch (request.url.path) {
      '/api/indent' => json(_page(firstPage)),
      '/api/indent/list/verify' => json(
          {'message': 'success', 'status': 200, 'data': awaitingFeedback},
          feedbackStatusCode,
        ),
      '/api/indent/admin/list_driver' => json([
          {'id': 143, 'name': 'Nizar'},
        ]),
      _ => json({'message': 'Not found'}, 404),
    };
  });

  return IndentVehicleRepository(apiClient: ApiClient(httpClient: client));
}

Future<IndentRequestListState> _load(IndentVehicleRepository repository) async {
  final bloc = IndentRequestListBloc(
    repository: repository,
    currentUserId: _me,
  )..add(const IndentRequestListStarted());
  addTearDown(bloc.close);

  return bloc.stream.firstWhere(
    (state) => state.status != IndentRequestListStatus.loading,
  );
}

void main() {
  group('needsFeedback mengikuti web (status 1 milik sendiri)', () {
    IndentRequestItem item(Map<String, dynamic> row) =>
        IndentRequestItem.fromJson(row, currentUserId: _me);

    test('status 1 walau driver belum mengisi date_close', () {
      expect(item(_row(id: 4853)).needsFeedback, isTrue);
    });

    test('status 1 yang sudah ditutup driver', () {
      expect(item(_row(id: 1, dateClose: '14:11:27')).needsFeedback, isTrue);
    });

    test('milik user lain tidak', () {
      expect(item(_row(id: 1, idUser: 99)).needsFeedback, isFalse);
    });

    test('status selain 1 tidak', () {
      expect(item(_row(id: 1, status: 0)).needsFeedback, isFalse);
      expect(item(_row(id: 1, status: 3, rating: 5)).needsFeedback, isFalse);
      expect(item(_row(id: 1, status: 3)).needsFeedback, isFalse);
      expect(item(_row(id: 1, status: 5)).needsFeedback, isFalse);
    });
  });

  group('IndentRequestListBloc', () {
    test('indent di luar halaman pertama tetap muncul di paling atas', () async {
      final state = await _load(_repository(
        firstPage: [_row(id: 5000, idUser: 99, status: 0)],
        awaitingFeedback: [_row(id: 4853)],
      ));

      expect(state.status, IndentRequestListStatus.success);
      expect(state.items.map((i) => i.id), ['4853', '5000']);
      expect(state.items.first.needsFeedback, isTrue);
      expect(state.items.first.driver, 'Nizar');
    });

    test('indent yang ada di kedua daftar tidak muncul dua kali', () async {
      final state = await _load(_repository(
        firstPage: [_row(id: 4853), _row(id: 5000, idUser: 99, status: 0)],
        awaitingFeedback: [_row(id: 4853)],
      ));

      expect(state.items.map((i) => i.id), ['4853', '5000']);
    });

    test('daftar request tetap tampil bila daftar feedback gagal', () async {
      final state = await _load(_repository(
        firstPage: [_row(id: 5000, idUser: 99, status: 0)],
        feedbackStatusCode: 500,
      ));

      expect(state.status, IndentRequestListStatus.success);
      expect(state.items.map((i) => i.id), ['5000']);
    });
  });
}
