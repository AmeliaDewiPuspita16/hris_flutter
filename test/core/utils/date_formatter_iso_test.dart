import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter.dayMonthYearFromIso', () {
    test('mengubah tanggal ISO dari API jadi format tampilan', () {
      expect(DateFormatter.dayMonthYearFromIso('1991-11-21'), '21-11-1991');
    });

    test('memberi nol di depan pada tanggal dan bulan satu digit', () {
      expect(DateFormatter.dayMonthYearFromIso('1994-04-08'), '08-04-1994');
    });

    test('menerima bentuk ISO lengkap dengan jam', () {
      expect(
        DateFormatter.dayMonthYearFromIso('1991-11-21T00:00:00.000000Z'),
        '21-11-1991',
      );
    });

    test('mengembalikan null saat teksnya bukan tanggal', () {
      expect(DateFormatter.dayMonthYearFromIso('belum diisi'), isNull);
    });

    test('menolak 0000-00-00 yang dipakai MySQL untuk tanggal kosong', () {
      // DateTime menormalkannya jadi 30-11-0000, bukan gagal urai.
      expect(DateFormatter.dayMonthYearFromIso('0000-00-00'), isNull);
    });

    test('menolak tanggal yang melewati akhir bulan', () {
      expect(DateFormatter.dayMonthYearFromIso('1991-02-31'), isNull);
    });

    test('mengembalikan null saat nilainya null atau kosong', () {
      expect(DateFormatter.dayMonthYearFromIso(null), isNull);
      expect(DateFormatter.dayMonthYearFromIso(''), isNull);
    });
  });
}
