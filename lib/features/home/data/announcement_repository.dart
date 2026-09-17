import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../domain/announcement_photo.dart';
import '../domain/published_announcement.dart';

/// Penerbitan pengumuman HR. Tidak tahu soal HTTP — itu urusan [ApiClient].
class AnnouncementRepository {
  AnnouncementRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Daftar pengumuman, terbaru lebih dulu sesuai urutan dari server.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<List<PublishedAnnouncement>> fetchAnnouncements({
    int page = 1,
    int perPage = 20,
  }) async {
    final data = await _apiClient.getList(
      '${ApiConfig.hrAnnouncement}?page=$page&per_page=$perPage',
    );

    final announcements = <PublishedAnnouncement>[];
    for (final item in data.whereType<Map<String, dynamic>>()) {
      try {
        announcements.add(PublishedAnnouncement.fromJson(item));
      } on FormatException catch (e) {
        // Satu baris rusak di server tidak boleh membuat seluruh daftar
        // pengumuman hilang dari layar — lewati saja, tapi catat.
        AppLogger.info('Melewati pengumuman yang tidak bisa dibaca: $e');
      }
    }
    return announcements;
  }

  /// Menerbitkan pengumuman, beserta lampiran foto bila ada.
  ///
  /// Melempar [ApiException] bila gagal — termasuk saat foto tidak memenuhi
  /// syarat, yang diperiksa lebih dulu di sini supaya berkas besar tidak
  /// terlanjur diunggah hanya untuk ditolak server.
  Future<PublishedAnnouncement> publish({
    required int departmentId,
    required String title,
    String? body,
    List<AnnouncementPhoto> photos = const [],
  }) async {
    // Diperiksa di sini, bukan hanya di layar, supaya 10 berkas 5 MB tidak
    // terlanjur naik ke server hanya untuk dibalas 422.
    final photoError = AnnouncementPhoto.errorForSelection(photos);
    if (photoError != null) {
      throw ApiException(ApiErrorKind.badRequest, photoError);
    }

    final trimmedBody = body?.trim() ?? '';

    final data = await _apiClient.postMultipart(
      ApiConfig.hrAnnouncement,
      fields: {
        'department_id': '$departmentId',
        'title': title,
        if (trimmedBody.isNotEmpty) 'body': trimmedBody,
      },
      files: {
        if (photos.isNotEmpty)
          'photos[]': photos.map((p) => p.path).toList(growable: false),
      },
    );

    try {
      return PublishedAnnouncement.fromJson(data);
    } on FormatException {
      throw const ApiException.server(
        'Pengumuman terkirim, tapi respons server tidak dikenali.',
      );
    }
  }
}
