import 'package:flutter/material.dart';

import '../../../../../../../core/logging/app_logger.dart';
import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_text_field.dart';

const _ratingLabels = {
  1: 'Very Dissatisfied',
  2: 'Dissatisfied',
  3: 'Fair',
  4: 'Satisfied',
  5: 'Very Satisfied',
};

/// Bottom sheet verifikasi + rating 1–5 bintang untuk Work Order yang sudah
/// selesai dikerjakan.
///
/// Pemanggil menyerahkan [onSubmit] yang mengirim ke server. Sheet
/// menampilkan loading selama menunggu, dan bila gagal tetap terbuka dengan
/// pesan galat supaya requester bisa mencoba lagi. Mengembalikan `true` lewat
/// Navigator.pop bila terkirim, atau null bila ditutup tanpa submit.
///
/// Catatan WAJIB diisi (maks 1000 karakter) — mengikuti
/// `POST /est_work_order/{id}/rating`.
class EstRequestFeedbackSheet extends StatefulWidget {
  const EstRequestFeedbackSheet({
    super.key,
    required this.description,
    required this.onSubmit,
  });

  /// Ringkasan WO untuk subjudul sheet, mis. `Repair · Gate 2`.
  final String description;

  /// Mengirim bintang + catatan. Melempar [ApiException] bila gagal; pesannya
  /// ditampilkan di sheet.
  final Future<void> Function(int star, String message) onSubmit;

  @override
  State<EstRequestFeedbackSheet> createState() =>
      _EstRequestFeedbackSheetState();
}

class _EstRequestFeedbackSheetState extends State<EstRequestFeedbackSheet> {
  static const int _maxMessageLength = 1000;

  int _rating = 0;
  final _noteController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0 || _sending) return;

    final note = _noteController.text.trim();
    if (note.isEmpty) {
      setState(() => _error = 'Please write a short note about the result.');
      return;
    }
    if (note.length > _maxMessageLength) {
      setState(() => _error = 'Notes must not exceed $_maxMessageLength characters.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await widget.onSubmit(_rating, note);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (e, stack) {
      AppLogger.error('Kirim rating EST gagal karena galat tak terduga', e, stack);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Text('Verify & give feedback',
                    style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      InkWell(
                        onTap: _sending ? null : () => setState(() => _rating = i),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            i <= _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 32,
                            color: i <= _rating ? AppColors.accent : AppColors.border,
                          ),
                        ),
                      ),
                  ],
                ),
                if (_rating > 0) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _ratingLabels[_rating]!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Notes',
                  controller: _noteController,
                  hint: 'Tell us about the result...',
                  maxLines: 3,
                  minLines: 1,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.rejected,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: (_rating == 0 || _sending) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Send Feedback',
                            style: AppTextStyles.buttonText
                                .copyWith(color: Colors.white),
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
