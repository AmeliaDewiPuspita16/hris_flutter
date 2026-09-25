import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Bottom sheet pemilih bulan & tahun bergaya scroll wheel (mirip iOS date
/// picker) — dua kolom yang bisa digulir terpisah, dengan kotak highlight di
/// tengah menandai pilihan aktif. Dipanggil lewat [showMonthYearPicker].
class MonthYearPickerSheet extends StatefulWidget {
  const MonthYearPickerSheet({
    super.key,
    required this.initialMonth,
    required this.firstMonth,
    required this.lastMonth,
  });

  /// Bulan yang sedang aktif — dipakai sebagai posisi awal kedua wheel.
  final DateTime initialMonth;

  /// Batas bawah & atas bulan yang boleh dipilih.
  final DateTime firstMonth;
  final DateTime lastMonth;

  @override
  State<MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<MonthYearPickerSheet> {
  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const _itemExtent = 44.0;

  late final List<int> _years = [
    for (var y = widget.firstMonth.year; y <= widget.lastMonth.year; y++) y,
  ];

  late int _monthIndex = widget.initialMonth.month - 1;
  late int _yearIndex = _years.indexOf(widget.initialMonth.year);

  late final _monthController = FixedExtentScrollController(initialItem: _monthIndex);
  late final _yearController = FixedExtentScrollController(initialItem: _yearIndex);

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.of(context).pop(DateTime(_years[_yearIndex], _monthIndex + 1));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
            const Text(
              'Pilih Bulan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: _itemExtent * 5,
              child: Stack(
                children: [
                  // Kotak highlight di tengah, di belakang kedua wheel —
                  // menandai baris yang sedang aktif.
                  Center(
                    child: Container(
                      height: _itemExtent,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _monthController,
                          itemExtent: _itemExtent,
                          looping: false,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) => setState(() => _monthIndex = index),
                          children: [
                            for (final month in _months)
                              Center(
                                child: Text(
                                  month,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _yearController,
                          itemExtent: _itemExtent,
                          looping: false,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) => setState(() => _yearIndex = index),
                          children: [
                            for (final year in _years)
                              Center(
                                child: Text(
                                  '$year',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: const Text('Pilih', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menampilkan [MonthYearPickerSheet] sebagai modal bottom sheet.
/// Mengembalikan bulan yang dipilih (tanggal di-set ke 1), atau null bila
/// dibatalkan (swipe-dismiss atau tap di luar sheet).
Future<DateTime?> showMonthYearPicker({
  required BuildContext context,
  required DateTime initialMonth,
  required DateTime firstMonth,
  required DateTime lastMonth,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => MonthYearPickerSheet(
      initialMonth: initialMonth,
      firstMonth: firstMonth,
      lastMonth: lastMonth,
    ),
  );
}
