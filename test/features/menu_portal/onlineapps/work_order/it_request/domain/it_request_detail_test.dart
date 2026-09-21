import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_detail.dart';

import '../../../../../../fixtures/it_request_response.dart';

void main() {
  group('ItRequestDetail.fromJson', () {
    test('membawa seluruh field ringkasan seperti versi daftar', () {
      final detail = ItRequestDetail.fromJson(itRequestDetail());

      expect(detail.id, 2395);
      expect(detail.status.code, 'finished');
      expect(detail.rating, 5);
    });

    test('memetakan requester', () {
      final detail = ItRequestDetail.fromJson(itRequestDetail());

      expect(detail.requester?.name, 'Frida Khaerani');
      expect(detail.requester?.department, 'HR & GA');
    });

    test('memetakan handling beserta tanggal mulai/selesainya', () {
      final detail = ItRequestDetail.fromJson(itRequestDetail());

      expect(detail.handling?.workBy, 'Aditya Yudha Pratama');
      expect(detail.handling?.dateStart, DateTime(2026, 8, 26));
      expect(detail.handling?.dateEnd, DateTime(2026, 8, 28));
      expect(detail.handling?.dateDone, isNull);
      expect(detail.handling?.resultImageUrl, isNotEmpty);
    });

    test('needs kosong dipetakan sebagai list kosong, bukan null', () {
      final detail = ItRequestDetail.fromJson(itRequestDetail());

      expect(detail.needs, isEmpty);
    });

    test('needs berisi dipetakan sebagai daftar CodeLabel', () {
      final detail = ItRequestDetail.fromJson(
        itRequestDetail(
          needs: const [
            {'code': 'hardware_need_laptop', 'label': 'Laptop'},
            {'code': 'hardware_need_mouse', 'label': 'Mouse'},
          ],
        ),
      );

      expect(detail.needs.map((n) => n.label).toList(), ['Laptop', 'Mouse']);
    });

    test('approved_at yang tanpa offset zona tetap terbaca', () {
      final detail = ItRequestDetail.fromJson(itRequestDetail());

      expect(detail.approvedAt, DateTime.parse('2026-08-26 11:11:39'));
    });

    test('rating_comment dan cancel_reason dibawa apa adanya', () {
      final detail = ItRequestDetail.fromJson(
        itRequestDetail(cancelReason: 'Sudah tidak dibutuhkan'),
      );

      expect(detail.ratingComment, 'thank youu');
      expect(detail.cancelReason, 'Sudah tidak dibutuhkan');
    });

    test('new_employee null tidak membuat parsing gagal', () {
      final detail = ItRequestDetail.fromJson(itRequestDetail());

      expect(detail.newEmployee, isNull);
    });
  });
}
