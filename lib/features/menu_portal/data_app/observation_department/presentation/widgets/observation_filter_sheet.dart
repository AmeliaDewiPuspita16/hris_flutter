import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_dropdown.dart';
import '../../data/observation_repository.dart';
import '../../domain/observation_category.dart';
import '../../domain/observation_filter.dart';

/// Bottom sheet "Filter" untuk tab All Observations: Month, Relevant Dept.,
/// Category — tiga filter yang sama dengan tabel di web. Mengembalikan
/// [ObservationFilter] saat "Apply" ditekan, atau null bila ditutup tanpa
/// menerapkan. "Reset" hanya mengosongkan pilihan di sheet; baru berlaku
/// setelah Apply.
class ObservationFilterSheet extends StatefulWidget {
  const ObservationFilterSheet({
    super.key,
    required this.initial,
    required this.months,
  });

  final ObservationFilter initial;

  /// Bulan yang ada di data (pilihan "Month").
  final List<DateTime> months;

  static Future<ObservationFilter?> show(
    BuildContext context, {
    required ObservationFilter initial,
    required List<DateTime> months,
  }) {
    return showModalBottomSheet<ObservationFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ObservationFilterSheet(initial: initial, months: months),
    );
  }

  @override
  State<ObservationFilterSheet> createState() => _ObservationFilterSheetState();
}

class _ObservationFilterSheetState extends State<ObservationFilterSheet> {
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December', //
  ];

  /// Kunci "tidak dipilih" untuk dropdown (AppDropdown butuh nilai non-null).
  static const _all = '';

  late String _month = widget.initial.month == null
      ? _all
      : _monthKey(widget.initial.month!);
  late String _dept = widget.initial.relevantDept ?? _all;
  late String _category = widget.initial.category?.name ?? _all;

  static String _monthKey(DateTime d) => '${d.year}-${d.month}';

  static String _monthLabel(DateTime d) => '${_monthNames[d.month - 1]} ${d.year}';

  ObservationFilter _build() {
    DateTime? month;
    for (final m in widget.months) {
      if (_monthKey(m) == _month) month = m;
    }
    ObservationCategory? category;
    for (final c in ObservationCategory.values) {
      if (c.name == _category) category = c;
    }
    return ObservationFilter(
      month: month,
      relevantDept: _dept == _all ? null : _dept,
      category: category,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
              Row(
                children: [
                  Expanded(
                    child: Text('Filter', style: AppTextStyles.sectionTitle),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _month = _all;
                      _dept = _all;
                      _category = _all;
                    }),
                    child: Text(
                      'Reset',
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.primaryText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppDropdown<String>(
                label: 'Month',
                value: _month,
                items: [
                  (value: _all, label: 'All Months'),
                  for (final m in widget.months)
                    (value: _monthKey(m), label: _monthLabel(m)),
                ],
                onChanged: (v) => setState(() => _month = v),
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'Relevant Dept.',
                value: _dept,
                items: [
                  (value: _all, label: 'All Departments'),
                  for (final d in ObservationRepository.departments)
                    (value: d, label: d),
                ],
                onChanged: (v) => setState(() => _dept = v),
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'Category',
                value: _category,
                items: [
                  (value: _all, label: 'All Categories'),
                  for (final c in ObservationCategory.values)
                    (value: c.name, label: c.label),
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_build()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style:
                        AppTextStyles.buttonText.copyWith(color: Colors.white),
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
