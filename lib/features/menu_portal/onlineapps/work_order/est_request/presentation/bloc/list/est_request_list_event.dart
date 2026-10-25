/// Hal-hal yang bisa terjadi pada daftar "All Request" EST.
sealed class EstRequestListEvent {
  const EstRequestListEvent();
}

/// Layar baru dibuka — muat daftar dari server.
class EstRequestListStarted extends EstRequestListEvent {
  const EstRequestListStarted();
}

/// Tarik-untuk-muat-ulang, tombol "Coba lagi" saat gagal, atau setelah
/// ada perubahan di server (request baru, hapus, rating).
class EstRequestListRefreshed extends EstRequestListEvent {
  const EstRequestListRefreshed();
}

/// Pengguna menggulir sampai dekat dasar daftar — muat halaman berikutnya.
/// Diabaikan Bloc kalau sedang memuat atau sudah halaman terakhir, jadi
/// layar boleh mengirimnya berulang tanpa khawatir.
class EstRequestListNextPageRequested extends EstRequestListEvent {
  const EstRequestListNextPageRequested();
}
