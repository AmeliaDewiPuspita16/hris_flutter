/// Hal-hal yang bisa terjadi pada daftar dokumen master satu tab (Manual,
/// SOP, dst).
sealed class MasterDocumentListEvent {
  const MasterDocumentListEvent();
}

/// Tab dibuka — muat daftar.
class MasterDocumentListStarted extends MasterDocumentListEvent {
  const MasterDocumentListStarted();
}

/// Tarik-untuk-muat-ulang.
class MasterDocumentListRefreshed extends MasterDocumentListEvent {
  const MasterDocumentListRefreshed();
}
