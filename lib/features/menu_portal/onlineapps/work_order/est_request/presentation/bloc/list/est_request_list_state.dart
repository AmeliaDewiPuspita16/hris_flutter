import '../../../../../../../../core/network/page_meta.dart';
import '../../../domain/est_request_item.dart';

enum EstRequestListStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [EstRequestListState.copyWith], supaya
/// `errorMessage: null` bisa berarti "hapus pesan galat" alih-alih
/// "biarkan".
const _unset = Object();

/// Keadaan daftar "All Request" EST.
class EstRequestListState {
  const EstRequestListState({
    this.status = EstRequestListStatus.initial,
    this.items = const [],
    this.meta = const PageMeta(currentPage: 1, lastPage: 1, perPage: 20, total: 0),
    this.awaitingVerification = 0,
    this.loadingMore = false,
    this.errorMessage,
  });

  final EstRequestListStatus status;

  /// Semua request yang sudah dimuat, dari halaman 1 sampai halaman
  /// terakhir yang sudah diminta.
  final List<EstRequestItem> items;

  /// Paginasi halaman terakhir yang dimuat; [PageMeta.hasMore] menentukan
  /// perlu tidaknya meminta halaman berikutnya.
  final PageMeta meta;

  /// Jumlah request milik user yang selesai dikerjakan tapi belum
  /// diverifikasi (`summary.awaiting_verification`). Belum dipakai UI;
  /// disiapkan untuk langkah rating.
  final int awaitingVerification;

  /// Sedang memuat halaman berikutnya (skeleton kecil di dasar daftar).
  final bool loadingMore;

  /// Pesan galat dari server, sudah siap ditampilkan.
  final String? errorMessage;

  /// Muat pertama kali: belum ada yang bisa ditampilkan, jadi layar
  /// menampilkan skeleton penuh. Saat refresh, daftar lama tetap tampil.
  ///
  /// [EstRequestListStatus.initial] ikut dihitung: itu keadaan di antara
  /// layar dibangun dan event `Started` diproses, dan tanpa ini layar
  /// sempat berkedip "No data".
  bool get isFirstLoad =>
      (status == EstRequestListStatus.initial ||
          status == EstRequestListStatus.loading) &&
      items.isEmpty;

  EstRequestListState copyWith({
    EstRequestListStatus? status,
    List<EstRequestItem>? items,
    PageMeta? meta,
    int? awaitingVerification,
    bool? loadingMore,
    Object? errorMessage = _unset,
  }) {
    return EstRequestListState(
      status: status ?? this.status,
      items: items ?? this.items,
      meta: meta ?? this.meta,
      awaitingVerification: awaitingVerification ?? this.awaitingVerification,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstRequestListState &&
          other.status == status &&
          identical(other.items, items) &&
          identical(other.meta, meta) &&
          other.awaitingVerification == awaitingVerification &&
          other.loadingMore == loadingMore &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        items,
        meta,
        awaitingVerification,
        loadingMore,
        errorMessage,
      );

  @override
  String toString() => 'EstRequestListState(${status.name}, '
      '${items.length}/${meta.total} request, hal ${meta.currentPage}/'
      '${meta.lastPage}, loadingMore: $loadingMore, error: $errorMessage)';
}
