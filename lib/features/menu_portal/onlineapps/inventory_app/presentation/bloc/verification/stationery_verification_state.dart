import '../../../domain/stationery_request_item.dart';

enum StationeryVerificationStatus { initial, loading, success, failure }

const _unset = Object();

/// Pesan sekali-tampil (snackbar) setelah sebuah keputusan. Sengaja tanpa
/// `==`: layar menampilkan snackbar hanya bila objeknya berganti (pola sama
/// dengan `EstApprovalNotice`).
class StationeryVerificationNotice {
  const StationeryVerificationNotice({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;
}

/// Keadaan tab "Verification".
class StationeryVerificationState {
  const StationeryVerificationState({
    this.status = StationeryVerificationStatus.initial,
    this.items = const [],
    this.pending = 0,
    this.busyIds = const {},
    this.errorMessage,
    this.notice,
    this.denied = false,
    this.resolved = false,
  });

  final StationeryVerificationStatus status;

  /// Request yang masih menunggu keputusan.
  final List<StationeryRequestItem> items;

  /// Total antrean dari `summary.pending`, untuk badge tab. Dikurangi satu
  /// tiap keputusan berhasil supaya tidak perlu muat ulang.
  final int pending;

  /// id request yang keputusannya sedang dikirim; kartunya dikunci supaya
  /// Approve/Reject tidak terkirim dua kali.
  final Set<int> busyIds;

  final String? errorMessage;
  final StationeryVerificationNotice? notice;

  /// True bila server menolak akun ini membuka antrean (401/403), artinya
  /// bukan verifier. Tab Verification disembunyikan sepenuhnya.
  final bool denied;

  /// True setelah muat pertama selesai (berhasil atau gagal). Selama belum,
  /// layar belum tahu user ini verifier atau bukan, jadi tab belum ditampilkan
  /// — mencegah tab sempat muncul lalu hilang untuk user biasa.
  final bool resolved;

  /// Tab Verification ditampilkan hanya untuk akun yang dikenali sebagai
  /// verifier.
  bool get showTab => resolved && !denied;

  /// Muat pertama kali: skeleton penuh. Saat refresh, daftar lama tetap tampil.
  bool get isFirstLoad =>
      (status == StationeryVerificationStatus.initial ||
          status == StationeryVerificationStatus.loading) &&
      items.isEmpty;

  StationeryVerificationState copyWith({
    StationeryVerificationStatus? status,
    List<StationeryRequestItem>? items,
    int? pending,
    Set<int>? busyIds,
    Object? errorMessage = _unset,
    StationeryVerificationNotice? notice,
    bool? denied,
    bool? resolved,
  }) {
    return StationeryVerificationState(
      status: status ?? this.status,
      items: items ?? this.items,
      pending: pending ?? this.pending,
      busyIds: busyIds ?? this.busyIds,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      notice: notice ?? this.notice,
      denied: denied ?? this.denied,
      resolved: resolved ?? this.resolved,
    );
  }
}
