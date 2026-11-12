import '../../../../../../../core/network/page_meta.dart';
import '../../../domain/stationery_request_item.dart';

enum StationeryRequestListStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [StationeryRequestListState.copyWith], supaya
/// `errorMessage: null` bisa berarti "hapus pesan galat".
const _unset = Object();

/// Keadaan daftar "Request Items" stationery.
class StationeryRequestListState {
  const StationeryRequestListState({
    this.status = StationeryRequestListStatus.initial,
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

  final StationeryRequestListStatus status;

  /// Semua request yang sudah dimuat, dari halaman 1 sampai halaman terakhir
  /// yang sudah diminta.
  final List<StationeryRequestItem> items;

  /// Paginasi halaman terakhir yang dimuat; `meta.hasMore` menentukan perlu
  /// tidaknya meminta halaman berikutnya.
  final PageMeta meta;

  /// Sedang memuat halaman berikutnya (skeleton kecil di dasar daftar).
  final bool loadingMore;

  final String? errorMessage;

  /// Muat pertama kali: belum ada yang bisa ditampilkan, jadi layar
  /// menampilkan skeleton penuh. [StationeryRequestListStatus.initial] ikut
  /// dihitung supaya layar tidak sempat berkedip "No data".
  bool get isFirstLoad =>
      (status == StationeryRequestListStatus.initial ||
          status == StationeryRequestListStatus.loading) &&
      items.isEmpty;

  StationeryRequestListState copyWith({
    StationeryRequestListStatus? status,
    List<StationeryRequestItem>? items,
    PageMeta? meta,
    bool? loadingMore,
    Object? errorMessage = _unset,
  }) {
    return StationeryRequestListState(
      status: status ?? this.status,
      items: items ?? this.items,
      meta: meta ?? this.meta,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }
}
