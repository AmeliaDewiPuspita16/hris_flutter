import 'package:flutter/material.dart';

import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_attachment_field.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../data/hse_work_request_repository.dart';
import 'hse_file_picker.dart';

/// Bottom sheet "Tutup Permit": deskripsi + evidence (foto/PDF), dikirim ke
/// `POST /hse_permit/{id}/close`. Pop dengan [HsePermitResult] bila
/// berhasil, null bila ditutup.
class HseClosePermitSheet extends StatefulWidget {
  const HseClosePermitSheet({
    super.key,
    required this.permitId,
    required this.repository,
  });

  final int permitId;
  final HseWorkRequestRepository repository;

  static const _extensions = ['jpeg', 'jpg', 'png', 'gif', 'pdf'];
  static const _maxKb = 10240;

  @override
  State<HseClosePermitSheet> createState() => _HseClosePermitSheetState();
}

class _HseClosePermitSheetState extends State<HseClosePermitSheet> {
  final _descriptionController = TextEditingController();
  HsePickedFile? _evidence;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _toggleEvidence() async {
    if (_submitting) return;
    if (_evidence != null) {
      setState(() => _evidence = null);
      return;
    }
    try {
      final picked = await pickHseFile(HseClosePermitSheet._extensions);
      if (picked == null || !mounted) return;
      final sizeError = hseFileSizeError(picked, HseClosePermitSheet._maxKb);
      setState(() {
        _evidence = sizeError == null ? picked : null;
        _error = sizeError;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to open the file picker.');
      }
    }
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty || _evidence == null) {
      setState(() => _error = 'Enter a description and attach evidence.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.repository.close(
        widget.permitId,
        description: description,
        evidencePath: _evidence!.path,
      );
      if (mounted) Navigator.of(context).pop(result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to close the permit. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Close Permit',
                    style: AppTextStyles.h2.copyWith(fontSize: 17)),
                const SizedBox(height: 4),
                Text(
                  'Attach proof that the work is finished. The permit status will change to Done.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  required: true,
                  hint: 'e.g. Work completed, area cleaned up',
                  maxLines: 4,
                  minLines: 3,
                ),
                const SizedBox(height: 14),
                AppAttachmentField(
                  label: 'Evidence',
                  required: true,
                  fileName: _evidence?.name,
                  onTap: _toggleEvidence,
                  hint: 'JPG, PNG, GIF, or PDF — max 10 MB',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.rejected),
                  ),
                ],
                const SizedBox(height: 20),
                AppButton(
                  label: 'Close Permit',
                  isLoading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
