/// Hal-hal yang bisa terjadi pada daftar "Request Items" stationery.
sealed class StationeryRequestListEvent {
  const StationeryRequestListEvent();
}

/// Layar baru dibuka — muat daftar dari server.
class StationeryRequestListStarted extends StationeryRequestListEvent {
  const StationeryRequestListStarted();
}

/// Tarik-untuk-muat-ulang, tombol "Retry", atau setelah ada perubahan di
/// server (request baru, edit, cancel, approve/reject).
class StationeryRequestListRefreshed extends StationeryRequestListEvent {
  const StationeryRequestListRefreshed();
}

/// Pengguna menggulir sampai dekat dasar daftar — muat halaman berikutnya.
/// Diabaikan bloc kalau sedang memuat atau sudah halaman terakhir.
class StationeryRequestListNextPageRequested
    extends StationeryRequestListEvent {
  const StationeryRequestListNextPageRequested();
}
