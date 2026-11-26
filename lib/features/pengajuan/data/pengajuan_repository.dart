import 'package:material_ui/material_ui.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../domain/duration_type.dart';
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
/// Draft server sudah terhubung: [updateLeaveRequest] (PATCH) dan
/// [releaseDraft] (POST release).
///
/// [submitLeaveRequest] sudah memakai `POST leave/request` untuk Annual Leave
/// (jenis lain masih dummy).
///
/// [fetchBalances] BELUM punya endpoint — keduanya
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

  /// Membuat pengajuan baru: `POST .../leave/request`, mengembalikan baris
  /// riwayat dari respons 201 (ID asli server) untuk disisipkan ke puncak
  /// daftar Status.
  ///
  /// [asDraft] true = `status: "draft"` (belum dirilis, masih bisa diedit
  /// dari tab Status); false = `status: "release"` (langsung diajukan,
  /// status OEZ_RELEASE / Pending).
  ///
  /// Baru Annual Leave yang nilai `leave_type`-nya diketahui (`annual`).
  /// Jenis lain masih dummy (entri lokal, ID berawalan `PGJ-`) sampai
  /// endpoint dan nilai `leave_type`-nya jelas.
  ///
  /// Melempar [ApiException] bila gagal (mis. 422 validasi).
  Future<LeaveHistoryEntry> submitLeaveRequest(
    LeaveRequestDraft draft, {
    bool asDraft = false,
  }) async {
    final typeKey = _leaveTypeKey(draft.leaveType);

    if (typeKey == null) {
      await Future.delayed(_simulatedLatency);
      return _buildEntry(
        'PGJ-${DateTime.now().millisecondsSinceEpoch}',
        draft,
        asDraft: asDraft,
      );
    }

    final data = await _apiClient.post(
      ApiConfig.leaveRequest,
      body: {
        'leave_type': typeKey,
        ..._leaveRequestBody(draft, forCreate: true),
        'status': asDraft ? 'draft' : 'release',
      },
    );
    return _entryFromResponse(data);
  }

  /// Nilai `leave_type` untuk body POST; null bila belum diketahui.
  String? _leaveTypeKey(LeaveType type) =>
      type == LeaveType.cutiTahunan ? 'annual' : null;

  /// Menyimpan perubahan pada draft [id]: `PATCH .../leave/request/{id}`.
  /// Dengan [asDraft] false, draft sekaligus dirilis
  /// (`POST .../{id}/release`) setelah perubahannya tersimpan.
  ///
  /// Draft lokal (dibuat lewat [submitLeaveRequest] yang masih dummy, ID
  /// berawalan `PGJ-`) tidak ada di server, jadi diproses dummy juga.
  ///
  /// Endpoint ini milik sumber `leave_request` (Annual Leave, OIL); untuk
  /// sumber lain lihat [_ensureEndpointAvailable].
  ///
  /// Melempar [ApiException] bila gagal.
  Future<LeaveHistoryEntry> updateLeaveRequest(
    LeaveHistoryEntry entry,
    LeaveRequestDraft draft, {
    bool asDraft = true,
  }) async {
    final id = entry.id;
    if (_isLocalId(id)) {
      await Future.delayed(_simulatedLatency);
      return _buildEntry(id, draft, asDraft: asDraft);
    }
    _ensureEndpointAvailable(entry);

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
  ///
  /// Draft lokal diproses dummy (lihat [updateLeaveRequest]).
  Future<LeaveHistoryEntry> releaseDraft(LeaveHistoryEntry entry) async {
    if (_isLocalId(entry.id)) {
      await Future.delayed(_simulatedLatency);

      final draft = entry.draft;
      if (draft == null) {
        throw StateError('Draft ${entry.id} tidak punya data untuk dirilis');
      }
      return _buildEntry(entry.id, draft, asDraft: false);
    }

    _ensureEndpointAvailable(entry);

    final data = await _apiClient.post(ApiConfig.leaveRequestRelease(entry.id));
    return _entryFromResponse(data);
  }

  /// Endpoint edit/release yang tersedia baru milik `leave_request`. Draft
  /// jenis lain (izin, lembur, cek kesehatan) juga ada, tapi endpoint-nya
  /// belum diketahui; ditolak dengan pesan jelas, bukan salah alamat.
  ///
  /// Sumber kosong dianggap `leave_request` (respons lama tanpa `source`).
  void _ensureEndpointAvailable(LeaveHistoryEntry entry) {
    final source = entry.source ?? 'leave_request';
    if (source == 'leave_request') return;

    AppLogger.info('Edit/release draft sumber "$source" belum punya endpoint');
    throw ApiException(
      ApiErrorKind.server,
      'Editing this type of request is not available yet.',
    );
  }

  bool _isLocalId(String id) => id.startsWith('PGJ-');

  /// `data` dari PATCH/release berbentuk sama seperti satu item riwayat.
  LeaveHistoryEntry _entryFromResponse(Map<String, dynamic> data) {
    final entry = LeaveHistoryEntry.fromApi(data, index: 0);
    if (entry == null) {
      AppLogger.info('Respons pengajuan cuti tidak bisa dipetakan: $data');
      throw const ApiException.server();
    }
    return entry;
  }

  /// Body pengajuan cuti.
  ///
  /// PATCH ([forCreate] false): semua field dikirim, jam `null` bila Full Day,
  /// supaya berpindah Half Day -> Full Day ikut menghapus jam lama di server.
  /// POST ([forCreate] true): field kosong dihilangkan.
  ///
  /// Aturan server untuk `is_hour: true`: jam wajib (H:i, WIB), jam selesai
  /// harus lebih besar, dan tanggal mulai harus sama dengan tanggal selesai
  /// (form Half Day sudah menjamin yang terakhir).
  Map<String, dynamic> _leaveRequestBody(
    LeaveRequestDraft draft, {
    bool forCreate = false,
  }) {
    final start = draft.startDate ?? draft.date;
    final end = draft.endDate ?? start;
    final isHour = draft.durationType == DurationType.half;
    final startTime = isHour ? draft.startTime : null;
    final endTime = isHour ? draft.endTime : null;
    final reason = draft.reason;

    return {
      if (start != null) 'start_date': _apiDate(start),
      if (end != null) 'end_date': _apiDate(end),
      if (!forCreate || isHour) 'is_hour': isHour,
      if (startTime != null) 'start_time': _formatTime(startTime),
      if (!forCreate && startTime == null) 'start_time': null,
      if (endTime != null) 'end_time': _formatTime(endTime),
      if (!forCreate && endTime == null) 'end_time': null,
      if (!forCreate || (reason != null && reason.isNotEmpty))
        'description': reason,
      'is_urgent': draft.isUrgent,
    };
  }

  String _apiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  LeaveHistoryEntry _buildEntry(
    String id,
    LeaveRequestDraft draft, {
    required bool asDraft,
  }) {
    return LeaveHistoryEntry(
      id: id,
      type: draft.leaveType.label,
      typeColor: draft.leaveType.color,
      typeBackground: draft.leaveType.background,
      date: _describeDraftDate(draft),
      requestDate: draft.startDate ?? draft.date ?? DateTime.now(),
      status: asDraft ? AppStatus.neutral : AppStatus.pending,
      statusLabel: asDraft ? 'Draft' : null,
      note: asDraft ? 'Draft, not submitted yet' : 'Awaiting approval',
      reason: draft.reason,
      photoUrl: draft.attachmentFileName,
      isDraft: asDraft,
      draft: asDraft ? draft : null,
      canEdit: asDraft,
      isUrgent: draft.isUrgent,
    );
  }

  String _describeDraftDate(LeaveRequestDraft draft) {
    final start = draft.startDate ?? draft.date;
    if (start == null) return '-';
    final end = draft.endDate ?? start;

    final isSameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    var label = DateFormatter.shortDateID(start);
    if (!isSameDay) label = '$label – ${DateFormatter.shortDateID(end)}';

    final startTime = draft.startTime;
    final endTime = draft.endTime;
    if (startTime == null || endTime == null) return label;

    return '$label · ${_formatTime(startTime)}–${_formatTime(endTime)}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
