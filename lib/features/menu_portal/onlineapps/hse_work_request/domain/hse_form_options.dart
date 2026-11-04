import '../../../../../core/utils/json_value.dart';

/// Isi dropdown & checklist form permit, dari `GET /hse_permit/options`.
///
/// Nilai checklist, type of works, dan PPE yang dikirim saat submit harus
/// persis salah satu nilai di sini — karena itu form tidak lagi memakai
/// daftar statis di aplikasi.
class HseFormOptions {
  const HseFormOptions({
    required this.categories,
    required this.departments,
    required this.sectionDepartmentId,
    required this.sections,
    required this.generalChecklist,
    required this.typeOfWorks,
    required this.ppe,
    required this.documentFields,
    required this.documentsRequiredFor,
    required this.documentExtensions,
    required this.documentMaxKb,
  });

  final List<({String code, String label})> categories;
  final List<({int id, String name})> departments;

  /// Section hanya berlaku untuk departemen ini (EST). Null = tidak ada.
  final int? sectionDepartmentId;
  final List<String> sections;

  final List<String> generalChecklist;
  final List<String> typeOfWorks;
  final List<String> ppe;

  /// Nama field dokumen, mis. `jsa`, `timeline`, `soft_drawing`.
  final List<String> documentFields;

  /// Kode kategori yang wajib melampirkan [documentFields] (NON-RUTIN).
  final String? documentsRequiredFor;
  final List<String> documentExtensions;
  final int documentMaxKb;

  bool requiresDocuments(String? categoryCode) =>
      categoryCode != null && categoryCode == documentsRequiredFor;

  bool hasSections(int? departmentId) =>
      departmentId != null &&
      departmentId == sectionDepartmentId &&
      sections.isNotEmpty;

  String? departmentName(int? id) {
    for (final d in departments) {
      if (d.id == id) return d.name;
    }
    return null;
  }

  String? categoryLabel(String? code) {
    for (final c in categories) {
      if (c.code == code) return c.label;
    }
    return null;
  }

  /// Label tampilan untuk nama field dokumen dari server.
  static String documentLabel(String field) => switch (field) {
        'jsa' => 'JSA',
        'timeline' => 'Timeline',
        'soft_drawing' => 'Soft Drawing',
        _ => field
            .split('_')
            .map(
                (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' '),
      };

  factory HseFormOptions.fromJson(Map<String, dynamic> json) {
    final sections = _map(json['sections']);
    final documents = _map(json['documents']);

    return HseFormOptions(
      categories: [
        for (final c in _list(json['categories']).whereType<Map>())
          if (textOrNull(c['code']) != null)
            (
              code: '${c['code']}',
              label: textOrNull(c['label']) ?? '${c['code']}',
            ),
      ],
      departments: [
        for (final d in _list(json['departments']).whereType<Map>())
          if (d['id'] is num)
            (id: (d['id'] as num).toInt(), name: '${d['name'] ?? ''}'),
      ],
      sectionDepartmentId: sections['department_id'] is num
          ? (sections['department_id'] as num).toInt()
          : null,
      sections: _strings(sections['options']),
      generalChecklist: _strings(json['general_checklist']),
      typeOfWorks: _strings(json['type_of_works']),
      ppe: _strings(json['ppe']),
      documentFields: _strings(documents['fields']),
      documentsRequiredFor: textOrNull(documents['required_for']),
      documentExtensions: _strings(documents['extensions']),
      documentMaxKb: intOr(documents['max_kb'], 10240),
    );
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  static List<dynamic> _list(dynamic value) => value is List ? value : const [];

  static List<String> _strings(dynamic value) => _list(value)
      .map((e) => '$e')
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
}
