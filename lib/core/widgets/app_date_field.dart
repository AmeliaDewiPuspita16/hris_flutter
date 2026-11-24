import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/date_formatter.dart';
import 'field_label_row.dart';

/// Field tanggal tunggal. Tap untuk membuka bottom sheet kalender modern
/// (digambar sendiri dengan widget material_ui, tanpa paket kalender pihak
/// ketiga), menggantikan input teks manual DD/MM/YYYY.
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

  /// Buka bottom sheet kalender. Null bila dibatalkan. Dipakai juga oleh
  /// form yang membuat tampilan kolomnya sendiri (mis. Add Indent).
  static Future<DateTime?> pick(BuildContext context, {DateTime? initial}) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DateCalendarSheet(initial: initial),
    );
  }

  Future<void> _open(BuildContext context) async {
    final result = await pick(context, initial: value);
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
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasValue ? AppColors.primaryMidText : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color:
                      hasValue ? AppColors.primaryMidText : AppColors.textMuted,
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
  late final DateTime _today;
  late DateTime _firstDate;
  late DateTime _lastDate;
  late DateTime _month; // selalu tanggal 1 pada bulan yang sedang tampil
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _today = DateUtils.dateOnly(DateTime.now());

    // Rentang pilih: 1 tahun ke belakang & ke depan. Tanggal lama dari mode
    // edit yang di luar rentang tetap dimasukkan.
    _firstDate = _today.subtract(const Duration(days: 365));
    _lastDate = _today.add(const Duration(days: 365));
    final initial =
        widget.initial == null ? null : DateUtils.dateOnly(widget.initial!);
    if (initial != null) {
      if (initial.isBefore(_firstDate)) _firstDate = initial;
      if (initial.isAfter(_lastDate)) _lastDate = initial;
    }

    _selected = initial;
    final focus = initial ?? _today;
    _month = DateTime(focus.year, focus.month);
  }

  bool get _canPrev =>
      _month.isAfter(DateTime(_firstDate.year, _firstDate.month));

  bool get _canNext =>
      _month.isBefore(DateTime(_lastDate.year, _lastDate.month));

  bool get _todayInRange =>
      !_today.isBefore(_firstDate) && !_today.isAfter(_lastDate);

  void _shiftMonth(int delta) {
    final target = DateTime(_month.year, _month.month + delta);
    if (delta < 0 && !_canPrev) return;
    if (delta > 0 && !_canNext) return;
    setState(() => _month = target);
  }

  void _goToday() {
    setState(() {
      _selected = _today;
      _month = DateTime(_today.year, _today.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Judul + pintasan "Today".
            Row(
              children: [
                Expanded(
                  child: Text('Select Date', style: AppTextStyles.sectionTitle),
                ),
                if (_todayInRange)
                  TextButton(
                    onPressed: _goToday,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryText,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Today'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Tanggal terpilih, ditampilkan seperti kolom isian di form.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 18,
                    color: _selected != null
                        ? AppColors.primaryMidText
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _selected != null
                        ? DateFormatter.shortDateID(_selected!)
                        : 'No date selected',
                    style: AppTextStyles.body.copyWith(
                      fontWeight:
                          _selected != null ? FontWeight.w600 : FontWeight.w400,
                      color: _selected != null
                          ? AppColors.text
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Header bulan: panah bulat di kiri-kanan, judul di tengah.
            Row(
              children: [
                _NavButton(
                  icon: Icons.chevron_left,
                  onTap: _canPrev ? () => _shiftMonth(-1) : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormatter.monthYearID(_month),
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                _NavButton(
                  icon: Icons.chevron_right,
                  onTap: _canNext ? () => _shiftMonth(1) : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Nama hari (Minggu di kolom pertama). 7 Jan 2024 = Minggu.
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        DateFormatter.shortDayID(DateTime(2024, 1, 7 + i)),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Grid hari; geser kiri/kanan untuk pindah bulan.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -200) _shiftMonth(1);
                if (v > 200) _shiftMonth(-1);
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _MonthGrid(
                  key: ValueKey(_month),
                  month: _month,
                  today: _today,
                  selected: _selected,
                  firstDate: _firstDate,
                  lastDate: _lastDate,
                  onSelect: (d) => setState(() => _selected = d),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _selected != null
                        ? () => Navigator.pop(context, _selected)
                        : null,
                    child: const Text('Confirm'),
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

/// Tombol panah bulat untuk pindah bulan. [onTap] null = nonaktif.
class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 22,
            color: onTap != null
                ? AppColors.text
                : AppColors.textMuted.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

/// Grid hari satu bulan, selalu 6 baris supaya tinggi sheet tidak
/// melompat saat pindah bulan.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    super.key,
    required this.month,
    required this.today,
    required this.selected,
    required this.firstDate,
    required this.lastDate,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime today;
  final DateTime? selected;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onSelect;

  static const _cell = 44.0;

  @override
  Widget build(BuildContext context) {
    // Minggu = kolom 0 (DateTime.weekday: Senin 1 ... Minggu 7).
    final lead = month.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    return Column(
      children: [
        for (var r = 0; r < 6; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: _buildCell(r * 7 + c - lead + 1, daysInMonth)),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: _cell);

    final date = DateTime(month.year, month.month, day);
    final enabled = !date.isBefore(firstDate) && !date.isAfter(lastDate);
    final isSelected = selected != null && DateUtils.isSameDay(date, selected);
    final isToday = DateUtils.isSameDay(date, today);

    final Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (!enabled) {
      textColor = AppColors.textMuted.withValues(alpha: 0.4);
    } else if (isToday) {
      textColor = AppColors.primaryText;
    } else {
      textColor = AppColors.text;
    }

    return SizedBox(
      height: _cell,
      child: Center(
        child: GestureDetector(
          onTap: enabled ? () => onSelect(date) : null,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: AppColors.primaryMidText, width: 1.5)
                  : null,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
