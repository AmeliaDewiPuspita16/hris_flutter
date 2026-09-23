/// Kategori pekerjaan pada form HSE Work Request — menentukan apakah
/// pekerjaan ini rutin (pemeliharaan/maintenance/repair) atau non-rutin
/// (proyek/pekerjaan baru).
enum HseRequestCategory { rutin, nonRutin }

extension HseRequestCategoryX on HseRequestCategory {
  String get label => switch (this) {
        HseRequestCategory.rutin => 'Rutin (Pemeliharaan, Maintenance, Repair)',
        HseRequestCategory.nonRutin => 'Non-Rutin (Project & Pekerjaan Baru)',
      };

  /// Label pendek untuk tempat yang sempit, mis. kartu daftar.
  String get shortLabel => switch (this) {
        HseRequestCategory.rutin => 'Rutin',
        HseRequestCategory.nonRutin => 'Non-Rutin',
      };

  static HseRequestCategory fromApi(String? value) => switch (value) {
        'NON-RUTIN' || 'non_rutin' || 'nonRutin' => HseRequestCategory.nonRutin,
        _ => HseRequestCategory.rutin,
      };

  String toApi() => switch (this) {
        HseRequestCategory.rutin => 'RUTIN',
        HseRequestCategory.nonRutin => 'NON-RUTIN',
      };
}
