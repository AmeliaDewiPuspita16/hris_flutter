import '../../../domain/leave_history_entry.dart';

/// Hal-hal yang bisa terjadi pada riwayat pengajuan (tab Status).
sealed class LeaveHistoryEvent {
  const LeaveHistoryEvent();
}

/// Layar baru dibuka — muat riwayat.
class LeaveHistoryStarted extends LeaveHistoryEvent {
  const LeaveHistoryStarted();
}

/// Tarik-untuk-muat-ulang.
class LeaveHistoryRefreshed extends LeaveHistoryEvent {
  const LeaveHistoryRefreshed();
}

/// Pengajuan baru berhasil dikirim lewat tab Ajukan dan disisipkan ke
/// puncak riwayat.
///
/// [AjukanTab] sudah memanggil `PengajuanRepository.submitLeaveRequest`
/// sendiri, jadi [entry] di sini sudah jadi hasil dari
/// repository, bukan tebakan lokal.
class LeaveHistoryLocalItemAdded extends LeaveHistoryEvent {
  const LeaveHistoryLocalItemAdded(this.entry);

  final LeaveHistoryEntry entry;
}

/// Sebuah entri (mis. draft) diganti hasil terbarunya: diedit, atau dirilis
/// jadi pengajuan. Posisinya di daftar tidak berubah.
class LeaveHistoryLocalItemReplaced extends LeaveHistoryEvent {
  const LeaveHistoryLocalItemReplaced(this.id, this.entry);

  /// ID entri lama yang diganti.
  final String id;
  final LeaveHistoryEntry entry;
}
