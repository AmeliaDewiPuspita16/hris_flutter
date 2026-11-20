import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../data/meter_reading_repository.dart';
import '../../domain/meter_photo.dart';
import '../../domain/meter_reading.dart';
import '../../domain/meter_reading_input.dart';
import '../../domain/meter_record_action.dart';
import '../../domain/meter_value_format.dart';
import '../widgets/meter_entry_card.dart';
import '../widgets/meter_photo_source_sheet.dart';
import '../widgets/meter_save_bar.dart';

/// Form catat / edit / bacaan baru untuk SATU meter. Mana yang berlaku
/// ditentukan `reading.action` dari server:
///
/// - `record`: catat bacaan pertama periode ini.
/// - `edit`: ubah bacaan yang sudah dicatat (angka dan catatan terisi).
/// - `new_reading`: bacaan baru di periode aktif dari baris yang sudah
///   approved (angka awal = `next_previous_value`). Kolom catatan
///   disembunyikan karena belum jelas apakah endpoint ini menerimanya.
///
/// State form (controller, foto, galat, `_submitting`) hidup di layar ini,
/// bukan di bloc. Bila berhasil, layar menutup dan mengembalikan
/// `(reading, message)` lewat `Navigator.pop` — `reading.id` adalah id baris
/// BARU setelah `new_reading`; layar detail yang memberi tahu blocnya. Bila
/// dibatalkan, mengembalikan null.
class RecordMeterReadingScreen extends StatefulWidget {
  const RecordMeterReadingScreen({
    super.key,
    required this.reading,
    this.repository,
    this.pickPhoto,
  });

  /// Rincian lengkap (`next_previous_value`, `action`, dan seterusnya).
  final MeterReading reading;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final MeterReadingRepository? repository;

  /// Null berarti memakai kamera/galeri sungguhan lewat image_picker.
  final MeterPhotoPicker? pickPhoto;

  @override
  State<RecordMeterReadingScreen> createState() => _RecordMeterReadingScreenState();
}

class _RecordMeterReadingScreenState extends State<RecordMeterReadingScreen> {
  late final MeterReadingRepository _repository;
  final _value = TextEditingController();
  final _remark = TextEditingController();

  late final String _initialValue;
  late final String _initialRemark;

  MeterPhoto? _photo;
  String? _photoError;

  /// Galat "wajib diisi" baru ditampilkan setelah petugas menekan Save —
  /// kolom kosong sejak awal tidak langsung dimerahkan.
  bool _submitAttempted = false;

  bool _submitting = false;
  String? _submitError;

  MeterReading get _reading => widget.reading;
  MeterRecordAction get _action => _reading.action;
  bool get _isNewReading => _action == MeterRecordAction.newReading;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<MeterReadingRepository>();

    // Edit: angka dan catatan lama terisi supaya tinggal diubah.
    if (_action == MeterRecordAction.edit) {
      _value.text = _inputText(_reading.currentValue);
      _remark.text = _reading.notes ?? '';
    }
    _initialValue = _value.text.trim();
    _initialRemark = _remark.text.trim();
  }

  @override
  void dispose() {
    _value.dispose();
    _remark.dispose();
    super.dispose();
  }

  /// Angka dari server untuk kolom isian: titik desimal, tanpa ".0" yang
  /// tidak perlu.
  String _inputText(num? value) {
    if (value == null) return '';
    return value == value.truncate() ? value.truncate().toString() : value.toString();
  }

  bool get _isDirty =>
      _value.text.trim() != _initialValue ||
      (!_isNewReading && _remark.text.trim() != _initialRemark) ||
      _photo != null;

  num? get _baseline => _reading.formBaseline;

  String? get _errorText {
    if (_value.text.trim().isEmpty && !_submitAttempted) return null;
    return validateMeterInput(_value.text);
  }

  String? get _warningText =>
      lowerThanPreviousWarning(_value.text, previous: _baseline);

  num? get _usage {
    final value = parseMeterInput(_value.text);
    final previous = _baseline;
    if (value == null || previous == null || value < previous) return null;
    return value - previous;
  }

  Future<MeterPhoto?> _pickFromDevice(MeterPhotoSource source) async {
    final file = await picker.ImagePicker().pickImage(
      source: source == MeterPhotoSource.camera
          ? picker.ImageSource.camera
          : picker.ImageSource.gallery,
      // Foto dikecilkan: kerja lapangan sering di sinyal lemah, dan server
      // membatasi 5 MB.
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (file == null) return null;

    return MeterPhoto(
      path: file.path,
      fileName: file.name,
      sizeBytes: await file.length(),
    );
  }

  Future<void> _pickPhoto() async {
    if (_submitting) return;

    final source = await showMeterPhotoSourceSheet(context);
    if (source == null || !mounted) return;

    final pick = widget.pickPhoto ?? _pickFromDevice;

    final MeterPhoto? picked;
    try {
      picked = await pick(source);
    } catch (e) {
      if (mounted) {
        setState(() => _photoError = 'Unable to open the camera or gallery.');
      }
      return;
    }

    if (!mounted || picked == null) return;

    final error = picked.validationError;
    setState(() {
      if (error == null) _photo = picked;
      _photoError = error;
    });
  }

  /// Angka lebih kecil dari pembanding hanya diperingatkan: meter yang
  /// diganti atau di-reset bisa sah. Petugas diminta memastikan sebelum lanjut.
  Future<bool> _confirmLowerValue() async {
    final previous = _baseline;
    final value = parseMeterInput(_value.text);
    if (previous == null || value == null) return true;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Value is lower than previous'),
        content: Text(
          'You entered ${formatMeterValue(value)}, which is lower than the '
          'previous value (${formatMeterValue(previous)}). Continue only if '
          'the meter was replaced or reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Check again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save anyway'),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _submitAttempted = true;
      _submitError = null;
    });

    if (validateMeterInput(_value.text) != null) {
      setState(() => _submitError = 'Please check the highlighted value.');
      return;
    }

    if (_warningText != null && !await _confirmLowerValue()) return;
    if (!mounted) return;

    setState(() => _submitting = true);

    try {
      final result = await _repository.save(
        _reading,
        MeterReadingInput(
          currentValue: parseMeterInput(_value.text)!,
          notes: _isNewReading ? null : _remark.text,
          photoPath: _photo?.path,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Pesan 422 dari server ditampilkan apa adanya.
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    } catch (e, stack) {
      AppLogger.error('Pencatatan Meter Reading gagal karena galat tak terduga', e, stack);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('The values you entered have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.rejected),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  String get _title =>
      _action.buttonLabel.isEmpty ? 'Record New Data' : _action.buttonLabel;

  String get _saveLabel => switch (_action) {
        MeterRecordAction.edit => 'Save Changes',
        MeterRecordAction.newReading => 'Save New Reading',
        _ => 'Save Data',
      };

  String get _hint => switch (_action) {
        MeterRecordAction.edit =>
          'Update the reading recorded for this period. Leave the photo as '
              'is to keep the current one.',
        MeterRecordAction.newReading =>
          'New reading for the active period. The previous approved value is '
              'carried forward and usage is calculated for you.',
        _ => 'Enter the current reading. The previous value is carried '
            'forward and usage is calculated for you.',
      };

  /// Periode bacaan yang sedang dibuat: untuk bacaan baru itu periode AKTIF,
  /// bukan periode baris lama yang jadi asalnya.
  String get _periodLabel =>
      _isNewReading && _reading.activePeriod != null
          ? _reading.activePeriod!.label
          : _reading.period.label;

  String get _previousLabel => _isNewReading ? 'PREVIOUS (APPROVED)' : 'PREVIOUS';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Mundur tanpa perubahan langsung boleh; kalau sudah ada isian, tanya
      // dulu. Selama menyimpan, mundur ditahan sama sekali.
      canPop: !_isDirty && !_submitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _submitting) return;
        final discard = await _confirmDiscard();
        if (discard && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BackHeader(
                title: _title,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _ContextCard(
                      reading: _reading,
                      periodLabel: _periodLabel,
                      hint: _hint,
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(message: _submitError!),
                    ],
                    const SizedBox(height: 16),
                    MeterEntryCard(
                      type: _reading.type,
                      serialNumber: _reading.serialNumber,
                      previous: _baseline,
                      previousLabel: _previousLabel,
                      valueController: _value,
                      remarkController: _isNewReading ? null : _remark,
                      photo: _photo,
                      // Foto lama hanya relevan saat edit; bacaan baru dimulai
                      // tanpa foto.
                      existingPhotoUrl:
                          _action == MeterRecordAction.edit ? _reading.imageProofUrl : null,
                      errorText: _errorText,
                      warningText: _warningText,
                      photoError: _photoError,
                      usage: _usage,
                      enabled: !_submitting,
                      // Pemakaian, galat, dan peringatan dihitung ulang tiap ketikan.
                      onChanged: () => setState(() {}),
                      onPickPhoto: _pickPhoto,
                      onRemovePhoto: () => setState(() {
                        _photo = null;
                        _photoError = null;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: MeterSaveBar(
          submitting: _submitting,
          onSave: _submit,
          label: _saveLabel,
        ),
      ),
    );
  }
}

/// Ringkasan "untuk apa form ini": siapa, di mana, periode mana.
class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.reading,
    required this.periodLabel,
    required this.hint,
  });

  final MeterReading reading;
  final String periodLabel;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.apartment_rounded, size: 22, color: AppColors.primaryText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reading.company,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(reading.location, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _InfoLine(icon: Icons.event_outlined, text: periodLabel),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.neutralBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMid),
                const SizedBox(width: 8),
                Expanded(child: Text(hint, style: AppTextStyles.caption)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.caption)),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.rejected.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: AppColors.rejected),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.rejected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
