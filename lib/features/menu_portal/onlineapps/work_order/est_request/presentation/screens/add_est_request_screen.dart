import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../../../../../../core/widgets/field_label_row.dart';
import '../../data/est_request_repository.dart';
import '../../domain/est_request_item.dart';
import '../../domain/est_request_photo.dart';
import '../../domain/est_request_type.dart';
import '../widgets/est_photo_upload_field.dart';
import '../widgets/request_type_selector.dart';

/// Layar "+ Add Request", sekaligus form edit bila [initialItem] diisi.
///
/// Mode tambah mengirim ke `POST /est_work_order`; mode edit ke
/// `POST /est_work_order/{id}` (multipart, foto opsional) lewat
/// [EstRequestRepository]. Menutup diri dengan `true` lewat Navigator.pop
/// kalau tersimpan di server (pemanggil lalu memuat ulang), atau null kalau
/// ditutup tanpa submit. Pola sama dengan `AddIndentScreen`.
///
/// Galat ditangani dengan setState lokal (bukan bloc) — aksi sekali-jalan
/// yang terikat ke satu layar, pola sama dengan `AddIndentScreen`. Nama &
/// departemen requester tidak perlu dikirim: server memakai user yang login.
class AddEstRequestScreen extends StatefulWidget {
  const AddEstRequestScreen({
    super.key,
    this.repository,
    this.pickPhoto,
    this.initialItem,
  });

  final EstRequestRepository? repository;

  /// Null = mode tambah. Diisi = mode edit untuk request ini.
  final EstRequestItem? initialItem;

  /// Null berarti memakai galeri sungguhan lewat image_picker.
  final EstPhotoPicker? pickPhoto;

  @override
  State<AddEstRequestScreen> createState() => _AddEstRequestScreenState();
}

class _AddEstRequestScreenState extends State<AddEstRequestScreen> {
  static const int _maxLocationLength = 255;

  late final EstRequestRepository _repository;

  EstRequestType? _type = EstRequestType.repair;
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  EstRequestPhoto? _photo;
  String? _photoError;
  bool _submitting = false;

  /// Mode edit: foto yang sudah ada di server, dan apakah user memintanya
  /// dihapus. Foto baru ([_photo]) menggantikan foto lama.
  String? _existingImageUrl;
  bool _removeExisting = false;

  bool get _isEdit => widget.initialItem != null;

  /// Nama yang ditampilkan di field foto; null = belum ada foto sama sekali.
  String? get _photoLabel {
    if (_photo != null) return _photo!.fileName;
    if (_existingImageUrl != null && !_removeExisting) return 'Current photo';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<EstRequestRepository>();

    final item = widget.initialItem;
    if (item != null) {
      _type = EstRequestType.values.firstWhere(
        (t) => t.label == item.type,
        orElse: () => EstRequestType.repair,
      );
      _locationController.text = item.location;
      _descriptionController.text = item.description;
      _existingImageUrl = item.imageUrl;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_type == null) return 'Please select type of request.';
    final location = _locationController.text.trim();
    if (location.isEmpty) return 'Please fill in the location.';
    if (location.length > _maxLocationLength) {
      return 'Location must not exceed $_maxLocationLength characters.';
    }
    if (_descriptionController.text.trim().isEmpty) {
      return 'Please fill in the description.';
    }
    return null;
  }

  Future<EstRequestPhoto?> _pickFromGallery() async {
    // Dikecilkan sedikit supaya foto kamera (sering > 2 MB) lolos batas server.
    final file = await picker.ImagePicker().pickImage(
      source: picker.ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return null;

    return EstRequestPhoto(
      path: file.path,
      fileName: file.name,
      sizeBytes: await file.length(),
    );
  }

  /// Ketuk saat belum ada foto: buka galeri. Ketuk saat sudah ada: hapus
  /// (di mode edit, foto lama di server ikut ditandai untuk dihapus).
  Future<void> _onPhotoTap() async {
    if (_submitting) return;

    if (_photoLabel != null) {
      setState(() {
        _photo = null;
        _photoError = null;
        if (_existingImageUrl != null) _removeExisting = true;
      });
      return;
    }

    final pick = widget.pickPhoto ?? _pickFromGallery;

    final EstRequestPhoto? picked;
    try {
      picked = await pick();
    } catch (e, stack) {
      AppLogger.error('Gagal membuka galeri untuk EST request', e, stack);
      if (mounted) setState(() => _photoError = 'Unable to open the gallery.');
      return;
    }

    if (!mounted || picked == null) return;

    final error = picked.validationError;
    setState(() {
      _photoError = error;
      _photo = error == null ? picked : null;
      // Foto baru menggantikan foto lama, jadi tidak perlu `remove_image`.
      if (_photo != null) _removeExisting = false;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _submitting = true);
    try {
      if (_isEdit) {
        await _repository.update(
          widget.initialItem!.id,
          type: _type!,
          location: _locationController.text,
          description: _descriptionController.text,
          imagePath: _photo?.path,
          removeImage: _removeExisting,
        );
      } else {
        await _repository.create(
          type: _type!,
          location: _locationController.text,
          description: _descriptionController.text,
          imagePath: _photo?.path,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, stack) {
      AppLogger.error(
        '${_isEdit ? 'Edit' : 'Submit'} EST request gagal karena galat tak terduga',
        e,
        stack,
      );
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
        title: _isEdit ? 'Edit Request' : 'Add Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FieldLabelRow(label: 'Type of request'),
                RequestTypeSelector(
                  value: _type,
                  onChanged: (v) {
                    if (!_submitting) setState(() => _type = v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const FieldLabelRow(label: 'Location', required: true),
          TextField(
            controller: _locationController,
            enabled: !_submitting,
            maxLength: _maxLocationLength,
            style: AppTextStyles.body,
            decoration: _fieldDecoration('e.g. Block 3, unit 8')
                .copyWith(counterText: ''),
          ),
          const SizedBox(height: 18),
          const FieldLabelRow(label: 'Description', required: true),
          TextField(
            controller: _descriptionController,
            enabled: !_submitting,
            minLines: 4,
            maxLines: null,
            style: AppTextStyles.body,
            decoration: _fieldDecoration('Describe your request in detail'),
          ),
          const SizedBox(height: 18),
          const FieldLabelRow(label: 'Photo'),
          EstPhotoUploadField(
            fileName: _photoLabel,
            onTap: _onPhotoTap,
          ),
          if (_photoError != null) ...[
            const SizedBox(height: 6),
            Text(
              _photoError!,
              style: AppTextStyles.caption.copyWith(color: Colors.red.shade700),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
