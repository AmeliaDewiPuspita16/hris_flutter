/// Tiga keputusan yang bisa diambil atasan atas sebuah PR.
///
/// [path] adalah segmen terakhir endpoint:
/// POST /api/portal/apps/eprocurement/{id}/{path}`
enum PrAction {
  approve('approve', commentRequired: false),
  revision('revision', commentRequired: true),
  reject('reject', commentRequired: true);

  const PrAction(this.path, {required this.commentRequired});

  final String path;

  /// server menolak `revision` dan `reject` tanpa `comments`; `approve`
  /// boleh tanpa komentar.
  final bool commentRequired;
}
