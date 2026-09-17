import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hris_mobile/core/network/api_client.dart';
import 'package:hris_mobile/features/home/data/announcement_repository.dart';
import 'package:hris_mobile/features/home/presentation/screens/beranda_screen.dart';
import 'package:hris_mobile/features/shared/domain/role.dart';

import '../../../../fixtures/announcement_list_response.dart';

void main() {
  /// Repository yang dilayani [handler]; tanpa handler, server membalas satu
  /// pengumuman.
  AnnouncementRepository repositoryThatResponds([
    Future<http.Response> Function(http.Request request)? handler,
  ]) {
    return AnnouncementRepository(
      apiClient: ApiClient(
        httpClient: MockClient(
          handler ??
              (_) async => http.Response(
                    jsonEncode(announcementListEnvelope()),
                    200,
                  ),
        ),
      ),
    );
  }

  Future<void> pumpBeranda(
    WidgetTester tester,
    AnnouncementRepository repository,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        home: BerandaScreen(
          role: Role.hrPublisher,
          announcementRepository: repository,
        ),
      ),
    );
  }

  testWidgets('tidak lagi menampilkan pengumuman demo', (tester) async {
    await pumpBeranda(tester, repositoryThatResponds());
    await tester.pumpAndSettle();

    expect(
      find.text('Payroll cut-off moves to the 23rd this month'),
      findsNothing,
    );
    expect(
      find.text('Annual medical check-up — booking now open'),
      findsNothing,
    );
  });

  testWidgets('menampilkan pengumuman dari server', (tester) async {
    await pumpBeranda(tester, repositoryThatResponds());
    await tester.pumpAndSettle();

    expect(
      find.text('Payroll cut-off pindah ke tanggal 23'),
      findsOneWidget,
    );
    expect(find.text('HR & GA'), findsOneWidget);
  });

  testWidgets('menampilkan indikator selagi daftar diambil', (tester) async {
    final release = Completer<void>();
    await pumpBeranda(
      tester,
      repositoryThatResponds((_) async {
        await release.future;
        return http.Response(jsonEncode(announcementListEnvelope()), 200);
      }),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    release.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('menampilkan galat beserta tombol coba lagi saat gagal',
      (tester) async {
    await pumpBeranda(
      tester,
      repositoryThatResponds(
        (_) async => throw http.ClientException('Connection refused'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('koneksi internet'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('coba lagi mengambil ulang dan menampilkan hasilnya',
      (tester) async {
    var attempt = 0;
    await pumpBeranda(
      tester,
      repositoryThatResponds((_) async {
        attempt++;
        if (attempt == 1) throw http.ClientException('Connection refused');
        return http.Response(jsonEncode(announcementListEnvelope()), 200);
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Coba lagi'), findsOneWidget);

    // Bagian pengumuman ada di bawah lipatan layar — tanpa digulir dulu,
    // ketukannya meleset dan test lolos secara palsu.
    await tester.ensureVisible(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(attempt, 2);
    expect(find.text('Payroll cut-off pindah ke tanggal 23'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });

  testWidgets('menampilkan keadaan kosong saat server belum punya data',
      (tester) async {
    await pumpBeranda(
      tester,
      repositoryThatResponds(
        (_) async => http.Response(
          jsonEncode(announcementListEnvelope(items: [])),
          200,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No announcements yet'), findsOneWidget);
  });

  testWidgets('menampilkan beberapa pengumuman sesuai urutan server',
      (tester) async {
    await pumpBeranda(
      tester,
      repositoryThatResponds(
        (_) async => http.Response(
          jsonEncode(
            announcementListEnvelope(
              items: [
                announcementListItem(id: 2, title: 'Pengumuman kedua'),
                announcementListItem(id: 1, title: 'Pengumuman pertama'),
              ],
            ),
          ),
          200,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final kedua = tester.getTopLeft(find.text('Pengumuman kedua')).dy;
    final pertama = tester.getTopLeft(find.text('Pengumuman pertama')).dy;
    expect(kedua, lessThan(pertama));
  });
}
