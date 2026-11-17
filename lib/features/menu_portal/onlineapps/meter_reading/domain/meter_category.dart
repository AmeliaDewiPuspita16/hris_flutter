/// Kategory lokasi untuk filter, ex: "Town Centre", "Dormitory"
///
/// sengaja bukan enum: daftarnya milik server (kategori baru bisa
/// ditambahkan di web), jadi layar mengambilnya lewat
/// MeterReadingRepository.fetchCategories`.
class MeterCategory {
  const MeterCategory({required this.code, required this.label});

  final String code;
  final String label;
}
