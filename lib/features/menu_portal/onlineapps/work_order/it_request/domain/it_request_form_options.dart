import '../../../../../shared/domain/department.dart';
import 'need_option.dart';
import 'request_category.dart';

/// Aturan lampiran dari `attachment` di `GET /api/portal/apps/it_request/options`.
class ItRequestAttachmentRules {
  const ItRequestAttachmentRules({
    required this.extensions,
    required this.maxBytes,
  });

  /// Dipakai kalau server belum menjawab (atau gagal) — sama dengan aturan
  /// terakhir yang dikirim server.
  static const fallback = ItRequestAttachmentRules(
    extensions: {
      'jpg',
      'jpeg',
      'png',
      'pdf',
      'doc',
      'docx',
      'ppt',
      'pptx',
      'xls',
      'xlsx',
    },
    maxBytes: 10 * 1024 * 1024,
  );

  /// Huruf kecil, tanpa titik.
  final Set<String> extensions;
  final int maxBytes;

  int get maxMb => (maxBytes / (1024 * 1024)).round();

  factory ItRequestAttachmentRules.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return fallback;

    final extensions = (json['extensions'] as List<dynamic>? ?? const [])
        .map((e) => '$e'.toLowerCase().replaceFirst('.', ''))
        .where((e) => e.isNotEmpty)
        .toSet();
    final maxKb = json['max_kb'];

    return ItRequestAttachmentRules(
      extensions: extensions.isEmpty ? fallback.extensions : extensions,
      maxBytes: maxKb is int && maxKb > 0 ? maxKb * 1024 : fallback.maxBytes,
    );
  }
}

/// Isi `data` dari `GET /api/portal/apps/it_request/options` — semua yang
/// dibutuhkan form Add Request, dibaca dari definisi yang sama dengan yang
/// dipakai server untuk validasi.
///
/// Hanya bagian yang dipakai aplikasi yang dipetakan. Opsi "What do you
/// need?" dibangun ke [NeedOption] yang sama dengan katalog bawaan
/// ([NeedOptionCatalog]), jadi widget form tidak perlu tahu dari mana
/// daftarnya datang.
class ItRequestFormOptions {
  const ItRequestFormOptions({
    required this.itOptions,
    required this.mediaOptions,
    required this.maxAdditionalEmployees,
    required this.departments,
    required this.attachment,
  });

  final List<NeedOption> itOptions;
  final List<NeedOption> mediaOptions;

  /// Berapa karyawan baru TAMBAHAN (di luar karyawan pertama) yang boleh
  /// dalam satu request.
  final int maxAdditionalEmployees;

  /// Kosong bila server tidak mengirimnya — pemanggil jatuh ke
  /// `DepartmentRepository`.
  final List<Department> departments;

  final ItRequestAttachmentRules attachment;

  List<NeedOption> optionsFor(RequestCategory category) =>
      category == RequestCategory.it ? itOptions : mediaOptions;

  /// Melempar [FormatException] bila `categories` tidak ada sama sekali —
  /// form tanpa daftar kategori tidak bisa dipakai, lebih baik pemanggil
  /// jatuh ke katalog bawaan.
  factory ItRequestFormOptions.fromJson(Map<String, dynamic> json) {
    final categories = json['categories'];
    if (categories is! Map<String, dynamic>) {
      throw const FormatException('Opsi form IT Request tidak memuat categories');
    }

    final itOptions = _optionsFrom(categories['IT']);
    final mediaOptions = _optionsFrom(categories['Media']);
    if (itOptions.isEmpty && mediaOptions.isEmpty) {
      throw const FormatException('Opsi form IT Request kosong');
    }

    final newEmployee = json['new_employee'];
    final maxAdditional =
        newEmployee is Map<String, dynamic> ? newEmployee['max_additional'] : null;
    final departments =
        newEmployee is Map<String, dynamic> ? newEmployee['departments'] : null;

    return ItRequestFormOptions(
      itOptions: itOptions,
      mediaOptions: mediaOptions,
      maxAdditionalEmployees: maxAdditional is int && maxAdditional >= 0
          ? maxAdditional
          : 0,
      departments: [
        if (departments is List)
          for (final row in departments)
            if (row is Map<String, dynamic> &&
                row['id'] is int &&
                row['name'] is String)
              Department(id: row['id'] as int, name: row['name'] as String),
      ],
      attachment: ItRequestAttachmentRules.fromJson(json['attachment']),
    );
  }

  static List<NeedOption> _optionsFrom(dynamic rows) {
    if (rows is! List) return const [];

    return [
      for (final row in rows)
        if (row is Map<String, dynamic> && '${row['code'] ?? ''}'.isNotEmpty)
          _optionFrom(row),
    ];
  }

  static NeedOption _optionFrom(Map<String, dynamic> row) {
    final code = '${row['code']}';
    final label = '${row['label'] ?? code}';

    final needs = [
      if (row['needs'] is List)
        for (final need in row['needs'] as List)
          if (need is Map<String, dynamic> && '${need['code'] ?? ''}'.isNotEmpty)
            (code: '${need['code']}', label: '${need['label'] ?? need['code']}'),
    ];

    if (needs.isNotEmpty) {
      return NeedOption(
        id: code,
        label: label,
        requestCategoryCode: code,
        fieldKind: NeedFieldKind.checkboxGroup,
        checkboxLabels: [for (final n in needs) n.label],
        checkboxFieldCodes: [for (final n in needs) n.code],
      );
    }

    // Kategori tanpa checkbox, tapi punya isian khusus. Nama field-nya tidak
    // dikirim server, jadi dipetakan di sini.
    return switch (code) {
      'new_employee_req' => NeedOption(
          id: code,
          label: label,
          requestCategoryCode: code,
          fieldKind: NeedFieldKind.newEmployeeForm,
        ),
      'download_req' => NeedOption(
          id: code,
          label: label,
          requestCategoryCode: code,
          fieldKind: NeedFieldKind.textField,
          textHint: 'Specify application name',
          textFieldCode: 'download_desc',
        ),
      'other_req' => NeedOption(
          id: code,
          label: label,
          requestCategoryCode: code,
          fieldKind: NeedFieldKind.textField,
          textHint: 'Specify',
          textFieldCode: 'other_desc',
        ),
      _ => NeedOption(id: code, label: label, requestCategoryCode: code),
    };
  }
}
