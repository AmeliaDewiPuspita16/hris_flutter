/// Hal-hal yang bisa terjadi pada daftar Procurement Monitoring.
sealed class ProcurementListEvent {
  const ProcurementListEvent();
}

/// Layar baru dibuka — muat halaman pertama.
class ProcurementListStarted extends ProcurementListEvent {
  const ProcurementListStarted();
}

/// Tarik-untuk-muat-ulang. Kembali ke halaman pertama dengan filter dan
/// kata kunci yang sedang aktif.
class ProcurementListRefreshed extends ProcurementListEvent {
  const ProcurementListRefreshed();
}

/// Chip status ditekan. [statusCode] null berarti chip "Semua".
class ProcurementListStatusSelected extends ProcurementListEvent {
  const ProcurementListStatusSelected(this.statusCode);

  final String? statusCode;
}

/// Kata kunci pencarian berubah.
///
/// Sudah melewati jeda ketik di layar — bloc langsung meminta ke server
/// begitu event ini masuk.
class ProcurementListSearched extends ProcurementListEvent {
  const ProcurementListSearched(this.query);

  final String query;
}

/// Daftar tergulir mendekati ujung — muat halaman berikutnya.
class ProcurementListNextPageRequested extends ProcurementListEvent {
  const ProcurementListNextPageRequested();
}
