import 'package:url_launcher/url_launcher.dart';

/// Tautan ke website IMS. Dokumen master TIDAK diunduh di aplikasi: unduh
/// dilakukan di website karena file diberi cap saat diunduh dan butuh
/// approval dulu. Aplikasi hanya mengarahkan user ke sana.
class ImsWebLinks {
  ImsWebLinks._();

  /// TODO: ganti dengan alamat halaman dokumen website IMS yang sebenarnya.
  /// Dipakai selama [MasterDocument.downloadUrl] / `obsoleteUrl` masih
  /// berupa data dummy (skema `dummy://`).
  static const documentsPage = 'https://ims.example.com/documents';

  /// Alamat yang dibuka untuk sebuah dokumen. Kalau [url] dari data sudah
  /// berupa http(s), pakai apa adanya; kalau masih dummy, jatuh ke
  /// [documentsPage].
  static Uri resolve(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return uri;
    }
    return Uri.parse(documentsPage);
  }

  /// Buka di browser bawaan HP. False kalau gagal dibuka.
  static Future<bool> open(String url) async {
    try {
      return await launchUrl(
        resolve(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
