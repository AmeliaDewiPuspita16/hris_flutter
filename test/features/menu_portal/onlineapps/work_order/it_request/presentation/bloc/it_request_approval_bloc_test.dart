import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/bloc/approval/it_request_approval_bloc.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/bloc/approval/it_request_approval_event.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/bloc/approval/it_request_approval_state.dart';

import '../../../../../../../fixtures/it_request_response.dart';
import '../../support/it_request_harness.dart';

void main() {
  Future<void> settle(ItRequestApprovalBloc bloc) async {
    await bloc.stream
        .firstWhere((s) => s.status == ItRequestApprovalStatus.loading);
    await bloc.stream
        .firstWhere((s) => s.status != ItRequestApprovalStatus.loading);
  }

  Future<ItRequestApprovalBloc> loaded(ItRequestHarness harness) async {
    final bloc = ItRequestApprovalBloc(repository: harness.repository)
      ..add(const ItRequestApprovalStarted());
    await settle(bloc);
    return bloc;
  }

  test('memuat antrean HOD saat dimulai', () async {
    final harness =
        ItRequestHarness((_, __) => ok(itRequestApprovalsEnvelope(pending: 3)));

    final bloc = await loaded(harness);

    expect(bloc.state.status, ItRequestApprovalStatus.success);
    expect(bloc.state.items.single.id, 2396);
    expect(bloc.state.pending, 3);

    await bloc.close();
  });

  test('gagal memuat -> failure dengan pesan server', () async {
    final harness = ItRequestHarness((_, __) => fails(message: 'Server sibuk'));

    final bloc = await loaded(harness);

    expect(bloc.state.status, ItRequestApprovalStatus.failure);
    expect(bloc.state.errorMessage, 'Server sibuk');

    await bloc.close();
  });

  test('approve berhasil: request keluar dari daftar, pending berkurang',
      () async {
    final harness = ItRequestHarness((url, _) => url.path.endsWith('/approvals')
        ? ok(itRequestApprovalsEnvelope(pending: 2))
        : ok({
            'message': 'Request has been approved.',
            'data': itRequestDetail()
          }));
    final bloc = await loaded(harness);

    bloc.add(ItRequestApprovalDecided(
        item: bloc.state.items.single, approved: true));
    final state = await bloc.stream.firstWhere((s) => s.notice != null);

    expect(
        harness.lastRequest.path, '/api/portal/apps/it_request/2396/approve');
    expect(state.items, isEmpty);
    expect(state.pending, 1);
    expect(state.busyIds, isEmpty);
    expect(state.notice!.isError, isFalse);

    await bloc.close();
  });

  test('reject gagal: request tetap ada dan pesan galat muncul', () async {
    final harness = ItRequestHarness((url, _) => url.path.endsWith('/approvals')
        ? ok(itRequestApprovalsEnvelope())
        : fails(statusCode: 422, message: 'Request sudah diputuskan'));
    final bloc = await loaded(harness);

    bloc.add(ItRequestApprovalDecided(
      item: bloc.state.items.single,
      approved: false,
      reason: 'Tidak perlu',
    ));
    final state = await bloc.stream.firstWhere((s) => s.notice != null);

    expect(harness.lastRequest.path, '/api/portal/apps/it_request/2396/reject');
    expect(state.items, hasLength(1));
    expect(state.busyIds, isEmpty);
    expect(state.notice!.isError, isTrue);
    expect(state.notice!.message, 'Request sudah diputuskan');

    await bloc.close();
  });
}
