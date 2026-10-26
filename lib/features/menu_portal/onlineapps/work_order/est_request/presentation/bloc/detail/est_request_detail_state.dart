import '../../../domain/est_request_detail.dart';

enum EstRequestDetailStatus { initial, loading, success, failure }

/// Penanda "tidak diisi" untuk [EstRequestDetailState.copyWith], supaya
/// `errorMessage: null` bisa berarti "hapus pesan galat".
const _unset = Object();

/// Keadaan layar detail EST.
class EstRequestDetailState {
  const EstRequestDetailState({
    this.status = EstRequestDetailStatus.initial,
    this.detail,
    this.errorMessage,
  });

  final EstRequestDetailStatus status;

  /// Null sampai pertama kali berhasil dimuat. Saat refresh gagal, detail
  /// lama dibiarkan tampil.
  final EstRequestDetail? detail;

  /// Pesan galat dari server, sudah siap ditampilkan.
  final String? errorMessage;

  /// Belum ada detail untuk ditampilkan, dan masih menunggu server.
  /// [EstRequestDetailStatus.initial] ikut dihitung supaya layar tidak
  /// sempat berkedip kosong sebelum event `Started` diproses.
  bool get isFirstLoad =>
      (status == EstRequestDetailStatus.initial ||
          status == EstRequestDetailStatus.loading) &&
      detail == null;

  EstRequestDetailState copyWith({
    EstRequestDetailStatus? status,
    EstRequestDetail? detail,
    Object? errorMessage = _unset,
  }) {
    return EstRequestDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstRequestDetailState &&
          other.status == status &&
          identical(other.detail, detail) &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, detail, errorMessage);
}
