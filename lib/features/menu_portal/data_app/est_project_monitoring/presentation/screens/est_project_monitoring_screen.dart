import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../data/est_project_repository.dart';
import '../../domain/executive_dashboard.dart';
import '../bloc/dashboard/executive_dashboard_bloc.dart';
import '../bloc/dashboard/executive_dashboard_event.dart';
import '../bloc/dashboard/executive_dashboard_state.dart';
import '../widgets/est_close_session_sheet.dart';
import '../widgets/est_create_project_fab.dart';
import '../widgets/est_dashboard_error.dart';
import '../widgets/est_dashboard_header.dart';
import '../widgets/est_dashboard_shimmer.dart';
import '../widgets/est_no_access_view.dart';
import '../widgets/est_not_clocked_out_sheet.dart';
import '../widgets/est_open_session_dialog.dart';
import '../widgets/est_project_card.dart';
import '../widgets/est_stat_cards.dart';
import 'exec_project_detail_screen.dart';
import 'project_form_screen.dart';

/// Beranda executive EST Project Monitoring (menu Data): ringkasan, daftar
/// "Performa Proyek", serta buka/tutup sesi harian per proyek.
class EstProjectMonitoringScreen extends StatefulWidget {
  const EstProjectMonitoringScreen({super.key});

  @override
  State<EstProjectMonitoringScreen> createState() =>
      _EstProjectMonitoringScreenState();
}

class _EstProjectMonitoringScreenState
    extends State<EstProjectMonitoringScreen> {
  late final ExecutiveDashboardBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ExecutiveDashboardBloc(
      repository: context.read<EstProjectRepository>(),
    )..add(const LoadExecutiveDashboard());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  // ── Detail proyek ─────────────────────────────────────
  Future<void> _openDetail(ExecutiveProjectModel p) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ExecProjectDetailScreen(project: p)),
    );
    if (result == true && mounted) {
      _bloc.add(const LoadExecutiveDashboard());
    }
  }

  // ── Buat proyek ───────────────────────────────────────
  Future<void> _openCreateForm() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
    );
    if (result == true && mounted) {
      _bloc.add(const LoadExecutiveDashboard());
    }
  }

  // ── Alur buka/tutup sesi ──────────────────────────────
  Future<void> _toggleSession(ExecutiveProjectModel p) async {
    if (!p.isOpen) {
      final confirmed = await EstOpenSessionDialog.show(context, p);
      if (confirmed && mounted) _bloc.add(OpenExecutiveSession(p.id));
    } else if (p.notClockedOut > 0) {
      final autoClockOut = await EstNotClockedOutSheet.show(context, p);
      if (autoClockOut && mounted) await _closeSession(p, autoClockOut: true);
    } else {
      await _closeSession(p, autoClockOut: false);
    }
  }

  Future<void> _closeSession(
    ExecutiveProjectModel p, {
    required bool autoClockOut,
  }) async {
    final input = await EstCloseSessionSheet.show(
      context,
      p,
      autoClockOut: autoClockOut,
    );
    if (input == null || !mounted) return;
    _bloc.add(
      CloseExecutiveSession(
        p.id,
        input.description,
        autoClockOut: autoClockOut,
        photoPaths: input.photoPaths,
      ),
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onState(BuildContext context, ExecutiveDashboardState state) {
    if (state is ExecutiveSessionSuccess) {
      _showSnack(state.message, AppColors.primary);
      _bloc.add(const LoadExecutiveDashboard());
    }
    if (state is ExecutiveSessionError) {
      _showSnack(state.message, AppColors.rejected);
    }
  }

  Widget _buildBody(BuildContext context, ExecutiveDashboardState state) {
    return switch (state) {
      ExecutiveDashboardInitial() ||
      ExecutiveDashboardLoading() =>
        const EstDashboardShimmer(),
      ExecutiveDashboardError() => EstDashboardError(
          message: state.message,
          onRetry: () => _bloc.add(const LoadExecutiveDashboard()),
        ),
      ExecutiveDashboardNoAccess() => const EstNoAccessView(),
      ExecutiveDashboardLoaded() => _buildContent(state.data),
      ExecutiveSessionLoading() => Stack(
          children: [
            _buildContent(state.currentData),
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memproses...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ExecutiveSessionError() => _buildContent(state.currentData),
      ExecutiveSessionSuccess() => const SizedBox.shrink(),
    };
  }

  Widget _buildContent(ExecutiveDashboardModel data) {
    return RefreshIndicator(
      color: AppColors.primaryText,
      onRefresh: () async {
        _bloc.add(const LoadExecutiveDashboard());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EstStatCards(summary: data.summary),
            const SizedBox(height: 28),
            _buildProjectSection(data.projects),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSection(List<ExecutiveProjectModel> projects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performa Proyek',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...projects.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EstProjectCard(
              project: p,
              onTap: () => _openDetail(p),
              onToggleSession: () => _toggleSession(p),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = context.read<AuthBloc>().state.session?.user.name ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: EstCreateProjectFab(onPressed: _openCreateForm),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Column(
          children: [
            EstDashboardHeader(userName: name),
            Expanded(
              child:
                  BlocConsumer<ExecutiveDashboardBloc, ExecutiveDashboardState>(
                bloc: _bloc,
                listener: _onState,
                builder: _buildBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
