import '../../../domain/indent_my_request_item.dart';

enum IndentMyRequestStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [IndentMyRequestState.copyWith], supaya
/// `errorMessage: null` berarti "hapus pesan galat".
const _unset = Object();

/// Keadaan tab "My Request".
class IndentMyRequestState {
  const IndentMyRequestState({
    this.status = IndentMyRequestStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final IndentMyRequestStatus status;

  /// Request milik sendiri, urutan dari server (terbaru di atas).
  final List<IndentMyRequestItem> items;

  /// Pesan galat dari server, sudah siap ditampilkan.
  final String? errorMessage;

  /// Muat pertama kali: layar menampilkan spinner penuh. Saat refresh,
  /// daftar lama tetap tampil.
  bool get isFirstLoad =>
      status == IndentMyRequestStatus.loading && items.isEmpty;

  IndentMyRequestState copyWith({
    IndentMyRequestStatus? status,
    List<IndentMyRequestItem>? items,
    Object? errorMessage = _unset,
  }) {
    return IndentMyRequestState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndentMyRequestState &&
          other.status == status &&
          identical(other.items, items) &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, items, errorMessage);

  @override
  String toString() => 'IndentMyRequestState(${status.name}, '
      '${items.length} request, error: $errorMessage)';
}
