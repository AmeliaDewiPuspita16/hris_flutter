import '../../../domain/it_request_detail.dart';
import '../../../domain/it_request_item.dart';

/// Hal-hal yang bisa terjadi pada riwayat IT/Media Request.
sealed class ItRequestListEvent {
  const ItRequestListEvent();
}

/// Layar baru dibuka — muat halaman pertama.
class ItRequestListStarted extends ItRequestListEvent {
  const ItRequestListStarted();
}

/// Tarik-untuk-muat-ulang. Kembali ke halaman pertama.
class ItRequestListRefreshed extends ItRequestListEvent {
  const ItRequestListRefreshed();
}

/// Daftar tergulir mendekati ujung — muat halaman berikutnya.
class ItRequestListNextPageRequested extends ItRequestListEvent {
  const ItRequestListNextPageRequested();
}

/// Request baru berhasil disusun lewat "+ Add Request" dan disisipkan ke
/// puncak daftar.
///
/// Local-only: belum ada endpoint submit untuk IT Request, jadi item ini
/// TIDAK benar-benar tersimpan di server — sama seperti perilaku fitur ini
/// sebelum tersambung ke API (lihat `AddItRequestScreen`).
class ItRequestLocalItemAdded extends ItRequestListEvent {
  const ItRequestLocalItemAdded(this.item);

  final ItRequestItem item;
}

/// User berhasil mengirim rating lewat bottom sheet feedback —
/// [ItRequestFeedbackSheet] sudah memanggil `ItRequestRepository.submitRating`
/// sendiri (pola sama dengan `AddItRequestScreen`/[ItRequestLocalItemAdded]),
/// jadi [detail] di sini adalah rincian TERBARU dari server, bukan tebakan
/// lokal. Item yang cocok di daftar diganti dengan [detail], dan
/// `summary.awaitingRating` dikurangi satu supaya tombol "+ Add Request"
/// langsung terbuka lagi begitu tidak ada lagi yang menunggu rating.
class ItRequestFeedbackGiven extends ItRequestListEvent {
  const ItRequestFeedbackGiven(this.detail);

  final ItRequestDetail detail;
}
