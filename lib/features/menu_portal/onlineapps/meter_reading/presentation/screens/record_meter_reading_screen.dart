import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../data/meter_reading_repository.dart';
import '../../domain/installed_meter.dart';
import '../../domain/meter_photo.dart';
import '../../domain/meter_reading.dart';
import '../../domain/meter_reading_entry.dart';
import '../../domain/meter_value_format.dart';
import '../widgets/meter_entry_card.dart';
import '../widgets/meter_photo_source_sheet.dart';
import '../widgets/meter_save_bar.dart';
import '../widgets/meter_section_title.dart';

/// Form Record New Data: petugas mengisi angka meter periode ini.
///
/// State form (controller, foto, galat, `_submitting`) hidup di layar ini,
/// bukan di bloc — pola sama dengan `AddItRequestScreen`: aksi sekali-jalan
/// yang terikat ke satu layar. Bila berhasil, layar menutup dan
/// mengembalikan [MeterReading] TERBARU dari server lewat `Navigator.pop`;
/// layar detail yang memberi tahu blocnya. Bila dibatalkan, mengembalikan null.
class RecordMeterReadingScreen extends StatefulWidget {
  const RecordMeterReadingScreen({
    super.key,
    required this.reading,
    this.repository,
    this.pickPhoto,
  });

  /// Rincian lengkap — dari sinilah daftar meter yang harus diisi diketahui.
  final MeterReading reading;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final MeterReadingRepository? repository;

  /// Null berarti memakai kamera/galeri sungguhan lewat image_picker.
  final MeterPhotoPicker? pickPhoto;

  @override
  State<RecordMeterReadingScreen> createState() => _RecordMeterReadingScreenState();
}

/// Isian satu meter.
class _Draft {
  final value = TextEditingController();
  final remark = TextEditingController();
  MeterPhoto? photo;
  String? photoError;

  bool get isEmpty =>
      value.text.trim().isEmpty && remark.text.trim().isEmpty && photo == null;

  void dispose() {
    value.dispose();
    remark.dispose();
  }
}

class _RecordMeterReadingScreenState extends State<RecordMeterReadingScreen> {
  late final MeterReadingRepository _repository;
  late final Map<int, _Draft> _drafts;

  /// Galat "wajib diisi" baru ditampilkan setelah petugas menekan Save —
  /// kolom kosong sejak awal tidak langsung dimerahkan.
  bool _submitAttempted = false;

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<MeterReadingRepository>();
    _drafts = {for (final meter in widget.reading.meters) meter.id: _Draft()};
  }

  @override
  void dispose() {
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  /// Meter yang angkanya sudah terisi (sah atau belum).
  int get _filledCount =>
      _drafts.values.where((d) => d.value.text.trim().isNotEmpty).length;

  bool get _isDirty => _drafts.values.any((draft) => !draft.isEmpty);

  /// Galat yang pantas ditampilkan di kolom angka sekarang.
  String? _errorFor(InstalledMeter meter) {
    final text = _drafts[meter.id]!.value.text;
    if (text.trim().isEmpty && !_submitAttempted) return null;
    return validateMeterInput(text, previous: meter.baselineForNextReading);
  }

  num? _usageFor(InstalledMeter meter) {
    final value = parseMeterInput(_drafts[meter.id]!.value.text);
    final previous = meter.baselineForNextReading;
    if (value == null || previous == null || value < previous) return null;
    return value - previous;
  }

  Future<MeterPhoto?> _pickFromDevice(MeterPhotoSource source) async {
    final file = await picker.ImagePicker().pickImage(
      source: source == MeterPhotoSource.camera
          ? picker.ImageSource.camera
          : picker.ImageSource.gallery,
      // Foto dikecilkan: kerja lapangan sering di sinyal lemah.
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

  Future<void> _pickPhoto(InstalledMeter meter) async {
    if (_submitting) return;

    final source = await showMeterPhotoSourceSheet(context);
    if (source == null || !mounted) return;

    final pick = widget.pickPhoto ?? _pickFromDevice;
    final draft = _drafts[meter.id]!;

    final MeterPhoto? picked;
    try {
      picked = await pick(source);
    } catch (e) {
      if (mounted) {
        setState(() => draft.photoError = 'Unable to open the camera or gallery.');
      }
      return;
    }

    if (!mounted || picked == null) return;

    final error = picked.validationError;
    setState(() {
      if (error == null) draft.photo = picked;
      draft.photoError = error;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _submitAttempted = true;
      _submitError = null;
    });

    final hasInvalid = widget.reading.meters.any(
      (meter) =>
          validateMeterInput(
            _drafts[meter.id]!.value.text,
            previous: meter.baselineForNextReading,
          ) !=
          null,
    );
    if (hasInvalid) {
      setState(() => _submitError = 'Please check the highlighted values.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final updated = await _repository.record(
        widget.reading.id,
        entries: [
          for (final meter in widget.reading.meters)
            MeterReadingEntry(
              meterId: meter.id,
              currentValue: parseMeterInput(_drafts[meter.id]!.value.text)!,
              remark: _drafts[meter.id]!.remark.text,
              photoPath: _drafts[meter.id]!.photo?.path,
            ),
        ],
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final reading = widget.reading;

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
                title: 'Record New Data',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _ContextCard(reading: reading),
                    if (_submitError != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(message: _submitError!),
                    ],
                    const SizedBox(height: 22),
                    MeterSectionTitle(
                      title: 'METER READINGS',
                      icon: Icons.speed_rounded,
                      trailing: MeterCountChip(
                        label: '${reading.meters.length} '
                            '${reading.meters.length == 1 ? 'meter' : 'meters'}',
                      ),
                    ),
                    for (var i = 0; i < reading.meters.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _buildEntry(reading.meters[i]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: MeterSaveBar(
          submitting: _submitting,
          onSave: _submit,
          filled: _filledCount,
          total: reading.meters.length,
        ),
      ),
    );
  }

  Widget _buildEntry(InstalledMeter meter) {
    final draft = _drafts[meter.id]!;

    return MeterEntryCard(
      meter: meter,
      valueController: draft.value,
      remarkController: draft.remark,
      photo: draft.photo,
      errorText: _errorFor(meter),
      photoError: draft.photoError,
      usage: _usageFor(meter),
      enabled: !_submitting,
      // Pemakaian dan galat dihitung ulang tiap ketikan.
      onChanged: () => setState(() {}),
      onPickPhoto: () => _pickPhoto(meter),
      onRemovePhoto: () => setState(() {
        draft.photo = null;
        draft.photoError = null;
      }),
    );
  }
}

/// Ringkasan "untuk apa form ini": siapa, di mana, kontrak mana.
class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.reading});

  final MeterReading reading;

  @override
  Widget build(BuildContext context) {
    final representative = reading.biieRepresentative;

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
          _InfoLine(icon: Icons.description_outlined, text: reading.contractNumber),
          if (representative != null) ...[
            const SizedBox(height: 8),
            _InfoLine(icon: Icons.person_outline_rounded, text: 'BIIE · $representative'),
          ],
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
                Expanded(
                  child: Text(
                    'Enter today\'s reading for each meter. The previous value is '
                    'carried forward and usage is calculated for you.',
                    style: AppTextStyles.caption,
                  ),
                ),
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
