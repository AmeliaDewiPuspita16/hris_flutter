import '../../../domain/est_approval_item.dart';

enum EstApprovalStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [EstApprovalState.copyWith], supaya
/// `errorMessage: null` bisa berarti "hapus pesan galat".
const _unset = Object();

/// Pesan sekali-tampil (snackbar) setelah sebuah keputusan.
///
/// Sengaja tidak punya `==` — pola sama dengan `IndentApprovalNotice`:
/// layar menampilkan snackbar hanya bila objeknya berganti.
class EstApprovalNotice {
  const EstApprovalNotice({required this.message, required this.isError});

  final String message;
  final bool isError;
}

/// Keadaan tab "Approve HOD".
class EstApprovalState {
  const EstApprovalState({
    this.status = EstApprovalStatus.initial,
    this.items = const [],
    this.pending = 0,
    this.busyIds = const {},
    this.errorMessage,
    this.notice,
    this.denied = false,
  });

  final EstApprovalStatus status;

  /// Request yang masih menunggu keputusan.
  final List<EstApprovalItem> items;

  /// Total antrean dari `summary.pending`, untuk badge tab. Dikurangi satu
  /// tiap keputusan berhasil supaya tidak perlu muat ulang.
  final int pending;

  /// id request yang keputusannya sedang dikirim. Kartunya dikunci selama
  /// itu supaya Approve/Reject tidak terkirim dua kali.
  final Set<int> busyIds;

  /// Pesan galat saat memuat daftar (bukan galat keputusan; itu [notice]).
  final String? errorMessage;

  final EstApprovalNotice? notice;

  /// True bila server menolak akun ini membuka antrean (401/403), mis. bukan
  /// HOD atau tidak punya departemen. Layar memakainya untuk menyembunyikan
  /// tab "Approve HOD" sepenuhnya, bukan membiarkannya tampil kosong.
  final bool denied;

  /// Muat pertama kali: spinner penuh. Saat refresh, daftar lama tetap tampil.
  bool get isFirstLoad =>
      status == EstApprovalStatus.loading && items.isEmpty;

  EstApprovalState copyWith({
    EstApprovalStatus? status,
    List<EstApprovalItem>? items,
    int? pending,
    Set<int>? busyIds,
    Object? errorMessage = _unset,
    EstApprovalNotice? notice,
    bool? denied,
  }) {
    return EstApprovalState(
      status: status ?? this.status,
      items: items ?? this.items,
      pending: pending ?? this.pending,
      busyIds: busyIds ?? this.busyIds,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      notice: notice ?? this.notice,
      denied: denied ?? this.denied,
    );
  }
}
