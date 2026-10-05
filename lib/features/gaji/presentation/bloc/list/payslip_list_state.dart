import '../../../domain/payslip.dart';

enum PayslipListStatus { loading, success, failure }

/// Keadaan daftar slip gaji.
class PayslipListState {
  const PayslipListState({
    required this.year,
    required this.years,
    this.status = PayslipListStatus.loading,
    this.payslips = const [],
    this.errorMessage,
  });

  /// Tahun yang sedang ditampilkan.
  final int year;

  /// Tahun yang bisa dipilih, terbaru lebih dulu.
  final List<int> years;

  final PayslipListStatus status;
  final List<Payslip> payslips;
  final String? errorMessage;

  PayslipListState copyWith({
    int? year,
    PayslipListStatus? status,
    List<Payslip>? payslips,
    String? errorMessage,
  }) {
    return PayslipListState(
      year: year ?? this.year,
      years: years,
      status: status ?? this.status,
      payslips: payslips ?? this.payslips,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayslipListState &&
          other.year == year &&
          other.status == status &&
          identical(other.payslips, payslips) &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(year, status, payslips, errorMessage);
}
