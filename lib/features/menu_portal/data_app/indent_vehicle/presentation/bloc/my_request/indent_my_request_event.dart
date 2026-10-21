/// Hal-hal yang bisa terjadi pada tab "My Request".
sealed class IndentMyRequestEvent {
  const IndentMyRequestEvent();
}

/// Layar baru dibuka — muat request milik sendiri.
class IndentMyRequestStarted extends IndentMyRequestEvent {
  const IndentMyRequestStarted();
}

/// Tarik-untuk-muat-ulang, tombol "Coba lagi", atau pemicu dari tab lain
/// (tambah/edit/hapus request, approve, assign).
class IndentMyRequestRefreshed extends IndentMyRequestEvent {
  const IndentMyRequestRefreshed();
}
