import 'package:flutter/material.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../data/observation_repository.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../domain/observation_item.dart';
import 'observation_image_field.dart';

/// Bottom sheet "Close Observation": ringkasan observasi, alasan penutupan
/// (wajib), dan foto opsional. Pop dengan [ObservationItem] yang sudah
/// closed bila berhasil, null bila ditutup.
class ObservationCloseSheet extends StatefulWidget {
  const ObservationCloseSheet({
    super.key,
    required this.item,
    required this.repository,
  });

  final ObservationItem item;
  final ObservationRepository repository;

  static Future<ObservationItem?> show(
    BuildContext context, {
    required ObservationItem item,
    required ObservationRepository repository,
  }) {
    return showModalBottomSheet<ObservationItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ObservationCloseSheet(item: item, repository: repository),
    );
  }

  @override
  State<ObservationCloseSheet> createState() => _ObservationCloseSheetState();
}

class _ObservationCloseSheetState extends State<ObservationCloseSheet> {
  final _reasonController = TextEditingController();
  String? _imagePath;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Please enter the reason for closing.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final closed = await widget.repository.close(
        widget.item.id,
        reason: reason,
        imagePath: _imagePath,
      );
      if (mounted) Navigator.of(context).pop(closed);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e, stack) {
      AppLogger.error('Close observation gagal tak terduga', e, stack);
      if (mounted) {
        setState(() => _error = 'Failed to close the observation. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

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
                Text('Close Observation',
                    style: AppTextStyles.h2.copyWith(fontSize: 17)),
                const SizedBox(height: 4),
                Text(
                  'Explain how this finding was resolved. The status will change to Closed.',
                  style: AppTextStyles.bodyMuted,
                ),
                const SizedBox(height: 14),
                // Ringkasan observasi — di web ada di kartu "Observation
                // Summary"; di sini jadi satu-satunya tempat melihat isi
                // observasi yang masih open.
                _Summary(item: item),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Reason close',
                  controller: _reasonController,
                  required: true,
                  hint: 'Reason for closing the observation',
                  // Mulai satu baris, memanjang mengikuti isi (maks 10 baris,
                  // lalu menggulir di dalam field).
                  minLines: 1,
                  maxLines: 10,
                ),
                const SizedBox(height: 14),
                ObservationImageField(
                  label: 'Image (optional)',
                  path: _imagePath,
                  onChanged: (p) => setState(() {
                    _imagePath = p;
                    _error = null;
                  }),
                  onError: (m) => setState(() => _error = m),
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
                  label: 'Submit',
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

/// Kartu "Observation Summary": Category, Relevant Department, Date Finding,
/// Location, Description — urutan sama dengan halaman Close di web.
class _Summary extends StatelessWidget {
  const _Summary({required this.item});

  final ObservationItem item;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('CATEGORY', item.categoryLabel),
      ('RELEVANT DEPARTMENT', item.relevantDept),
      ('DATE FINDING', DateFormatter.shortDate(item.createdDate)),
      ('LOCATION', item.location),
      ('DESCRIPTION', item.description),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: item.category.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.category.icon, size: 16, color: item.category.color),
              const SizedBox(width: 8),
              Text(
                'OBSERVATION SUMMARY',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Text(
              rows[i].$1,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              rows[i].$2,
              style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
