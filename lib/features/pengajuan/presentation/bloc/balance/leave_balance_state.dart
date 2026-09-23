import '../../../domain/leave_balance.dart';

enum LeaveBalanceStatus { initial, loading, success, failure }

/// Keadaan saldo cuti/izin/lembur (tab Ringkasan).
class LeaveBalanceState {
  const LeaveBalanceState({
    this.status = LeaveBalanceStatus.initial,
    this.balances = const [],
    this.errorMessage,
  });

  final LeaveBalanceStatus status;
  final List<LeaveBalance> balances;
  final String? errorMessage;

  LeaveBalanceState copyWith({
    LeaveBalanceStatus? status,
    List<LeaveBalance>? balances,
    String? errorMessage,
  }) {
    return LeaveBalanceState(
      status: status ?? this.status,
      balances: balances ?? this.balances,
      // Selalu diisi eksplisit oleh pemanggil (null utk hapus, string utk
      // isi) — beda dgn field lain di atas, state ini tidak butuh sentinel
      // "unset" karena tidak ada transisi yang perlu MEMPERTAHANKAN pesan
      // galat lama sambil mengubah field lain.
      errorMessage: errorMessage,
    );
  }
}
