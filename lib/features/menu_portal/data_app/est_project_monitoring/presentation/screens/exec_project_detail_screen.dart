import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../data/est_project_repository.dart';
import '../../domain/executive_dashboard.dart';
import '../bloc/add_workers/add_workers_bloc.dart';
import '../bloc/add_workers/add_workers_state.dart';
import '../bloc/detail/close_project_bloc.dart';
import '../bloc/detail/close_project_state.dart';
import '../bloc/detail/exec_project_detail_bloc.dart';
import '../bloc/detail/exec_project_detail_event.dart';
import '../bloc/detail/project_workers_bloc.dart';
import '../bloc/detail/project_workers_event.dart';
import '../bloc/substitute/substitute_bloc.dart';
import '../bloc/substitute/substitute_state.dart';
import '../bloc/worker_transfer/worker_transfer_bloc.dart';
import '../bloc/worker_transfer/worker_transfer_state.dart';
import '../widgets/est_close_project_button.dart';
import '../widgets/est_detail_actions.dart';
import '../widgets/est_detail_closed_at_card.dart';
import '../widgets/est_detail_mandor_section.dart';
import '../widgets/est_detail_progress_card.dart';
import '../widgets/est_detail_stats_row.dart';
import '../widgets/est_detail_summary_card.dart';
import '../widgets/est_detail_team_section.dart';
import '../widgets/est_detail_timeline_card.dart';
import 'project_form_screen.dart';

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
        BlocProvider(
          create: (_) => WorkerTransferBloc(repository: repository),
        ),
        BlocProvider(create: (_) => AddWorkersBloc(repository: repository)),
        BlocProvider(create: (_) => SubstituteBloc(repository: repository)),
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

  void _refreshDetail(BuildContext context) {
    context
        .read<ExecProjectDetailBloc>()
        .add(LoadExecProjectDetail(project.id));
    context.read<ProjectWorkersBloc>().add(LoadProjectWorkers(project.id));
  }

  // Form edit memakai map yang sama dengan DW; muat ulang detail bila tersimpan.
  Future<void> _openEditForm(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectFormScreen(
          project: {
            'id': project.id,
            'name': project.name,
            'location': project.location,
            'budget_hours': project.budgetHours,
            'start_date': project.startDate,
            'target_end_date': project.targetEndDate,
          },
        ),
      ),
    );
    if (result == true && context.mounted) {
      context
          .read<ExecProjectDetailBloc>()
          .add(LoadExecProjectDetail(project.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<WorkerTransferBloc, WorkerTransferState>(
          listener: (context, state) {
            if (state is WorkerTransferSuccess) {
              _showSnack(context, state.message, AppColors.primary);
              context
                  .read<ProjectWorkersBloc>()
                  .add(LoadProjectWorkers(project.id));
            } else if (state is WorkerTransferFailure) {
              _showSnack(context, state.message, AppColors.rejected);
            }
          },
        ),
        BlocListener<AddWorkersBloc, AddWorkersState>(
          listener: (context, state) {
            if (state is AddWorkersSuccess) {
              _showSnack(context, state.message, AppColors.primary);
              _refreshDetail(context);
            } else if (state is AddWorkersFailure) {
              _showSnack(context, state.message, AppColors.rejected);
            }
          },
        ),
        BlocListener<SubstituteBloc, SubstituteState>(
          listener: (context, state) {
            if (state is SubstituteSuccess) {
              _showSnack(context, state.message, AppColors.primary);
              // Muat ulang mandor dan daftar worker
              _refreshDetail(context);
            } else if (state is SubstituteFailure) {
              _showSnack(context, state.message, AppColors.rejected);
            }
          },
        ),
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
        appBar: BackHeader(
          title: project.name,
          onBack: () => Navigator.pop(context),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EstDetailSummaryCard(project: project),
              const SizedBox(height: 16),
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
              EstDetailMandorSection(
                onSubstitute: (m) => EstDetailActions.showSubstitute(
                  context,
                  project: project,
                  role: 'mandor',
                  substituteForId: m.id,
                  substituteForName: m.name,
                ),
                onEndSubstitute: (m) => EstDetailActions.endMandorSubstitute(
                  context,
                  project,
                  m,
                ),
              ),
              const SizedBox(height: 24),
              EstDetailTeamSection(
                projectId: project.id,
                isCompleted: project.status == 'completed',
                onAddWorker: () =>
                    EstDetailActions.showAddWorker(context, project),
                onTransfer: (w) =>
                    EstDetailActions.showTransfer(context, project, w),
                onSubstitute: (w) => EstDetailActions.showSubstitute(
                  context,
                  project: project,
                  role: 'worker',
                  substituteForId: w.workerId,
                  substituteForName: w.name,
                ),
                onEndSubstitute: (w) => EstDetailActions.endWorkerSubstitute(
                  context,
                  project,
                  w,
                ),
              ),
              if (project.status != 'completed') ...[
                const SizedBox(height: 32),
                if (project.status != 'pending_close') ...[
                  _EditProjectButton(onPressed: () => _openEditForm(context)),
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
    );
  }
}

/// Tombol "Edit Proyek": membuka form edit lewat [onPressed].
class _EditProjectButton extends StatelessWidget {
  const _EditProjectButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
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
