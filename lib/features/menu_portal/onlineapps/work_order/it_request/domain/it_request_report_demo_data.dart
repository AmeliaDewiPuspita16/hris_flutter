import 'it_request_monthly_trend.dart';
import 'it_request_report_summary.dart';
import 'it_request_status_breakdown.dart';

/// Data contoh untuk tab "Report" IT/Media Request.
///
/// SEMENTARA: belum ada endpoint report sungguhan, jadi angkanya statis
/// terlepas dari bulan/tahun yang dipilih — begitu API-nya ada, tinggal
/// diganti panggilan repository per periode tanpa mengubah bentuk
/// [ItRequestReportSummary] atau tampilan yang memakainya.
class ItRequestReportDemoData {
  ItRequestReportDemoData._();

  static ItRequestReportSummary summary() => const ItRequestReportSummary(
        totalRequest: 46,
        done: 17,
        onProgress: 5,
        onWaiting: 16,
        waitHod: 8,
        completionRate: 37,
        avgResponseDays: 3,
      );

  /// Sembilan bulan pertama berisi data (Jan–Sep), sisanya nol — belum
  /// terjadi di tahun berjalan, sama seperti contoh di web.
  static List<ItRequestMonthlyTrend> trend() => const [
        ItRequestMonthlyTrend(month: 1, itCount: 22, mediaCount: 17),
        ItRequestMonthlyTrend(month: 2, itCount: 21, mediaCount: 18),
        ItRequestMonthlyTrend(month: 3, itCount: 23, mediaCount: 26),
        ItRequestMonthlyTrend(month: 4, itCount: 24, mediaCount: 27),
        ItRequestMonthlyTrend(month: 5, itCount: 28, mediaCount: 18),
        ItRequestMonthlyTrend(month: 6, itCount: 19, mediaCount: 14),
        ItRequestMonthlyTrend(month: 7, itCount: 32, mediaCount: 22),
        ItRequestMonthlyTrend(month: 8, itCount: 44, mediaCount: 20),
        ItRequestMonthlyTrend(month: 9, itCount: 30, mediaCount: 17),
        ItRequestMonthlyTrend(month: 10, itCount: 0, mediaCount: 0),
        ItRequestMonthlyTrend(month: 11, itCount: 0, mediaCount: 0),
        ItRequestMonthlyTrend(month: 12, itCount: 0, mediaCount: 0),
      ];

  static ItRequestStatusBreakdown itStatus() =>
      const ItRequestStatusBreakdown(open: 9, close: 15);

  static ItRequestStatusBreakdown mediaStatus() =>
      const ItRequestStatusBreakdown(open: 11, close: 4);
}
