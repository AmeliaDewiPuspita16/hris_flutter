import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/date_formatter.dart';
import 'field_label_row.dart';

/// Field tanggal tunggal. Tap untuk membuka bottom sheet kalender
/// minimalis (table_calendar), menggantikan input teks manual DD/MM/YYYY.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool required;

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DateCalendarSheet(initial: value),
    );

    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelRow(label: label, required: required),
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasValue ? AppColors.primaryMid : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: hasValue ? AppColors.primaryMid : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  hasValue ? DateFormatter.shortDateID(value!) : 'Select date',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    color: hasValue ? AppColors.text : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateCalendarSheet extends StatefulWidget {
  const _DateCalendarSheet({this.initial});

  final DateTime? initial;

  @override
  State<_DateCalendarSheet> createState() => _DateCalendarSheetState();
}

class _DateCalendarSheetState extends State<_DateCalendarSheet> {
  late DateTime _focusedDay;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initial ?? DateTime.now();
    _selected = widget.initial;
  }
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Pilih Tanggal', style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => _selected != null && isSameDay(day, _selected),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
                titleTextFormatter: (date, _) => DateFormatter.monthYearID(date),
                leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.textMuted, size: 20),
                rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (date, _) => DateFormatter.shortDayID(date),
                weekdayStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                weekendStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(fontSize: 13),
                weekendTextStyle: TextStyle(fontSize: 13),
                todayDecoration: BoxDecoration(
                  border: Border.fromBorderSide(BorderSide(color: AppColors.primaryMid, width: 1.5)),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: AppColors.primary, fontSize: 13),
                selectedDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                selectedTextStyle: TextStyle(color: Colors.white, fontSize: 13),
              ),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selected = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) {
                _focusedDay = focused;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _selected != null ? () => Navigator.pop(context, _selected) : null,
                    child: const Text('Konfirmasi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
