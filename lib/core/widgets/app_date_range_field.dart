import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/date_formatter.dart';
import 'field_label_row.dart';

/// Field rentang tanggal (mulai - selesai) dalam satu kontrol.
/// Menggantikan dua AppTextField terpisah untuk cuti tahunan.
class AppDateRangeField extends StatelessWidget {
  const AppDateRangeField({
    super.key,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime start, DateTime end) onChanged;
  final bool required;

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<({DateTime start, DateTime end})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RangeCalendarSheet(initialStart: startDate, initialEnd: endDate),
    );

    if (result != null) onChanged(result.start, result.end);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = startDate != null && endDate != null;
    final dayCount = hasValue ? endDate!.difference(startDate!).inDays + 1 : null;

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
                Expanded(
                  child: hasValue
                      ? Row(
                          children: [
                            Text(
                              DateFormatter.shortDateID(startDate!),
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              DateFormatter.shortDateID(endDate!),
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      : Text(
                          'Pilih rentang tanggal',
                          style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                        ),
                ),
                if (dayCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.presentBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$dayCount hari',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
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

class _RangeCalendarSheet extends StatefulWidget {
  const _RangeCalendarSheet({this.initialStart, this.initialEnd});

  final DateTime? initialStart;
  final DateTime? initialEnd;

  @override
  State<_RangeCalendarSheet> createState() => _RangeCalendarSheetState();
}

class _RangeCalendarSheetState extends State<_RangeCalendarSheet> {
  late DateTime _focusedDay = widget.initialStart ?? DateTime.now();
  DateTime? _rangeStart = null;
  DateTime? _rangeEnd = null;

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.initialStart;
    _rangeEnd = widget.initialEnd;
  }

  @override
  Widget build(BuildContext context) {
    final dayCount =
        (_rangeStart != null && _rangeEnd != null) ? _rangeEnd!.difference(_rangeStart!).inDays + 1 : null;

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
            Row(
              children: [
                const Text('Pilih Rentang Tanggal', style: AppTextStyles.sectionTitle),
                const Spacer(),
                if (dayCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.presentBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$dayCount hari',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
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
                rangeStartDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                rangeEndDecoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                rangeStartTextStyle: TextStyle(color: Colors.white, fontSize: 13),
                rangeEndTextStyle: TextStyle(color: Colors.white, fontSize: 13),
                withinRangeDecoration: BoxDecoration(color: AppColors.presentBg, shape: BoxShape.circle),
                withinRangeTextStyle: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
              onRangeSelected: (start, end, focused) {
                setState(() {
                  _rangeStart = start;
                  _rangeEnd = end ?? start;
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
                    onPressed: (_rangeStart != null && _rangeEnd != null)
                        ? () => Navigator.pop(context, (start: _rangeStart!, end: _rangeEnd!))
                        : null,
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
