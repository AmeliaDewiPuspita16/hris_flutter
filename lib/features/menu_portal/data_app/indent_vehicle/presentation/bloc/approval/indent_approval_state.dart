import '../../../domain/indent_approval_item.dart';

enum IndentApprovalStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [IndentApprovalState.copyWith], supaya
/// `errorMessage: null` bisa berarti "hapus pesan galat".
const _unset = Object();

/// Pesan sekali-tampil untuk pengguna (snackbar) setelah sebuah keputusan.
///
/// Sengaja tidak punya `==`: setiap hasil keputusan menghasilkan objek baru,
/// dan layar menampilkan snackbar hanya bila objeknya berganti — jadi
/// emisi state lain (mis. daftar yang berubah) tidak memunculkannya lagi.
class IndentApprovalNotice {
  const IndentApprovalNotice({required this.message, required this.isError});

  final String message;
  final bool isError;
}

/// Keadaan tab "Supervisor Approval".
class IndentApprovalState {
  const IndentApprovalState({
    this.status = IndentApprovalStatus.initial,
    this.items = const [],
    this.busyIds = const {},
    this.errorMessage,
    this.notice,
  });

  final IndentApprovalStatus status;

  /// Request yang masih menunggu keputusan.
  final List<IndentApprovalItem> items;

  /// id request yang keputusannya sedang dikirim ke server. Kartunya
  /// dikunci selama itu supaya Approve/Reject tidak terkirim dua kali.
  final Set<String> busyIds;

  /// Pesan galat saat memuat daftar (bukan galat keputusan; itu [notice]).
  final String? errorMessage;

  /// Hasil keputusan terakhir untuk ditampilkan sebagai snackbar.
  final IndentApprovalNotice? notice;

  /// Muat pertama kali: belum ada yang bisa ditampilkan, jadi layar
  /// menampilkan spinner penuh. Saat refresh, daftar lama tetap tampil.
  bool get isFirstLoad =>
      status == IndentApprovalStatus.loading && items.isEmpty;

  IndentApprovalState copyWith({
    IndentApprovalStatus? status,
    List<IndentApprovalItem>? items,
    Set<String>? busyIds,
    Object? errorMessage = _unset,
    IndentApprovalNotice? notice,
  }) {
    return IndentApprovalState(
      status: status ?? this.status,
      items: items ?? this.items,
      busyIds: busyIds ?? this.busyIds,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      notice: notice ?? this.notice,
    );
  }
}
