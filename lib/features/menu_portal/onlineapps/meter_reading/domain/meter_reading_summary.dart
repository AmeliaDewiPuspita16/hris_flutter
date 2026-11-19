import 'meter_category.dart';
import 'meter_period.dart';
import 'meter_reading_state.dart';
import 'meter_type.dart';

/// Satu baris di daftar Meter Reading — padanan satu baris tabel di web
/// (Location, Company, Type, Last Value, Period, Action).
///
/// Sengaja terpisah dari `MeterReading`: daftar tidak membawa rincian meter,
/// kontrak, atau foto, jadi model daftar tidak boleh berpura-pura punya
/// itu. Pola sama dengan `PurchaseRequisitionSummary`.
class MeterReadingSummary {
  const MeterReadingSummary({
    required this.id,
    required this.location,
    required this.company,
    required this.category,
    required this.type,
    required this.period,
    required this.state,
    this.lastValue,
    this.canRecord = false,
  });

  final int id;

  /// Ex: "Town Centre", "BIEV #03-03".
  final String location;

  /// Ex: "AC Sentral ATM", "BIEV".
  final String company;

  final MeterCategory category;
  final MeterType type;

  /// Angka terakhir yang tercatat. Null bila belum pernah dicatat.
  final num? lastValue;

  final MeterPeriod period;
  final MeterReadingState state;

  /// Sumber kebenaran untuk tombol "+" / "Record New Data" — bukan tebakan
  /// klien dari [state]. Nantinya server yang menentukan, termasuk soal hak
  /// akses (pola sama dengan `ItRequestItem.canRate`).
  final bool canRecord;
}
