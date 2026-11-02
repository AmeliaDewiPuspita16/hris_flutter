import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/home/domain/approvals_waiting_summary.dart';

void main() {
  test('membaca kategori hse_permit dari approvals-waiting', () {
    final summary = ApprovalsWaitingSummary.fromJson({
      'total': 3,
      'categories': {
        'it_request': 0,
        'est_work_order': 0,
        'indent_vehicle': 0,
        'eprocurement': 2,
        'hse_permit': 1,
      },
    });

    expect(summary.total, 3);
    expect(summary.eprocurement, 2);
    expect(summary.hsePermit, 1);
  });

  test('hse_permit tidak ada (server lama) dianggap 0', () {
    final summary = ApprovalsWaitingSummary.fromJson({
      'total': 2,
      'categories': {'eprocurement': 2},
    });

    expect(summary.hsePermit, 0);
  });
}
