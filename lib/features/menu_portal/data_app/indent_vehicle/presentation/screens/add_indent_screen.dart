import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_date_field.dart';
import '../../../../../../core/widgets/app_time_field.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../../core/widgets/field_label_row.dart';
import '../../domain/indent_approve_status.dart';
import '../../domain/indent_progress_status.dart';
import '../../domain/indent_request_item.dart';
import '../widgets/indent_driver_choice.dart';

/// Layar "+ Add Indent" — form pengajuan kendaraan.
///
/// Pola sama dengan `AddEstRequestScreen`: dibuka lewat Navigator.push,
/// mengembalikan [IndentRequestItem] baru lewat Navigator.pop kalau berhasil
/// disubmit, atau null kalau ditutup tanpa submit. Validasi lewat snackbar.
/// Belum terhubung ke API.
class AddIndentScreen extends StatefulWidget {
  const AddIndentScreen({super.key});

  @override
  State<AddIndentScreen> createState() => _AddIndentScreenState();
}

class _AddIndentScreenState extends State<AddIndentScreen> {
  DateTime? _date;
  TimeOfDay? _from;
  TimeOfDay? _until;
  final _destinationController = TextEditingController();
  final _remarkController = TextEditingController();

  /// Default "dengan driver" karena mayoritas request memakai driver; user
  /// tinggal ganti kalau tidak perlu.
  bool _withDriver = true;

  @override
  void dispose() {
    _destinationController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  // --- format ---------------------------------------------------------------

  String _two(int n) => n.toString().padLeft(2, '0');

  /// 'dd-MM-yyyy' — format yang sama dengan data di list.
  String _formatDate(DateTime d) => '${_two(d.day)}-${_two(d.month)}-${d.year}';

  /// 'HH:mm' — dipakai menyusun timeRange untuk item di list.
  String _formatTime(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';


  // --- submit ---------------------------------------------------------------

  String? _validate() {
    if (_date == null) return 'Please select the date.';
    if (_from == null) return 'Please select the start time.';
    if (_until == null) return 'Please select the end time.';
    final fromMinutes = _from!.hour * 60 + _from!.minute;
    final untilMinutes = _until!.hour * 60 + _until!.minute;
    if (untilMinutes <= fromMinutes) {
      return 'End time must be after the start time.';
    }
    if (_destinationController.text.trim().isEmpty) {
      return 'Please fill in the destination.';
    }
    if (_remarkController.text.trim().isEmpty) {
      return 'Please fill in the remark.';
    }
    return null;
  }

  void _submit() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final item = IndentRequestItem(
      id: 'indent-${DateTime.now().microsecondsSinceEpoch}',
      // TODO: ambil dari sesi auth begitu tersambung — sama seperti catatan
      // requesterName di AddEstRequestScreen.
      name: 'Anda',
      destination: _destinationController.text.trim(),
      date: _formatDate(_date!),
      // Format list: 'HH:mm:00 s/d HH:mm:00' (detik selalu 00 dari picker).
      timeRange: '${_formatTime(_from!)}:00 s/d ${_formatTime(_until!)}:00',
      remark: _remarkController.text.trim(),
      approve: IndentApproveStatus.onWaiting,
      status: IndentProgressStatus.onWaiting,
      withDriver: _withDriver,
    );

    Navigator.of(context).pop(item);
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'Add Indent',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Tanggal & jam memakai AppDateField / AppTimeField dari core —
          // sama dengan form Pengajuan cuti & izin, label sudah ada di dalam widget-nya.
          AppDateField(
            label: 'Date Indent',
            value: _date,
            required: true,
            onChanged: (date) => setState(() => _date = date ),
          ),
          const SizedBox(height: 18),
          // From & Until berdampingan: terbaca sebagai satu rentang waktu.
          Row(
            children: [
              Expanded(
                child: AppTimeField(
                  label: 'From',
                  value: _from,
                  onChanged: (time) => setState(() => _from = time)
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTimeField(
                  label: 'Until',
                  value: _until,
                  onChanged: (time) => setState(() => _until = time)
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const FieldLabelRow(label: 'Destination', required: true),
          TextField(
            controller: _destinationController,
            textCapitalization: TextCapitalization.words,
            style: AppTextStyles.body,
            decoration: _fieldDecoration('Contoh: Pelabuhan Speed Tanjung Uban'),
          ),
          const SizedBox(height: 18),
          const FieldLabelRow(label: 'Remark to go', required: true),
          TextField(
            controller: _remarkController,
            minLines: 3,
            maxLines: null,
            style: AppTextStyles.body,
            decoration: _fieldDecoration('Keperluan perjalanan'),
          ),
          const SizedBox(height: 18),
          const FieldLabelRow(label: 'With driver', required: true),
          IndentDriverChoice(
            withDriver: _withDriver,
            onChanged: (v) => setState(() => _withDriver = v),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Submit request',
                style: AppTextStyles.buttonText.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
