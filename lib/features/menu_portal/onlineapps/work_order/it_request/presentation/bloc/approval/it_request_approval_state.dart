import '../../../domain/approve_request_item.dart';

enum ItRequestApprovalStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [ItRequestApprovalState.copyWith], supaya
/// `errorMessage: null` bisa berarti "hapus pesan galat".
const _unset = Object();

/// Pesan sekali-tampil (snackbar) setelah sebuah keputusan.
///
/// Sengaja tidak punya `==` — pola sama dengan `IndentApprovalNotice`:
/// layar menampilkan snackbar hanya bila objeknya berganti.
class ItRequestApprovalNotice {
  const ItRequestApprovalNotice({required this.message, required this.isError});

  final String message;
  final bool isError;
}

/// Keadaan tab "Approve Request".
class ItRequestApprovalState {
  const ItRequestApprovalState({
    this.status = ItRequestApprovalStatus.initial,
    this.items = const [],
    this.pending = 0,
    this.busyIds = const {},
    this.errorMessage,
    this.notice,
  });

  final ItRequestApprovalStatus status;

  /// Request yang masih menunggu keputusan.
  final List<ApproveRequestItem> items;

  /// Total antrean dari `summary.pending`, untuk badge tab. Dikurangi satu
  /// tiap keputusan berhasil supaya tidak perlu muat ulang.
  final int pending;

  /// id request yang keputusannya sedang dikirim. Kartunya dikunci selama
  /// itu supaya Approve/Reject tidak terkirim dua kali.
  final Set<int> busyIds;

  /// Pesan galat saat memuat daftar (bukan galat keputusan; itu [notice]).
  final String? errorMessage;

  final ItRequestApprovalNotice? notice;

  /// Muat pertama kali: spinner penuh. Saat refresh, daftar lama tetap tampil.
  bool get isFirstLoad =>
      status == ItRequestApprovalStatus.loading && items.isEmpty;

  ItRequestApprovalState copyWith({
    ItRequestApprovalStatus? status,
    List<ApproveRequestItem>? items,
    int? pending,
    Set<int>? busyIds,
    Object? errorMessage = _unset,
    ItRequestApprovalNotice? notice,
  }) {
    return ItRequestApprovalState(
      status: status ?? this.status,
      items: items ?? this.items,
      pending: pending ?? this.pending,
      busyIds: busyIds ?? this.busyIds,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      notice: notice ?? this.notice,
    );
  }
}
