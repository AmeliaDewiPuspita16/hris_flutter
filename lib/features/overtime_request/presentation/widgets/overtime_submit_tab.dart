import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_time_field.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/overtime_format.dart';
import '../../domain/overtime_request_entry.dart';

/// Tab "Submit" — form pengajuan lembur: tanggal, jam mulai/selesai, alasan.
///
/// Belum tersambung ke API: pengajuan hanya diteruskan ke [onSubmit] dan
/// ditampung layar induk.
class OvertimeSubmitTab extends StatefulWidget {
  const OvertimeSubmitTab({super.key, required this.onSubmit});

  final ValueChanged<OvertimeRequestEntry> onSubmit;

  @override
  State<OvertimeSubmitTab> createState() => _OvertimeSubmitTabState();
}

class _OvertimeSubmitTabState extends State<OvertimeSubmitTab> {
  final _reasonCtrl = TextEditingController();

  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  String? _error;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  /// Durasi bila jam mulai & selesai sudah diisi dan urutannya masuk akal.
  int? get _minutes {
    final start = _start;
    final end = _end;
    if (start == null || end == null) return null;

    final minutes = overtimeMinutesBetween(start, end);
    return minutes > 0 ? minutes : null;
  }

  void _submit() {
    final date = _date;
    final start = _start;
    final end = _end;
    final reason = _reasonCtrl.text.trim();

    if (date == null || start == null || end == null || reason.isEmpty) {
      setState(() => _error = 'Please complete all required fields.');
      return;
    }
    if (_minutes == null) {
      setState(() => _error = 'End time must be later than start time.');
      return;
    }

    widget.onSubmit(
      OvertimeRequestEntry(
        id: 'OT-${DateTime.now().millisecondsSinceEpoch}',
        date: date,
        start: start,
        end: end,
        reason: reason,
        status: AppStatus.pending,
        statusLabel: 'Pending',
      ),
    );
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
                const Text(
                  'OVERTIME DETAILS',
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
                        const Icon(Icons.timer_outlined, size: 16, color: AppColors.overtime),
                        const SizedBox(width: 8),
                        Text(
                          'Duration: ${formatOvertimeDuration(minutes)}',
                          style: const TextStyle(
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
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
