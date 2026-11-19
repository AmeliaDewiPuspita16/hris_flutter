import '../domain/installed_meter.dart';
import '../domain/meter_category.dart';
import '../domain/meter_period.dart';
import '../domain/meter_reading.dart';
import '../domain/meter_reading_state.dart';
import '../domain/meter_type.dart';

/// Data contoh Meter Reading - SEMENTARA
class MeterReadingDemoData {
  MeterReadingDemoData._();

  static const categories = [
    MeterCategory(code: 'amenity', label: 'Amenity'),
    MeterCategory(code: 'biev', label: 'BIEV'),
    MeterCategory(code: 'contractor', label: 'Contractor'),
    MeterCategory(code: 'dormitory', label: 'Dormitory'),
    MeterCategory(code: 'factory', label: 'Factory'),
    MeterCategory(code: 'solar_panel', label: 'Solar Panel Puja Sera'),
    MeterCategory(code: 'town_centre', label: 'Town Centre'),
    MeterCategory(code: 'utility', label: 'Utility'),
    MeterCategory(code: 'waste_water', label: 'Waste Water'),
  ];

  /// Periode berjalan (sudah dicatat) dan periode yang terlewat (belum).
  static final currentPeriod =
      MeterPeriod(start: DateTime(2026, 10, 2), end: DateTime(2026, 11, 2));
  static final overduePeriod =
      MeterPeriod(start: DateTime(2026, 9, 2), end: DateTime(2026, 10, 1));

  static MeterCategory _category(String code) =>
      categories.firstWhere((c) => c.code == code);

  static List<MeterReading> readings() {
    final seeds = <_Seed>[
      const _Seed('Town Centre', 'AC Sentral ATM', 'town_centre',
          MeterType.electricity, 19303,
          previous: 17915),
      const _Seed(
          'Town Centre', 'ATM BCA', 'town_centre', MeterType.electricity, 3915),
      const _Seed(
          'Town Centre', 'ATM BNI', 'town_centre', MeterType.electricity, 2972),
      const _Seed('Town Centre', 'ATM BRI', 'town_centre',
          MeterType.electricity, 12656),
      const _Seed('Town Centre', 'ATM Mandiri', 'town_centre',
          MeterType.electricity, 3508),
      const _Seed('Block 05B Unit 02C', 'Abdi Utomo', 'factory',
          MeterType.electricity, 759),
      const _Seed(
          'Block 05B Unit 02C', 'Abdi Utomo', 'factory', MeterType.water, 12),
      const _Seed('Block 29 #01-11', 'Agnes Bellyntiarini', 'dormitory',
          MeterType.electricity, 15239),
      const _Seed('Block 29 #01-11', 'Agnes Bellyntiarini', 'dormitory',
          MeterType.water, 1649),
      const _Seed('Block 18C Unit 04', 'BEA CUKAI', 'utility',
          MeterType.electricity, 79951),
      // Baris 11–20: pengisi.
      for (var id = 11; id <= 20; id++) _filler(id),
      // Halaman 3 di web (baris 21–30).
      const _Seed('BIEV #03-02', 'BIEV', 'biev', MeterType.water, 4841),
      const _Seed('BIEV #03-03', 'BIEV', 'biev', MeterType.electricity, 34600,
          previous: 34380,
          pending: true,
          serial: '5388970',
          contract: 'EST-02-003/RF-I-0'),
      const _Seed('BIEV #03-03', 'BIEV', 'biev', MeterType.water, 3093,
          pending: true),
      const _Seed('BIEV #03-04', 'BIEV', 'biev', MeterType.electricity, 74172),
      const _Seed('BIEV #03-04', 'BIEV', 'biev', MeterType.water, 2838),
      const _Seed('BIEV #04-01', 'BIEV', 'biev', MeterType.electricity, 15727),
      const _Seed('BIEV #04-01', 'BIEV', 'biev', MeterType.water, 3397),
      const _Seed('BIEV #04-02', 'BIEV', 'biev', MeterType.electricity, 99064),
      const _Seed('BIEV #04-02', 'BIEV', 'biev', MeterType.water, 3787),
      const _Seed('Club House', 'BIEV', 'biev', MeterType.electricity, 846989),
      // Sisanya: pengisi.
      for (var id = 31; id <= 60; id++) _filler(id),
    ];

    return [
      for (var i = 0; i < seeds.length; i++) _build(i + 1, seeds[i]),
    ];
  }

  static const _fillerCompanies = [
    'PT Samudra Jaya', 'CV Mitra Lestari', 'PT Bintan Makmur', 'PT Karya Utama',
    'CV Sinar Baru', 'PT Nusa Prima', 'PT Citra Mandiri', 'CV Harapan Jaya',
  ];
  static const _fillerCategories = [
    'factory', 'dormitory', 'contractor', 'utility', 'amenity', 'waste_water',
  ];

  /// Data pengisi yang deterministik: dijalankan dua kali hasilnya sama.
  static _Seed _filler(int id) {
    final block = 10 + id % 20;
    final letter = String.fromCharCode(65 + id % 5);
    return _Seed(
      'Block $block$letter Unit ${(id % 9 + 1).toString().padLeft(2, '0')}',
      _fillerCompanies[id % _fillerCompanies.length],
      _fillerCategories[id % _fillerCategories.length],
      id.isEven ? MeterType.electricity : MeterType.water,
      id.isEven ? (id * 7919) % 90000 + 100 : (id * 131) % 4000 + 5,
      pending: id % 7 == 0,
    );
  }

  static MeterReading _build(int id, _Seed seed) {
    final last = seed.lastValue;
    final previous = seed.previous ?? (last - (last * 0.03).round().clamp(1, last)).clamp(0, last);

    return MeterReading(
      id: id,
      location: seed.location,
      company: seed.company,
      category: _category(seed.category),
      type: seed.type,
      lastValue: last,
      period: seed.pending ? overduePeriod : currentPeriod,
      state: seed.pending ? MeterReadingState.pending : MeterReadingState.recorded,
      canRecord: seed.pending,
      contractNumber: seed.contract ??
          'EST-${(id % 9 + 1).toString().padLeft(2, '0')}-${id.toString().padLeft(3, '0')}/RF-I-0',
      recordedBy: seed.pending ? 'Darmawati' : 'Syamsuddin',
      recordedAt: seed.pending ? DateTime(2026, 10, 19, 15, 19) : DateTime(2026, 11, 2, 11, 33),
      biieRepresentative: 'Ari Putra',
      meters: [
        InstalledMeter(
          id: id,
          serialNumber: seed.serial ?? '${5000000 + id * 137}',
          type: seed.type,
          previousValue: previous,
          lastValue: last,
        ),
      ],
    );
  }
}

class _Seed {
  const _Seed(
    this.location,
    this.company,
    this.category,
    this.type,
    this.lastValue, {
    this.previous,
    this.pending = false,
    this.serial,
    this.contract,
  });

  final String location;
  final String company;
  final String category;
  final MeterType type;
  final num lastValue;
  final num? previous;
  final bool pending;
  final String? serial;
  final String? contract;
}
