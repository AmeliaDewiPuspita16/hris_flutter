import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../domain/indent_request_item.dart';

const _ratingLabels = {
  1: 'Very Dissatisfied',
  2: 'Dissatisfied',
  3: 'Fair',
  4: 'Satisfied',
  5: 'Very Satisfied',
};

/// Bottom sheet rating 1–5 bintang + catatan opsional.
///
/// Mengembalikan ({int rating, String? note}) lewat Navigator.pop, atau null
/// kalau sheet ditutup tanpa submit.
///
/// TODO(api): saat endpoint feedback Indent tersedia, panggil repository di
/// sini (pola sama dengan ItRequestFeedbackSheet.submitRating) dan tampilkan
/// loading + error. Sekarang cuma mengembalikan nilainya ke layar.
class IndentFeedbackSheet extends StatefulWidget {
  const IndentFeedbackSheet({super.key, required this.item});

  final IndentRequestItem item;

  @override
  State<IndentFeedbackSheet> createState() => _IndentFeedbackSheetState();
}

class _IndentFeedbackSheetState extends State<IndentFeedbackSheet> {
  int _rating = 0;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) return;
    final note = _noteController.text.trim();
    Navigator.of(context).pop((rating: _rating, note: note.isEmpty ? null : note));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

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
                const Text('Give feedback', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                Text(
                  '${item.destination} · ${item.date}',
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
                        onTap: () => setState(() => _rating = i),
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
                  label: 'Notes (optional)',
                  controller: _noteController,
                  hint: 'Tell us about your trip...',
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _rating == 0 ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Send Feedback',
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
