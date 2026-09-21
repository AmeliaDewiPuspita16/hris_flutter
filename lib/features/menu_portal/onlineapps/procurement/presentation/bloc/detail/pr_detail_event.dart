/// Hal-hal yang bisa terjadi pada layar detail PR.
sealed class PrDetailEvent {
  const PrDetailEvent();
}

/// Minta rincian PR ber-id [id]. Dipakai juga oleh tombol "Coba lagi".
class PrDetailRequested extends PrDetailEvent {
  const PrDetailRequested(this.id);

  final int id;
}
