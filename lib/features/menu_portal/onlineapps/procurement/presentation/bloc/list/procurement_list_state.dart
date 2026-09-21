import '../../../domain/purchase_requisition_page.dart';
import '../../../domain/purchase_requisition_summary.dart';

enum ProcurementListStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [ProcurementListState.copyWith], supaya
/// `statusCode: null` bisa berarti "lepas filternya" alih-alih "biarkan".
const _unset = Object();

/// Keadaan daftar Procurement Monitoring.
class ProcurementListState {
  const ProcurementListState({
    this.status = ProcurementListStatus.initial,
    this.items = const [],
    this.summary = const PrStatusCounts(all: 0, byCode: {}),
    this.meta = const PageMeta(
      currentPage: 1,
      lastPage: 1,
      perPage: 20,
      total: 0,
    ),
    this.statusCode,
    this.query = '',
    this.loadingMore = false,
    this.errorMessage,
  });

  final ProcurementListStatus status;
  final List<PurchaseRequisitionSummary> items;

  /// Jumlah PR per status untuk chip filter. Dihitung server atas seluruh
  /// data yang cocok, bukan hanya halaman yang sudah termuat.
  final PrStatusCounts summary;

  final PageMeta meta;

  /// Filter status yang aktif. Null berarti "Semua".
  final String? statusCode;

  final String query;

  /// True saat halaman berikutnya sedang diambil, supaya daftar yang sudah
  /// tampil tidak diganti spinner sepenuh layar.
  final bool loadingMore;

  final String? errorMessage;

  /// True saat memang tidak ada PR yang cocok — bukan saat masih memuat.
  bool get isEmpty =>
      status == ProcurementListStatus.success && items.isEmpty;

  /// Spinner sepenuh layar hanya pantas saat belum ada apa pun yang tampil.
  bool get isFirstLoad =>
      status == ProcurementListStatus.loading && items.isEmpty;

  ProcurementListState copyWith({
    ProcurementListStatus? status,
    List<PurchaseRequisitionSummary>? items,
    PrStatusCounts? summary,
    PageMeta? meta,
    Object? statusCode = _unset,
    String? query,
    bool? loadingMore,
    Object? errorMessage = _unset,
  }) {
    return ProcurementListState(
      status: status ?? this.status,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      meta: meta ?? this.meta,
      statusCode:
          statusCode == _unset ? this.statusCode : statusCode as String?,
      query: query ?? this.query,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProcurementListState &&
          other.status == status &&
          identical(other.items, items) &&
          identical(other.summary, summary) &&
          identical(other.meta, meta) &&
          other.statusCode == statusCode &&
          other.query == query &&
          other.loadingMore == loadingMore &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        items,
        summary,
        meta,
        statusCode,
        query,
        loadingMore,
        errorMessage,
      );

  @override
  String toString() => 'ProcurementListState(${status.name}, '
      '${items.length} PR, status: $statusCode, error: $errorMessage)';
}
