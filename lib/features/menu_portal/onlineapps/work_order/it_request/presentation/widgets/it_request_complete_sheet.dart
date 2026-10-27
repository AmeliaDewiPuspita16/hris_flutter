import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import '../../data/it_request_repository.dart';
import '../../domain/it_request_attachment.dart';
import '../../domain/it_request_detail.dart';

/// Bottom sheet penutupan request tim IT untuk request yang "On Progress",
/// dibuka dari [ItRequestDetailScreen] saat `mode` tim IT aktif.
///
/// Foto bukti pengerjaan wajib (lih. dokumentasi
/// `POST .../complete`); catatan opsional. Memanggil
/// `ItRequestRepository.complete` sendiri (pola sama dengan
/// `ItRequestFeedbackSheet`/`ItRequestRespondSheet`) dan mengembalikan
/// [ItRequestDetail] terbaru dari server lewat Navigator.pop kalau berhasil
/// — status server berubah jadi "Wait Checked".
class ItRequestCompleteSheet extends StatefulWidget {
  const ItRequestCompleteSheet({
    super.key,
    required this.detail,
    this.repository,
    this.pickAttachment,
  });

  final ItRequestDetail detail;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ItRequestRepository? repository;

  /// Null berarti memakai galeri sungguhan lewat image_picker.
  final AttachmentPicker? pickAttachment;

  @override
  State<ItRequestCompleteSheet> createState() => _ItRequestCompleteSheetState();
}

class _ItRequestCompleteSheetState extends State<ItRequestCompleteSheet> {
  late final ItRequestRepository _repository;
  final _noteController = TextEditingController();

  ItRequestAttachment? _photo;
  String? _photoError;

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<ItRequestRepository>();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<ItRequestAttachment?> _pickFromGallery() async {
    final file = await picker.ImagePicker().pickImage(source: picker.ImageSource.gallery);
    if (file == null) return null;

    return ItRequestAttachment(
      path: file.path,
      fileName: file.name,
      sizeBytes: await file.length(),
    );
  }

  Future<void> _pickPhoto() async {
    if (_submitting) return;

    if (_photo != null) {
      setState(() {
        _photo = null;
        _photoError = null;
      });
      return;
    }

    final pick = widget.pickAttachment ?? _pickFromGallery;

    final ItRequestAttachment? picked;
    try {
      picked = await pick();
    } catch (e) {
      if (mounted) setState(() => _photoError = 'Unable to open the gallery.');
      return;
    }

    if (!mounted || picked == null) return;

    final error = picked.validationError;
    setState(() {
      if (error != null) {
        _photoError = error;
      } else {
        _photo = picked;
        _photoError = null;
      }
    });
  }

  Future<void> _submit() async {
    final photo = _photo;
    if (photo == null || _submitting) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final note = _noteController.text.trim();
      final updated = await _repository.complete(
        widget.detail.id,
        photoPath: photo.path,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;

    return Padding(
      // Naik mengikuti keyboard supaya field catatan tidak ketutupan.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('Finish Request', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                if (detail.requester != null)
                  Text(
                    '${detail.requester!.name} · ${detail.requester!.department}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  detail.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'IT Notes (optional)',
                  controller: _noteController,
                  hint: 'Write completion notes, solution provided...',
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 16),
                Text(
                  'COMPLETION PHOTO EVIDENCE (REQUIRED)',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppColors.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                _PhotoField(
                  fileName: _photo?.fileName,
                  onTap: _submitting ? () {} : _pickPhoto,
                ),
                if (_photoError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _photoError!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.rejected),
                  ),
                ],
                if (_submitError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _submitError!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.rejected),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _photo == null || _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.present,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Complete Request',
                            style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoField extends StatelessWidget {
  const _PhotoField({required this.fileName, required this.onTap});

  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                hasFile ? Icons.insert_drive_file_outlined : Icons.image_outlined,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasFile ? fileName! : 'Click to select photo evidence',
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              hasFile ? Icons.close : Icons.file_upload_outlined,
              size: 16,
              color: hasFile ? AppColors.textMuted : AppColors.present,
            ),
          ],
        ),
      ),
    );
  }
}
