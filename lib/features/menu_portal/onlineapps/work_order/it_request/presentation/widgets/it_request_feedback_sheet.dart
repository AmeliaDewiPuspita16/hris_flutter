import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/date_formatter.dart';
import '../../../../../../../core/widgets/app_text_field.dart';
import '../../data/it_request_repository.dart';
import '../../domain/it_request_detail.dart';

const _ratingLabels = {
  1: 'Sangat Kecewa',
  2: 'Kecewa',
  3: 'Cukup',
  4: 'Puas',
  5: 'Sangat Puas',
};

/// Bottom sheet rating 1–5 bintang + catatan opsional, dibuka lewat tombol
/// "Beri Feedback" di [ItRequestFeedbackBanner].
///
/// Menampilkan konteks request (kategori, jenis, tanggal diajukan) dan
/// ringkasan pengerjaan tim IT (kalau ada) supaya staff ingat apa yang
/// sedang dinilai — [detail] karena itu harus rincian PENUH (lewat
/// `ItRequestRepository.fetchDetail`), bukan cuma item dari daftar yang
/// tidak membawa `handling`.
///
/// Memanggil `ItRequestRepository.submitRating` sendiri (pola sama dengan
/// `AddItRequestScreen`) dan mengembalikan [ItRequestDetail] terbaru dari
/// server lewat Navigator.pop kalau berhasil, atau null kalau sheet ditutup
/// tanpa submit.
class ItRequestFeedbackSheet extends StatefulWidget {
  const ItRequestFeedbackSheet({super.key, required this.detail, this.repository});

  final ItRequestDetail detail;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final ItRequestRepository? repository;

  @override
  State<ItRequestFeedbackSheet> createState() => _ItRequestFeedbackSheetState();
}

class _ItRequestFeedbackSheetState extends State<ItRequestFeedbackSheet> {
  late final ItRequestRepository _repository;

  int _rating = 0;
  final _noteController = TextEditingController();

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

  Future<void> _submit() async {
    if (_rating == 0 || _submitting) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final note = _noteController.text.trim();
      final updated = await _repository.submitRating(
        widget.detail.id,
        star: _rating,
        message: note.isEmpty ? null : note,
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
    final handling = detail.handling;

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
                const Text('Beri feedback', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                Text(
                  detail.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(label: '${detail.type.label} · ${detail.category.label}'),
                    _Chip(label: DateFormatter.shortDate(detail.createdAt)),
                  ],
                ),
                if (handling != null &&
                    (handling.workBy != null || handling.note != null)) ...[
                  const SizedBox(height: 14),
                  _HandlingSummary(workBy: handling.workBy, note: handling.note),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      InkWell(
                        onTap: _submitting ? null : () => setState(() => _rating = i),
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
                  label: 'Catatan (opsional)',
                  controller: _noteController,
                  hint: 'Ceritakan hasil pengerjaannya...',
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
                    onPressed: _rating == 0 || _submitting ? null : _submit,
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
                            'Kirim Feedback',
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

class _HandlingSummary extends StatelessWidget {
  const _HandlingSummary({this.workBy, this.note});

  final String? workBy;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (workBy != null)
            Text(
              'Dikerjakan oleh: $workBy',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textMid,
              ),
            ),
          if (note != null) ...[
            if (workBy != null) const SizedBox(height: 4),
            Text(
              note!,
              style: AppTextStyles.caption.copyWith(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMid,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
