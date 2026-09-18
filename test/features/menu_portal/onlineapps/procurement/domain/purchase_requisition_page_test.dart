import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/procurement/domain/purchase_requisition_page.dart';

import '../../../../../fixtures/eprocurement_response.dart';

void main() {
  group('PurchaseRequisitionPage.fromEnvelope', () {
    test('memetakan daftar, ringkasan, dan paginasi sekaligus', () {
      final page = PurchaseRequisitionPage.fromEnvelope(
        eprocurementListEnvelope(currentPage: 1, lastPage: 5, total: 9),
      );

      expect(page.items, hasLength(1));
      expect(page.summary.all, 9);
      expect(page.summary.countFor('pending_review'), 3);
      expect(page.meta.currentPage, 1);
      expect(page.meta.lastPage, 5);
      expect(page.meta.total, 9);
    });

    test('hasMore benar selama masih ada halaman berikutnya', () {
      final first = PurchaseRequisitionPage.fromEnvelope(
        eprocurementListEnvelope(currentPage: 1, lastPage: 5),
      );
      final last = PurchaseRequisitionPage.fromEnvelope(
        eprocurementListEnvelope(currentPage: 5, lastPage: 5),
      );

      expect(first.meta.hasMore, isTrue);
      expect(last.meta.hasMore, isFalse);
    });

    test('status tanpa catatan di ringkasan dihitung nol', () {
      final page = PurchaseRequisitionPage.fromEnvelope(
        eprocurementListEnvelope(summary: const {'all': 2, 'draft': 2}),
      );

      expect(page.summary.countFor('rejected'), 0);
    });

    test('hanya status yang dikirim server yang jadi chip filter', () {
      final page = PurchaseRequisitionPage.fromEnvelope(
        eprocurementListEnvelope(
          summary: const {'all': 2, 'draft': 2, 'approved': 0},
        ),
      );

      expect(
        page.summary.reportedCodes.map((c) => c.code).toList(),
        ['draft', 'approved'],
      );
    });

    test('satu baris rusak tidak menggugurkan seluruh halaman', () {
      final page = PurchaseRequisitionPage.fromEnvelope(
        eprocurementListEnvelope(
          items: [
            eprocurementListItem(id: 9),
            eprocurementListItem(id: 8)..remove('id'),
          ],
        ),
      );

      expect(page.items.map((i) => i.id).toList(), [9]);
    });

    test('amplop tanpa meta dianggap satu halaman saja', () {
      final envelope = eprocurementListEnvelope()..remove('meta');

      final page = PurchaseRequisitionPage.fromEnvelope(envelope);

      expect(page.meta.currentPage, 1);
      expect(page.meta.hasMore, isFalse);
    });
  });
}
