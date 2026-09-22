import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hris_mobile/core/utils/date_formatter.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_report_demo_data.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/presentation/widgets/report_tab.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  Future<void> pumpReportTab(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ReportTab())));
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan label bulan-tahun berjalan', (tester) async {
    await pumpReportTab(tester);

    expect(find.text(DateFormatter.monthYearID(DateTime.now())), findsOneWidget);
  });

  testWidgets('menampilkan ketujuh kartu ringkasan dari data', (tester) async {
    await pumpReportTab(tester);

    final summary = ItRequestReportDemoData.summary();

    // Label kartu sengaja ditampilkan huruf kapital semua (gaya KPI/dashboard),
    // sama seperti label kategori di ItRequestFeedbackBanner.
    expect(find.text('TOTAL REQUEST'), findsOneWidget);
    expect(find.text('${summary.totalRequest}'), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);
    expect(find.text('${summary.done}'), findsOneWidget);
    expect(find.text('ON PROGRESS'), findsOneWidget);
    expect(find.text('${summary.onProgress}'), findsOneWidget);
    expect(find.text('ON WAITING'), findsOneWidget);
    expect(find.text('${summary.onWaiting}'), findsOneWidget);
    expect(find.text('WAIT HOD'), findsOneWidget);
    expect(find.text('${summary.waitHod}'), findsOneWidget);
    expect(find.text('COMPLETION RATE'), findsOneWidget);
    expect(find.text('${summary.completionRate}%'), findsOneWidget);
    expect(find.text('AVG RESPONSE'), findsOneWidget);
    expect(find.text('${summary.avgResponseDays}'), findsOneWidget);
  });

  testWidgets('mengetuk label bulan membuka dialog pemilih bulan',
      (tester) async {
    await pumpReportTab(tester);

    await tester.tap(find.text(DateFormatter.monthYearID(DateTime.now())));
    await tester.pumpAndSettle();

    expect(find.text('Pilih'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });

  testWidgets('menampilkan judul dan tahun chart tren', (tester) async {
    await pumpReportTab(tester);

    expect(find.text('Tren Request Per Bulan'), findsOneWidget);
    expect(find.textContaining('${DateTime.now().year}'), findsWidgets);
  });

  testWidgets('menampilkan legend IT Request dan Media Request',
      (tester) async {
    await pumpReportTab(tester);

    expect(find.text('IT Request'), findsOneWidget);
    expect(find.text('Media Request'), findsOneWidget);
  });

  testWidgets('menampilkan label semua bulan Jan sampai Des', (tester) async {
    await pumpReportTab(tester);

    for (final label in const [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'label $label');
    }
  });

  testWidgets('mengetuk bar IT bulan Agustus menampilkan nilainya',
      (tester) async {
    await pumpReportTab(tester);

    final trend = ItRequestReportDemoData.trend()
        .firstWhere((t) => t.month == 8);

    expect(find.text('${trend.itCount}'), findsNothing);

    final bar = find.byKey(const ValueKey('trend-bar-it-8'));
    await tester.ensureVisible(bar);
    await tester.pumpAndSettle();
    await tester.tap(bar);
    await tester.pump();

    expect(find.text('${trend.itCount}'), findsOneWidget);
  });

  testWidgets('bar chart tren tumbuh bawah ke atas (vertikal)',
      (tester) async {
    await pumpReportTab(tester);

    final bar = find.byKey(const ValueKey('trend-bar-it-8'));
    await tester.ensureVisible(bar);
    await tester.pumpAndSettle();

    final size = tester.getSize(bar);
    expect(size.height, greaterThan(size.width),
        reason: 'bar Agustus (nilai tertinggi) harus lebih tinggi dari '
            'lebar kalau tumbuh vertikal');
  });

  testWidgets('menampilkan status IT dan Media dengan angka Open/Close',
      (tester) async {
    await pumpReportTab(tester);

    final itStatus = ItRequestReportDemoData.itStatus();
    final mediaStatus = ItRequestReportDemoData.mediaStatus();

    // ListView(children:) tetap lazy-mount lewat sliver di baliknya, jadi
    // kartu status yang ada di bawah trend chart belum ter-build sampai
    // di-scroll ke sana.
    await tester.scrollUntilVisible(find.text('Status IT Request'), 300);
    await tester.pumpAndSettle();

    expect(find.text('Status IT Request'), findsOneWidget);
    expect(find.text('Status Media Request'), findsOneWidget);
    expect(find.text('Open'), findsNWidgets(2));
    expect(find.text('Close'), findsNWidgets(2));
    expect(find.text('${itStatus.open}'), findsOneWidget);
    expect(find.text('${itStatus.close}'), findsOneWidget);
    expect(find.text('${mediaStatus.open}'), findsOneWidget);
    expect(find.text('${mediaStatus.close}'), findsOneWidget);
  });

  testWidgets('menampilkan persentase closed yang benar untuk IT dan Media',
      (tester) async {
    await pumpReportTab(tester);

    final itStatus = ItRequestReportDemoData.itStatus();
    final mediaStatus = ItRequestReportDemoData.mediaStatus();

    await tester.scrollUntilVisible(find.text('Status IT Request'), 300);
    await tester.pumpAndSettle();

    expect(find.text('${itStatus.closedPercent}% closed'), findsOneWidget);
    expect(find.text('${mediaStatus.closedPercent}% closed'), findsOneWidget);
  });
}
