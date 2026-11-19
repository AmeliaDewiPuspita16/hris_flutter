import '../../../../../../../core/network/page_meta.dart';
import '../../../domain/item_request_entry.dart';

enum ItemRequestVerificationStatus { initial, loading, success, failure }

const _unset = Object();

/// Pesan sekali-tampil (snackbar) setelah sebuah keputusan. Sengaja tanpa
/// `==`: layar menampilkan snackbar hanya bila objeknya berganti (pola sama
/// dengan `EstApprovalNotice`).
class ItemRequestVerificationNotice {
  const ItemRequestVerificationNotice({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;
}

/// Keadaan tab "Verification".
class ItemRequestVerificationState {
  const ItemRequestVerificationState({
    this.status = ItemRequestVerificationStatus.initial,
    this.items = const [],
    this.pending = 0,
    this.meta = const PageMeta(
      currentPage: 1,
      lastPage: 1,
      perPage: 20,
      total: 0,
    ),
    this.loadingMore = false,
    this.busyIds = const {},
    this.errorMessage,
    this.notice,
    this.denied = false,
    this.resolved = false,
  });

  final ItemRequestVerificationStatus status;

  /// LINE yang masih menunggu keputusan, dari halaman 1 sampai halaman
  /// terakhir yang sudah diminta.
  final List<ItemRequestEntry> items;

  /// Total antrean (`pending-count`), untuk badge tab. Tidak ikut menyusut
  /// saat pencarian aktif. Dikurangi satu tiap keputusan berhasil supaya
  /// tidak perlu muat ulang.
  final int pending;

  /// Paginasi halaman terakhir yang dimuat; `meta.hasMore` menentukan perlu
  /// tidaknya meminta halaman berikutnya.
  final PageMeta meta;

  /// Sedang memuat halaman berikutnya.
  final bool loadingMore;

  /// id LINE yang keputusannya sedang dikirim; kartunya dikunci supaya
  /// Approve/Reject tidak terkirim dua kali.
  final Set<int> busyIds;

  final String? errorMessage;
  final ItemRequestVerificationNotice? notice;

  /// True bila server menolak akun ini membuka antrean (401/403), artinya
  /// bukan verifier. Tab Verification disembunyikan sepenuhnya.
  final bool denied;

  /// True setelah muat pertama selesai (berhasil atau gagal). Selama belum,
  /// layar belum tahu user ini verifier atau bukan, jadi tab belum ditampilkan
  /// — mencegah tab sempat muncul lalu hilang untuk user biasa.
  final bool resolved;

  /// Tab Verification ditampilkan hanya untuk akun yang dikenali sebagai
  /// verifier.
  bool get showTab => resolved && !denied;

  /// Muat pertama kali: skeleton penuh. Saat refresh, daftar lama tetap tampil.
  bool get isFirstLoad =>
      (status == ItemRequestVerificationStatus.initial ||
          status == ItemRequestVerificationStatus.loading) &&
      items.isEmpty;

  ItemRequestVerificationState copyWith({
    ItemRequestVerificationStatus? status,
    List<ItemRequestEntry>? items,
    int? pending,
    PageMeta? meta,
    bool? loadingMore,
    Set<int>? busyIds,
    Object? errorMessage = _unset,
    ItemRequestVerificationNotice? notice,
    bool? denied,
    bool? resolved,
  }) {
    return ItemRequestVerificationState(
      status: status ?? this.status,
      items: items ?? this.items,
      pending: pending ?? this.pending,
      meta: meta ?? this.meta,
      loadingMore: loadingMore ?? this.loadingMore,
      busyIds: busyIds ?? this.busyIds,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      notice: notice ?? this.notice,
      denied: denied ?? this.denied,
      resolved: resolved ?? this.resolved,
    );
  }
}
