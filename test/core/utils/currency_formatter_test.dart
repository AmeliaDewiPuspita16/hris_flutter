import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/utils/currency_formatter.dart';

void main() {
  test('memberi pemisah ribuan setiap tiga digit', () {
    expect(formatRupiah(2265000), 'Rp 2.265.000');
  });

  test('tidak memberi pemisah untuk nilai di bawah seribu', () {
    expect(formatRupiah(453), 'Rp 453');
  });

  test('menaruh tanda minus sebelum "Rp"', () {
    expect(formatRupiah(-1500000), '-Rp 1.500.000');
  });

  test('menulis nol apa adanya', () {
    expect(formatRupiah(0), 'Rp 0');
  });
}
