import '../../../domain/overtime_month.dart';

enum OvertimeSummaryStatus { initial, loading, success, failure }

/// Keadaan tab Summary: bulan terpilih + realisasi lembur bulan itu.
class OvertimeSummaryState {
  const OvertimeSummaryState({
    required this.month,
    this.status = OvertimeSummaryStatus.initial,
    this.data,
    this.errorMessage,
  });

  /// Bulan terpilih (tanggal selalu 1).
  final DateTime month;
  final OvertimeSummaryStatus status;
  final OvertimeMonth? data;
  final String? errorMessage;

  OvertimeSummaryState copyWith({
    OvertimeSummaryStatus? status,
    OvertimeMonth? data,
    String? errorMessage,
  }) {
    return OvertimeSummaryState(
      month: month,
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}
