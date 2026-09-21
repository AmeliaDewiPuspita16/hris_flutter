import '../../../domain/it_request_detail.dart';

enum ItRequestDetailStatus { initial, loading, success, failure }

/// Keadaan layar detail request.
class ItRequestDetailState {
  const ItRequestDetailState({
    this.status = ItRequestDetailStatus.initial,
    this.detail,
    this.errorMessage,
  });

  final ItRequestDetailStatus status;

  /// Terisi hanya setelah rinciannya berhasil diambil. Kepala layar sebelum
  /// itu digambar dari item yang sudah dibawa dari daftar.
  final ItRequestDetail? detail;

  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItRequestDetailState &&
          other.status == status &&
          identical(other.detail, detail) &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, detail, errorMessage);

  @override
  String toString() => 'ItRequestDetailState(${status.name}, error: $errorMessage)';
}
