/// Hal-hal yang bisa terjadi pada tab Status Overtime Request.
sealed class OvertimeRequestsEvent {
  const OvertimeRequestsEvent();
}

/// Muat riwayat pengajuan: saat layar dibuka, tombol "Try again", dan setelah
/// pengajuan baru berhasil dikirim.
class OvertimeRequestsLoaded extends OvertimeRequestsEvent {
  const OvertimeRequestsLoaded();
}
