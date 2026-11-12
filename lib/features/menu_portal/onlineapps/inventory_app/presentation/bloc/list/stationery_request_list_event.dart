/// Penyaring daftar yang dikirim ke server (`status`, `search`, `mine`).
class StationeryRequestListFilter {
  const StationeryRequestListFilter({
    this.status,
    this.search = '',
    this.mine = false,
  });

  /// Kode status (`pending` | `approved` | `rejected`), atau null = semua.
  final String? status;
  final String search;
  final bool mine;

  static const none = StationeryRequestListFilter();

  @override
  bool operator ==(Object other) =>
      other is StationeryRequestListFilter &&
      other.status == status &&
      other.search == search &&
      other.mine == mine;

  @override
  int get hashCode => Object.hash(status, search, mine);
}

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

/// Status, kata kunci, atau "My requests" berubah — muat ulang dari halaman 1
/// dengan penyaring baru. Penyaring itu tetap dipakai oleh Refreshed dan
/// NextPageRequested sampai diganti lagi.
class StationeryRequestListFilterChanged extends StationeryRequestListEvent {
  const StationeryRequestListFilterChanged(this.filter);

  final StationeryRequestListFilter filter;
}
