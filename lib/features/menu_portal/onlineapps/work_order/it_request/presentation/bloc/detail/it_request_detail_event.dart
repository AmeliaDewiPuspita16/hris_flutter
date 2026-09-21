/// Hal-hal yang bisa terjadi pada layar detail request.
sealed class ItRequestDetailEvent {
  const ItRequestDetailEvent();
}

/// Minta rincian request ber-id [id]. Dipakai juga oleh tombol "Coba lagi".
class ItRequestDetailRequested extends ItRequestDetailEvent {
  const ItRequestDetailRequested(this.id);

  final int id;
}
