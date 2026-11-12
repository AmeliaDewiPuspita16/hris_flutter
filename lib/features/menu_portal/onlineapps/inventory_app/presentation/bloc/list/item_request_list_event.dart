/// Penyaring daftar yang dikirim ke server (`status`, `search`, `mine`).
class ItemRequestListFilter {
  const ItemRequestListFilter({
    this.status,
    this.search = '',
    this.mine = false,
  });

  /// Kode status (`pending` | `approved` | `rejected`), atau null = semua.
  final String? status;
  final String search;
  final bool mine;

  static const none = ItemRequestListFilter();

  @override
  bool operator ==(Object other) =>
      other is ItemRequestListFilter &&
      other.status == status &&
      other.search == search &&
      other.mine == mine;

  @override
  int get hashCode => Object.hash(status, search, mine);
}

/// Hal-hal yang bisa terjadi pada daftar "Request Items".
sealed class ItemRequestListEvent {
  const ItemRequestListEvent();
}

/// Layar baru dibuka — muat daftar dari server.
class ItemRequestListStarted extends ItemRequestListEvent {
  const ItemRequestListStarted();
}

/// Tarik-untuk-muat-ulang, tombol "Retry", atau setelah ada perubahan di
/// server (request baru, edit, cancel, approve/reject).
class ItemRequestListRefreshed extends ItemRequestListEvent {
  const ItemRequestListRefreshed();
}

/// Pengguna menggulir sampai dekat dasar daftar — muat halaman berikutnya.
/// Diabaikan bloc kalau sedang memuat atau sudah halaman terakhir.
class ItemRequestListNextPageRequested
    extends ItemRequestListEvent {
  const ItemRequestListNextPageRequested();
}

/// Status, kata kunci, atau "My requests" berubah — muat ulang dari halaman 1
/// dengan penyaring baru. Penyaring itu tetap dipakai oleh Refreshed dan
/// NextPageRequested sampai diganti lagi.
class ItemRequestListFilterChanged extends ItemRequestListEvent {
  const ItemRequestListFilterChanged(this.filter);

  final ItemRequestListFilter filter;
}
