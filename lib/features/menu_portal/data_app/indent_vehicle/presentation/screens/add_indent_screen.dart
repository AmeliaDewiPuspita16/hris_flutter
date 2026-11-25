import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_date_field.dart';
import '../../../../../../core/widgets/app_time_field.dart';
import '../../../../../../core/widgets/back_header.dart';
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
///
/// Tampilan mengikuti form Project (EST): kartu putih bersudut besar,
/// header section + garis pemisah, kolom isian berlatar krem tanpa border,
/// dan ikon di sisi kiri tiap kolom.
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
  final _remarkFocus = FocusNode();

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
    _remarkFocus.addListener(() => setState(() {}));
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
    _remarkFocus.dispose();
    super.dispose();
  }

  // --- format ---------------------------------------------------------------

  String _two(int n) => n.toString().padLeft(2, '0');

  /// 'HH:mm' — format jam yang diminta API.
  String _formatTime(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

  /// Format tampilan tanggal di kolom — sama dengan AppDateField lama.
  String _formatDate(DateTime d) => DateFormatter.shortDateID(d);

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

  // --- pickers --------------------------------------------------------------
  // Memakai dialog yang sama dengan AppDateField / AppTimeField (bottom sheet
  // kalender dan wheel jam), hanya tampilan kolomnya yang mengikuti form
  // Project.

  Future<void> _pickDate() async {
    final picked = await AppDateField.pick(context, initial: _date);
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isFrom}) async {
    final picked =
        await AppTimeField.pick(context, initial: isFrom ? _from : _until);
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _from = picked;
        } else {
          _until = picked;
        }
      });
    }
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
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // --- field style ----------------------------------------------------------

  /// Kolom isian krem tanpa border + ikon kiri, sama dengan form Project.
  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primaryMidText, width: 1.5),
      ),
    );
  }

  /// Kolom remark: mulai setinggi kolom lain (1 baris) lalu memanjang
  /// mengikuti isi. Ikonnya tetap di baris pertama, makanya digambar
  /// sendiri di samping TextField (prefixIcon akan ikut ke tengah saat
  /// kolom memanjang).
  Widget _buildRemarkField() {
    final focused = _remarkFocus.hasFocus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        // Lebar border selalu 1.5 (transparan saat tidak fokus) supaya
        // tinggi kolom tidak bergeser.
        border: Border.all(
          color: focused ? AppColors.primaryMidText : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 13),
            child:
                Icon(Icons.edit_note_outlined, size: 20, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _remarkController,
              focusNode: _remarkFocus,
              minLines: 1,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Purpose of the trip',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textMuted),
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- build ----------------------------------------------------------------

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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            _FormSection(
              icon: Icons.event_outlined,
              title: 'Schedule',
              children: [
                _LabeledField(
                  label: 'Date Indent',
                  child: _PickerField(
                    icon: Icons.calendar_today_outlined,
                    hint: 'Select date',
                    text: _date == null ? null : _formatDate(_date!),
                    onTap: _pickDate,
                  ),
                ),
                // From & Until berdampingan: terbaca sebagai satu rentang
                // waktu.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'From',
                        child: _PickerField(
                          icon: Icons.schedule_outlined,
                          hint: 'Select time',
                          text: _from == null ? null : _formatTime(_from!),
                          onTap: () => _pickTime(isFrom: true),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'Until',
                        child: _PickerField(
                          icon: Icons.schedule_outlined,
                          hint: 'Select time',
                          text: _until == null ? null : _formatTime(_until!),
                          onTap: () => _pickTime(isFrom: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FormSection(
              icon: Icons.place_outlined,
              title: 'Trip',
              children: [
                _LabeledField(
                  label: 'Destination',
                  child: TextField(
                    controller: _destinationController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: AppTextStyles.body,
                    decoration: _fieldDecoration(
                      'e.g. Tanjung Uban Speed Port',
                      Icons.location_on_outlined,
                    ),
                  ),
                ),
                _LabeledField(
                  label: 'Remark to go',
                  child: _buildRemarkField(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FormSection(
              icon: Icons.directions_car_outlined,
              title: 'Driver',
              children: [
                _LabeledField(
                  label: 'With driver',
                  child: IndentDriverChoice(
                    withDriver: _withDriver,
                    onChanged: (v) => setState(() => _withDriver = v),
                  ),
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
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
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
                  borderRadius: BorderRadius.circular(14),
                ),
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
                      style: AppTextStyles.buttonText
                          .copyWith(color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu putih berisi satu kelompok field: ikon + judul, garis pemisah, lalu
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primaryText),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 16),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Label tebal di atas field, dengan tanda * merah untuk field wajib.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = true,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.solid(AppColors.rejected)),
                ),
            ],
          ),
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Kolom krem yang bisa diketuk (tanggal / jam), tampilannya sama dengan
/// TextField di form ini: ikon kiri, hint muted saat kosong.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.hint,
    required this.onTap,
    this.text,
  });

  final IconData icon;
  final String hint;
  final String? text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = text != null;
    return Material(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue ? text! : hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hasValue
                      ? AppTextStyles.body
                      : AppTextStyles.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
