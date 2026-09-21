import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/menu_portal/onlineapps/work_order/it_request/domain/it_request_attachment.dart';

void main() {
  ItRequestAttachment attachment({
    String fileName = 'foto.jpg',
    int sizeBytes = 1024,
  }) =>
      ItRequestAttachment(path: '/tmp/$fileName', fileName: fileName, sizeBytes: sizeBytes);

  group('validationError', () {
    for (final ext in ['jpg', 'jpeg', 'png', 'gif', 'webp']) {
      test('menerima ekstensi $ext', () {
        expect(attachment(fileName: 'foto.$ext').validationError, isNull);
      });
    }

    test('menolak ekstensi di luar daftar', () {
      expect(attachment(fileName: 'dokumen.pdf').validationError, isNotNull);
    });

    test('menolak berkas lebih dari 10 MB', () {
      final tooBig = attachment(sizeBytes: 10 * 1024 * 1024 + 1);

      expect(tooBig.validationError, contains('10 MB'));
    });

    test('menerima berkas persis 10 MB', () {
      expect(attachment(sizeBytes: 10 * 1024 * 1024).validationError, isNull);
    });

    test('menolak berkas kosong', () {
      expect(attachment(sizeBytes: 0).validationError, isNotNull);
    });

    test('pesan galat menyebut nama berkas', () {
      expect(attachment(fileName: 'dokumen.pdf').validationError, contains('dokumen.pdf'));
    });
  });
}
