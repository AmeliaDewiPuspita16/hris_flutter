import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../../core/utils/date_formatter.dart';
import '../../../../../../../core/widgets/app_card.dart';
import '../../domain/it_request_monthly_trend.dart';
import '../../domain/it_request_report_demo_data.dart';
import '../../domain/it_request_report_summary.dart';
import '../../domain/it_request_status_breakdown.dart';

/// Isi tab "Report": ringkasan angka IT/Media Request per bulan.
///
/// SEMENTARA: [ItRequestReportDemoData] statis, belum tersambung ke API —
/// filter bulan/tahun di sini sudah berfungsi penuh (state + dialog),
/// tinggal disambungkan ke repository sungguhan begitu endpoint-nya ada;
/// bentuk [ItRequestReportSummary] dan tampilan kartu tidak perlu berubah.
class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  static final _firstSelectableMonth = DateTime(2023, 1);
  static final _lastSelectableMonth = DateTime(DateTime.now().year + 1, 12);

  DateTime _selectedMonth = DateTime.now();

  void _shiftMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    // SEMENTARA: refetch ringkasan per periode begitu API report ada.
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: _firstSelectableMonth,
      lastDate: _lastSelectableMonth,
      monthPickerDialogSettings: const MonthPickerDialogSettings(
        dialogSettings: PickerDialogSettings(
          dialogRoundedCornersRadius: 16,
          dialogBackgroundColor: AppColors.card,
        ),
        headerSettings: PickerHeaderSettings(
          headerBackgroundColor: AppColors.primary,
          headerIconsColor: Colors.white,
          headerCurrentPageTextStyle: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          headerSelectedIntervalTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        dateButtonsSettings: PickerDateButtonsSettings(
          selectedMonthBackgroundColor: AppColors.primary,
          selectedMonthTextColor: Colors.white,
          unselectedMonthsTextColor: AppColors.text,
          currentMonthTextColor: AppColors.primary,
        ),
        actionBarSettings: PickerActionBarSettings(
          confirmWidget: Text(
            'Pilih',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
          cancelWidget: Text(
            'Batal',
            style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );

    if (picked == null) return;
    setState(() => _selectedMonth = picked);
    // SEMENTARA: refetch ringkasan per periode begitu API report ada.
  }

  @override
  Widget build(BuildContext context) {
    final summary = ItRequestReportDemoData.summary();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _buildMonthPicker(),
        const SizedBox(height: 14),
        _StatGrid(summary: summary),
        const SizedBox(height: 14),
        _TrendChart(year: _selectedMonth.year, trend: ItRequestReportDemoData.trend()),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatusMeter(
                title: 'Status IT Request',
                breakdown: ItRequestReportDemoData.itStatus(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatusMeter(
                title: 'Status Media Request',
                breakdown: ItRequestReportDemoData.mediaStatus(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthPicker() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => _shiftMonth(-1),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.chevron_left, size: 20, color: AppColors.textMuted),
            ),
          ),
          InkWell(
            onTap: _pickMonth,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormatter.monthYearID(_selectedMonth),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => _shiftMonth(1),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.summary});

  final ItRequestReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.checklist_outlined,
                iconColor: AppColors.itRequest,
                iconBackground: AppColors.itRequestBg,
                label: 'Total Request',
                value: '${summary.totalRequest}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline,
                iconColor: AppColors.present,
                iconBackground: AppColors.presentBg,
                label: 'Done',
                value: '${summary.done}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.sync_outlined,
                iconColor: AppColors.orange,
                iconBackground: AppColors.orangeBg,
                label: 'On Progress',
                value: '${summary.onProgress}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.schedule_outlined,
                iconColor: AppColors.textMuted,
                iconBackground: AppColors.neutralBg,
                label: 'On Waiting',
                value: '${summary.onWaiting}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _StatCard(
          icon: Icons.groups_outlined,
          iconColor: AppColors.violet,
          iconBackground: AppColors.violetBg,
          label: 'Wait HOD',
          value: '${summary.waitHod}',
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CompletionRateCard(rate: summary.completionRate),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AvgResponseCard(days: summary.avgResponseDays),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTextStyles.h2.copyWith(fontSize: 24),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _CompletionRateCard extends StatelessWidget {
  const _CompletionRateCard({required this.rate});

  final int rate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMPLETION RATE',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$rate%',
            style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 5,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvgResponseCard extends StatelessWidget {
  const _AvgResponseCard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.violet,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVG RESPONSE',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$days',
            style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 10),
          Text(
            'Hari sejak disetujui HOD',
            style: AppTextStyles.caption.copyWith(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Grouped bar chart IT vs Media per bulan — vertikal (bar tumbuh bawah ke
/// atas), bulan tersusun kiri (Jan) ke kanan (Des).
///
/// Dibangun dari widget dasar (bukan package chart) — belum ada dependency
/// chart di project ini, dan bentuknya (12 bulan x 2 seri) cukup sederhana
/// untuk dirakit langsung. Warna seri (`AppColors.itRequest` biru,
/// `AppColors.orange`) sudah divalidasi aman untuk buta warna.
///
/// Tap satu bar menampilkan nilainya — pengganti hover di mobile, karena
/// dengan 24 bar sekaligus label di tiap bar akan jadi berisik (lihat
/// panduan "label selektif" dataviz).
class _TrendChart extends StatefulWidget {
  const _TrendChart({required this.year, required this.trend});

  final int year;
  final List<ItRequestMonthlyTrend> trend;

  @override
  State<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<_TrendChart> {
  static const _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const _chartHeight = 160.0;
  static const _yAxisWidth = 28.0;

  /// (bulan, true=IT/false=Media) yang sedang ditekan — null berarti tidak
  /// ada bar yang menampilkan nilainya.
  (int, bool)? _selected;

  void _toggle(int month, bool isIt) {
    setState(() {
      final tapped = (month, isIt);
      _selected = _selected == tapped ? null : tapped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = widget.trend
        .map((t) => t.itCount > t.mediaCount ? t.itCount : t.mediaCount)
        .fold(0, (a, b) => a > b ? a : b);
    final niceMax = maxValue == 0 ? 10 : (maxValue / 10).ceil() * 10;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Tren Request Per Bulan', style: AppTextStyles.sectionTitle),
              const SizedBox(width: 6),
              Text('(${widget.year})', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const _LegendDot(color: AppColors.itRequest),
              const SizedBox(width: 6),
              const Text('IT Request', style: AppTextStyles.caption),
              const SizedBox(width: 16),
              const _LegendDot(color: AppColors.orange),
              const SizedBox(width: 6),
              const Text('Media Request', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _YAxisLabels(niceMax: niceMax, height: _chartHeight, width: _yAxisWidth),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: _chartHeight,
                  child: Stack(
                    children: [
                      const Positioned.fill(child: _GridLines()),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final t in widget.trend)
                              Expanded(
                                child: _MonthGroup(
                                  trend: t,
                                  maxValue: niceMax,
                                  chartHeight: _chartHeight,
                                  selected: _selected,
                                  onTapBar: _toggle,
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
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(width: _yAxisWidth + 6),
              for (final t in widget.trend)
                Expanded(
                  child: Center(
                    child: Text(_monthLabels[t.month - 1], style: AppTextStyles.caption),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Lima label sumbu-Y (0, 1/4, 1/2, 3/4, penuh dari [niceMax]) — bulat ke
/// puluhan terdekat supaya enak dibaca, bukan pecahan data mentah.
class _YAxisLabels extends StatelessWidget {
  const _YAxisLabels({required this.niceMax, required this.height, required this.width});

  final int niceMax;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final steps = [niceMax, (niceMax * 3 / 4).round(), (niceMax / 2).round(),
        (niceMax / 4).round(), 0];

    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final step in steps)
            Text('$step', style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

/// Garis bantu horizontal tipis — recessive, cuma penanda skala, bukan data.
class _GridLines extends StatelessWidget {
  const _GridLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        5,
        (_) => Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

class _MonthGroup extends StatelessWidget {
  const _MonthGroup({
    required this.trend,
    required this.maxValue,
    required this.chartHeight,
    required this.selected,
    required this.onTapBar,
  });

  final ItRequestMonthlyTrend trend;
  final int maxValue;
  final double chartHeight;
  final (int, bool)? selected;
  final void Function(int month, bool isIt) onTapBar;

  double _barHeight(int value) => maxValue == 0 ? 0 : (value / maxValue) * chartHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Bar(
          key: ValueKey('trend-bar-it-${trend.month}'),
          height: _barHeight(trend.itCount),
          color: AppColors.itRequest,
          value: trend.itCount,
          showValue: selected == (trend.month, true),
          onTap: () => onTapBar(trend.month, true),
        ),
        const SizedBox(width: 2),
        _Bar(
          key: ValueKey('trend-bar-media-${trend.month}'),
          height: _barHeight(trend.mediaCount),
          color: AppColors.orange,
          value: trend.mediaCount,
          showValue: selected == (trend.month, false),
          onTap: () => onTapBar(trend.month, false),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    super.key,
    required this.height,
    required this.color,
    required this.value,
    required this.showValue,
    required this.onTap,
  });

  final double height;
  final Color color;
  final int value;
  final bool showValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 10,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showValue) ...[
              Text(
                '$value',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Container(
              height: height < 2 ? 2 : height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ringkasan Open vs Close satu jenis request (IT/Media), sebagai stat tile
/// + meter — bukan donut 2-juring seperti di web.
///
/// Donut 2 kategori sengaja dihindari (lihat panduan dataviz "❌ a 2-slice
/// pie ✅ a stat tile — the number is the chart"): dua angka besar
/// berdampingan lebih cepat dibaca daripada membandingkan luas juring, dan
/// tidak butuh keputusan warna kategorikal sama sekali — cuma satu hue
/// (hijau "selesai") dipakai buat meter proporsinya.
class _StatusMeter extends StatelessWidget {
  const _StatusMeter({required this.title, required this.breakdown});

  final String title;
  final ItRequestStatusBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final percent = breakdown.closedPercent;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Open', value: breakdown.open)),
              Expanded(child: _MiniStat(label: 'Close', value: breakdown.close)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent == null ? 0 : percent / 100,
              minHeight: 6,
              backgroundColor: AppColors.presentBg,
              valueColor: const AlwaysStoppedAnimation(AppColors.present),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            percent == null ? 'Belum ada data' : '$percent% closed',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text('$value', style: AppTextStyles.h2.copyWith(fontSize: 20)),
      ],
    );
  }
}
