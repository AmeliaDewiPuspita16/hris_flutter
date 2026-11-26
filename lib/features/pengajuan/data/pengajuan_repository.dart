import 'package:material_ui/material_ui.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/duration_type.dart';
import '../domain/leave_balance.dart';
import '../domain/leave_history_entry.dart';
import '../domain/leave_request_draft.dart';
import '../domain/leave_type.dart';

/// Sumber data cuti/izin/lembur: saldo, riwayat, dan pengiriman pengajuan
/// baru.
///
/// Sudah terhubung ke HRIS: [fetchHistory] (`GET .../leave/status`),
/// [submitLeaveRequest] (`POST .../leave/request`, `status` draft/release),
/// [updateLeaveRequest] (PATCH) dan [releaseDraft] (POST release).
///
/// Belum punya endpoint: [fetchBalances], masih data dummy lewat
/// `Future.delayed` supaya UI tetap bisa diuji.
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
      LeaveBalance(
        label: 'Annual Leave',
        used: 4,
        total: 12,
        unit: 'Days',
        color: AppColors.primaryMidText,
        background: AppColors.primaryLight,
      ),
      LeaveBalance(
        label: 'Sick Leave',
        used: 0,
        unit: 'Days',
        color: AppColors.rejected,
        background: AppColors.rejectedBg,
      ),
      LeaveBalance(
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
      LeaveBalance(
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

  /// Mengirim pengajuan baru: `POST .../leave/request`.
  ///
  /// [asDraft] true = `status: "draft"` (belum dirilis, masih bisa diedit dari
  /// tab Status); false = `status: "release"` (langsung jadi pengajuan).
  /// Mengembalikan baris riwayat dari respons 201 server.
  ///
  /// Melempar [ApiException] bila gagal (mis. 422 validasi).
  Future<LeaveHistoryEntry> submitLeaveRequest(
    LeaveRequestDraft draft, {
    bool asDraft = false,
  }) async {
    final leaveType = draft.leaveType.apiValue;
    if (leaveType == null) {
      AppLogger.info('Jenis ${draft.leaveType.label} bukan lewat leave/request');
      throw ApiException(
        ApiErrorKind.server,
        '${draft.leaveType.label} requests are not available here yet.',
      );
    }

    final data = await _apiClient.post(
      ApiConfig.leaveRequest,
      body: _insertBody(draft, leaveType: leaveType, asDraft: asDraft),
    );
    return _entryFromResponse(data);
  }

  /// Menyimpan perubahan pada draft [id]: `PATCH .../leave/request/{id}`.
  /// Dengan [asDraft] false, draft sekaligus dirilis
  /// (`POST .../{id}/release`) setelah perubahannya tersimpan.
  ///
  /// Melempar [ApiException] bila gagal.
  Future<LeaveHistoryEntry> updateLeaveRequest(
    LeaveHistoryEntry entry,
    LeaveRequestDraft draft, {
    bool asDraft = true,
  }) async {
    final id = entry.id;

    var data = await _apiClient.patch(
      ApiConfig.leaveRequestDetail(id),
      body: _leaveRequestBody(draft),
    );
    if (!asDraft) {
      data = await _apiClient.post(ApiConfig.leaveRequestRelease(id));
    }
    return _entryFromResponse(data);
  }

  /// Merilis draft apa adanya (tanpa diedit) jadi pengajuan berstatus
  /// pending: `POST .../leave/request/{id}/release`, tanpa body.
  Future<LeaveHistoryEntry> releaseDraft(LeaveHistoryEntry entry) async {
    final data = await _apiClient.post(ApiConfig.leaveRequestRelease(entry.id));
    return _entryFromResponse(data);
  }

  /// `data` dari PATCH/release berbentuk sama seperti satu item riwayat.
  LeaveHistoryEntry _entryFromResponse(Map<String, dynamic> data) {
    final entry = LeaveHistoryEntry.fromApi(data, index: 0);
    if (entry == null) {
      AppLogger.info('Respons pengajuan cuti tidak bisa dipetakan: $data');
      throw const ApiException.server();
    }
    return entry;
  }

  /// Body PATCH. Semua field dikirim (jam `null` bila Full Day) supaya
  /// berpindah Half Day -> Full Day ikut menghapus jam lama di server.
  Map<String, dynamic> _leaveRequestBody(LeaveRequestDraft draft) {
    final start = draft.startDate ?? draft.date;
    final end = draft.endDate ?? start;
    final isHour = draft.durationType == DurationType.half;
    final startTime = draft.startTime;
    final endTime = draft.endTime;

    return {
      if (start != null) 'start_date': _apiDate(start),
      if (end != null) 'end_date': _apiDate(end),
      'is_hour': isHour,
      'start_time': isHour && startTime != null ? _formatTime(startTime) : null,
      'end_time': isHour && endTime != null ? _formatTime(endTime) : null,
      'description': draft.reason,
      'is_urgent': draft.isUrgent,
    };
  }

  String _apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Body POST. Field jam hanya dikirim untuk Half Day (`is_hour: true`);
  /// server mewajibkan `start_date == end_date` dan `end_time > start_time`.
  Map<String, dynamic> _insertBody(
    LeaveRequestDraft draft, {
    required String leaveType,
    required bool asDraft,
  }) {
    final start = draft.startDate ?? draft.date;
    final isHour = draft.durationType == DurationType.half;
    // Cuti per jam wajib satu tanggal: tanggal akhir disamakan dengan mulai.
    final end = isHour ? start : (draft.endDate ?? start);
    final startTime = draft.startTime;
    final endTime = draft.endTime;

    return {
      'leave_type': leaveType,
      if (start != null) 'start_date': _apiDate(start),
      if (end != null) 'end_date': _apiDate(end),
      if (isHour) ...{
        'is_hour': true,
        if (startTime != null) 'start_time': _formatTime(startTime),
        if (endTime != null) 'end_time': _formatTime(endTime),
      },
      if (draft.reason != null) 'description': draft.reason,
      'is_urgent': draft.isUrgent,
      'status': asDraft ? 'draft' : 'release',
    };
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
