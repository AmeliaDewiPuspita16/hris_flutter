import '../../../domain/indent_pending_item.dart';

enum IndentPendingStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [IndentPendingState.copyWith], supaya
/// `errorMessage: null` bisa berarti "hapus pesan galat".
const _unset = Object();

/// Pesan sekali-tampil untuk pengguna (snackbar) setelah sebuah assign.
///
/// Sengaja tidak punya `==`: setiap hasil menghasilkan objek baru, dan
/// layar menampilkan snackbar hanya bila objeknya berganti.
class IndentPendingNotice {
  const IndentPendingNotice({required this.message, required this.isError});

  final String message;
  final bool isError;
}

/// Keadaan tab "Pending Vehicle Assignment".
class IndentPendingState {
  const IndentPendingState({
    this.status = IndentPendingStatus.initial,
    this.items = const [],
    this.busyIds = const {},
    this.errorMessage,
    this.notice,
  });

  final IndentPendingStatus status;

  /// Request yang masih menunggu kendaraan.
  final List<IndentPendingItem> items;

  /// id request yang penugasannya sedang dikirim ke server. Kartunya dikunci
  /// selama itu supaya Assign tidak terkirim dua kali.
  final Set<String> busyIds;

  /// Pesan galat saat memuat daftar (galat assign ada di [notice]).
  final String? errorMessage;

  /// Hasil assign terakhir untuk ditampilkan sebagai snackbar.
  final IndentPendingNotice? notice;

  /// Muat pertama kali: belum ada yang bisa ditampilkan, jadi layar
  /// menampilkan spinner penuh. Saat refresh, daftar lama tetap tampil.
  bool get isFirstLoad =>
      status == IndentPendingStatus.loading && items.isEmpty;

  IndentPendingState copyWith({
    IndentPendingStatus? status,
    List<IndentPendingItem>? items,
    Set<String>? busyIds,
    Object? errorMessage = _unset,
    IndentPendingNotice? notice,
  }) {
    return IndentPendingState(
      status: status ?? this.status,
      items: items ?? this.items,
      busyIds: busyIds ?? this.busyIds,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      notice: notice ?? this.notice,
    );
  }
}
