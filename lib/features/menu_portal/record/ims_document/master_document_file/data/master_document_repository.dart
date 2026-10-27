import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/api_config.dart';
import '../../../../../../core/network/page_meta.dart';
import '../../../../../../core/utils/json_value.dart';
import '../../shared/domain/document_category.dart';
import '../../shared/domain/master_document.dart';
import '../../shared/domain/master_document_page.dart';

/// Dokumen master IMS (halaman "Document File") dari
/// `/api/record/ims/documents`. Tidak tahu soal HTTP — itu urusan
/// [ApiClient].
///
/// Semua method melempar [ApiException] bila gagal. 403 (akun Daily Worker)
/// datang sebagai `ApiErrorKind.unauthorized` dengan pesan dari server.
class MasterDocumentRepository {
  MasterDocumentRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Tab-tab kategori beserta jumlah dokumennya, sesuai urutan dari server.
  Future<List<DocumentCategory>> fetchCategories() async {
    final rows = await _apiClient.getRawList(ApiConfig.imsDocumentCategories);

    return [
      for (final row in rows)
        if (_categoryFromJson(row) case final category?) category,
    ];
  }

  /// Satu halaman dokumen kategori [category]. [search] yang kosong sengaja
  /// tidak dikirim. Server mencari berdasarkan nomor dokumen atau judul.
  Future<MasterDocumentPage> fetchDocuments({
    required String category,
    int page = 1,
    int perPage = 50,
    String search = '',
  }) async {
    final keyword = search.trim();

    final envelope = await _apiClient.getEnvelope(
      Uri(path: ApiConfig.imsDocuments, queryParameters: {
        'category': category,
        'page': '$page',
        'per_page': '$perPage',
        if (keyword.isNotEmpty) 'search': keyword,
      }).toString(),
    );

    final rows = envelope['data'];
    return MasterDocumentPage(
      items: [
        if (rows is List)
          for (final row in rows.whereType<Map<String, dynamic>>())
            if (_documentFromJson(row) case final document?) document,
      ],
      // Paginasi Laravel bawaan: `current_page`, `last_page`, dst. berada di
      // akar respons, bukan di dalam `meta`.
      meta: PageMeta.fromJson(envelope),
    );
  }

  /// Header untuk memuat PDF lewat viewer — token yang sama dengan request
  /// API lainnya.
  Map<String, String> get pdfHeaders => {
        'Accept': 'application/pdf, application/json',
        if (_apiClient.authorizationHeader case final header?) 'Authorization': header,
      };

  /// Server mengirim `pdf_url` absolut berisi host miliknya sendiri (mis.
  /// `http://127.0.0.1:8000/...`), yang tidak terjangkau dari HP. Jadi
  /// alamatnya disusun ulang dari [ApiConfig.baseUrl] dan id dokumen.
  static MasterDocument? _documentFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final docNo = textOrNull(json['no_document']);
    if (id is! int || docNo == null) {
      AppLogger.info('Melewati dokumen IMS yang tidak bisa dibaca: $json');
      return null;
    }

    return MasterDocument(
      id: id,
      docNo: docNo,
      title: json['title']?.toString() ?? '',
      hierarchy: textOrNull(json['department']) ?? '-',
      viewUrl: '${ApiConfig.baseUrl}${ApiConfig.imsDocumentPdf(id)}',
      isPdf: json['is_pdf'] != false,
      updatedAt: dateOrNull(json['updated_at'])?.toLocal(),
    );
  }

  /// Toleran terhadap nama kunci: `key`/`slug`/`value`/`category` untuk nilai
  /// query, `label`/`name`/`title` untuk teks tab, `count`/`total`/
  /// `documents_count` untuk jumlah. Baris berupa string polos juga diterima.
  static DocumentCategory? _categoryFromJson(Object? row) {
    if (row is String && row.trim().isNotEmpty) {
      return DocumentCategory(key: row, label: row);
    }
    if (row is! Map<String, dynamic>) return null;

    final label = textOrNull(row['label']) ?? textOrNull(row['name']) ?? textOrNull(row['title']);
    final key = textOrNull(row['key']) ??
        textOrNull(row['slug']) ??
        textOrNull(row['value']) ??
        textOrNull(row['category']) ??
        label?.toLowerCase().replaceAll(' ', '_');
    if (key == null) {
      AppLogger.info('Melewati kategori IMS yang tidak bisa dibaca: $row');
      return null;
    }

    final count = row['count'] ?? row['total'] ?? row['documents_count'];
    return DocumentCategory(
      key: key,
      label: label ?? key,
      count: count is int ? count : null,
    );
  }
}
