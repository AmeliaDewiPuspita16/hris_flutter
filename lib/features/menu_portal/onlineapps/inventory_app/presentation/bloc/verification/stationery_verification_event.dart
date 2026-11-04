import '../../../domain/stationery_request_item.dart';

/// Hal-hal yang bisa terjadi pada tab "Verification".
sealed class StationeryVerificationEvent {
  const StationeryVerificationEvent();
}

/// Layar baru dibuka — muat antrean verifikasi.
class StationeryVerificationStarted extends StationeryVerificationEvent {
  const StationeryVerificationStarted();
}

/// Tarik-untuk-muat-ulang, atau tombol "Retry" saat gagal.
class StationeryVerificationRefreshed extends StationeryVerificationEvent {
  const StationeryVerificationRefreshed();
}

/// Verifier menekan Approve ([approved] true) atau Reject (false) pada
/// [item]. [reason] hanya dipakai saat reject, dan boleh kosong.
class StationeryVerificationDecided extends StationeryVerificationEvent {
  const StationeryVerificationDecided({
    required this.item,
    required this.approved,
    this.reason,
  });

  final StationeryRequestItem item;
  final bool approved;
  final String? reason;
}
