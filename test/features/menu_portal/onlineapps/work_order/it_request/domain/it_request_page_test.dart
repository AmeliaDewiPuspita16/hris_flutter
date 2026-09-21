import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_page.dart';

import '../../../../../../fixtures/it_request_response.dart';

void main() {
  group('ItRequestPage.fromEnvelope', () {
    test('memetakan daftar, ringkasan, dan paginasi sekaligus', () {
      final page = ItRequestPage.fromEnvelope(
        itRequestListEnvelope(awaitingRating: 6, currentPage: 1, lastPage: 57, total: 114),
      );

      expect(page.items, hasLength(1));
      expect(page.summary.awaitingRating, 6);
      expect(page.meta.currentPage, 1);
      expect(page.meta.lastPage, 57);
      expect(page.meta.total, 114);
    });

    test('hasMore benar selama masih ada halaman berikutnya', () {
      final page = ItRequestPage.fromEnvelope(
        itRequestListEnvelope(currentPage: 1, lastPage: 57),
      );

      expect(page.meta.hasMore, isTrue);
    });

    test('satu baris rusak tidak menggugurkan seluruh halaman', () {
      final page = ItRequestPage.fromEnvelope(
        itRequestListEnvelope(
          items: [
            itRequestListItem(id: 9),
            itRequestListItem(id: 8)..remove('id'),
          ],
        ),
      );

      expect(page.items.map((i) => i.id).toList(), [9]);
    });

    test('amplop tanpa summary dianggap tidak ada yang menunggu rating', () {
      final envelope = itRequestListEnvelope()..remove('summary');

      final page = ItRequestPage.fromEnvelope(envelope);

      expect(page.summary.awaitingRating, 0);
    });
  });
}
