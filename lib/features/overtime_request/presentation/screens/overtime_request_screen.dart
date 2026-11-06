import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/header_title_row.dart';
import '../../data/overtime_repository.dart';
import '../../domain/overtime_submission.dart';
import '../bloc/requests/overtime_requests_bloc.dart';
import '../bloc/requests/overtime_requests_event.dart';
import '../bloc/summary/overtime_summary_bloc.dart';
import '../bloc/summary/overtime_summary_event.dart';
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
/// Tab Summary memakai [OvertimeSummaryBloc], tab Status memakai
/// [OvertimeRequestsBloc], dan tab Submit langsung ke repository.
class OvertimeRequestScreen extends StatefulWidget {
  const OvertimeRequestScreen({
    super.key,
    this.showBack = true,
    this.repository,
  });

  final bool showBack;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final OvertimeRepository? repository;

  @override
  State<OvertimeRequestScreen> createState() => _OvertimeRequestScreenState();
}

class _OvertimeRequestScreenState extends State<OvertimeRequestScreen> {
  _OvertimeTab _tab = _OvertimeTab.summary;

  late final OvertimeRepository _repository =
      widget.repository ?? context.read<OvertimeRepository>();

  late final OvertimeRequestsBloc _requestsBloc =
      OvertimeRequestsBloc(repository: _repository);

  @override
  void initState() {
    super.initState();
    _requestsBloc.add(const OvertimeRequestsLoaded());
  }

  @override
  void dispose() {
    _requestsBloc.close();
    super.dispose();
  }

  /// Kegagalan sengaja dibiarkan naik ke [OvertimeSubmitTab] supaya pesannya
  /// tampil di form dan isian user tidak hilang.
  Future<void> _handleSubmit(OvertimeSubmission submission) async {
    await _repository.submitRequest(submission);

    if (!mounted) return;

    _requestsBloc.add(const OvertimeRequestsLoaded());
    setState(() => _tab = _OvertimeTab.status);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Overtime request submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => OvertimeSummaryBloc(repository: _repository)
            ..add(const OvertimeSummaryStarted()),
        ),
        BlocProvider.value(value: _requestsBloc),
      ],
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
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
                      _OvertimeTab.summary => const OvertimeSummaryTab(),
                      _OvertimeTab.submit =>
                        OvertimeSubmitTab(onSubmit: _handleSubmit),
                      _OvertimeTab.status => const OvertimeStatusTab(),
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
              color: active ? AppColors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: active ? AppColors.primaryText : Colors.white.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.primaryText : Colors.white.withValues(alpha: 0.75),
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
      decoration: BoxDecoration(
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
