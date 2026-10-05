import 'payslip.dart';

/// sumber data slip gaji milik user yang sedang login
///
/// sengaja berupa kontrak (abstract) karena API-nya belum ada:
/// sekarang diisi 'MockPayslipRepository' yang mengembalikan data contoh.
abstract class PayslipRepository {
  /// Slip gaji pada [year], terbaru lebih dulu. Kosong bila belum ada.
  ///
  /// Implementasi API melempar `ApiException` bila gagal.
  Future<List<Payslip>> getPayslips({required int year});
}
