import 'meter_period.dart';
import 'meter_record_action.dart';
import 'meter_reading_summary.dart';

/// Rincian satu record — isi layar detail dan form catat/edit.
///
/// Mewarisi [MeterReadingSummary] supaya layar detail bisa menggambar kepala
/// halaman dari baris daftar sambil menunggu rinciannya.
///
/// Bentuk respons POST (catat / edit / new_reading) TIDAK membawa field
/// tambahan di bawah ini, jadi setelah menyimpan, repository memanggil
/// `GET /records/{id}` lagi.
class MeterReading extends MeterReadingSummary {
  const MeterReading({
    required super.id,
    required super.company,
    required super.location,
    required super.type,
    required super.serialNumber,
    required super.period,
    required super.recordedInActivePeriod,
    required super.approval,
    required super.action,
    super.previousValue,
    super.currentValue,
    super.lastValue,
    super.notes,
    super.imageProofUrl,
    super.recordedBy,
    super.recordedAt,
    this.categoryLabel,
    this.meterTypeLabel,
    this.buildingType,
    this.typeWater,
    this.multiplier,
    this.meterDigits,
    this.nextPreviousValue,
    this.meterRecordedInActivePeriod = false,
    this.activePeriod,
    this.canWrite = false,
  });

  /// Ex: "Tenant" (teks siap tampil).
  final String? categoryLabel;

  /// Ex: "Water" (teks siap tampil).
  final String? meterTypeLabel;

  // Arti tiga field ini belum dikonfirmasi backend — jangan ditampilkan
  // atau dipakai untuk logika dulu.
  final String? buildingType;
  final String? typeWater;
  final bool meterRecordedInActivePeriod;

  /// Pengali dan jumlah digit meter. Fungsinya belum dikonfirmasi.
  final num? multiplier;
  final int? meterDigits;

  /// Angka awal untuk bacaan baru; ditampilkan di samping input saat
  /// `action == new_reading`.
  final num? nextPreviousValue;

  /// Periode aktif saat ini (di luar `data`). Null = tidak ada periode aktif.
  final MeterPeriod? activePeriod;

  /// Hak tulis user (di luar `data`).
  final bool canWrite;

  bool get hasActivePeriod => activePeriod != null;

  /// Angka pembanding di form: `next_previous_value` untuk bacaan baru,
  /// `previous_value` untuk catat / edit.
  num? get formBaseline =>
      action == MeterRecordAction.newReading ? nextPreviousValue : previousValue;

  @override
  bool get canRecord => canWrite && action.isAvailable;
}
