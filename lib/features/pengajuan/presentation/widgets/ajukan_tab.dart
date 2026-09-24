import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import '../../domain/leave_request_draft.dart';
import '../../domain/leave_type.dart';
import '../bloc/history/leave_history_bloc.dart';
import '../bloc/history/leave_history_event.dart';
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
  });

  final Role role;

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
  String? _submitError;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool get _needsTimeRange =>
      _leaveType == LeaveType.lembur || _durationType != DurationType.full;

  Future<void> _handleSubmit() async {
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
    );

    try {
      final repository = context.read<PengajuanRepository>();
      final entry = await repository.submitLeaveRequest(draft);

      if (!mounted) return;
      context.read<LeaveHistoryBloc>().add(LeaveHistoryLocalItemAdded(entry));

      setState(() {
        _submitting = false;
        _submitted = true;
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'REQUEST DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                AppDropdown<LeaveType>(
                  label: 'Request Type',
                  value: _leaveType,
                  required: true,
                  items: options.map((o) => (value: o, label: o.label)).toList(),
                  onChanged: (value) => setState(() => _leaveType = value),
                ),
                const SizedBox(height: 16),
                ..._buildDynamicFields(),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _submitError!,
                    style: const TextStyle(fontSize: 12, color: AppColors.rejected),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Submit Request',
            variant: AppButtonVariant.green,
            isLoading: _submitting,
            onPressed: _handleSubmit,
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
            const Text(
              'Request Submitted!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.present,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
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
            onChanged: (type) => setState(() => _durationType = type),
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
              color: const Color(0xFFFFFBEB),
              border: Border.all(color: AppColors.accentLight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '🩺 Schedule your annual health check-up. A doctor note must '
              'be uploaded after the examination.',
              style: TextStyle(fontSize: 12, color: Color(0xFF744210)),
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
