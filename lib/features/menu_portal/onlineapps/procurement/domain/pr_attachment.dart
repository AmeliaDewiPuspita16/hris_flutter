import '../../../../../core/utils/json_value.dart';

/// Berkas atau tautan yang dilampirkan pada sebuah Purchase Requisition.
class PrAttachment {
  const PrAttachment({
    required this.id,
    required this.isLink,
    required this.label,
    required this.url,
    this.category,
    this.fileName,
    this.fileType,
    this.fileSize,
    this.sizeLabel,
    this.uploadedAt,
  });

  final int id;

  /// True bila lampirannya berupa tautan, bukan berkas yang diunggah —
  /// [fileName], [fileType], dan [fileSize] boleh kosong untuk kasus itu.
  final bool isLink;

  /// Nama yang ditampilkan. Untuk berkas biasanya sama dengan [fileName].
  final String label;

  final String url;
  final String? category;
  final String? fileName;
  final String? fileType;
  final int? fileSize;

  /// Ukuran siap tampil dari server, ex: "389.57 KB".
  final String? sizeLabel;

  final DateTime? uploadedAt;

  /// URL yang benar-benar bisa dibuka, atau null.
  ///
  /// Disaring di sini supaya layar tidak menawarkan tombol buka untuk URL
  /// cacat — mengikuti pola [AnnouncementPhotoRef.displayUrl].
  String? get openableUrl {
    if (url.isEmpty) return null;

    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) return null;

    return url;
  }

  factory PrAttachment.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final fileSize = json['file_size'];
    final label = json['label'];
    final fileName = json['file_name'];

    return PrAttachment(
      id: id is int ? id : 0,
      isLink: json['is_link'] == true,
      // Tautan kadang tidak punya label; URL-nya sendiri lebih berguna
      // daripada baris kosong.
      label: label is String && label.isNotEmpty
          ? label
          : (fileName is String && fileName.isNotEmpty
              ? fileName
              : '${json['url'] ?? 'Lampiran'}'),
      url: '${json['url'] ?? ''}',
      category: textOrNull(json['category']),
      fileName: textOrNull(fileName),
      fileType: textOrNull(json['file_type']),
      fileSize: fileSize is int ? fileSize : null,
      sizeLabel: textOrNull(json['size_label']),
      uploadedAt: dateOrNull(json['uploaded_at']),
    );
  }
}
