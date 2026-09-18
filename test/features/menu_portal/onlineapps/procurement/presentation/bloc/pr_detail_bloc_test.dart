import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/bloc/detail/pr_detail_bloc.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/bloc/detail/pr_detail_event.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/presentation/bloc/detail/pr_detail_state.dart';

import '../../../../../../fixtures/eprocurement_response.dart';
import '../../support/procurement_harness.dart';

void main() {
  test('memuat rincian PR yang diminta', () async {
    final harness = ProcurementHarness(
      (_, __) => ok({'data': eprocurementDetail()}),
    );
    final bloc = PrDetailBloc(repository: harness.repository);

    bloc.add(const PrDetailRequested(3));
    await bloc.stream.firstWhere((s) => s.status == PrDetailStatus.success);

    expect(bloc.state.requisition?.prNumber, 'PR/HSE/26-08/01');
    expect(bloc.state.requisition?.items, hasLength(2));
    expect(harness.lastRequest.path, '/api/portal/apps/eprocurement/3');

    await bloc.close();
  });

  test('kegagalan jadi pesan yang siap ditampilkan', () async {
    final harness = ProcurementHarness(
      (_, __) => fails(message: 'PR tidak ditemukan.', statusCode: 404),
    );
    final bloc = PrDetailBloc(repository: harness.repository);

    bloc.add(const PrDetailRequested(3));
    await bloc.stream.firstWhere((s) => s.status == PrDetailStatus.failure);

    expect(bloc.state.errorMessage, 'PR tidak ditemukan.');
    expect(bloc.state.requisition, isNull);

    await bloc.close();
  });

  test('memuat ulang setelah gagal membersihkan pesan galat sebelumnya',
      () async {
    var shouldFail = true;
    final harness = ProcurementHarness((_, __) {
      if (shouldFail) return fails(message: 'Server sibuk');
      return ok({'data': eprocurementDetail()});
    });
    final bloc = PrDetailBloc(repository: harness.repository);

    bloc.add(const PrDetailRequested(3));
    await bloc.stream.firstWhere((s) => s.status == PrDetailStatus.failure);

    shouldFail = false;
    bloc.add(const PrDetailRequested(3));
    await bloc.stream.firstWhere((s) => s.status == PrDetailStatus.success);

    expect(bloc.state.errorMessage, isNull);

    await bloc.close();
  });
}
