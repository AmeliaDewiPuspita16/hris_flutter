/// model Payslip, PayslipItem, PayslipStatus, 
/// plus dummy data 3 bulan dan helper formatRupiah().

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
class Payslip {
  const Payslip({
    required this.id,
    required this.periodLabel,
    required this.netPay,
    required this.status,
    required this.earnings,
    required this.deductions,
    this.paidDate,
    this.bankInfo,
  });

  final String id;

  /// Label periode, ex: "Agustus 2026".
  final String periodLabel;

  /// Take home pay (pendapatan - potongan).
  final int netPay;

  final PayslipStatus status;

  final List<PayslipItem> earnings;
  final List<PayslipItem> deductions;

  /// Tanggal slip dibayarkan, ex: "25 Agustus 2026". Null kalau masih [PayslipStatus.pending].
  final String? paidDate;

  /// Info rekening tujuan, ex: "BCA ••1234". Null kalau masih [PayslipStatus.pending].
  final String? bankInfo;

  /// Data dummy
  static const dummy2026 = [
    Payslip(
      id: '2026-09',
      periodLabel: 'September 2026',
      netPay: 8450000,
      status: PayslipStatus.pending,
      earnings: [
        PayslipItem(label: 'Gaji Pokok', amount: 7500000),
        PayslipItem(label: 'Tunjangan Jabatan', amount: 800000),
        PayslipItem(label: 'Lembur', amount: 350000),
      ],
      deductions: [
        PayslipItem(label: 'BPJS Kesehatan', amount: 100000),
        PayslipItem(label: 'PPh 21', amount: 100000),
      ],
    ),
    Payslip(
      id: '2026-08',
      periodLabel: 'Agustus 2026',
      netPay: 8120000,
      status: PayslipStatus.paid,
      paidDate: '25 Agustus 2026',
      bankInfo: 'BCA ••1234',
      earnings: [
        PayslipItem(label: 'Gaji Pokok', amount: 7500000),
        PayslipItem(label: 'Tunjangan Jabatan', amount: 800000),
        PayslipItem(label: 'Lembur', amount: 20000),
      ],
      deductions: [
        PayslipItem(label: 'BPJS Kesehatan', amount: 100000),
        PayslipItem(label: 'PPh 21', amount: 100000),
      ],
    ),
    Payslip(
      id: '2026-07',
      periodLabel: 'Juli 2026',
      netPay: 7980000,
      status: PayslipStatus.paid,
      paidDate: '25 Juli 2026',
      bankInfo: 'BCA ••1234',
      earnings: [
        PayslipItem(label: 'Gaji Pokok', amount: 7500000),
        PayslipItem(label: 'Tunjangan Jabatan', amount: 800000),
      ],
      deductions: [
        PayslipItem(label: 'BPJS Kesehatan', amount: 100000),
        PayslipItem(label: 'PPh 21', amount: 220000),
      ],
    ),
  ];
}

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