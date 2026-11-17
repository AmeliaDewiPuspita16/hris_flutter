import '../../../domain/meter_reading.dart';

enum MeterReadingDetailStatus { initial, loading, success, failure }

/// Keadaan layar detail Meter Reading.
class MeterReadingDetailState {
  const MeterReadingDetailState({
    this.status = MeterReadingDetailStatus.initial,
    this.detail,
    this.errorMessage,
  });

  final MeterReadingDetailStatus status;

  /// Terisi hanya setelah rinciannya berhasil diambil. Kepala layar sebelum
  /// itu digambar dari ringkasan yang sudah dibawa dari daftar.
  final MeterReading? detail;

  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeterReadingDetailState &&
          other.status == status &&
          identical(other.detail, detail) &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, detail, errorMessage);

  @override
  String toString() =>
      'MeterReadingDetailState(${status.name}, error: $errorMessage)';
}
