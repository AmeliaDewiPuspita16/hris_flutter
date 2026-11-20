/// Hal-hal yang bisa terjadi pada daftar Meter Reading
sealed class MeterReadingListEvent {
  const MeterReadingListEvent();
}

/// Layar baru terbuka - muat halaman pertama.
class MeterReadingListStarted extends MeterReadingListEvent {
  const MeterReadingListStarted();
}

/// Tarik-untuk-muat-ulang, atau tombol "coba lagi" saat gagal. Kembali ke
/// halaman pertama dengan filter dan kata kunci yang sedang aktif.
class MeterReadingListRefreshed extends MeterReadingListEvent {
  const MeterReadingListRefreshed();
}

/// Chip status pencatatan ditekan. [stateCode] adalah
/// `MeterReadingState.code` (`pending`/`recorded`); null berarti "Semua".
class MeterReadingListStateSelected extends MeterReadingListEvent {
  const MeterReadingListStateSelected(this.stateCode);

  final String? stateCode;
}

/// Jenis meter dipilih. [typeCode] adalah `MeterType.code` (`kwh`/`m3`);
/// null berarti semua jenis.
class MeterReadingListTypeSelected extends MeterReadingListEvent {
  const MeterReadingListTypeSelected(this.typeCode);

  final String? typeCode;
}

/// Kategori dipilih. [category] adalah label kategori (ex: "Dormitory"),
/// persis seperti nilai `category` di record; null berarti semua kategori.
class MeterReadingListCategorySelected extends MeterReadingListEvent {
  const MeterReadingListCategorySelected(this.category);

  final String? category;
}

/// Sheet filter diterapkan: jenis meter dan kategori berubah SEKALIGUS,
/// jadi cukup satu permintaan ke server.
class MeterReadingListFiltersApplied extends MeterReadingListEvent {
  const MeterReadingListFiltersApplied({this.typeCode, this.category});

  final String? typeCode;
  final String? category;
}

/// Kata kunci pencarian berubah.
///
/// Sudah melewati jeda ketik di layar — bloc langsung meminta ke server
/// begitu event ini masuk.
class MeterReadingListSearched extends MeterReadingListEvent {
  const MeterReadingListSearched(this.query);

  final String query;
}

/// Jenis, kategori, status, dan kata kunci dilepas sekaligus (tombol "Reset filter"
/// di tampilan kosong).
class MeterReadingListFiltersCleared extends MeterReadingListEvent {
  const MeterReadingListFiltersCleared();
}

/// Daftar tergulir mendekati ujung — muat halaman berikutnya.
class MeterReadingListNextPageRequested extends MeterReadingListEvent {
  const MeterReadingListNextPageRequested();
}

/// Tombol "Coba lagi" di ujung daftar setelah memuat halaman berikutnya
/// gagal. Terpisah dari [MeterReadingListNextPageRequested] karena gulir
/// memicu event itu berkali-kali — tanpa pemisahan, kegagalan akan diulang
/// otomatis setiap kali daftar digulir.
class MeterReadingListNextPageRetried extends MeterReadingListEvent {
  const MeterReadingListNextPageRetried();
}
