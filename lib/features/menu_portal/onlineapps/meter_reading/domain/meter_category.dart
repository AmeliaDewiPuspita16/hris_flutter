/// Kategori lokasi untuk filter, ex: "Town Centre", "Dormitory", dll.
///
/// API Meter Reading TIDAK punya endpoint daftar kategori, hanya query
/// `category` di `GET /records` dan field `category` (teks) di tiap record.
/// jadi pilihan di dropdown berupa daftar teteap dibawah, dan nilai yang
/// dikirim ke server adalah [label]-nya - persis teks yang datang di field
/// `category`.
///
/// Bila backend menambah kategori, daftar [all] ikut ditambah di sini.
class MeterCategory {
  const MeterCategory(this.label);

  final String label;

  static const all = <MeterCategory>[
    MeterCategory('Amenity'),
    MeterCategory('BIEV'),
    MeterCategory('Contractor'),
    MeterCategory('Dormitory'),
    MeterCategory('Factory'),
    MeterCategory('Solar Panel Puja Sera'),
    MeterCategory('Town Centre'),
    MeterCategory('Utility'),
    MeterCategory('Waste Water'),
  ];
}
