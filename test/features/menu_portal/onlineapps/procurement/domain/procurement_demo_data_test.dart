import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/pr_status.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/procurement_demo_data.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/progress_state.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/purchase_requisition.dart';

void main() {
  final items = ProcurementDemoData.items();

  PurchaseRequisition byNumber(String prNumber) =>
      items.firstWhere((pr) => pr.prNumber == prNumber);

  test('setiap PR punya minimal satu item', () {
    expect(items.every((pr) => pr.items.isNotEmpty), isTrue);
  });

  test('tahap approval sebelum status berjalan sudah ditandai selesai', () {
    final pr = byNumber('PR/EST/26-09/13');

    expect(pr.status, PrStatus.pendingDgm);
    expect(pr.approvalSteps[0].state, ProgressState.done);
    expect(pr.approvalSteps[1].state, ProgressState.done);
    expect(pr.approvalSteps[2].state, ProgressState.current);
    expect(pr.approvalSteps[3].state, ProgressState.pending);
  });

  test('PR yang sudah disetujui tidak menyisakan tahap yang berjalan', () {
    final pr = byNumber('PR/CVL/26-09/02');

    expect(pr.status, PrStatus.prApproved);
    expect(
      pr.approvalSteps.every((step) => step.state == ProgressState.done),
      isTrue,
    );
  });

  test('progress dokumen selalu berakhir di Goods Receipt', () {
    expect(
      items.every((pr) => pr.documentStages.last.title == 'Goods Receipt'),
      isTrue,
    );
  });
}
