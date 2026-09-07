import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

enum _DayType { present, late, absent, weekend, future }

class _DayData {
  const _DayData(this.day, this.type, this.hours);
  final int day;
  final _DayType type;
  final double hours;
}

class _LogItem {
  const _LogItem(this.date, this.checkIn, this.checkOut, this.isLate, this.note, this.machine);
  final String date;
  final String checkIn;
  final String checkOut;
  final bool isLate;
  final String note;
  final String machine;
}

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  int? _selectedDay;

  /// Padanan mock data 30 hari bulan September 2026.
  static final List<_DayData> _days = List.generate(30, (i) {
    final d = i + 1;
    const weekendDays = [4, 5, 11, 12, 18, 19, 25, 26];
    final isWeekend = weekendDays.contains(d);
    final isFuture = d > 2;
    if (isFuture) return _DayData(d, _DayType.future, 0);
    if (isWeekend) return _DayData(d, _DayType.weekend, 0);
    final type = d == 1 ? _DayType.present : _DayType.late;
    return _DayData(d, type, type == _DayType.present ? 8.5 : 7.8);
  });

  static const _logs = [
    _LogItem('Sel, 2 Sep 2026', '07:52', '17:10', false, 'Tepat Waktu', 'FP-MAIN-01'),
    _LogItem('Sen, 1 Sep 2026', '08:23', '17:30', true, 'Terlambat 23 mnt', 'FP-MAIN-01'),
  ];

  static const _summary = (hadir: 2, terlambat: 1, absen: 0, cuti: 0);

  Color _barColor(_DayType type) {
    switch (type) {
      case _DayType.present:
        return AppColors.presentMid;
      case _DayType.late:
        return AppColors.pending;
      case _DayType.absent:
        return AppColors.rejected;
      case _DayType.weekend:
      case _DayType.future:
        return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Absensi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                  SizedBox(height: 4),
                  Text('September 2026', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildChartCard(),
                    const SizedBox(height: 16),
                    const Text('Log Harian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(height: 10),
                    ..._logs.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildLogCard(l),
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.neutralBg, borderRadius: BorderRadius.circular(10)),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🔒', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Data absensi disinkronkan otomatis dari mesin fingerprint. Baca saja.',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final items = [
      (_summary.hadir, 'Hadir', AppColors.presentMid),
      (_summary.terlambat, 'Terlambat', AppColors.pending),
      (_summary.absen, 'Absen', AppColors.rejected),
      (_summary.cuti, 'Cuti', AppColors.primaryMid),
    ];
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RINGKASAN BULAN INI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.3)),
          const SizedBox(height: 12),
          Row(
            children: items.map((it) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Text('${it.$1}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: it.$3)),
                      const SizedBox(height: 2),
                      Text(it.$2, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    const legend = [
      (AppColors.presentMid, 'Hadir'),
      (AppColors.pending, 'Terlambat'),
      (AppColors.rejected, 'Absen'),
      (AppColors.border, 'Libur'),
    ];
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GRAFIK KEHADIRAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.3)),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _days.map((d) {
                  final selected = _selectedDay == d.day;
                  final barHeight = d.type == _DayType.future
                      ? 4.0
                      : d.type == _DayType.weekend
                          ? 12.0
                          : (d.hours * 6).clamp(8.0, 60.0);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = selected ? null : d.day),
                    child: Container(
                      width: 9,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Opacity(
                            opacity: d.type == _DayType.future ? 0.3 : 1,
                            child: Container(
                              width: 9,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: selected ? AppColors.accent : _barColor(d.type),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            d.day % 5 == 1 ? '${d.day}' : '',
                            style: const TextStyle(fontSize: 7, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: legend.map((l) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: l.$1, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 4),
                  Text(l.$2, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(_LogItem l) {
    final badgeColor = l.isLate ? AppColors.pending : AppColors.presentMid;
    final badgeBg = l.isLate ? AppColors.pendingBg : AppColors.presentBg;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(height: 2),
                    Text('Mesin: ${l.machine}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                child: Text(l.note, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MASUK', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                      const SizedBox(height: 3),
                      Text(l.checkIn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.present)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('KELUAR', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                      const SizedBox(height: 3),
                      Text(l.checkOut, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.presentMid)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}