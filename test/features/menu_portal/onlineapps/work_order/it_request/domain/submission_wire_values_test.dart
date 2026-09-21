import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_type.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/support_type.dart';

void main() {
  group('ItRequestType.formValue — dipakai field type_request saat submit',
      () {
    test('IT terkirim sebagai "1"', () {
      expect(ItRequestType.it.formValue, '1');
    });

    test('Media terkirim sebagai "2"', () {
      expect(ItRequestType.media.formValue, '2');
    });
  });

  group('SupportType.wireValue — dipakai field jenis_dukungan saat submit',
      () {
    test('request terkirim sebagai PERMINTAAN', () {
      expect(SupportType.request.wireValue, 'PERMINTAAN');
    });

    test('repair terkirim sebagai PERBAIKAN', () {
      expect(SupportType.repair.wireValue, 'PERBAIKAN');
    });

    test('return_ terkirim sebagai PENGEMBALIAN', () {
      expect(SupportType.return_.wireValue, 'PENGEMBALIAN');
    });
  });
}
