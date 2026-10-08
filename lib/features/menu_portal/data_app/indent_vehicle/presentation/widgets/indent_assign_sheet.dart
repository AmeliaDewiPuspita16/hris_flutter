import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/field_label_row.dart';
import '../../domain/indent_assign_result.dart';
import '../../domain/indent_pending_demo_data.dart';
import '../../domain/indent_pending_item.dart';

/// Bottom sheet "Assign Vehicle", dibuka lewat
/// tombol Assign di [IndentPendingCard].
///
/// Isinya bergantung pada [IndentPendingItem.withDriver]:
/// - true  → Plate Number + Driver (dua-duanya wajib)
/// - false → Plate Number saja (field Driver disembunyikan)
///
/// Mengembalikan [IndentAssignResult] lewat Navigator.pop kalau admin menekan
/// Assign, atau null kalau sheet ditutup tanpa assign.
class IndentAssignSheet extends StatefulWidget {
  const IndentAssignSheet({super.key, required this.item});

  final IndentPendingItem item;

  @override
  State<IndentAssignSheet> createState() => _IndentAssignSheetState();
}

class _IndentAssignSheetState extends State<IndentAssignSheet> {
  final _plateController = TextEditingController();
  String? _driver;

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  /// Tombol Assign baru aktif kalau semua field wajib sudah terisi.
  bool get _canSubmit =>
      _plateController.text.trim().isNotEmpty &&
      (!widget.item.withDriver || _driver != null);

  void _submit() {
    Navigator.of(context).pop(
      IndentAssignResult(
        plateNumber: _plateController.text.trim().toUpperCase(),
        driver: widget.item.withDriver ? _driver : null,
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
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
    return Padding(
      // Naikkan sheet setinggi keyboard supaya field tidak tertutup.
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
              const Text('Assign Vehicle', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 4),
              Text(
                '${widget.item.name} · ${widget.item.destination}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
              const FieldLabelRow(label: 'Plate Number', required: true),
              TextField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
                style: AppTextStyles.body,
                decoration: _decoration('e.g. B 1234 ABC'),
              ),
              if (widget.item.withDriver) ...[
                const SizedBox(height: 16),
                const FieldLabelRow(label: 'Driver', required: true),
                DropdownButtonFormField<String>(
                  value: _driver,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  style: AppTextStyles.body,
                  decoration: _decoration('-- Select Driver --'),
                  items: [
                    for (final d in IndentPendingDemoData.drivers)
                      DropdownMenuItem(value: d, child: Text(d)),
                  ],
                  onChanged: (v) => setState(() => _driver = v),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Assign',
                    style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textMuted,
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
