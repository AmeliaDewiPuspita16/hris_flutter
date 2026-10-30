import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../data/est_project_repository.dart';
import '../../domain/executive_dashboard.dart';
import '../bloc/detail/close_project_bloc.dart';
import '../bloc/detail/close_project_state.dart';
import '../bloc/detail/exec_project_detail_bloc.dart';
import '../bloc/detail/exec_project_detail_event.dart';
import '../bloc/detail/project_workers_bloc.dart';
import '../bloc/detail/project_workers_event.dart';
import '../widgets/est_close_project_button.dart';
import '../widgets/est_detail_closed_at_card.dart';
import '../widgets/est_detail_header.dart';
import '../widgets/est_detail_mandor_section.dart';
import '../widgets/est_detail_progress_card.dart';
import '../widgets/est_detail_stats_row.dart';
import '../widgets/est_detail_team_section.dart';
import '../widgets/est_detail_timeline_card.dart';

/// Detail proyek executive: progres, timeline, supervisor, tim, dan request
/// tutup proyek. Pop dengan `true` bila proyek berubah (beranda perlu muat
/// ulang).
class ExecProjectDetailScreen extends StatelessWidget {
  const ExecProjectDetailScreen({super.key, required this.project});

  final ExecutiveProjectModel project;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<EstProjectRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ExecProjectDetailBloc(repository: repository)
            ..add(LoadExecProjectDetail(project.id)),
        ),
        BlocProvider(
          create: (_) => ProjectWorkersBloc(repository: repository)
            ..add(LoadProjectWorkers(project.id)),
        ),
        BlocProvider(create: (_) => CloseProjectBloc(repository: repository)),
      ],
      child: _ExecProjectDetailView(project: project),
    );
  }
}

class _ExecProjectDetailView extends StatelessWidget {
  const _ExecProjectDetailView({required this.project});

  final ExecutiveProjectModel project;

  void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CloseProjectBloc, CloseProjectState>(
          listener: (context, state) {
            if (state is CloseProjectSuccess) {
              _showSnack(
                context,
                'Request tutup proyek dikirim — menunggu persetujuan HOD',
                AppColors.solid(AppColors.orange),
              );
              Navigator.pop(context, true);
            } else if (state is CloseProjectFailure) {
              _showSnack(context, state.message, AppColors.rejected);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: Column(
            children: [
              EstDetailHeader(project: project),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EstDetailProgressCard(project: project),
                      const SizedBox(height: 16),
                      EstDetailTimelineCard(project: project),
                      if (project.status == 'completed') ...[
                        const SizedBox(height: 16),
                        const EstDetailClosedAtCard(),
                      ],
                      const SizedBox(height: 16),
                      EstDetailStatsRow(project: project),
                      const SizedBox(height: 16),
                      const EstDetailMandorSection(),
                      const SizedBox(height: 24),
                      EstDetailTeamSection(
                        projectId: project.id,
                        isCompleted: project.status == 'completed',
                      ),
                      if (project.status != 'completed') ...[
                        const SizedBox(height: 32),
                        if (project.status != 'pending_close') ...[
                          const _EditProjectButton(),
                          const SizedBox(height: 12),
                        ],
                        EstCloseProjectButton(
                          projectId: project.id,
                          status: project.status,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol "Edit Proyek"; belum tersambung (onPressed null) sampai form edit
/// tersedia.
class _EditProjectButton extends StatelessWidget {
  const _EditProjectButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.presentBg,
          foregroundColor: AppColors.primaryText,
          disabledBackgroundColor: AppColors.presentBg,
          disabledForegroundColor: AppColors.primaryText,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text(
          'Edit Proyek',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
