import '../../../domain/indent_request_item.dart';

/// Hal-hal yang bisa terjadi pada tab "List of User Requests".
sealed class IndentRequestListEvent {
  const IndentRequestListEvent();
}

/// Layar baru dibuka — muat daftar dari server.
class IndentRequestListStarted extends IndentRequestListEvent {
  const IndentRequestListStarted();
}

/// Tarik-untuk-muat-ulang, atau tombol "Coba lagi" saat gagal.
class IndentRequestListRefreshed extends IndentRequestListEvent {
  const IndentRequestListRefreshed();
}

/// SEMENTARA — aksi di bawah ini masih lokal (belum tersambung ke API),
/// jadi layar yang menjalankannya memberi tahu Bloc supaya tampilan ikut
/// berubah. Dihapus satu per satu begitu endpoint-nya disambungkan
/// (tambah, edit, hapus request), karena nanti cukup memuat ulang daftar.

/// Request baru dari form Add Indent, disisipkan di puncak daftar.
class IndentRequestLocalAdded extends IndentRequestListEvent {
  const IndentRequestLocalAdded(this.item);

  final IndentRequestItem item;
}

/// Request yang diedit atau diberi rating; menggantikan item ber-id sama.
class IndentRequestLocalUpdated extends IndentRequestListEvent {
  const IndentRequestLocalUpdated(this.item);

  final IndentRequestItem item;
}

/// Request yang dihapus dari daftar.
class IndentRequestLocalRemoved extends IndentRequestListEvent {
  const IndentRequestLocalRemoved(this.id);

  final String id;
}
