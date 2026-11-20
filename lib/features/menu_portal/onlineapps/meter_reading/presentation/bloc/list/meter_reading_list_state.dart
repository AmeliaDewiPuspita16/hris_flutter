import '../../../../../../../core/network/page_meta.dart';
import '../../../domain/meter_period.dart';
import '../../../domain/meter_reading_page.dart';
import '../../../domain/meter_reading_summary.dart';

enum MeterReadingListStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [MeterReadingListState.copyWith], supaya
/// `typeCode: null` bisa berarti "lepas filternya" alih-alih "biarkan".
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
    this.activePeriod,
    this.canWrite = false,
    this.categories = const [],
    this.typeCode,
    this.category,
    this.stateCode,
    this.query = '',
    this.loadingMore = false,
    this.errorMessage,
    this.loadMoreError,
  });

  final MeterReadingListStatus status;
  final List<MeterReadingSummary> items;

  /// Jumlah meter per status pencatatan untuk chip filter dan progress bar,
  /// dari `summary` server.
  final MeterReadingCounts counts;

  final PageMeta meta;

  /// Periode aktif. Null = tidak ada periode aktif, jadi tidak ada yang bisa
  /// dicatat.
  final MeterPeriod? activePeriod;

  /// Hak tulis user; false = tampilan hanya-baca.
  final bool canWrite;

  /// Pilihan untuk filter kategori, dari `categories` di respons list.
  /// Kosong selagi belum termuat, atau bila server tidak mengirimnya —
  /// tombol kategori disembunyikan, daftarnya tetap jalan.
  final List<String> categories;

  /// Filter jenis meter yang aktif (`kwh`/`m3`). Null berarti semua jenis.
  final String? typeCode;

  /// Filter kategori yang aktif, ex: "Dormitory". Null berarti semua
  /// kategori.
  final String? category;

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

  /// True bila ada jenis, kategori, status, atau kata kunci yang sedang
  /// menyaring.
  bool get hasActiveFilter =>
      typeCode != null ||
      category != null ||
      stateCode != null ||
      query.trim().isNotEmpty;

  MeterReadingListState copyWith({
    MeterReadingListStatus? status,
    List<MeterReadingSummary>? items,
    MeterReadingCounts? counts,
    PageMeta? meta,
    Object? activePeriod = _unset,
    bool? canWrite,
    List<String>? categories,
    Object? typeCode = _unset,
    Object? category = _unset,
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
      activePeriod: activePeriod == _unset
          ? this.activePeriod
          : activePeriod as MeterPeriod?,
      canWrite: canWrite ?? this.canWrite,
      categories: categories ?? this.categories,
      typeCode: typeCode == _unset ? this.typeCode : typeCode as String?,
      category: category == _unset ? this.category : category as String?,
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
          identical(other.activePeriod, activePeriod) &&
          other.canWrite == canWrite &&
          identical(other.categories, categories) &&
          other.typeCode == typeCode &&
          other.category == category &&
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
        activePeriod,
        canWrite,
        categories,
        typeCode,
        category,
        stateCode,
        query,
        loadingMore,
        errorMessage,
        loadMoreError,
      );

  @override
  String toString() => 'MeterReadingListState(${status.name}, '
      '${items.length} meter, type: $typeCode, category: $category, state: $stateCode, '
      'error: $errorMessage)';
}
