import '../../../domain/leave_history_entry.dart';

enum LeaveHistoryStatus { initial, loading, success, failure }

/// Keadaan riwayat pengajuan cuti/izin/lembur (tab Status).
class LeaveHistoryState {
  const LeaveHistoryState({
    this.status = LeaveHistoryStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final LeaveHistoryStatus status;
  final List<LeaveHistoryEntry> items;
  final String? errorMessage;

  LeaveHistoryState copyWith({
    LeaveHistoryStatus? status,
    List<LeaveHistoryEntry>? items,
    String? errorMessage,
  }) {
    return LeaveHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}
