/// Pemformat nilai uang Rupiah.
///
/// Sebelumnya menumpang di `features/gaji/domain/payslip.dart`. Dipindah ke
/// core begitu layar kedua (Procurement Monitoring) ikut membutuhkannya —
/// feature yang saling meng-import feature lain hanya demi satu helper.
library;

/// Contoh: 2265000 -> "Rp 2.265.000", -1500000 -> "-Rp 1.500.000".
String formatRupiah(int amount) {
  final sign = amount < 0 ? '-' : '';
  final digits = amount.abs().toString();

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final posFromRight = digits.length - i;
    buffer.write(digits[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write('.');
  }

  return '${sign}Rp $buffer';
}
