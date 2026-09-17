/// Pilihan dropdown "Type request" pada form Ajukan Request.
///
/// Menentukan daftar opsi "What do you need?" yang tampil — lihat
/// [NeedOptionCatalog.optionsFor] di `need_option.dart`. Sengaja dipisah
/// dari `RequestType` (IT Request / EST Request) di `request_type.dart`,
/// karena itu pilihan modul di level "Choose App", beda konteks dengan
/// dropdown di dalam form ini.
enum RequestCategory {
  it,
  media;

  String get label => switch (this) {
        RequestCategory.it => 'IT',
        RequestCategory.media => 'MEDIA',
      };
}
