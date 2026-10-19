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

/// Pengguna menggulir sampai dekat dasar daftar — muat halaman berikutnya.
/// Diabaikan Bloc kalau sedang memuat atau sudah halaman terakhir, jadi
/// layar boleh mengirimnya berulang tanpa khawatir.
class IndentRequestListNextPageRequested extends IndentRequestListEvent {
  const IndentRequestListNextPageRequested();
}

/// SEMENTARA — aksi di bawah ini masih lokal (belum tersambung ke API),
/// jadi layar yang menjalankannya memberi tahu Bloc supaya tampilan ikut
/// berubah. Dihapus satu per satu begitu endpoint-nya disambungkan
/// (feedback, hapus request), karena nanti cukup memuat ulang daftar.
/// Tambah dan edit request sudah tersambung: layar langsung memicu
/// [IndentRequestListRefreshed] setelah form berhasil menyimpan.

/// Request yang diberi rating; menggantikan item ber-id sama.
class IndentRequestLocalUpdated extends IndentRequestListEvent {
  const IndentRequestLocalUpdated(this.item);

  final IndentRequestItem item;
}

/// Request yang dihapus dari daftar.
class IndentRequestLocalRemoved extends IndentRequestListEvent {
  const IndentRequestLocalRemoved(this.id);

  final String id;
}
