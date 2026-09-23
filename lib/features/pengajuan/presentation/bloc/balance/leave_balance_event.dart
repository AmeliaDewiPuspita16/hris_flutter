/// Hal-hal yang bisa terjadi pada saldo cuti/izin/lembur (tab Ringkasan).
sealed class LeaveBalanceEvent {
  const LeaveBalanceEvent();
}

/// Layar baru dibuka — muat saldo.
class LeaveBalanceStarted extends LeaveBalanceEvent {
  const LeaveBalanceStarted();
}

/// Tarik-untuk-muat-ulang.
class LeaveBalanceRefreshed extends LeaveBalanceEvent {
  const LeaveBalanceRefreshed();
}
