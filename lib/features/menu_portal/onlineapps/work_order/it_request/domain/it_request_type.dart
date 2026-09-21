/// Jenis permintaan, dari field `type` di respons — "IT" atau "Media".
enum ItRequestType {
  it,
  media;

  static ItRequestType fromCode(String code) => switch (code.toUpperCase()) {
        'MEDIA' => ItRequestType.media,
        _ => ItRequestType.it,
      };

  String get label => switch (this) {
        ItRequestType.it => 'IT',
        ItRequestType.media => 'Media',
      };

  /// Nilai `type_request` untuk `POST /api/portal/apps/it_request` — beda
  /// dari [label]: field ini dikirim sebagai kode angka, bukan nama.
  String get formValue => switch (this) {
        ItRequestType.it => '1',
        ItRequestType.media => '2',
      };
}
