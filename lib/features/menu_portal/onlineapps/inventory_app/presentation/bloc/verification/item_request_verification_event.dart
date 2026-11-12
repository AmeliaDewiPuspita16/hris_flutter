import '../../../domain/item_request_entry.dart';

/// Hal-hal yang bisa terjadi pada tab "Verification".
sealed class ItemRequestVerificationEvent {
  const ItemRequestVerificationEvent();
}

/// Layar baru dibuka — muat antrean verifikasi.
class ItemRequestVerificationStarted extends ItemRequestVerificationEvent {
  const ItemRequestVerificationStarted();
}

/// Tarik-untuk-muat-ulang, atau tombol "Retry" saat gagal, atau setelah ada
/// perubahan di server.
class ItemRequestVerificationRefreshed extends ItemRequestVerificationEvent {
  const ItemRequestVerificationRefreshed();
}

/// Pengguna mengulir sampai dekat dasar daftar - muat halaman berikutnya.
class ItemRequestVerificationNextPageRequested
    extends ItemRequestVerificationEvent {
  const ItemRequestVerificationNextPageRequested();
}

/// Kata kunci pencarian berubah - muat ulang dari halaman 1. Penyaringan
/// dilakukan server, jadi hasilnya encakup seluiruh antrean, bukan hanya
/// halaman yang sedang dimuat.
class ItemRequestVerificationSearchChanged
    extends ItemRequestVerificationEvent {
  const ItemRequestVerificationSearchChanged(this.search);

  final String search;
}

/// Verifier menekan Approve ([approved] true) atau Reject (false) pada
/// [item] (satu LINE).
class ItemRequestVerificationDecided extends ItemRequestVerificationEvent {
  const ItemRequestVerificationDecided({
    required this.item,
    required this.approved,
  });

  final ItemRequestEntry item;
  final bool approved;
}
