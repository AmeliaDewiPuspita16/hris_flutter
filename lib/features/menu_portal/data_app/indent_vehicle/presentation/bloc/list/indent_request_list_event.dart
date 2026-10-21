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

// Tambah, edit, dan feedback sudah tersambung ke API: layar langsung
// memicu [IndentRequestListRefreshed] setelah server menerima.

/// Request yang sudah dihapus di server; dibuang dari daftar tanpa memuat
/// ulang supaya posisi scroll tetap.
class IndentRequestLocalRemoved extends IndentRequestListEvent {
  const IndentRequestLocalRemoved(this.id);

  final String id;
}
