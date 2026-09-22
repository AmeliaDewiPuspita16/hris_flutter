import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_status_breakdown.dart';

void main() {
  group('ItRequestStatusBreakdown.closedPercent', () {
    test('membulatkan persentase yang sudah ditutup', () {
      const breakdown = ItRequestStatusBreakdown(open: 9, close: 14);

      expect(breakdown.closedPercent, 61);
    });

    test('20% tepat tanpa pembulatan', () {
      const breakdown = ItRequestStatusBreakdown(open: 12, close: 3);

      expect(breakdown.closedPercent, 20);
    });

    test('null kalau belum ada data sama sekali, bukan 0%', () {
      const breakdown = ItRequestStatusBreakdown(open: 0, close: 0);

      expect(breakdown.closedPercent, isNull);
    });

    test('100% kalau semuanya sudah ditutup', () {
      const breakdown = ItRequestStatusBreakdown(open: 0, close: 5);

      expect(breakdown.closedPercent, 100);
    });
  });
}
