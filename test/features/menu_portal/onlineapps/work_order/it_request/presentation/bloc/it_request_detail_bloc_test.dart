import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/bloc/detail/it_request_detail_bloc.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/bloc/detail/it_request_detail_event.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/bloc/detail/it_request_detail_state.dart';

import '../../../../../../../fixtures/it_request_response.dart';
import '../../support/it_request_harness.dart';

void main() {
  test('memuat rincian request yang diminta', () async {
    final harness = ItRequestHarness((_, __) => ok({'data': itRequestDetail()}));
    final bloc = ItRequestDetailBloc(repository: harness.repository);

    bloc.add(const ItRequestDetailRequested(2395));
    await bloc.stream.firstWhere((s) => s.status == ItRequestDetailStatus.success);

    expect(bloc.state.detail?.id, 2395);
    expect(bloc.state.detail?.requester?.name, 'Frida Khaerani');
    expect(harness.lastRequest.path, '/api/portal/apps/it_request/2395');

    await bloc.close();
  });

  test('kegagalan jadi pesan yang siap ditampilkan', () async {
    final harness =
        ItRequestHarness((_, __) => fails(message: 'Request tidak ditemukan.', statusCode: 404));
    final bloc = ItRequestDetailBloc(repository: harness.repository);

    bloc.add(const ItRequestDetailRequested(2395));
    await bloc.stream.firstWhere((s) => s.status == ItRequestDetailStatus.failure);

    expect(bloc.state.errorMessage, 'Request tidak ditemukan.');
    expect(bloc.state.detail, isNull);

    await bloc.close();
  });

  test('memuat ulang setelah gagal membersihkan pesan galat sebelumnya', () async {
    var shouldFail = true;
    final harness = ItRequestHarness((_, __) {
      if (shouldFail) return fails(message: 'Server sibuk');
      return ok({'data': itRequestDetail()});
    });
    final bloc = ItRequestDetailBloc(repository: harness.repository);

    bloc.add(const ItRequestDetailRequested(2395));
    await bloc.stream.firstWhere((s) => s.status == ItRequestDetailStatus.failure);

    shouldFail = false;
    bloc.add(const ItRequestDetailRequested(2395));
    await bloc.stream.firstWhere((s) => s.status == ItRequestDetailStatus.success);

    expect(bloc.state.errorMessage, isNull);

    await bloc.close();
  });
}
