import 'package:flutter/material.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_time_field.dart';
import '../../domain/overtime_format.dart';
import '../../domain/overtime_submission.dart';

/// Tab "Submit" — form pengajuan lembur: tanggal, jam mulai/selesai, jam
/// lembur, alasan.
///
/// Jam lembur diisi user, bukan dihitung dari jam mulai dan selesai, karena
/// waktu istirahat tidak ikut dihitung. Jam selesai yang lebih awal dari jam
/// mulai berarti lembur melewati tengah malam.
///
/// Pengiriman dilakukan layar induk lewat [onSubmit]; bila gagal, pesannya
/// tampil di sini dan isian form tetap ada.
class OvertimeSubmitTab extends StatefulWidget {
  const OvertimeSubmitTab({super.key, required this.onSubmit});

  final Future<void> Function(OvertimeSubmission submission) onSubmit;

  @override
  State<OvertimeSubmitTab> createState() => _OvertimeSubmitTabState();
}

class _OvertimeSubmitTabState extends State<OvertimeSubmitTab> {
  final _reasonCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  /// Selisih jam mulai dan selesai, bila keduanya sudah diisi dan berbeda.
  int? get _minutes {
    final start = _start;
    final end = _end;
    if (start == null || end == null) return null;

    final minutes = overtimeMinutesBetween(start, end);
    return minutes > 0 ? minutes : null;
  }

  bool get _crossesMidnight {
    final start = _start;
    final end = _end;
    if (start == null || end == null) return false;

    return end.hour * 60 + end.minute < start.hour * 60 + start.minute;
  }

  Future<void> _submit() async {
    final date = _date;
    final start = _start;
    final end = _end;
    final reason = _reasonCtrl.text.trim();
    final hoursText = _hoursCtrl.text.trim();

    if (date == null ||
        start == null ||
        end == null ||
        hoursText.isEmpty ||
        reason.isEmpty) {
      setState(() => _error = 'Please complete all required fields.');
      return;
    }

    final minutes = _minutes;
    if (minutes == null) {
      setState(() => _error = 'End time must be different from start time.');
      return;
    }

    final hours = parseOvertimeHours(hoursText);
    if (hours == null) {
      setState(() => _error = 'Overtime hours must be a number above 0.');
      return;
    }
    if (hours > minutes / 60) {
      setState(() => _error =
          'Overtime hours cannot exceed the time between start and end.');
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    try {
      await widget.onSubmit(
        OvertimeSubmission(
          date: date,
          start: start,
          end: end,
          durationHours: hours,
          reason: reason,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e, stack) {
      AppLogger.error('Pengajuan lembur gagal dikirim', e, stack);
      if (mounted) {
        setState(() => _error = 'Failed to submit overtime. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _minutes;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'OVERTIME DETAILS',
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
                AppDateField(
                  label: 'Date',
                  value: _date,
                  required: true,
                  onChanged: (value) => setState(() => _date = value),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTimeField(
                        label: 'Start Time',
                        value: _start,
                        required: true,
                        onChanged: (value) => setState(() => _start = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTimeField(
                        label: 'End Time',
                        value: _end,
                        required: true,
                        onChanged: (value) => setState(() => _end = value),
                      ),
                    ),
                  ],
                ),
                if (minutes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.overtimeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: AppColors.overtime),
                        const SizedBox(width: 8),
                        Text(
                          'Start to end: ${formatOvertimeDuration(minutes)}'
                          '${_crossesMidnight ? ' (ends next day)' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.overtime,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Overtime Hours',
                  controller: _hoursCtrl,
                  hint: 'Excluding breaks, e.g. 2.5',
                  required: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Reason',
                  controller: _reasonCtrl,
                  hint: 'Why do you need to work overtime?',
                  required: true,
                  minLines: 3,
                  maxLines: 5,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 12, color: AppColors.rejected),
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
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
