import '../../../../../../../../core/network/page_meta.dart';
import '../../../domain/it_request_item.dart';
import '../../../domain/it_request_summary.dart';

enum ItRequestListStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [ItRequestListState.copyWith], supaya
/// `errorMessage: null` bisa berarti "hapus pesan galat" alih-alih
/// "biarkan" — pola sama dengan `ProcurementListState`.
const _unset = Object();

/// Keadaan riwayat IT/Media Request.
class ItRequestListState {
  const ItRequestListState({
    this.status = ItRequestListStatus.initial,
    this.items = const [],
    this.summary = const ItRequestSummary(awaitingRating: 0),
    this.meta = const PageMeta(currentPage: 1, lastPage: 1, perPage: 20, total: 0),
    this.loadingMore = false,
    this.errorMessage,
  });

  final ItRequestListStatus status;
  final List<ItRequestItem> items;

  /// `summary.awaitingRating` dari server — satu-satunya sumber kebenaran
  /// untuk [canAddRequest], dihitung atas SELURUH request user, bukan cuma
  /// yang termuat di [items].
  final ItRequestSummary summary;

  final PageMeta meta;

  /// True saat halaman berikutnya sedang diambil, supaya daftar yang sudah
  /// tampil tidak diganti spinner sepenuh layar.
  final bool loadingMore;

  final String? errorMessage;

  /// Tombol "+ Add Request" hanya boleh terbuka kalau server bilang tidak
  /// ada request yang menunggu rating — bukan hasil tebakan klien dari
  /// status/rating item yang kebetulan sedang termuat.
  bool get canAddRequest => summary.awaitingRating == 0;

  bool get isEmpty => status == ItRequestListStatus.success && items.isEmpty;

  bool get isFirstLoad => status == ItRequestListStatus.loading && items.isEmpty;

  ItRequestListState copyWith({
    ItRequestListStatus? status,
    List<ItRequestItem>? items,
    ItRequestSummary? summary,
    PageMeta? meta,
    bool? loadingMore,
    Object? errorMessage = _unset,
  }) {
    return ItRequestListState(
      status: status ?? this.status,
      items: items ?? this.items,
      summary: summary ?? this.summary,
      meta: meta ?? this.meta,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItRequestListState &&
          other.status == status &&
          identical(other.items, items) &&
          identical(other.summary, summary) &&
          identical(other.meta, meta) &&
          other.loadingMore == loadingMore &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode =>
      Object.hash(status, items, summary, meta, loadingMore, errorMessage);

  @override
  String toString() => 'ItRequestListState(${status.name}, '
      '${items.length} request, awaitingRating: ${summary.awaitingRating}, '
      'error: $errorMessage)';
}
