import '../../../domain/item_request_entry.dart';

/// Hal-hal yang bisa terjadi pada tab "Verification".
sealed class ItemRequestVerificationEvent {
  const ItemRequestVerificationEvent();
}

/// Layar baru dibuka — muat antrean verifikasi.
class ItemRequestVerificationStarted extends ItemRequestVerificationEvent {
  const ItemRequestVerificationStarted();
}

/// Tarik-untuk-muat-ulang, atau tombol "Retry" saat gagal.
class ItemRequestVerificationRefreshed extends ItemRequestVerificationEvent {
  const ItemRequestVerificationRefreshed();
}

/// Verifier menekan Approve ([approved] true) atau Reject (false) pada
/// [item]. [reason] hanya dipakai saat reject, dan boleh kosong.
class ItemRequestVerificationDecided extends ItemRequestVerificationEvent {
  const ItemRequestVerificationDecided({
    required this.item,
    required this.approved,
    this.reason,
  });

  final ItemRequestEntry item;
  final bool approved;
  final String? reason;
}
