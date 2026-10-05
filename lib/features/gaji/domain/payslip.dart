/// Model slip gaji. Tidak menyimpan data contoh — itu urusan lapisan data
/// (lihat di `MockPayslipRepository`).
///
/// formatRupiah() ada di `core/utils/currency_formatter.dart`.
library;

// Status pembayaran slip gaji per periode.
enum PayslipStatus {
  paid,
  pending,
}

class PayslipItem {
  const PayslipItem({
    required this.label,
    required this.amount,
  });

  final String label;
  final int amount;
}

/// Slip gaji untuk satu periode (bulan).
///
/// Komponen pendapatan dan potongan berupa DAFTAR, bukan kolom tetap:
/// tiap perusahaan/golongan punya komponen berbeda, jadi layar cukup
/// menampilkan apa pun yang dikirim tanpa perlu diubah.
class Payslip {
  const Payslip({
    required this.id,
    required this.periodLabel,
    required this.status,
    required this.earnings,
    required this.deductions,
    this.paidDate,
    this.bankInfo,
  });

  final String id;

  /// Label periode, ex: "Agustus 2026".
  final String periodLabel;

  final PayslipStatus status;

  final List<PayslipItem> earnings;
  final List<PayslipItem> deductions;

  /// Tanggal slip dibayarkan, ex: "25 Agustus 2026". Null kalau masih [PayslipStatus.pending].
  final String? paidDate;

  /// Info rekening tujuan, ex: "BCA ••1234". Null kalau masih [PayslipStatus.pending].
  final String? bankInfo;

  int get totalEarnings => earnings.fold(0, (sum, e) => sum + e.amount);

  int get totalDeductions => deductions.fold(0, (sum, e) => sum + e.amount);

  /// Take home pay = pendapatan - potongan. Dihitung, bukan disimpan, supaya
  /// tidak pernah selisih dengan rinciannya.
  int get netPay => totalEarnings - totalDeductions;

  bool get isPaid => status == PayslipStatus.paid;
}
