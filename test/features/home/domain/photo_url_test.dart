import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/features/home/domain/published_announcement.dart';

void main() {
  AnnouncementPhotoRef refWithUrl(String url) =>
      AnnouncementPhotoRef.fromJson({'id': 1, 'url': url});

  group('displayUrl', () {
    test('meneruskan URL dari server apa adanya', () {
      const url =
          'https://biieportal.co.id/storage/hrga/announcements/mJLGfOAy.jpg';

      expect(refWithUrl(url).displayUrl, url);
    });

    test('mempertahankan query string', () {
      const url = 'https://biieportal.co.id/storage/a.jpg?v=2';

      expect(refWithUrl(url).displayUrl, url);
    });

    test('mengembalikan string kosong saat URL tidak bisa diurai', () {
      expect(refWithUrl('bukan url sama sekali').displayUrl, '');
    });

    test('mengembalikan string kosong saat URL tanpa skema', () {
      expect(refWithUrl('biieportal.co.id/a.jpg').displayUrl, '');
    });

    test('mengembalikan string kosong saat server tidak mengirim url', () {
      expect(AnnouncementPhotoRef.fromJson({'id': 1}).displayUrl, '');
    });
  });
}
