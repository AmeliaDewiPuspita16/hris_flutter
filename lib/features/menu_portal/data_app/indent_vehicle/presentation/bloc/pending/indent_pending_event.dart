import '../../../domain/indent_assign_result.dart';
import '../../../domain/indent_pending_item.dart';

/// Hal-hal yang bisa terjadi pada tab "Pending Vehicle Assignment".
sealed class IndentPendingEvent {
  const IndentPendingEvent();
}

/// Layar baru dibuka — muat daftar request yang menunggu kendaraan.
class IndentPendingStarted extends IndentPendingEvent {
  const IndentPendingStarted();
}

/// Tarik-untuk-muat-ulang, atau tombol "Coba lagi" saat gagal.
class IndentPendingRefreshed extends IndentPendingEvent {
  const IndentPendingRefreshed();
}

/// Admin menekan Assign di sheet: kirim [result] (plat + driver) untuk
/// [item] ke server.
class IndentPendingAssigned extends IndentPendingEvent {
  const IndentPendingAssigned({required this.item, required this.result});

  final IndentPendingItem item;
  final IndentAssignResult result;
}
