import '../../../../../../core/utils/json_value.dart';

/// Lampiran sebuah request, dari `attachment` di respons detail
/// (`{url, name, is_image}`). Berlaku untuk foto MAUPUN dokumen — beda
/// dari `image_url` yang hanya terisi untuk foto.
class ItRequestFile {
  const ItRequestFile({
    required this.url,
    required this.name,
    required this.isImage,
  });

  final String url;
  final String name;
  final bool isImage;

  /// Null bila `attachment` null atau tidak memuat `url`.
  static ItRequestFile? fromJsonOrNull(dynamic json) {
    if (json is! Map<String, dynamic>) return null;

    final url = textOrNull(json['url']);
    if (url == null) return null;

    return ItRequestFile(
      url: url,
      name: textOrNull(json['name']) ?? 'Attachment',
      isImage: json['is_image'] == true,
    );
  }
}
