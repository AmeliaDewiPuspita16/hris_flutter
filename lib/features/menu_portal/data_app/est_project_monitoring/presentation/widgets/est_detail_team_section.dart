import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../domain/project_worker.dart';
import '../bloc/detail/project_workers_bloc.dart';
import '../bloc/detail/project_workers_event.dart';
import '../bloc/detail/project_workers_state.dart';
import 'est_worker_card.dart';

/// Bagian "Tim Proyek": tombol Tambah, daftar worker, dan state loading,
/// kosong, galat. Callback null = aksinya belum tersambung.
class EstDetailTeamSection extends StatelessWidget {
  const EstDetailTeamSection({
    super.key,
    required this.projectId,
    required this.isCompleted,
    this.onAddWorker,
    this.onTransfer,
    this.onSubstitute,
    this.onEndSubstitute,
  });

  final int projectId;
  final bool isCompleted;
  final VoidCallback? onAddWorker;
  final Future<void> Function(ProjectWorkerModel worker)? onTransfer;
  final void Function(ProjectWorkerModel worker)? onSubstitute;
  final void Function(ProjectWorkerModel worker)? onEndSubstitute;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.presentBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.people_outline,
                size: 16,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tim Proyek',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            if (!isCompleted)
              GestureDetector(
                onTap: onAddWorker,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.presentBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryText.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 14,
                        color: AppColors.primaryText,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Tambah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Geser worker ke kiri untuk memindahkan ke proyek lain',
          style: TextStyle(fontSize: 11, color: AppColors.textSub),
        ),
        const SizedBox(height: 14),
        BlocBuilder<ProjectWorkersBloc, ProjectWorkersState>(
          builder: (context, state) {
            if (state is ProjectWorkersLoading ||
                state is ProjectWorkersInitial) {
              return const _WorkerShimmer();
            }
            if (state is ProjectWorkersError) {
              return _WorkerError(
                message: state.message,
                onRetry: () => context
                    .read<ProjectWorkersBloc>()
                    .add(LoadProjectWorkers(projectId)),
              );
            }
            if (state is ProjectWorkersLoaded) {
              if (state.workers.isEmpty) return const _WorkerEmpty();
              return Column(
                children: state.workers
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EstWorkerCard(
                          worker: w,
                          onTransfer:
                              onTransfer == null ? null : () => onTransfer!(w),
                          onSubstitute: onSubstitute == null
                              ? null
                              : () => onSubstitute!(w),
                          onEndSubstitute: onEndSubstitute == null
                              ? null
                              : () => onEndSubstitute!(w),
                        ),
                      ),
                    )
                    .toList(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _WorkerShimmer extends StatelessWidget {
  const _WorkerShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: ShimmerBox(height: 72, borderRadius: 14),
          ),
        ),
      ),
    );
  }
}

class _WorkerEmpty extends StatelessWidget {
  const _WorkerEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            'Belum ada tim di proyek ini',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _WorkerError extends StatelessWidget {
  const _WorkerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.rejected, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: AppColors.rejected),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Coba Lagi',
              style: TextStyle(color: AppColors.rejected, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
