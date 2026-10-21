import 'package:flutter/material.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
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
/// Yang sudah terhubung ke HRIS: [fetchHistory]
/// (`GET /api/portal/apps/hris/leave/status`).
///
/// [fetchBalances] dan [submitLeaveRequest] BELUM punya endpoint — keduanya
/// masih mengembalikan data dummy lewat `Future.delayed` supaya UI (loading
/// state, tombol submit, dst) tetap bisa diuji. Saat endpoint-nya siap, cukup
/// isi method itu pakai `_apiClient.getList(...)` / `.post(...)`; tidak ada
/// screen, bloc, atau widget yang perlu ikut berubah.
class PengajuanRepository {
  PengajuanRepository({required ApiClient apiClient}) : _apiClient = apiClient;

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
          label: 'Off in Lieu',
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

  /// Riwayat pengajuan milik user yang login, terbaru lebih dulu.
  ///
  /// Data dari HRIS (`GET /api/portal/apps/hris/leave/status`). Baris yang
  /// bentuknya tidak valid dilewati, bukan menggagalkan seluruh daftar.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<List<LeaveHistoryEntry>> fetchHistory() async {
    final rows = await _apiClient.getList(ApiConfig.leaveStatus);

    final entries = <LeaveHistoryEntry>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final entry =
          row is Map<String, dynamic> ? LeaveHistoryEntry.fromApi(row, index: i) : null;

      if (entry == null) {
        AppLogger.info('Riwayat cuti: baris #$i dilewati (bentuk tidak valid)');
        continue;
      }
      entries.add(entry);
    }

    entries.sort((a, b) => b.requestDate.compareTo(a.requestDate));
    return entries;
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
      typeColor: draft.leaveType.color,
      typeBackground: draft.leaveType.background,
      date: _describeDraftDate(draft),
      requestDate: draft.startDate ?? draft.date ?? DateTime.now(),
      status: AppStatus.pending,
      note: 'Awaiting approval',
      reason: draft.reason,
      photoUrl: draft.attachmentFileName,
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
