import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/widgets/app_text_field.dart';

/// Bottom sheet rating 1–5 bintang + catatan opsional, dibuka lewat tombol
/// "Beri Feedback" di [EstRequestFeedbackBanner] lihat catatan konvensi di banner-nya.
///
/// Mengembalikan rating (1–5) lewat Navigator.pop kalau requester submit,
/// atau null kalau sheet ditutup tanpa submit.
class EstRequestFeedbackSheet extends StatefulWidget {
  const EstRequestFeedbackSheet({super.key, required this.description});

  final String description;

  @override
  State<EstRequestFeedbackSheet> createState() => _EstRequestFeedbackSheetState();
}

class _EstRequestFeedbackSheetState extends State<EstRequestFeedbackSheet> {
  int _rating = 0;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
          ),
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
              const Text('Beri feedback', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 4),
              Text(
                widget.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
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
                          i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 32,
                          color: i <= _rating ? AppColors.accent : AppColors.border,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Catatan (opsional)',
                controller: _noteController,
                hint: 'Ceritakan hasil pengerjaannya...',
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _rating == 0
                      ? null
                      : () => Navigator.of(context).pop(_rating),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Kirim Feedback',
                    style: AppTextStyles.buttonText.copyWith(color: Colors.white),
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
