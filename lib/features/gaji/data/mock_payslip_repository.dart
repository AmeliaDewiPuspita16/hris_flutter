import '../domain/payslip.dart';
import '../domain/payslip_repository.dart';

/// Data contoh untuk slip gaji selama API belum tersedia. Nominal dan
/// komponen disini hanya untuk melihat bentuk tampilan, bukan data asli.
class MockPayslipRepository implements PayslipRepository {
  const MockPayslipRepository();

  @override
  Future<List<Payslip>> getPayslips({required int year}) async {
    // Meniru jeda jaringan supaya status loading ikut terlihat.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return _byYear[year] ?? const [];
  }

  static const _byYear = <int, List<Payslip>>{
    2026: _slips2026,
    2025: _slips2025,
    // 2024 sengaja kosong: untuk melihat tampilan "belum ada slip".
  };

  static const _slips2026 = [
    Payslip(
      id: '2026-09',
      periodLabel: 'September 2026',
      status: PayslipStatus.pending,
      earnings: [
        PayslipItem(label: 'Gaji Pokok', amount: 7500000),
        PayslipItem(label: 'Tunjangan Jabatan', amount: 800000),
        PayslipItem(label: 'Lembur', amount: 30000),
      ],
      deductions: [
        PayslipItem(label: 'BPJS Kesehatan', amount: 100000),
        PayslipItem(label: 'PPh 21', amount: 100000),
      ],
    ),
    Payslip(
      id: '2026-08',
      periodLabel: 'Agustus 2026',
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

  static const _slips2025 = [
    Payslip(
      id: '2025-12',
      periodLabel: 'Desember 2025',
      status: PayslipStatus.paid,
      paidDate: '25 Desember 2025',
      bankInfo: 'BCA ••1234',
      earnings: [
        PayslipItem(label: 'Gaji Pokok', amount: 7000000),
        PayslipItem(label: 'Tunjangan Jabatan', amount: 800000),
      ],
      deductions: [
        PayslipItem(label: 'BPJS Kesehatan', amount: 100000),
        PayslipItem(label: 'PPh 21', amount: 100000),
      ],
    ),
    Payslip(
      id: '2025-11',
      periodLabel: 'November 2025',
      status: PayslipStatus.paid,
      paidDate: '25 November 2025',
      bankInfo: 'BCA ••1234',
      earnings: [
        PayslipItem(label: 'Gaji Pokok', amount: 7000000),
        PayslipItem(label: 'Tunjangan Jabatan', amount: 800000),
      ],
      deductions: [
        PayslipItem(label: 'BPJS Kesehatan', amount: 100000),
        PayslipItem(label: 'PPh 21', amount: 100000),
      ],
    ),
  ];
}
