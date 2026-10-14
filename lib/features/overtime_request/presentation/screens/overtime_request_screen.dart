import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/header_title_row.dart';
import '../../domain/overtime_day.dart';
import '../../domain/overtime_demo_data.dart';
import '../../domain/overtime_request_entry.dart';
import '../widgets/overtime_status_tab.dart';
import '../widgets/overtime_submit_tab.dart';
import '../widgets/overtime_summary_tab.dart';

enum _OvertimeTab { summary, submit, status }

/// Overtime Request — pola sama dengan Leave Request (`PengajuanScreen`):
/// header hijau dengan tiga tab Summary / Submit / Status.
///
/// - Summary: lembur yang sudah terjadi (realisasi dari absensi).
/// - Submit : form pengajuan lembur.
/// - Status : riwayat pengajuan lembur.
///
/// MASIH TAMPILAN SAJA: datanya dummy dari [OvertimeDemoData] dan pengajuan
/// baru hanya disimpan di memori. Saat API tersambung, ganti dengan
/// repository + bloc seperti `PengajuanRepository`.
class OvertimeRequestScreen extends StatefulWidget {
  const OvertimeRequestScreen({super.key, this.showBack = true});

  final bool showBack;

  @override
  State<OvertimeRequestScreen> createState() => _OvertimeRequestScreenState();
}

class _OvertimeRequestScreenState extends State<OvertimeRequestScreen> {
  _OvertimeTab _tab = _OvertimeTab.summary;

  final List<OvertimeDay> _days = OvertimeDemoData.days();
  final List<OvertimeRequestEntry> _requests = OvertimeDemoData.requests();

  void _handleSubmit(OvertimeRequestEntry entry) {
    setState(() {
      _requests.insert(0, entry);
      _tab = _OvertimeTab.status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Overtime request submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: ColoredBox(
          color: AppColors.primary,
          child: SafeArea(
            bottom: false,
            child: ColoredBox(
              color: AppColors.bg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: switch (_tab) {
                      _OvertimeTab.summary => OvertimeSummaryTab(days: _days),
                      _OvertimeTab.submit =>
                        OvertimeSubmitTab(onSubmit: _handleSubmit),
                      _OvertimeTab.status =>
                        OvertimeStatusTab(requests: _requests),
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Widget tabButton(_OvertimeTab tab, String label, IconData icon) {
      final active = _tab == tab;

      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = tab),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderTitleRow(title: 'Overtime Request', showBack: widget.showBack),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                tabButton(_OvertimeTab.summary, 'Summary', Icons.pie_chart_outline_rounded),
                tabButton(_OvertimeTab.submit, 'Submit', Icons.edit_outlined),
                tabButton(_OvertimeTab.status, 'Status', Icons.calendar_month_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
