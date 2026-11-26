import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../../../core/widgets/app_date_range_field.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_time_field.dart';

import '../../../shared/domain/role.dart';
import '../../data/pengajuan_repository.dart';
import '../../domain/duration_type.dart';
import '../../domain/leave_history_entry.dart';
import '../../domain/leave_request_draft.dart';
import '../../domain/leave_type.dart';
import '../bloc/history/leave_history_bloc.dart';
import '../bloc/history/leave_history_event.dart';
import 'attachment_field.dart';
import 'duration_type_selector.dart';
import 'reason_field.dart';
import 'upload_field.dart';

/// Tab "Ajukan" — form pengajuan cuti/izin/lembur/cek kesehatan.
///
/// Field yang tampil dinamis mengikuti [LeaveType] terpilih (lihat
/// [_buildDynamicFields]). Submit memanggil
/// `PengajuanRepository.submitLeaveRequest` sendiri lalu menyisipkan
/// hasilnya ke [LeaveHistoryBloc] yang sudah disediakan `PengajuanScreen` —
/// pola sama dengan `AddItRequestScreen`/`ItRequestLocalItemAdded` di
/// modul IT Request. Galat ditangani dengan setState lokal (bukan bloc
/// tersendiri) karena ini aksi sekali-jalan yang terikat ke satu form,
/// sama seperti `AddItRequestScreen`.
class AjukanTab extends StatefulWidget {
  const AjukanTab({
    super.key,
    required this.role,
    required this.onSubmitted,
    this.initialDraft,
    this.editingEntry,
  });

  final Role role;

  /// Isian awal form, dipakai saat mengedit draft. Null = form kosong.
  final LeaveRequestDraft? initialDraft;

  /// Draft yang sedang diedit. Bila terisi, simpan/submit memperbarui entri
  /// ini (ID sama), bukan membuat pengajuan baru.
  final LeaveHistoryEntry? editingEntry;

  /// Dipanggil sesaat setelah pengajuan berhasil terkirim, supaya
  /// `PengajuanScreen` bisa memindahkan tab aktif ke Status.
  final VoidCallback onSubmitted;

  @override
  State<AjukanTab> createState() => _AjukanTabState();
}

class _AjukanTabState extends State<AjukanTab> {
  late LeaveType _leaveType = LeaveTypeX.optionsFor(widget.role).first;
  LeaveCategory _izinCategory = LeaveCategory.mcSakit;
  DurationType _durationType = DurationType.full;

  final _reasonCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _date;
  TimeOfDay? _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? _endTime = const TimeOfDay(hour: 12, minute: 0);
  String? _fileName;

  bool _submitting = false;
  bool _submitted = false;
  bool _savedAsDraft = false;
  bool _isUrgent = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();

    final draft = widget.initialDraft;
    if (draft == null) return;

    final options = LeaveTypeX.optionsFor(widget.role);
    _leaveType = options.contains(draft.leaveType) ? draft.leaveType : options.first;
    _izinCategory = draft.izinCategory ?? _izinCategory;
    _durationType = draft.durationType;
    _startDate = draft.startDate;
    _endDate = draft.endDate;
    _date = draft.date;
    _startTime = draft.startTime ?? _startTime;
    _endTime = draft.endTime ?? _endTime;
    _reasonCtrl.text = draft.reason ?? '';
    _fileName = draft.attachmentFileName;
    _isUrgent = draft.isUrgent;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool get _needsTimeRange =>
      _leaveType == LeaveType.lembur || _durationType != DurationType.full;

  /// Ganti durasi (Full/Half Day). Half Day hanya satu tanggal, jadi
  /// tanggal akhir disamakan dengan tanggal mulai.
  void _onDurationChanged(DurationType type) {
    setState(() {
      _durationType = type;
      if (type == DurationType.half && _startDate != null) {
        _endDate = _startDate;
      }
    });
  }

  /// Validasi sebelum Submit (draft tidak divalidasi). Sementara baru untuk
  /// Annual Leave dan OIL; jenis lain belum divalidasi di sini.
  String? _validateForSubmit() {
    if (!_leaveType.isLeaveRequest) return null;

    if (_startDate == null || _endDate == null) {
      return 'Please select the leave date.';
    }
    if (_durationType == DurationType.half) {
      final start = _startTime;
      final end = _endTime;
      if (start == null || end == null) return 'Please select start and end time.';
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      if (endMinutes <= startMinutes) return 'End time must be after start time.';
    }
    return null;
  }

  /// [asDraft] true = simpan sebagai draft (belum dirilis, masih bisa diedit
  /// dari tab Status); false = submit/release.
  Future<void> _handleSubmit({required bool asDraft}) async {
    // Pengaman: API pengajuan belum ada (FeatureFlags.leaveSubmit).
    if (!FeatureFlags.leaveSubmit) return;

    if (!asDraft) {
      final error = _validateForSubmit();
      if (error != null) {
        setState(() => _submitError = error);
        return;
      }
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final draft = LeaveRequestDraft(
      leaveType: _leaveType,
      izinCategory: _leaveType == LeaveType.izin ? _izinCategory : null,
      durationType: _durationType,
      startDate: _startDate,
      endDate: _endDate,
      date: _date,
      startTime: _needsTimeRange ? _startTime : null,
      endTime: _needsTimeRange ? _endTime : null,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      attachmentFileName: _fileName,
      isUrgent: _leaveType.isLeaveRequest && _isUrgent,
    );

    try {
      final repository = context.read<PengajuanRepository>();
      final editing = widget.editingEntry;
      final entry = editing == null
          ? await repository.submitLeaveRequest(draft, asDraft: asDraft)
          : await repository.updateLeaveRequest(editing, draft, asDraft: asDraft);

      if (!mounted) return;
      final historyBloc = context.read<LeaveHistoryBloc>();
      historyBloc.add(
        editing == null
            ? LeaveHistoryLocalItemAdded(entry)
            : LeaveHistoryLocalItemReplaced(editing.id, entry),
      );

      setState(() {
        _submitting = false;
        _submitted = true;
        _savedAsDraft = asDraft;
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      widget.onSubmitted();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    } catch (e, stack) {
      AppLogger.error(
        'Pengajuan gagal dikirim karena galat tak terduga',
        e,
        stack,
      );

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSubmitted();

    final options = LeaveTypeX.optionsFor(widget.role);

    return SingleChildScrollView(
      // Ruang bawah: jarak napas + area aman (home indicator / sudut layar).
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'REQUEST DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                AppDropdown<LeaveType>(
                  label: 'Request Type',
                  value: _leaveType,
                  required: true,
                  // Mengedit draft tidak boleh mengganti jenis: ID jenis cuti
                  // tidak dikirim lewat PATCH.
                  items: (widget.editingEntry == null ? options : [_leaveType])
                      .map((o) => (value: o, label: o.label))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _leaveType = value;
                    // Durasi dipakai Annual Leave & Permission; jangan
                    // terbawa dari jenis sebelumnya.
                    _durationType = DurationType.full;
                    _submitError = null;
                  }),
                ),
                const SizedBox(height: 16),
                ..._buildDynamicFields(),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _submitError!,
                    style: TextStyle(fontSize: 12, color: AppColors.rejected),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Nonaktif sampai API pengajuan ada (FeatureFlags.leaveSubmit).
          // Form di atas tetap bisa diisi; hanya tombol kirim yang mati.
          AppButton(
            label: 'Submit Request',
            variant: AppButtonVariant.green,
            enabled: FeatureFlags.leaveSubmit,
            isLoading: _submitting,
            onPressed: () => _handleSubmit(asDraft: false),
          ),
          const SizedBox(height: 10),
          _SaveDraftButton(
            label: widget.editingEntry == null ? 'Save as Draft' : 'Update Draft',
            enabled: FeatureFlags.leaveSubmit && !_submitting,
            onTap: () => _handleSubmit(asDraft: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitted() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.presentBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.presentMid, width: 2),
              ),
              child: const Text('✅', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),
            Text(
              _savedAsDraft
                  ? (widget.editingEntry == null ? 'Draft Saved!' : 'Draft Updated!')
                  : 'Request Submitted!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.present,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Redirecting to status page...',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    switch (_leaveType) {
      case LeaveType.cutiTahunan:
        return [
          DurationTypeSelector(
            value: _durationType,
            onChanged: _onDurationChanged,
          ),
          const SizedBox(height: 16),
          if (_durationType == DurationType.full)
            AppDateRangeField(
              label: 'Date Range',
              startDate: _startDate,
              endDate: _endDate,
              required: true,
              onChanged: (start, end) => setState(() {
                _startDate = start;
                _endDate = end;
              }),
            )
          else ...[
            // Half Day: satu tanggal (start_date == end_date) + rentang jam.
            AppDateField(
              label: 'Leave Date',
              value: _startDate,
              required: true,
              onChanged: (date) => setState(() {
                _startDate = date;
                _endDate = date;
              }),
            ),
            const SizedBox(height: 16),
            _timeRangeRow(startLabel: 'Start', endLabel: 'End'),
          ],
          // const SizedBox(height: 8),
          // const Text(
          //   'Ideally submitted at least H-3. Last-minute requests are still '
          //   'allowed, but may affect payroll.',
          //   style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          // ),
          const SizedBox(height: 16),
          ReasonField(controller: _reasonCtrl, hint: 'Example: Family vacation...'),
          const SizedBox(height: 16),
          _urgentToggle(),
          const SizedBox(height: 16),
          AttachmentField(
            fileName: _fileName,
            defaultFile: 'lampiran_cuti_tahunan.pdf',
            onChanged: (name) => setState(() => _fileName = name),
          ),
        ];

      case LeaveType.cutiPengganti:
        return [
          AppDateRangeField(
            label: 'Date Range',
            startDate: _startDate,
            endDate: _endDate,
            required: true,
            onChanged: (start, end) => setState(() {
              _startDate = start;
              _endDate = end;
            }),
          ),
          const SizedBox(height: 16),
          ReasonField(controller: _reasonCtrl, hint: 'Example: Family vacation...'),
          const SizedBox(height: 16),
          _urgentToggle(),
        ];

      case LeaveType.izin:
        return [
          AppDropdown<LeaveCategory>(
            label: 'Permission Category',
            value: _izinCategory,
            required: true,
            items: LeaveCategoryX.all.map((c) => (value: c, label: c.label)).toList(),
            onChanged: (value) => setState(() => _izinCategory = value),
          ),
          const SizedBox(height: 16),
          AppDateField(
            label: 'Permission Date',
            value: _date,
            required: true,
            onChanged: (date) => setState(() => _date = date),
          ),
          const SizedBox(height: 16),
          DurationTypeSelector(
            value: _durationType,
            onChanged: _onDurationChanged,
          ),
          if (_durationType != DurationType.full) ...[
            const SizedBox(height: 16),
            _timeRangeRow(startLabel: 'Start', endLabel: 'End'),
          ],
          const SizedBox(height: 16),
          ReasonField(controller: _reasonCtrl, hint: 'Example: Medical needs...'),
        ];

      case LeaveType.lembur:
        return [
          AppDateField(
            label: 'Overtime Date',
            value: _date,
            required: true,
            onChanged: (date) => setState(() => _date = date),
          ),
          const SizedBox(height: 16),
          _timeRangeRow(startLabel: 'Start Time', endLabel: 'End Time'),
          const SizedBox(height: 16),
          ReasonField(
            controller: _reasonCtrl,
            label: 'Work Description',
            hint: 'Example: Completing Q2 report...',
          ),
        ];

      case LeaveType.cekKesehatan:
        return [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.isDark ? AppColors.accentBg : const Color(0xFFFFFBEB),
              border: Border.all(color: AppColors.accentLight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '🩺 Schedule your annual health check-up. A doctor note must '
              'be uploaded after the examination.',
              style: TextStyle(fontSize: 12, color: AppColors.isDark ? AppColors.accentLight : const Color(0xFF744210)),
            ),
          ),
          const SizedBox(height: 16),
          AppDateField(
            label: 'Health Check Date',
            value: _date,
            required: true,
            onChanged: (date) => setState(() => _date = date),
          ),
          const SizedBox(height: 16),
          UploadField(
            label: 'Doctor\'s Note / Proof of Examination',
            required: true,
            fileName: _fileName,
            defaultFile: 'bukti_cek_kesehatan.pdf',
            onChanged: (name) => setState(() => _fileName = name),
          ),
        ];
    }
  }

  /// Saklar "Urgent Request" (`is_urgent`) untuk Annual Leave dan OIL.
  Widget _urgentToggle() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Urgent Request',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Turn on if this leave is requested at short notice.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Switch(
          value: _isUrgent,
          activeTrackColor: AppColors.primary,
          onChanged: (value) => setState(() => _isUrgent = value),
        ),
      ],
    );
  }

  Widget _timeRangeRow({required String startLabel, required String endLabel}) {
    return Row(
      children: [
        Expanded(
          child: AppTimeField(
            label: startLabel,
            value: _startTime,
            onChanged: (time) => setState(() => _startTime = time),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppTimeField(
            label: endLabel,
            value: _endTime,
            onChanged: (time) => setState(() => _endTime = time),
          ),
        ),
      ],
    );
  }
}

/// Tombol sekunder "Save as Draft" (outline), di bawah tombol Submit.
class _SaveDraftButton extends StatelessWidget {
  const _SaveDraftButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryText, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
