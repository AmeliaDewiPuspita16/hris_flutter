/// Hal-hal yang bisa terjadi pada Log Absensi.
sealed class AbsensiEvent {
  const AbsensiEvent();
}

/// Layar baru dibuka — muat entri & ringkasan untuk bulan yang sedang aktif.
class AbsensiStarted extends AbsensiEvent {
  const AbsensiStarted();
}

/// User pindah bulan (panah kiri/kanan atau lewat month picker) — muat
/// entri & ringkasan untuk bulan yang baru.
class AbsensiMonthChanged extends AbsensiEvent {
  const AbsensiMonthChanged(this.month);

  final DateTime month;
}
