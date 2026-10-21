import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_date_field.dart';
import '../../../../../../core/widgets/app_time_field.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../../core/widgets/field_label_row.dart';
import '../../data/indent_vehicle_repository.dart';
import '../../domain/indent_request_item.dart';
import '../widgets/indent_driver_choice.dart';

/// Layar "+ Add Indent" — form pengajuan kendaraan.
///
/// Dibuka lewat Navigator.push. Validasi lewat snackbar. Tombol submit
/// mengirim ke server lewat [IndentVehicleRepository.saveIndent] (tambah
/// maupun edit), menampilkan loading, dan pesan galat server lewat snackbar.
///
/// Hasilnya lewat Navigator.pop: `true` bila tersimpan di server, null bila
/// ditutup tanpa menyimpan. Layar pemanggil lalu memuat ulang daftar.
class AddIndentScreen extends StatefulWidget {
  const AddIndentScreen({super.key, this.initialItem});

  /// Diisi untuk mode edit: form terisi data lama, dan id-nya dikirim ke
  /// server supaya baris itu diperbarui, bukan dibuat baru. Null = mode
  /// tambah.
  final IndentRequestItem? initialItem;

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

  /// True selama permintaan ke server berjalan: tombol dikunci supaya
  /// ketukan ganda tidak membuat request dobel.
  bool _submitting = false;

  bool get _isEdit => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item == null) return;

    _date = _parseDate(item.date);
    final range = _parseTimeRange(item.timeRange);
    _from = range.$1;
    _until = range.$2;
    _destinationController.text = item.destination;
    _remarkController.text = item.remark;
    _withDriver = item.withDriver;
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  // --- format ---------------------------------------------------------------

  String _two(int n) => n.toString().padLeft(2, '0');

  /// 'HH:mm' — format jam yang diminta API.
  String _formatTime(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

  /// 'dd-MM-yyyy' -> DateTime. Null kalau formatnya tidak dikenali.
  DateTime? _parseDate(String s) {
    final p = s.split('-');
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  /// '01:00:00 to 14:30:00' -> (dari, sampai).
  (TimeOfDay?, TimeOfDay?) _parseTimeRange(String s) {
    final parts = s.split(' to ');
    if (parts.length != 2) return (null, null);
    return (_parseTime(parts[0]), _parseTime(parts[1]));
  }

  TimeOfDay? _parseTime(String s) {
    final p = s.trim().split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

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

  Future<void> _submit() async {
    if (_submitting) return;

    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<IndentVehicleRepository>().saveIndent(
            // Mode edit mengirim id yang sama, jadi server memperbarui baris
            // itu. Mode tambah: id null.
            id: int.tryParse(widget.initialItem?.id ?? ''),
            date: _date!,
            departureTime: _formatTime(_from!),
            returnTime: _formatTime(_until!),
            destination: _destinationController.text.trim(),
            purpose: _remarkController.text.trim(),
            withDriver: _withDriver,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, stack) {
      AppLogger.error('Simpan indent gagal karena galat tak terduga', e, stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
        title: _isEdit ? 'Edit Indent' : 'Add Indent',
        onBack: () => Navigator.of(context).pop(),
      ),
      // Tombol submit dipasang di bawah layar (bukan ikut scroll) supaya
      // selalu terlihat dan tidak ada ruang kosong di bawah form.
      bottomNavigationBar: _buildSubmitBar(),
      // Ketuk area kosong untuk menutup keyboard.
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Field dikelompokkan jadi 3 kartu (jadwal, perjalanan, driver)
            // supaya form tidak terbaca sebagai satu daftar panjang.
            _FormSection(
              icon: Icons.event_outlined,
              title: 'Schedule',
              children: [
                // Tanggal & jam memakai AppDateField / AppTimeField dari
                // core — sama dengan form Pengajuan cuti & izin, label
                // sudah ada di dalam widget-nya.
                AppDateField(
                  label: 'Date Indent',
                  value: _date,
                  required: true,
                  onChanged: (date) => setState(() => _date = date),
                ),
                // From & Until berdampingan: terbaca sebagai satu rentang
                // waktu.
                Row(
                  children: [
                    Expanded(
                      child: AppTimeField(
                        label: 'From',
                        value: _from,
                        required: true,
                        onChanged: (time) => setState(() => _from = time),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTimeField(
                        label: 'Until',
                        value: _until,
                        required: true,
                        onChanged: (time) => setState(() => _until = time),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              icon: Icons.place_outlined,
              title: 'Trip',
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabelRow(label: 'Destination', required: true),
                    TextField(
                      controller: _destinationController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: AppTextStyles.body,
                      decoration: _fieldDecoration(
                          'e.g. Tanjung Uban Speed Port'),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabelRow(label: 'Remark to go', required: true),
                    TextField(
                      controller: _remarkController,
                      minLines: 3,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.body,
                      decoration: _fieldDecoration('Purpose of the trip'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FormSection(
              icon: Icons.directions_car_outlined,
              title: 'Driver',
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabelRow(label: 'With driver', required: true),
                    IndentDriverChoice(
                      withDriver: _withDriver,
                      onChanged: (v) => setState(() => _withDriver = v),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                // Tetap hijau saat loading (tombol dikunci, bukan abu-abu).
                disabledBackgroundColor: AppColors.primary,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEdit ? 'Save changes' : 'Submit request',
                      style:
                          AppTextStyles.buttonText.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu putih berisi satu kelompok field: ikon + judul di atas, lalu
/// field-nya dengan jarak seragam antar field.
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}
