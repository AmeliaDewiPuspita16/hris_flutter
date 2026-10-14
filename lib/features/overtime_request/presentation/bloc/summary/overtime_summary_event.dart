/// Hal-hal yang bisa terjadi pada tab Summary Overtime Request.
sealed class OvertimeSummaryEvent {
  const OvertimeSummaryEvent();
}

/// Layar dibuka — muat bulan yang sedang dipilih.
class OvertimeSummaryStarted extends OvertimeSummaryEvent {
  const OvertimeSummaryStarted();
}

/// Muat ulang bulan yang sedang dipilih (tombol "Try again").
class OvertimeSummaryRetried extends OvertimeSummaryEvent {
  const OvertimeSummaryRetried();
}

/// User pindah bulan lewat panah di atas daftar.
class OvertimeSummaryMonthChanged extends OvertimeSummaryEvent {
  const OvertimeSummaryMonthChanged(this.month);

  final DateTime month;
}
