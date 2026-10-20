import '../../../domain/it_request_detail.dart';

/// Hal-hal yang bisa terjadi pada layar detail request.
sealed class ItRequestDetailEvent {
  const ItRequestDetailEvent();
}

/// Minta rincian request ber-id [id]. Dipakai juga oleh tombol "Coba lagi".
class ItRequestDetailRequested extends ItRequestDetailEvent {
  const ItRequestDetailRequested(this.id);

  final int id;
}

/// Tim IT berhasil respond/complete request ini lewat
/// [ItRequestRespondSheet]/[ItRequestCompleteSheet] — kedua sheet itu sudah
/// memanggil `ItRequestRepository.respond`/`complete` sendiri (pola sama
/// dengan [ItRequestFeedbackSheet]/`submitRating`), jadi [detail] di sini
/// rincian TERBARU dari server. Layar detail cukup menggambarnya ulang,
/// tanpa fetch ulang.
class ItRequestDetailUpdated extends ItRequestDetailEvent {
  const ItRequestDetailUpdated(this.detail);

  final ItRequestDetail detail;
}
