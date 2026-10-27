/// Hal-hal yang bisa terjadi pada daftar dokumen master satu tab (Manual,
/// SOP, dst).
sealed class MasterDocumentListEvent {
  const MasterDocumentListEvent();
}

/// Tab dibuka — muat halaman pertama.
class MasterDocumentListStarted extends MasterDocumentListEvent {
  const MasterDocumentListStarted();
}

/// Tarik-untuk-muat-ulang. Kembali ke halaman pertama.
class MasterDocumentListRefreshed extends MasterDocumentListEvent {
  const MasterDocumentListRefreshed();
}

/// Kata kunci pencarian berubah (sudah di-debounce pemanggil) — muat ulang
/// dari halaman pertama.
class MasterDocumentListSearched extends MasterDocumentListEvent {
  const MasterDocumentListSearched(this.query);

  final String query;
}

/// Daftar tergulir mendekati ujung — muat halaman berikutnya.
class MasterDocumentListNextPageRequested extends MasterDocumentListEvent {
  const MasterDocumentListNextPageRequested();
}
