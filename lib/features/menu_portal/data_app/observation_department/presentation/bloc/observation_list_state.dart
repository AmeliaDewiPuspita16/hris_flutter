import '../../../../../../core/network/page_meta.dart';
import '../../domain/observation_filter.dart';
import '../../domain/observation_item.dart';
import '../../domain/observation_options.dart';
import '../../domain/observation_page.dart';

/// Penanda "tidak diisi" untuk copyWith, supaya `error: null` berarti
/// "hapus pesan galat" — pola sama dengan `IndentRequestListState`.
const _unset = Object();

/// Keadaan satu tab: baris yang sudah dimuat, posisi paginasi, dan status
/// muat. Tiap tab punya halaman dan galatnya sendiri.
class ObservationTabData {
  const ObservationTabData({
    this.items = const [],
    this.meta = const PageMeta(currentPage: 1, lastPage: 1, perPage: 20, total: 0),
    this.loading = false,
    this.loadingMore = false,
    this.error,
  });

  factory ObservationTabData.fromPage(ObservationPage page) {
    return ObservationTabData(items: page.items, meta: page.meta);
  }

  final List<ObservationItem> items;

  /// Paginasi halaman terakhir yang dimuat; `meta.total` adalah jumlah
  /// seluruh baris di server untuk pencarian/filter yang sedang berlaku.
  final PageMeta meta;

  /// Memuat halaman pertama (muat awal, refresh, atau ganti pencarian/filter).
  final bool loading;

  /// Memuat halaman berikutnya (gulir ke bawah).
  final bool loadingMore;
  final String? error;

  bool get hasMore => meta.hasMore;

  /// Belum ada yang bisa ditampilkan: layar menampilkan skeleton.
  bool get isInitialLoading => loading && items.isEmpty;

  ObservationTabData copyWith({
    List<ObservationItem>? items,
    PageMeta? meta,
    bool? loading,
    bool? loadingMore,
    Object? error = _unset,
  }) {
    return ObservationTabData(
      items: items ?? this.items,
      meta: meta ?? this.meta,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error == _unset ? this.error : error as String?,
    );
  }

  /// Menaruh [item] di paling atas bila belum ada (dipakai untuk temuan
  /// dari notifikasi yang tidak ikut di halaman yang sudah dimuat).
  ObservationTabData withPinned(ObservationItem item) => copyWith(
        items: [item, ...items.where((i) => i.id != item.id)],
      );
}

/// Keadaan layar Observation: dua tab (masing-masing berpaginasi dari
/// server), pencarian, filter, dan daftar departemen untuk filter.
class ObservationListState {
  const ObservationListState({
    this.myOpen = const ObservationTabData(loading: true),
    this.all = const ObservationTabData(loading: true),
    this.waitingCount,
    this.query = '',
    this.filter = ObservationFilter.none,
    this.departments = const [],
  });

  /// Tab "To Close" (`/requests`).
  final ObservationTabData myOpen;

  /// Tab "All Observations".
  final ObservationTabData all;

  /// Angka badge tab To Close: `meta.total` dari `/requests` TANPA
  /// pencarian, supaya tidak berubah-ubah saat mengetik di kolom search.
  final int? waitingCount;

  final String query;
  final ObservationFilter filter;

  /// Pilihan "Relevant Dept." untuk filter, dari `/options`.
  final List<ObservationDepartment> departments;

  bool get searchingMyOpen => query.trim().isNotEmpty;

  /// Pencarian berlaku di kedua tab; filter hanya di "All Observations"
  /// (sama dengan web).
  bool get searchingAll => searchingMyOpen || filter.isActive;

  ObservationListState copyWith({
    ObservationTabData? myOpen,
    ObservationTabData? all,
    int? waitingCount,
    String? query,
    ObservationFilter? filter,
    List<ObservationDepartment>? departments,
  }) {
    return ObservationListState(
      myOpen: myOpen ?? this.myOpen,
      all: all ?? this.all,
      waitingCount: waitingCount ?? this.waitingCount,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      departments: departments ?? this.departments,
    );
  }
}
