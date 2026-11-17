import '../../../../../core/network/api_exception.dart';
import '../../../../../core/network/page_meta.dart';
import '../domain/installed_meter.dart';
import '../domain/meter_category.dart';
import '../domain/meter_reading.dart';
import '../domain/meter_reading_entry.dart';
import '../domain/meter_reading_page.dart';
import '../domain/meter_reading_state.dart';
import '../domain/meter_value_format.dart';
import 'meter_reading_demo_data.dart';

/// Meter Reading. Tidak tahu soal HTTP.
///
/// SEMENTARA: belum ada API, jadi repository ini bekerja di atas data contoh
/// di memori ([MeterReadingDemoData]).
///
/// Begitu API siap, bentuk method di bawah (nama, parameter, tipe
/// kembalian) dipertahankan; yang diganti isinya , dan consttructor menerima
/// `ApiClient`. Bloc dan layar tidak berubah.
class MeterReadingRepository {
  MeterReadingRepository({
    Duration latency = const Duration(milliseconds: 450),
  })  : _latency = latency,
        _store = {
          for (final reading in MeterReadingDemoData.readings())
            reading.id: reading,
        };

  /// Jeda buatan agar skeleton/loading terlihat. Test memakai [Duration.zero].
  final Duration _latency;

  final Map<int, MeterReading> _store;

  Future<void> _simulateNetwork() => Future<void>.delayed(_latency);

  /// Satu halaman daftar, beserta jumlah per status pencatatan dan
  /// paginasinya.
  ///
  /// [categoryCode], [stateCode] (`pending`/`recorded`), dan [search] yang
  /// kosong dianggap tidak ada. [search] mencocokkan lokasi, perusahaan, atau
  /// nomor seri.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<MeterReadingPage> fetchList({
    int page = 1,
    int perPage = 20,
    String? categoryCode,
    String? stateCode,
    String? search,
  }) async {
    await _simulateNetwork();

    final keyword = search?.trim().toLowerCase() ?? '';
    final hasCategory = categoryCode != null && categoryCode.isNotEmpty;
    final hasState = stateCode != null && stateCode.isNotEmpty;

    bool matchesSearch(MeterReading r) =>
        keyword.isEmpty ||
        r.location.toLowerCase().contains(keyword) ||
        r.company.toLowerCase().contains(keyword) ||
        r.meters.any((m) => m.serialNumber.toLowerCase().contains(keyword));

    // Angka chip dihitung atas kategori + pencarian, belum disaring status.
    final scoped = _store.values
        .where((r) => !hasCategory || r.category.code == categoryCode)
        .where(matchesSearch)
        .toList();

    final counts = MeterReadingCounts(
      all: scoped.length,
      recorded:
          scoped.where((r) => r.state == MeterReadingState.recorded).length,
      pending:
          scoped.where((r) => r.state == MeterReadingState.pending).length,
    );

    final filtered =
        hasState ? scoped.where((r) => r.state.code == stateCode).toList() : scoped;

    final lastPage = filtered.isEmpty ? 1 : (filtered.length / perPage).ceil();
    final items = filtered
        .skip((page - 1) * perPage)
        .take(perPage)
        .map((r) => r.toSummary())
        .toList(growable: false);

    return MeterReadingPage(
      items: items,
      counts: counts,
      meta: PageMeta(
        currentPage: page,
        lastPage: lastPage,
        perPage: perPage,
        total: filtered.length,
      ),
    );
  }

  /// Daftar kategori untuk dropdown filter.
  Future<List<MeterCategory>> fetchCategories() async {
    await _simulateNetwork();
    return MeterReadingDemoData.categories;
  }

  /// Rincian satu kontrak/lokasi beserta meter-meternya.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<MeterReading> fetchDetail(int id) async {
    await _simulateNetwork();
    return _require(id);
  }

  /// Mencatat pembacaan baru untuk periode berjalan.
  ///
  /// Mengembalikan rincian TERBARU, jadi layar pemanggil bisa langsung
  /// memakainya tanpa mengambil ulang (pola sama dengan
  /// `ItRequestRepository.submit`).
  ///
  /// Aturan di bawah ini tebakan dari tampilan web, bukan dari server —
  /// periksa lagi saat kontrak API dibuat:
  /// - tiap meter wajib punya satu [entries],
  /// - "Current Value" tidak boleh lebih kecil dari angka sebelumnya,
  /// - periode yang sudah tercatat tidak bisa dicatat lagi.
  ///
  /// Melempar [ApiException] bila gagal, termasuk galat validasi.
  Future<MeterReading> record(
    int id, {
    required List<MeterReadingEntry> entries,
  }) async {
    await _simulateNetwork();

    final current = _require(id);
    if (!current.canRecord) {
      throw const ApiException.server('This period has already been recorded.');
    }

    final byMeter = {for (final entry in entries) entry.meterId: entry};
    final updatedMeters = <InstalledMeter>[];

    for (final meter in current.meters) {
      final entry = byMeter[meter.id];
      if (entry == null) {
        throw ApiException.server(
          'Current value for S/N ${meter.serialNumber} is required.',
        );
      }

      final baseline = meter.baselineForNextReading;
      if (baseline != null && entry.currentValue < baseline) {
        throw ApiException.server(
          'Current value cannot be lower than the previous value '
          '(${formatMeterValue(baseline)}).',
        );
      }

      final remark = entry.remark?.trim() ?? '';
      updatedMeters.add(meter.copyWith(
        previousValue: baseline,
        lastValue: entry.currentValue,
        remark: remark.isEmpty ? null : remark,
        photoUrl: entry.photoPath,
      ));
    }

    final headline = updatedMeters.isEmpty
        ? current.lastValue
        : updatedMeters
            .firstWhere((m) => m.type == current.type, orElse: () => updatedMeters.first)
            .lastValue;

    final updated = current.copyWith(
      state: MeterReadingState.recorded,
      canRecord: false,
      period: MeterReadingDemoData.currentPeriod,
      lastValue: headline,
      recordedBy: 'Syamsuddin',
      recordedAt: DateTime.now(),
      meters: updatedMeters,
    );

    _store[id] = updated;
    return updated;
  }

  MeterReading _require(int id) {
    final reading = _store[id];
    if (reading == null) {
      throw const ApiException.server('Meter reading not found.');
    }
    return reading;
  }
}
