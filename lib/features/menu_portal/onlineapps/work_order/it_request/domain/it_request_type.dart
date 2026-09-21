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
}
