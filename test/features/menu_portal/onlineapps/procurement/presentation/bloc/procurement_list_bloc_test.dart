import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/bloc/list/procurement_list_bloc.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/bloc/list/procurement_list_event.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/bloc/list/procurement_list_state.dart';

import '../../../../../../fixtures/eprocurement_response.dart';
import '../../support/procurement_harness.dart';

void main() {
  ProcurementListBloc blocOver(ProcurementHarness harness) =>
      ProcurementListBloc(repository: harness.repository);

  /// Menunggu satu siklus muat selesai: loading lalu hasilnya.
  ///
  /// Menunggu `status == success` saja tidak cukup — mengganti filter lebih
  /// dulu meng-emit state berisi filter barunya yang statusnya masih success
  /// dari muatan sebelumnya, jadi penantiannya selesai sebelum request
  /// berangkat.
  Future<void> settle(ProcurementListBloc bloc) async {
    await bloc.stream
        .firstWhere((s) => s.status == ProcurementListStatus.loading);
    await bloc.stream
        .firstWhere((s) => s.status != ProcurementListStatus.loading);
  }

  test('memuat halaman pertama saat layar dibuka', () async {
    final harness = ProcurementHarness((_, __) => ok(eprocurementListEnvelope()));
    final bloc = blocOver(harness);

    bloc.add(const ProcurementListStarted());
    await bloc.stream.firstWhere((s) => s.status == ProcurementListStatus.success);

    expect(bloc.state.items.single.prNumber, 'PR/AML/26-09/01');
    expect(bloc.state.summary.all, 9);
    expect(harness.lastRequest.queryParameters['page'], '1');

    await bloc.close();
  });

  test('kegagalan jaringan jadi pesan, bukan lemparan ke layar', () async {
    final harness = ProcurementHarness((_, __) => fails(message: 'Server sibuk'));
    final bloc = blocOver(harness);

    bloc.add(const ProcurementListStarted());
    await bloc.stream.firstWhere((s) => s.status == ProcurementListStatus.failure);

    expect(bloc.state.errorMessage, 'Server sibuk');
    expect(bloc.state.items, isEmpty);

    await bloc.close();
  });

  test('memilih chip status memuat ulang dari halaman pertama', () async {
    final harness = ProcurementHarness((_, __) => ok(eprocurementListEnvelope()));
    final bloc = blocOver(harness);

    bloc.add(const ProcurementListStarted());
    await settle(bloc);

    bloc.add(const ProcurementListStatusSelected('pending_hod'));
    await settle(bloc);

    expect(harness.lastRequest.queryParameters['status'], 'pending_hod');
    expect(harness.lastRequest.queryParameters['page'], '1');

    await bloc.close();
  });

  test('melepas chip status mengirim permintaan tanpa filter status', () async {
    final harness = ProcurementHarness((_, __) => ok(eprocurementListEnvelope()));
    final bloc = blocOver(harness);

    bloc.add(const ProcurementListStatusSelected('pending_hod'));
    await settle(bloc);

    bloc.add(const ProcurementListStatusSelected(null));
    await settle(bloc);

    expect(harness.lastRequest.queryParameters.containsKey('status'), isFalse);
    expect(bloc.state.statusCode, isNull);

    await bloc.close();
  });

  test('pencarian memuat ulang dengan kata kuncinya', () async {
    final harness = ProcurementHarness((_, __) => ok(eprocurementListEnvelope()));
    final bloc = blocOver(harness);

    bloc.add(const ProcurementListSearched('forklift'));
    await settle(bloc);

    expect(harness.lastRequest.queryParameters['search'], 'forklift');
    expect(bloc.state.query, 'forklift');

    await bloc.close();
  });

  test('halaman berikutnya menambah item, bukan menggantinya', () async {
    final harness = ProcurementHarness(
      (url, call) => ok(
        eprocurementListEnvelope(
          items: [eprocurementListItem(id: call, prNumber: 'PR/TEST/$call')],
          currentPage: call,
          lastPage: 3,
        ),
      ),
    );
    final bloc = blocOver(harness);

    bloc.add(const ProcurementListStarted());
    await settle(bloc);

    bloc.add(const ProcurementListNextPageRequested());
    await bloc.stream.firstWhere((s) => s.items.length == 2);

    expect(
      bloc.state.items.map((i) => i.prNumber).toList(),
      ['PR/TEST/1', 'PR/TEST/2'],
    );
    expect(harness.lastRequest.queryParameters['page'], '2');

    await bloc.close();
  });

  test('tidak meminta halaman berikutnya saat sudah di halaman terakhir',
      () async {
    final harness = ProcurementHarness(
      (_, __) => ok(eprocurementListEnvelope(currentPage: 1, lastPage: 1)),
    );
    final bloc = blocOver(harness);

    bloc.add(const ProcurementListStarted());
    await settle(bloc);

    bloc.add(const ProcurementListNextPageRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(harness.requested, hasLength(1));

    await bloc.close();
  });

  test('hasil pencarian yang keburu usang tidak menimpa yang terbaru',
      () async {
    // Permintaan pertama sengaja lambat: tanpa penjaga urutan, balasannya
    // yang datang belakangan akan menimpa hasil ketikan terakhir.
    final harness = ProcurementHarness((url, call) async {
      final keyword = url.queryParameters['search'] ?? '';
      if (call == 1) {
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
      return ok(
        eprocurementListEnvelope(
          items: [eprocurementListItem(prNumber: 'PR/$keyword')],
        ),
      );
    });
    final bloc = blocOver(harness);

    bloc.add(const ProcurementListSearched('lambat'));
    bloc.add(const ProcurementListSearched('cepat'));

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(bloc.state.items.single.prNumber, 'PR/cepat');
    expect(bloc.state.query, 'cepat');

    await bloc.close();
  });
}
