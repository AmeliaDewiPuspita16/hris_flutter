/// Hal-hal yang bisa terjadi pada Log Absensi.
sealed class AbsensiEvent {
  const AbsensiEvent();
}

/// Layar baru dibuka — muat jadwal & realisasi untuk bulan yang sedang
/// aktif.
class AbsensiStarted extends AbsensiEvent {
  const AbsensiStarted();
}

/// User pindah bulan (panah kiri/kanan atau lewat month picker) — muat
/// ulang data untuk bulan yang baru.
class AbsensiMonthChanged extends AbsensiEvent {
  const AbsensiMonthChanged(this.month);

  final DateTime month;
}

/// User memilih satu tanggal di kalender — tampilkan detailnya di panel
/// bawah.
class AbsensiDateSelected extends AbsensiEvent {
  const AbsensiDateSelected(this.date);

  final DateTime date;
}
