import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/leave_balance.dart';
import '../domain/leave_history_entry.dart';
import '../domain/leave_request_draft.dart';
import '../domain/leave_type.dart';

/// Sumber data cuti/izin/lembur: saldo, riwayat, dan pengiriman pengajuan
/// baru.
///
/// BELUM ada endpoint HRIS untuk modul ini — ketiga method di bawah
/// mengembalikan data dummy lewat `Future.delayed` supaya UI (loading state,
/// tombol submit, dst) sudah bisa diuji sekarang. [ApiClient] sudah
/// disuntik lebih dulu (pola sama dengan repository lain, mis.
/// `DepartmentRepository`) supaya saat endpoint-nya siap, hanya isi ketiga
/// method ini yang perlu diganti jadi `_apiClient.getList(...)` /
/// `.post(...)` — tidak ada screen, bloc, atau widget yang perlu ikut
/// berubah.
class PengajuanRepository {
  PengajuanRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  // ignore: unused_field
  final ApiClient _apiClient;

  static const _simulatedLatency = Duration(milliseconds: 500);

  /// Saldo tiap jenis cuti/izin/lembur untuk pegawai yang login.
  ///
  /// [showPersonalLembur] menentukan kartu "Lembur" vs "Cuti Pengganti" yang
  /// muncul — aturan yang sama dengan `LeaveTypeX.showPersonalLembur`,
  /// disuntikkan dari luar supaya repository ini tidak perlu tahu soal
  /// [Role].
  Future<List<LeaveBalance>> fetchBalances({
    required bool showPersonalLembur,
  }) async {
    await Future.delayed(_simulatedLatency);

    return [
      const LeaveBalance(
        label: 'Annual Leave',
        used: 4,
        total: 12,
        unit: 'Days',
        color: AppColors.primaryMid,
        background: AppColors.primaryLight,
      ),
      const LeaveBalance(
        label: 'Sick Leave',
        used: 0,
        unit: 'Days',
        color: AppColors.rejected,
        background: AppColors.rejectedBg,
      ),
      const LeaveBalance(
        label: 'Permission',
        used: 2,
        total: 6,
        unit: 'Days',
        color: AppColors.pending,
        background: AppColors.pendingBg,
      ),
      if (showPersonalLembur)
        const LeaveBalance(
          label: 'Overtime',
          used: 14.5,
          unit: 'Hours',
          color: Color(0xFF6B46C1),
          background: Color(0xFFFAF5FF),
        )
      else
        const LeaveBalance(
          label: 'Off in Liew',
          used: 2,
          total: 5,
          unit: 'Days',
          color: Color(0xFF2C7A7B),
          background: Color(0xFFE6FFFA),
        ),
      const LeaveBalance(
        label: 'Medical Check',
        used: 0,
        total: 1,
        unit: 'Times',
        color: AppColors.presentMid,
        background: AppColors.presentBg,
      ),
    ];
  }

  /// Riwayat pengajuan, terbaru lebih dulu.
  Future<List<LeaveHistoryEntry>> fetchHistory() async {
    await Future.delayed(_simulatedLatency);

    return const [
      LeaveHistoryEntry(
        id: 'PGJ-006',
        type: 'Annual Leave',
        typeColor: AppColors.primaryMid,
        typeBackground: AppColors.primaryLight,
        date: '17–19 Jul 2026',
        status: AppStatus.present,
        note: 'Approved by Dewi Kusumaa',
      ),
      LeaveHistoryEntry(
        id: 'PGJ-005',
        type: 'Overtime',
        typeColor: Color(0xFF6B46C1),
        typeBackground: Color(0xFFFAF5FF),
        date: '28 Aug 2026 · 18:30–20:45',
        status: AppStatus.pending,
        note: 'Pending approval',
      ),
      LeaveHistoryEntry(
        id: 'PGJ-004',
        type: 'Medical Check',
        typeColor: AppColors.presentMid,
        typeBackground: AppColors.presentBg,
        date: '10 Aug 2026',
        status: AppStatus.present,
        note: 'Approved',
      ),
      LeaveHistoryEntry(
        id: 'PGJ-003',
        type: 'MC/Sick',
        typeColor: AppColors.rejected,
        typeBackground: AppColors.rejectedBg,
        date: '5–6 Aug 2026',
        status: AppStatus.rejected,
        note: 'Rejected: Incomplete doctor\'s note',
      ),
      LeaveHistoryEntry(
        id: 'PGJ-002',
        type: 'Permission',
        typeColor: AppColors.pending,
        typeBackground: AppColors.pendingBg,
        date: '25 Jul 2026 · Half Day',
        status: AppStatus.present,
        note: 'Disetujui',
      ),
      LeaveHistoryEntry(
        id: 'PGJ-001',
        type: 'Cuti Tahunan',
        typeColor: AppColors.primaryMid,
        typeBackground: AppColors.primaryLight,
        date: '1–3 Jul 2026',
        status: AppStatus.present,
        note: 'Disetujui',
      ),
    ];
  }

  /// Mengirim pengajuan baru, mengembalikan baris riwayat yang siap
  /// disisipkan ke puncak daftar Status.
  ///
  /// Selalu berstatus [AppStatus.pending] — sama seperti pengajuan
  /// sungguhan yang baru dikirim dan belum diproses siapa pun.
  Future<LeaveHistoryEntry> submitLeaveRequest(LeaveRequestDraft draft) async {
    await Future.delayed(_simulatedLatency);

    return LeaveHistoryEntry(
      id: 'PGJ-${DateTime.now().millisecondsSinceEpoch}',
      type: draft.leaveType.label,
      typeColor: AppColors.pending,
      typeBackground: AppColors.pendingBg,
      date: _describeDraftDate(draft),
      status: AppStatus.pending,
      note: 'Menunggu persetujuan',
    );
  }

  String _describeDraftDate(LeaveRequestDraft draft) {
    final start = draft.startDate;
    final end = draft.endDate;
    if (start != null && end != null) {
      return '${DateFormatter.shortDateID(start)} – ${DateFormatter.shortDateID(end)}';
    }

    final date = draft.date;
    if (date == null) return '-';

    final dateLabel = DateFormatter.shortDateID(date);
    final startTime = draft.startTime;
    final endTime = draft.endTime;
    if (startTime == null || endTime == null) return dateLabel;

    return '$dateLabel · ${_formatTime(startTime)}–${_formatTime(endTime)}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
