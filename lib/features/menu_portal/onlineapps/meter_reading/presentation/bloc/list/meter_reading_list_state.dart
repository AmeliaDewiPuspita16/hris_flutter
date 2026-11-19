import '../../../../../../../core/network/page_meta.dart';
import '../../../domain/meter_category.dart';
import '../../../domain/meter_reading_page.dart';
import '../../../domain/meter_reading_summary.dart';

enum MeterReadingListStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [MeterReadingListState.copyWith], supaya
/// `categoryCode: null` bisa berarti "lepas filternya" alih-alih "biarkan".
const _unset = Object();

/// Keadaan daftar Meter Reading.
class MeterReadingListState {
  const MeterReadingListState({
    this.status = MeterReadingListStatus.initial,
    this.items = const [],
    this.counts = const MeterReadingCounts(all: 0, recorded: 0, pending: 0),
    this.meta = const PageMeta(
      currentPage: 1,
      lastPage: 1,
      perPage: 20,
      total: 0,
    ),
    this.categories = const [],
    this.categoryCode,
    this.stateCode,
    this.query = '',
    this.loadingMore = false,
    this.errorMessage,
    this.loadMoreError,
  });

  final MeterReadingListStatus status;
  final List<MeterReadingSummary> items;

  /// Jumlah meter per status pencatatan untuk chip filter. Dihitung server
  /// atas seluruh data yang cocok dengan kategori dan pencarian aktif.
  final MeterReadingCounts counts;

  final PageMeta meta;

  /// Pilihan untuk filter kategori. Kosong selagi belum termuat, atau bila
  /// gagal — filter kategori disembunyikan, daftarnya tetap jalan.
  final List<MeterCategory> categories;

  /// Filter kategori yang aktif. Null berarti "All Categories".
  final String? categoryCode;

  /// Filter status pencatatan yang aktif (`pending`/`recorded`). Null
  /// berarti "Semua".
  final String? stateCode;

  final String query;

  /// True saat halaman berikutnya sedang diambil, supaya daftar yang sudah
  /// tampil tidak diganti spinner sepenuh layar.
  final bool loadingMore;

  /// Galat saat memuat halaman PERTAMA. Hanya mengambil alih layar bila
  /// daftarnya kosong.
  final String? errorMessage;

  /// Galat saat memuat halaman BERIKUTNYA. Daftar yang sudah tampil
  /// dibiarkan; layar cukup menampilkan baris "Coba lagi" di ujung.
  final String? loadMoreError;

  /// True saat memang tidak ada meter yang cocok — bukan saat masih memuat.
  bool get isEmpty =>
      status == MeterReadingListStatus.success && items.isEmpty;

  /// Spinner/skeleton sepenuh layar hanya pantas saat belum ada apa pun
  /// yang tampil.
  bool get isFirstLoad =>
      status == MeterReadingListStatus.loading && items.isEmpty;

  /// True bila ada kategori, status, atau kata kunci yang sedang menyaring.
  bool get hasActiveFilter =>
      categoryCode != null || stateCode != null || query.trim().isNotEmpty;

  MeterReadingListState copyWith({
    MeterReadingListStatus? status,
    List<MeterReadingSummary>? items,
    MeterReadingCounts? counts,
    PageMeta? meta,
    List<MeterCategory>? categories,
    Object? categoryCode = _unset,
    Object? stateCode = _unset,
    String? query,
    bool? loadingMore,
    Object? errorMessage = _unset,
    Object? loadMoreError = _unset,
  }) {
    return MeterReadingListState(
      status: status ?? this.status,
      items: items ?? this.items,
      counts: counts ?? this.counts,
      meta: meta ?? this.meta,
      categories: categories ?? this.categories,
      categoryCode:
          categoryCode == _unset ? this.categoryCode : categoryCode as String?,
      stateCode: stateCode == _unset ? this.stateCode : stateCode as String?,
      query: query ?? this.query,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      loadMoreError: loadMoreError == _unset
          ? this.loadMoreError
          : loadMoreError as String?,
    );
  }

   @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeterReadingListState &&
          other.status == status &&
          identical(other.items, items) &&
          identical(other.counts, counts) &&
          identical(other.meta, meta) &&
          identical(other.categories, categories) &&
          other.categoryCode == categoryCode &&
          other.stateCode == stateCode &&
          other.query == query &&
          other.loadingMore == loadingMore &&
          other.errorMessage == errorMessage &&
          other.loadMoreError == loadMoreError;

  @override
  int get hashCode => Object.hash(
        status,
        items,
        counts,
        meta,
        categories,
        categoryCode,
        stateCode,
        query,
        loadingMore,
        errorMessage,
        loadMoreError,
      );

  @override
  String toString() => 'MeterReadingListState(${status.name}, '
      '${items.length} meter, category: $categoryCode, state: $stateCode, '
      'error: $errorMessage)';
}
