/// Hal-hal yang bisa terjadi pada layar detail EST.
sealed class EstRequestDetailEvent {
  const EstRequestDetailEvent();
}

/// Layar baru dibuka — muat detail dari server.
class EstRequestDetailStarted extends EstRequestDetailEvent {
  const EstRequestDetailStarted();
}

/// Tarik-untuk-muat-ulang, atau tombol "Try again" saat gagal.
class EstRequestDetailRefreshed extends EstRequestDetailEvent {
  const EstRequestDetailRefreshed();
}
