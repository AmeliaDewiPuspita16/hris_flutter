import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/home/domain/announcement_photo.dart';

void main() {
  AnnouncementPhoto photo({
    String fileName = 'poster.jpg',
    int sizeBytes = 1024,
  }) {
    return AnnouncementPhoto(
      path: '/tmp/$fileName',
      fileName: fileName,
      sizeBytes: sizeBytes,
    );
  }

  group('extension', () {
    test('mengambil ekstensi dalam huruf kecil', () {
      expect(photo(fileName: 'Poster.JPG').extension, 'jpg');
    });

    test('mengambil ekstensi terakhir pada nama berlapis', () {
      expect(photo(fileName: 'foto.bulan.ini.png').extension, 'png');
    });

    test('kosong saat nama berkas tidak punya ekstensi', () {
      expect(photo(fileName: 'poster').extension, '');
    });
  });

  group('validationError satu berkas', () {
    test('menerima jpg, jpeg, dan png', () {
      for (final name in ['a.jpg', 'b.jpeg', 'c.png', 'D.PNG']) {
        expect(photo(fileName: name).validationError, isNull, reason: name);
      }
    });

    test('menolak format lain dan menyebut nama berkasnya', () {
      final error = photo(fileName: 'dokumen.pdf').validationError;

      expect(error, isNotNull);
      expect(error, contains('dokumen.pdf'));
    });

    test('menolak HEIC yang lazim dari kamera iPhone', () {
      expect(photo(fileName: 'IMG_0001.HEIC').validationError, isNotNull);
    });

    test('menolak berkas lebih dari 5 MB', () {
      final error = photo(sizeBytes: AnnouncementPhoto.maxSizeBytes + 1)
          .validationError;

      expect(error, isNotNull);
      expect(error, contains('5 MB'));
    });

    test('menerima berkas tepat 5 MB', () {
      expect(
        photo(sizeBytes: AnnouncementPhoto.maxSizeBytes).validationError,
        isNull,
      );
    });

    test('menolak berkas kosong', () {
      expect(photo(sizeBytes: 0).validationError, isNotNull);
    });
  });

  group('errorForSelection', () {
    List<AnnouncementPhoto> photos(int count) =>
        List.generate(count, (i) => photo(fileName: 'poster$i.jpg'));

    test('menerima pilihan kosong karena foto memang opsional', () {
      expect(AnnouncementPhoto.errorForSelection(const []), isNull);
    });

    test('menerima tepat 10 berkas', () {
      expect(AnnouncementPhoto.errorForSelection(photos(10)), isNull);
    });

    test('menolak lebih dari 10 berkas', () {
      final error = AnnouncementPhoto.errorForSelection(photos(11));

      expect(error, isNotNull);
      expect(error, contains('10'));
    });

    test('melaporkan berkas pertama yang bermasalah', () {
      final error = AnnouncementPhoto.errorForSelection([
        photo(fileName: 'baik.jpg'),
        photo(fileName: 'buruk.gif'),
      ]);

      expect(error, contains('buruk.gif'));
    });
  });
}
