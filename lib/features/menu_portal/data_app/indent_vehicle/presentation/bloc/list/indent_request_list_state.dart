import '../../../../../../../core/network/page_meta.dart';
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
    this.meta = const PageMeta(currentPage: 1, lastPage: 1, perPage: 15, total: 0),
    this.loadingMore = false,
    this.errorMessage,
  });

  final IndentRequestListStatus status;

  /// Semua request yang sudah dimuat, dari halaman 1 sampai halaman
  /// terakhir yang sudah diminta.
  final List<IndentRequestItem> items;

  /// Paginasi halaman terakhir yang dimuat; [PageMeta.hasMore] menentukan
  /// perlu tidaknya meminta halaman berikutnya.
  final PageMeta meta;

  /// Sedang memuat halaman berikutnya (spinner kecil di dasar daftar).
  final bool loadingMore;

  /// Pesan galat dari server, sudah siap ditampilkan.
  final String? errorMessage;

  /// Muat pertama kali: belum ada yang bisa ditampilkan, jadi layar
  /// menampilkan spinner penuh. Saat refresh, daftar lama tetap tampil.
  bool get isFirstLoad =>
      status == IndentRequestListStatus.loading && items.isEmpty;

  IndentRequestListState copyWith({
    IndentRequestListStatus? status,
    List<IndentRequestItem>? items,
    PageMeta? meta,
    bool? loadingMore,
    Object? errorMessage = _unset,
  }) {
    return IndentRequestListState(
      status: status ?? this.status,
      items: items ?? this.items,
      meta: meta ?? this.meta,
      loadingMore: loadingMore ?? this.loadingMore,
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
          identical(other.meta, meta) &&
          other.loadingMore == loadingMore &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode =>
      Object.hash(status, items, meta, loadingMore, errorMessage);

  @override
  String toString() => 'IndentRequestListState(${status.name}, '
      '${items.length}/${meta.total} request, hal ${meta.currentPage}/'
      '${meta.lastPage}, loadingMore: $loadingMore, error: $errorMessage)';
}
