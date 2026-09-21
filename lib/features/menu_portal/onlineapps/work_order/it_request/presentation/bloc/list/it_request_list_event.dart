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

/// User memberi rating lewat bottom sheet feedback.
///
/// Local-only, dengan alasan sama seperti [ItRequestLocalItemAdded]: belum
/// ada endpoint submit rating. Rating disisipkan ke item yang cocok, dan
/// `summary.awaitingRating` dikurangi satu secara optimistis supaya tombol
/// "+ Add Request" langsung terbuka lagi seperti sebelum fitur ini
/// tersambung ke API — begitu endpoint submit-nya ada, event ini tinggal
/// diganti memanggil repository sungguhan tanpa mengubah bentuk state.
class ItRequestLocalFeedbackGiven extends ItRequestListEvent {
  const ItRequestLocalFeedbackGiven({required this.id, required this.rating});

  final int id;
  final int rating;
}
