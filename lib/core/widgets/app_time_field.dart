import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'field_label_row.dart';

/// Field jam. Tap untuk membuka bottom sheet dengan wheel scroll picker
/// minimalis (jam:menit), menggantikan input teks manual HH:mm.
class AppTimeField extends StatelessWidget {
  const AppTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final bool required;

  static String _format(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimeWheelSheet(initial: value ?? const TimeOfDay(hour: 9, minute: 0)),
    );

    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelRow(label: label, required: required),
        InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: value != null ? AppColors.primaryMid : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 16,
                  color: value != null ? AppColors.primaryMid : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  value != null ? _format(value!) : '--:--',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeWheelSheet extends StatefulWidget {
  const _TimeWheelSheet({required this.initial});

  final TimeOfDay initial;

  @override
  State<_TimeWheelSheet> createState() => _TimeWheelSheetState();
}

class _TimeWheelSheetState extends State<_TimeWheelSheet> {
  static const _minuteStep = 5;

  late int _hour = widget.initial.hour;
  late int _minute = widget.initial.minute - (widget.initial.minute % _minuteStep);

  late final FixedExtentScrollController _hourCtrl =
      FixedExtentScrollController(initialItem: _hour);
  late final FixedExtentScrollController _minuteCtrl =
      FixedExtentScrollController(initialItem: _minute ~/ _minuteStep);

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int index) label,
    required ValueChanged<int> onChanged,
  }) {
    return SizedBox(
      width: 70,
      height: 160,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 40,
        diameterRatio: 1.4,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) => Center(
            child: Text(
              label(index),
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  @override
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
              child: Text('Pilih Waktu', style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.presentBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _wheel(
                      controller: _hourCtrl,
                      itemCount: 24,
                      label: (i) => i.toString().padLeft(2, '0'),
                      onChanged: (i) => setState(() => _hour = i),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(':', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    _wheel(
                      controller: _minuteCtrl,
                      itemCount: 60 ~/ _minuteStep,
                      label: (i) => (i * _minuteStep).toString().padLeft(2, '0'),
                      onChanged: (i) => setState(() => _minute = i * _minuteStep),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                    onPressed: () => Navigator.pop(context, TimeOfDay(hour: _hour, minute: _minute)),
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
