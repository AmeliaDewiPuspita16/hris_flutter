import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_detail.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_item.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_type.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/checking.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/code_label.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_status.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/bloc/list/it_request_list_bloc.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/bloc/list/it_request_list_event.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/bloc/list/it_request_list_state.dart';

import '../../../../../../../fixtures/it_request_response.dart';
import '../../support/it_request_harness.dart';

void main() {
  ItRequestListBloc blocOver(ItRequestHarness harness) =>
      ItRequestListBloc(repository: harness.repository);

  Future<void> settle(ItRequestListBloc bloc) async {
    await bloc.stream.firstWhere((s) => s.status == ItRequestListStatus.loading);
    await bloc.stream.firstWhere((s) => s.status != ItRequestListStatus.loading);
  }

  test('memuat halaman pertama saat layar dibuka', () async {
    final harness =
        ItRequestHarness((_, __) => ok(itRequestListEnvelope(awaitingRating: 2)));
    final bloc = blocOver(harness);

    bloc.add(const ItRequestListStarted());
    await settle(bloc);

    expect(bloc.state.items.single.id, 2395);
    expect(bloc.state.summary.awaitingRating, 2);
    expect(harness.lastRequest.queryParameters['page'], '1');

    await bloc.close();
  });

  test('canAddRequest true kalau tidak ada yang menunggu rating', () async {
    final harness =
        ItRequestHarness((_, __) => ok(itRequestListEnvelope(awaitingRating: 0)));
    final bloc = blocOver(harness);

    bloc.add(const ItRequestListStarted());
    await settle(bloc);

    expect(bloc.state.canAddRequest, isTrue);

    await bloc.close();
  });

  test('canAddRequest false kalau masih ada yang menunggu rating', () async {
    final harness =
        ItRequestHarness((_, __) => ok(itRequestListEnvelope(awaitingRating: 1)));
    final bloc = blocOver(harness);

    bloc.add(const ItRequestListStarted());
    await settle(bloc);

    expect(bloc.state.canAddRequest, isFalse);

    await bloc.close();
  });

  test('kegagalan jaringan jadi pesan, bukan lemparan ke layar', () async {
    final harness = ItRequestHarness((_, __) => fails(message: 'Server sibuk'));
    final bloc = blocOver(harness);

    bloc.add(const ItRequestListStarted());
    await bloc.stream.firstWhere((s) => s.status == ItRequestListStatus.failure);

    expect(bloc.state.errorMessage, 'Server sibuk');
    expect(bloc.state.items, isEmpty);

    await bloc.close();
  });

  test('halaman berikutnya menambah item, bukan menggantinya', () async {
    final harness = ItRequestHarness(
      (url, call) => ok(
        itRequestListEnvelope(
          items: [itRequestListItem(id: call)],
          currentPage: call,
          lastPage: 3,
        ),
      ),
    );
    final bloc = blocOver(harness);

    bloc.add(const ItRequestListStarted());
    await settle(bloc);

    bloc.add(const ItRequestListNextPageRequested());
    await bloc.stream.firstWhere((s) => s.items.length == 2);

    expect(bloc.state.items.map((i) => i.id).toList(), [1, 2]);
    expect(harness.lastRequest.queryParameters['page'], '2');

    await bloc.close();
  });

  test('tidak meminta halaman berikutnya saat sudah di halaman terakhir', () async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(currentPage: 1, lastPage: 1)),
    );
    final bloc = blocOver(harness);

    bloc.add(const ItRequestListStarted());
    await settle(bloc);

    bloc.add(const ItRequestListNextPageRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(harness.requested, hasLength(1));

    await bloc.close();
  });

  ItRequestItem localItem({int id = -1, int? rating}) => ItRequestItem(
        id: id,
        type: ItRequestType.it,
        supportType: 'PERMINTAAN',
        category: const CodeLabel(code: 'email_req', label: 'Email account'),
        description: 'Request baru dari form',
        approval: const CodeLabel(code: 'pending', label: 'Pending'),
        checking: const Checking(checked: false, label: 'Belum'),
        status: const ItRequestStatus(code: 'pending', label: 'Pending'),
        createdAt: DateTime(2026, 9, 21),
        rating: rating,
      );

  test('item yang ditambah lokal muncul di puncak daftar', () async {
    final harness = ItRequestHarness((_, __) => ok(itRequestListEnvelope()));
    final bloc = blocOver(harness);

    bloc.add(const ItRequestListStarted());
    await settle(bloc);

    bloc.add(ItRequestLocalItemAdded(localItem(id: -1)));
    await bloc.stream.firstWhere((s) => s.items.length == 2);

    expect(bloc.state.items.first.id, -1);
    expect(bloc.state.meta.total, 3);

    await bloc.close();
  });

  test('memberi feedback mengganti item dengan detail dari server dan '
      'mengurangi awaitingRating', () async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [itRequestListItem(id: 2394, statusCode: 'done', rating: null)],
        awaitingRating: 1,
      )),
    );
    final bloc = blocOver(harness);

    bloc.add(const ItRequestListStarted());
    await settle(bloc);

    bloc.add(ItRequestFeedbackGiven(
      ItRequestDetail.fromJson(itRequestDetail(id: 2394, rating: 4, canRate: false)),
    ));
    await bloc.stream.firstWhere((s) => s.summary.awaitingRating == 0);

    expect(bloc.state.items.single.rating, 4);
    expect(bloc.state.canAddRequest, isTrue);

    await bloc.close();
  });

  test('memberi feedback juga mematikan canRate item itu sendiri', () async {
    // Bukan cuma summary.awaitingRating yang perlu turun — item yang baru
    // dinilai juga tidak boleh lagi dianggap "butuh rating" oleh UI banner,
    // yang membaca canRate per item, bukan summary.
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [itRequestListItem(id: 2394, statusCode: 'done', rating: null, canRate: true)],
        awaitingRating: 1,
      )),
    );
    final bloc = blocOver(harness);

    bloc.add(const ItRequestListStarted());
    await settle(bloc);

    bloc.add(ItRequestFeedbackGiven(
      ItRequestDetail.fromJson(itRequestDetail(id: 2394, rating: 4, canRate: false)),
    ));
    await bloc.stream.firstWhere((s) => s.items.single.rating == 4);

    expect(bloc.state.items.single.canRate, isFalse);

    await bloc.close();
  });

  test('memberi feedback membawa ratingComment dari server ke item', () async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [itRequestListItem(id: 2394, statusCode: 'done', rating: null, canRate: true)],
        awaitingRating: 1,
      )),
    );
    final bloc = blocOver(harness);

    bloc.add(const ItRequestListStarted());
    await settle(bloc);

    bloc.add(ItRequestFeedbackGiven(
      ItRequestDetail.fromJson(itRequestDetail(
        id: 2394,
        rating: 5,
        canRate: false,
        ratingComment: 'Responsif, terima kasih!',
      )),
    ));
    await bloc.stream.firstWhere((s) => s.items.single.rating == 5);

    final updated = bloc.state.items.single;
    expect(updated, isA<ItRequestDetail>());
    expect((updated as ItRequestDetail).ratingComment, 'Responsif, terima kasih!');

    await bloc.close();
  });

  test('awaitingRating tidak pernah menjadi negatif', () async {
    final harness =
        ItRequestHarness((_, __) => ok(itRequestListEnvelope(awaitingRating: 0)));
    final bloc = blocOver(harness);

    bloc.add(const ItRequestListStarted());
    await settle(bloc);

    bloc.add(ItRequestFeedbackGiven(
      ItRequestDetail.fromJson(itRequestDetail(id: 2395, rating: 5, canRate: false)),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.summary.awaitingRating, 0);

    await bloc.close();
  });
}
