/// Asal foto profil yang dipilih user. Dipisah dari `ImageSource` milik
/// image_picker supaya bloc dan layar tidak bergantung pada paket itu.
enum PhotoSource { camera, gallery }

/// Pilihan di [showPhotoSourceSheet]: lihat foto yang sudah ada, atau ganti
/// lewat salah satu [PhotoSource].
enum PhotoSheetAction { view, camera, gallery }
