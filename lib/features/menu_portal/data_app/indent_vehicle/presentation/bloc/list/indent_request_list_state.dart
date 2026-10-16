import '../../../domain/indent_request_item.dart';

enum IndentRequestListStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [IndentRequestListState.copyWith], supaya
/// `errorMessage: null` bisa berarti "hapus pesan galat" alih-alih
/// "biarkan" — pola sama dengan `ItRequestListState`.
const _unset = Object();

/// Keadaan tab "List of User Requests".
class IndentRequestListState {
  const IndentRequestListState({
    this.status = IndentRequestListStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final IndentRequestListStatus status;
  final List<IndentRequestItem> items;

  /// Pesan galat dari server, sudah siap ditampilkan.
  final String? errorMessage;

  /// Muat pertama kali: belum ada yang bisa ditampilkan, jadi layar
  /// menampilkan spinner penuh. Saat refresh, daftar lama tetap tampil.
  bool get isFirstLoad =>
      status == IndentRequestListStatus.loading && items.isEmpty;

  IndentRequestListState copyWith({
    IndentRequestListStatus? status,
    List<IndentRequestItem>? items,
    Object? errorMessage = _unset,
  }) {
    return IndentRequestListState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndentRequestListState &&
          other.status == status &&
          identical(other.items, items) &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, items, errorMessage);

  @override
  String toString() => 'IndentRequestListState(${status.name}, '
      '${items.length} request, error: $errorMessage)';
}
