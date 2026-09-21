import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_item.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_type.dart';

import '../../../../../../fixtures/it_request_response.dart';

void main() {
  group('ItRequestItem.fromJson', () {
    test('memetakan satu baris daftar', () {
      final item = ItRequestItem.fromJson(itRequestListItem());

      expect(item.id, 2395);
      expect(item.type, ItRequestType.it);
      expect(item.supportType, 'PERMINTAAN');
      expect(item.category.label, 'Email account');
      expect(item.description, contains('rifki.a@biie.co.id'));
      expect(item.approval.label, 'Approved');
      expect(item.checking.checked, isTrue);
      expect(item.status.label, 'Finished');
      expect(item.rating, 5);
      expect(item.createdAt, DateTime.parse('2026-08-26T11:11:13+07:00'));
      expect(item.requester?.name, 'Admin CRS');
      expect(item.requester?.department, 'CRS');
      expect(item.isMine, isTrue);
      expect(item.canRate, isFalse);
    });

    test('can_rate menggantikan tebakan dari status code dan rating', () {
      // done tapi belum rated biasanya berarti "menunggu rating" — tapi
      // server sekarang bilang langsung lewat can_rate, bukan ditebak.
      final item = ItRequestItem.fromJson(
        itRequestListItem(statusCode: 'done', rating: null, canRate: true),
      );

      expect(item.canRate, isTrue);
    });

    test('requester yang hilang tidak menggagalkan parsing', () {
      final json = itRequestListItem()..remove('requester');

      final item = ItRequestItem.fromJson(json);

      expect(item.requester, isNull);
    });

    test('type Media terbaca dari kode "Media"', () {
      final item = ItRequestItem.fromJson(itRequestListItem(type: 'Media'));

      expect(item.type, ItRequestType.media);
    });

    test('menolak baris tanpa id — request tanpa identitas tidak bisa dibuka', () {
      final json = itRequestListItem()..remove('id');

      expect(() => ItRequestItem.fromJson(json), throwsA(isA<FormatException>()));
    });

    test('rating null dibaca apa adanya, bukan 0', () {
      final item = ItRequestItem.fromJson(itRequestListItem(rating: null));

      expect(item.rating, isNull);
    });
  });

  group('ItRequestItem.copyWith', () {
    test('mengganti rating tanpa mengubah field lain', () {
      final item = ItRequestItem.fromJson(itRequestListItem(rating: null));

      final rated = item.copyWith(rating: 4);

      expect(rated.rating, 4);
      expect(rated.id, item.id);
      expect(rated.description, item.description);
    });
  });
}
