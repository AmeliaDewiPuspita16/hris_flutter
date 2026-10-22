import '../../../domain/pr_action.dart';

/// Hal-hal yang bisa terjadi pada layar detail PR.
sealed class PrDetailEvent {
  const PrDetailEvent();
}

/// Minta rincian PR ber-id [id]. Dipakai juga oleh tombol "Coba lagi".
class PrDetailRequested extends PrDetailEvent {
  const PrDetailRequested(this.id);

  final int id;
}

/// Atasan mengambil keputusan atas PR yang sedang dibuka.
///
/// [comments] bolehkosong hanya untuk [PrAction.approve]. Untuk revisi dan
/// penolakan, bloc menolak komentar kosong sebelum menyentuh server.
class PrActionSubmitted extends PrDetailEvent {
  const PrActionSubmitted(this.action, {this.comments});

  final PrAction action;
  final String? comments;
}
