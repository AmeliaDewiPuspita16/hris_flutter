import '../../../domain/purchase_requisition.dart';

enum PrDetailStatus { initial, loading, success, failure }

/// Keadaan layar detail PR.
class PrDetailState {
  const PrDetailState({
    this.status = PrDetailStatus.initial,
    this.requisition,
    this.errorMessage,
  });

  final PrDetailStatus status;

  /// Terisi hanya setelah rinciannya berhasil diambil. Kepala layar sebelum
  /// itu digambar dari ringkasan yang sudah dibawa dari daftar.
  final PurchaseRequisition? requisition;

  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrDetailState &&
          other.status == status &&
          identical(other.requisition, requisition) &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, requisition, errorMessage);

  @override
  String toString() => 'PrDetailState(${status.name}, error: $errorMessage)';
}
