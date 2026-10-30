import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import '../../data/it_request_repository.dart';
import '../../domain/it_request_detail.dart';

/// Bottom sheet respons tim IT untuk request yang masih "On Waiting",
/// dibuka dari [ItRequestDetailScreen] saat `mode` tim IT aktif.
///
/// Memanggil `ItRequestRepository.respond` sendiri (pola sama dengan
/// `ItRequestFeedbackSheet`/`submitRating`) dan mengembalikan
/// [ItRequestDetail] terbaru dari server lewat Navigator.pop kalau berhasil
/// — server otomatis mengubah status jadi "On Progress", jadi badge di
/// layar detail langsung ikut berubah tanpa fetch ulang.
class ItRequestRespondSheet extends StatefulWidget {
  const ItRequestRespondSheet({super.key, required this.detail, this.repository});

  final ItRequestDetail detail;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ItRequestRepository? repository;

  @override
  State<ItRequestRespondSheet> createState() => _ItRequestRespondSheetState();
}

class _ItRequestRespondSheetState extends State<ItRequestRespondSheet> {
  late final ItRequestRepository _repository;
  final _noteController = TextEditingController();

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? context.read<ItRequestRepository>();
    // Tombol Submit aktif/nonaktif mengikuti isi catatan — perlu rebuild
    // manual karena TextEditingController tidak memicu build sendiri.
    _noteController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    if (note.isEmpty || _submitting) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final updated = await _repository.respond(widget.detail.id, note: note);
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
                Text('Respond Request', style: AppTextStyles.sectionTitle),
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
                  label: 'IT Response',
                  controller: _noteController,
                  hint: 'Write response for this request...',
                  maxLines: 3,
                  minLines: 1,
                ),
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
                    onPressed:
                        _noteController.text.trim().isEmpty || _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
                            'Submit',
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
