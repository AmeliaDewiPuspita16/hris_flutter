import '../../../../../../../core/network/page_meta.dart';
import '../../../domain/item_request_entry.dart';

enum ItemRequestListStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [ItemRequestListState.copyWith], supaya
/// `errorMessage: null` bisa berarti "hapus pesan galat".
const _unset = Object();

/// Keadaan daftar "Request Items".
class ItemRequestListState {
  const ItemRequestListState({
    this.status = ItemRequestListStatus.initial,
    this.items = const [],
    this.meta = const PageMeta(
      currentPage: 1,
      lastPage: 1,
      perPage: 20,
      total: 0,
    ),
    this.loadingMore = false,
    this.errorMessage,
  });

  final ItemRequestListStatus status;

  /// Semua request yang sudah dimuat, dari halaman 1 sampai halaman terakhir
  /// yang sudah diminta.
  final List<ItemRequestEntry> items;

  /// Paginasi halaman terakhir yang dimuat; `meta.hasMore` menentukan perlu
  /// tidaknya meminta halaman berikutnya.
  final PageMeta meta;

  /// Sedang memuat halaman berikutnya (skeleton kecil di dasar daftar).
  final bool loadingMore;

  final String? errorMessage;

  /// Muat pertama kali: belum ada yang bisa ditampilkan, jadi layar
  /// menampilkan skeleton penuh. [ItemRequestListStatus.initial] ikut
  /// dihitung supaya layar tidak sempat berkedip "No data".
  bool get isFirstLoad =>
      (status == ItemRequestListStatus.initial ||
          status == ItemRequestListStatus.loading) &&
      items.isEmpty;

  ItemRequestListState copyWith({
    ItemRequestListStatus? status,
    List<ItemRequestEntry>? items,
    PageMeta? meta,
    bool? loadingMore,
    Object? errorMessage = _unset,
  }) {
    return ItemRequestListState(
      status: status ?? this.status,
      items: items ?? this.items,
      meta: meta ?? this.meta,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }
}
