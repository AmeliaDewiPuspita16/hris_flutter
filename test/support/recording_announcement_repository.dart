import 'package:hris_mobile/core/network/api_exception.dart';
import 'package:hris_mobile/features/home/data/announcement_repository.dart';
import 'package:hris_mobile/features/home/domain/announcement_photo.dart';
import 'package:hris_mobile/features/home/domain/published_announcement.dart';

import '../fixtures/published_announcement_response.dart';

/// Mencatat panggilan [publish] tanpa menyentuh jaringan maupun berkas.
///
/// Dipakai test widget: format multipart sudah dijaga di test repository,
/// jadi di lapisan UI yang perlu dibuktikan hanya "apa yang diteruskan".
/// Memakai berkas sungguhan di widget test membuat pumpAndSettle menggantung,
/// karena I/O nyata tidak bisa dimajukan zona async milik test.
class RecordingAnnouncementRepository implements AnnouncementRepository {
  RecordingAnnouncementRepository({
    this.failure,
    this.hold,
    this.failOnlyFirstCall = false,
  });

  /// Dilempar alih-alih berhasil, untuk menguji jalur galat.
  final ApiException? failure;

  /// Menahan penyelesaian, untuk menguji keadaan "sedang mengirim".
  final Future<void>? hold;

  /// Hanya panggilan pertama yang gagal — untuk menguji "coba lagi".
  final bool failOnlyFirstCall;

  int calls = 0;
  int? lastDepartmentId;
  String? lastTitle;
  String? lastBody;
  List<AnnouncementPhoto> lastPhotos = const [];

  @override
  Future<PublishedAnnouncement> publish({
    required int departmentId,
    required String title,
    String? body,
    List<AnnouncementPhoto> photos = const [],
  }) async {
    calls++;
    lastDepartmentId = departmentId;
    lastTitle = title;
    lastBody = body;
    lastPhotos = photos;

    final shouldFail =
        failure != null && (!failOnlyFirstCall || calls == 1);
    if (shouldFail) throw failure!;

    if (hold != null) await hold;

    return PublishedAnnouncement.fromJson(publishAnnouncementData());
  }
}
