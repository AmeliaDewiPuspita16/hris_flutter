/// Jenis kegagalan yang bisa terjadi saat memanggil API.
///
/// Dipisah supaya pemanggil bisa bereaksi berbeda — khususnya
/// [ApiErrorKind.unauthorized] yang memicu sesi berakhir.
enum ApiErrorKind {
  /// Tidak ada koneksi, host tak tercapai, atau melewati batas waktu.
  network,

  /// Token tidak berlaku, atau kredensial login salah.
  unauthorized,

  /// Input ditolak server (validasi).
  badRequest,

  /// Gangguan di sisi server, atau respons yang tidak bisa dipahami.
  server,
}

/// Kegagalan pemanggilan API yang [message]-nya sudah siap ditampilkan
/// ke pengguna dalam bahasa Indonesia.
class ApiException implements Exception {
  const ApiException(this.kind, this.message);

  const ApiException.network([
    this.message = 'No internet connection. Please check your network.',
  ]) : kind = ApiErrorKind.network;

  const ApiException.timeout([
    this.message = 'The server is not responding. Please try again shortly.',
  ]) : kind = ApiErrorKind.network;

  const ApiException.unauthorized([
    this.message = 'Your Session has expired. Please sign in again.',
  ]) : kind = ApiErrorKind.unauthorized;

  const ApiException.badRequest([
    this.message = 'The submitted data is invalid.',
  ]) : kind = ApiErrorKind.badRequest;

  const ApiException.server([
    this.message = 'A server error occurred. Please try again later.',
  ]) : kind = ApiErrorKind.server;

  final ApiErrorKind kind;

  /// Pesan berbahasa Indonesia yang layak ditampilkan apa adanya di UI.
  final String message;

  @override
  String toString() => 'ApiException(${kind.name}): $message';
}
