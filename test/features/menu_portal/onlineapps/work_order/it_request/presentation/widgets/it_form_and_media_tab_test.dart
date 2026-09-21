import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/core/theme/app_colors.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/data/it_request_repository.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/screens/add_it_request_screen.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/screens/it_request_detail_screen.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/widgets/it_form_and_media_tab.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/widgets/it_request_card.dart';
import 'package:hris_mobile/features/shared/data/department_repository.dart';

import '../../../../../../../fixtures/it_request_response.dart';
import '../../support/it_request_harness.dart';

void main() {
  /// Repository departemen yang selalu berhasil, supaya AddItRequestScreen
  /// yang dibuka lewat FAB (tanpa constructor param) bisa mengambilnya dari
  /// context tanpa meledak.
  DepartmentRepository departmentRepository() {
    return DepartmentRepository(
      apiClient: ApiClient(
        httpClient: MockClient(
          (_) async => http.Response('{"data": []}', 200),
        ),
      ),
    );
  }

  Future<void> pumpTab(WidgetTester tester, ItRequestHarness harness) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ItRequestRepository>.value(
            value: harness.repository,
          ),
          RepositoryProvider<DepartmentRepository>.value(
            value: departmentRepository(),
          ),
        ],
        child: const MaterialApp(home: ItFormAndMediaTab()),
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('menampilkan spinner selagi memuat pertama kali', (tester) async {
    final harness = ItRequestHarness((_, __) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return ok(itRequestListEnvelope());
    });

    await pumpTab(tester, harness);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets(
      'FAB tersembunyi selama server bilang masih ada yang menunggu rating',
      (tester) async {
    final harness =
        ItRequestHarness((_, __) => ok(itRequestListEnvelope(awaitingRating: 1)));

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('FAB muncul (ikon saja, warna orange) saat awaitingRating nol',
      (tester) async {
    final harness =
        ItRequestHarness((_, __) => ok(itRequestListEnvelope(awaitingRating: 0)));

    await pumpTab(tester, harness);
    await settle(tester);

    final fab =
        tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
    expect(fab.backgroundColor, AppColors.orange);
    expect(
      find.descendant(of: find.byType(FloatingActionButton), matching: find.byIcon(Icons.add)),
      findsOneWidget,
    );
    expect(find.text('Add Request'), findsNothing);
  });

  testWidgets('menekan FAB membuka layar tambah request', (tester) async {
    final harness =
        ItRequestHarness((_, __) => ok(itRequestListEnvelope(awaitingRating: 0)));

    await pumpTab(tester, harness);
    await settle(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(AddItRequestScreen), findsOneWidget);
  });

  testWidgets('item dengan can_rate true tampil sebagai banner feedback',
      (tester) async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [
          itRequestListItem(
            id: 2394,
            description: 'Perbaikan print WWTP',
            statusCode: 'done',
            statusLabel: 'Done',
            rating: null,
            canRate: true,
          ),
        ],
        awaitingRating: 1,
      )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.text('Perbaikan print WWTP'), findsOneWidget);
    expect(find.text('Beri Feedback'), findsOneWidget);
  });

  testWidgets(
      'status done + rating kosong saja TIDAK cukup — can_rate false tidak '
      'menampilkan banner (server yang menentukan, bukan tebakan klien)',
      (tester) async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [
          itRequestListItem(
            description: 'Perbaikan print WWTP',
            statusCode: 'done',
            rating: null,
            canRate: false,
          ),
        ],
      )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.text('Beri Feedback'), findsNothing);
  });

  testWidgets(
      'memberi feedback menghilangkan banner dan akhirnya membuka FAB',
      (tester) async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [
          itRequestListItem(
            id: 2394,
            description: 'Perbaikan print WWTP',
            statusCode: 'done',
            rating: null,
            canRate: true,
          ),
        ],
        awaitingRating: 1,
      )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    await tester.tap(find.text('Beri Feedback'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(3));
    await tester.pump();
    await tester.tap(find.text('Kirim Feedback'));
    await tester.pumpAndSettle();

    expect(find.text('Beri Feedback'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('kegagalan memunculkan pesan dan tombol coba lagi', (tester) async {
    var attempts = 0;
    final harness = ItRequestHarness((_, __) {
      attempts++;
      if (attempts == 1) return fails(message: 'Server sibuk');
      return ok(itRequestListEnvelope());
    });

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.text('Server sibuk'), findsOneWidget);

    await tester.tap(find.text('Coba lagi'));
    await settle(tester);

    expect(find.text('Server sibuk'), findsNothing);
  });

  testWidgets('kartu riwayat menampilkan jenis dan kategori', (tester) async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [itRequestListItem(type: 'IT', categoryLabel: 'Email account')],
      )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.text('IT · Email account'), findsOneWidget);
  });

  testWidgets('kartu riwayat menampilkan bintang rating bila sudah dinilai',
      (tester) async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [itRequestListItem(rating: 4)],
      )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(1));
  });

  testWidgets('kartu riwayat tanpa rating tidak menampilkan bintang',
      (tester) async {
    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [itRequestListItem(rating: null)],
      )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
  });

  testWidgets('kartu riwayat tidak meluber di layar sempit walau kategori '
      'dan label status panjang', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final harness = ItRequestHarness(
      (_, __) => ok(itRequestListEnvelope(
        items: [
          itRequestListItem(
            type: 'Media',
            categoryLabel: 'Computer/IT hardware (laptop, PC, printer, mouse)',
            statusCode: 'unknown_long_status',
            statusLabel: 'Menunggu Verifikasi Berlapis Dari Tim IT',
            rating: 5,
          ),
        ],
      )),
    );

    await pumpTab(tester, harness);
    await settle(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('mengetuk kartu riwayat membuka layar detail', (tester) async {
    final harness = ItRequestHarness((url, __) {
      if (url.path.endsWith('/2395')) return ok({'data': itRequestDetail()});
      return ok(itRequestListEnvelope());
    });

    await pumpTab(tester, harness);
    await settle(tester);

    await tester.tap(find.byType(ItRequestCard));
    await tester.pumpAndSettle();

    expect(find.byType(ItRequestDetailScreen), findsOneWidget);
  });
}
