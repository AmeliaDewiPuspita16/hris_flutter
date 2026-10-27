import '../../../../../../../core/network/page_meta.dart';
import '../../domain/master_document.dart';

enum MasterDocumentListStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [MasterDocumentListState.copyWith], supaya
/// `errorMessage: null` bisa berarti "hapus pesan galat" alih-alih
/// "biarkan" — pola sama dengan `ItRequestListState`.
const _unset = Object();

/// Keadaan daftar dokumen master satu tab (Manual, SOP, dst).
class MasterDocumentListState {
  const MasterDocumentListState({
    this.status = MasterDocumentListStatus.initial,
    this.documents = const [],
    this.meta = const PageMeta(currentPage: 1, lastPage: 1, perPage: 50, total: 0),
    this.search = '',
    this.loadingMore = false,
    this.errorMessage,
  });

  final MasterDocumentListStatus status;
  final List<MasterDocument> documents;
  final PageMeta meta;

  /// Kata kunci yang dipakai untuk [documents] saat ini.
  final String search;

  /// True saat halaman berikutnya sedang diambil, supaya daftar yang sudah
  /// tampil tidak diganti skeleton sepenuh layar.
  final bool loadingMore;

  final String? errorMessage;

  MasterDocumentListState copyWith({
    MasterDocumentListStatus? status,
    List<MasterDocument>? documents,
    PageMeta? meta,
    String? search,
    bool? loadingMore,
    Object? errorMessage = _unset,
  }) {
    return MasterDocumentListState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      meta: meta ?? this.meta,
      search: search ?? this.search,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }
}
