import '../../shared/domain/department.dart';

/// Pengumuman yang baru saja diterbitkan, hasil pemetaan `data` dari
/// `POST /api/portal/hr_announcement`.
class PublishedAnnouncement {
  const PublishedAnnouncement({
    required this.id,
    required this.title,
    required this.department,
    required this.createdAt,
    this.body,
    this.postedByName,
    this.photos = const [],
  });

  final int id;
  final String title;

  /// Boleh kosong — `body` opsional di API.
  final String? body;

  final Department department;

  /// Nama penerbit dari `posted_by`. Belum ditampilkan di daftar Beranda,
  /// tapi ikut dipetakan supaya kontrak responsnya tercatat utuh.
  final String? postedByName;

  final DateTime createdAt;
  final List<AnnouncementPhotoRef> photos;

  /// Melempar [FormatException] bila field yang menentukan identitas
  /// pengumuman tidak ada — lebih baik gagal keras di sini daripada
  /// menampilkan kartu pengumuman yang separuh kosong.
  factory PublishedAnnouncement.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Respons pengumuman tidak memuat id');
    }

    final department = json['department'];
    if (department is! Map<String, dynamic>) {
      throw const FormatException('Respons pengumuman tidak memuat department');
    }

    final createdAt = DateTime.tryParse('${json['created_at']}');
    if (createdAt == null) {
      throw const FormatException('created_at tidak bisa diurai');
    }

    final postedBy = json['posted_by'];
    final body = json['body'];

    return PublishedAnnouncement(
      id: id,
      title: '${json['title'] ?? ''}',
      body: body is String && body.isNotEmpty ? body : null,
      department: Department.fromJson(department),
      postedByName: postedBy is Map && postedBy['name'] is String
          ? postedBy['name'] as String
          : null,
      createdAt: createdAt,
      photos: (json['photos'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AnnouncementPhotoRef.fromJson)
          .toList(growable: false),
    );
  }
}

/// Foto pengumuman yang sudah tersimpan di server.
class AnnouncementPhotoRef {
  const AnnouncementPhotoRef({
    required this.id,
    required this.url,
    this.fileName,
  });

  final int id;

  /// URL penuh dari server, mis.
  /// `https://biieportal.co.id/storage/hrga/announcements/…jpg`.
  /// Pakai [displayUrl] saat menampilkannya.
  final String url;

  final String? fileName;

  /// URL yang siap dimuat, atau string kosong bila tidak bisa dipakai.
  ///
  /// Pemanggil menyaring yang kosong supaya tidak ada kotak gambar kosong
  /// menggantung di layar saat server mengirim URL cacat.
  String get displayUrl {
    if (url.isEmpty) return '';

    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) return '';

    return url;
  }

  factory AnnouncementPhotoRef.fromJson(Map<String, dynamic> json) {
    final fileName = json['file_name'];
    return AnnouncementPhotoRef(
      id: json['id'] is int ? json['id'] as int : 0,
      url: '${json['url'] ?? ''}',
      fileName: fileName is String ? fileName : null,
    );
  }
}
