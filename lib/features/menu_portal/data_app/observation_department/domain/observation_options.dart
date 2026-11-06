/// Pilihan form dari `GET /api/data/observation/options`: kategori beserta
/// sub-kategori dan aturan foto, daftar departemen, dan aturan berkas gambar.
/// Dipakai form Add / Edit / Close supaya aturan tidak di-hardcode di UI.
class ObservationOptions {
  const ObservationOptions({
    required this.categories,
    required this.departments,
    required this.imageTypes,
    required this.imageMaxKb,
  });

  factory ObservationOptions.fromJson(Map<String, dynamic> json) {
    final image = json['image'];

    return ObservationOptions(
      categories: [
        for (final row in _rows(json['categories']))
          if (_text(row['value']) != null)
            ObservationCategoryOption.fromJson(row),
      ],
      departments: [
        for (final row in _rows(json['departments']))
          if (_int(row['id']) != null && _text(row['name']) != null)
            ObservationDepartment(
              id: _int(row['id'])!,
              name: _text(row['name'])!,
            ),
      ],
      imageTypes: image is Map && image['types'] is List
          ? [for (final t in image['types'] as List) '$t'.toLowerCase()]
          : const ['jpg', 'jpeg', 'png'],
      imageMaxKb: image is Map ? (_int(image['max_kb']) ?? 2048) : 2048,
    );
  }

  final List<ObservationCategoryOption> categories;
  final List<ObservationDepartment> departments;

  /// Ekstensi berkas yang boleh diunggah, mis. `jpg`, `jpeg`, `png`.
  final List<String> imageTypes;
  final int imageMaxKb;

  ObservationCategoryOption? categoryByValue(String value) {
    for (final c in categories) {
      if (c.value == value) return c;
    }
    return null;
  }

  ObservationDepartment? departmentByName(String name) {
    for (final d in departments) {
      if (d.name == name) return d;
    }
    return null;
  }

  static Iterable<Map<String, dynamic>> _rows(dynamic value) =>
      value is List ? value.whereType<Map<String, dynamic>>() : const [];

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  static int? _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');
}

/// Satu kategori: nama (`value`), sub-kategori (kosong bila tidak ada), dan
/// apakah foto wajib saat melapor / menutup.
class ObservationCategoryOption {
  const ObservationCategoryOption({
    required this.value,
    required this.subCategories,
    required this.imageRequiredToReport,
    required this.imageRequiredToClose,
  });

  factory ObservationCategoryOption.fromJson(Map<String, dynamic> json) {
    final subs = json['sub_categories'];
    return ObservationCategoryOption(
      value: json['value'].toString().trim(),
      subCategories: subs is List ? [for (final s in subs) '$s'] : const [],
      imageRequiredToReport: json['image_required_to_report'] == true,
      imageRequiredToClose: json['image_required_to_close'] == true,
    );
  }

  final String value;
  final List<String> subCategories;
  final bool imageRequiredToReport;
  final bool imageRequiredToClose;
}

/// Departemen tujuan: `id` yang dikirim ke server sebagai `id_dept`.
class ObservationDepartment {
  const ObservationDepartment({required this.id, required this.name});

  final int id;
  final String name;
}
