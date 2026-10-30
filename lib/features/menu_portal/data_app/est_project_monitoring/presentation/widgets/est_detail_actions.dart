import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../data/est_project_repository.dart';
import '../../domain/exec_project_full.dart';
import '../../domain/executive_dashboard.dart';
import '../../domain/project_worker.dart';
import '../bloc/add_workers/add_workers_bloc.dart';
import '../bloc/substitute/substitute_bloc.dart';
import '../bloc/substitute/substitute_event.dart';
import '../bloc/worker_transfer/worker_transfer_bloc.dart';
import 'est_add_worker_sheet.dart';
import 'est_substitute_sheet.dart';
import 'est_transfer_sheet.dart';

/// Aksi tim di detail proyek: tambah worker, pindah, dan substitusi. [context]
/// harus berada di bawah provider bloc detail (lihat ExecProjectDetailScreen).
class EstDetailActions {
  const EstDetailActions._();

  static Future<void> showAddWorker(
    BuildContext context,
    ExecutiveProjectModel project,
  ) async {
    final repository = context.read<EstProjectRepository>();
    final bloc = context.read<AddWorkersBloc>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EstAddWorkerSheet(
          projectId: project.id,
          repository: repository,
        ),
      ),
    );
  }

  static Future<void> showTransfer(
    BuildContext context,
    ExecutiveProjectModel project,
    ProjectWorkerModel worker,
  ) async {
    // Kondisi 2: worker sedang bekerja -> tampilkan dialog konfirmasi
    if (worker.attendanceCondition == 2) {
      final confirmed = await _confirmWorking(context, worker);
      if (!confirmed) return;
    }
    if (!context.mounted) return;
    final repository = context.read<EstProjectRepository>();
    final bloc = context.read<WorkerTransferBloc>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EstTransferSheet(
          worker: worker,
          fromProject: project,
          repository: repository,
        ),
      ),
    );
  }

  static Future<void> showSubstitute(
    BuildContext context, {
    required ExecutiveProjectModel project,
    required String role,
    required int substituteForId,
    required String substituteForName,
  }) async {
    final repository = context.read<EstProjectRepository>();
    final bloc = context.read<SubstituteBloc>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: EstSubstituteSheet(
          projectId: project.id,
          role: role,
          substituteForId: substituteForId,
          substituteForName: substituteForName,
          repository: repository,
        ),
      ),
    );
  }

  static Future<void> endWorkerSubstitute(
    BuildContext context,
    ExecutiveProjectModel project,
    ProjectWorkerModel worker,
  ) {
    return _confirmEnd(
      context,
      project: project,
      assignmentId: worker.assignmentId!,
      message: 'Worker asli (${worker.substituteForName ?? '-'}) sudah '
          'kembali?\n\n${worker.name} akan dilepas dari peran pengganti '
          'sementara.',
    );
  }

  static Future<void> endMandorSubstitute(
    BuildContext context,
    ExecutiveProjectModel project,
    MandorModel mandor,
  ) {
    return _confirmEnd(
      context,
      project: project,
      assignmentId: mandor.assignmentId!,
      message: 'Mandor asli (${mandor.substituteFor?.name ?? '-'}) sudah '
          'kembali?\n\n${mandor.name} akan dilepas dari peran pengganti '
          'sementara.',
    );
  }

  static Future<void> _confirmEnd(
    BuildContext context, {
    required ExecutiveProjectModel project,
    required int assignmentId,
    required String message,
  }) async {
    final bloc = context.read<SubstituteBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Akhiri Substitusi?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rejected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Ya, Akhiri',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      bloc.add(
          EndSubstitute(projectId: project.id, assignmentId: assignmentId));
    }
  }

  static Future<bool> _confirmWorking(
    BuildContext context,
    ProjectWorkerModel worker,
  ) async {
    final hoursStr = worker.hoursToday > 0
        ? '${worker.hoursToday.toStringAsFixed(1)} jam'
        : 'beberapa saat';

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.orangeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Worker Sedang Bekerja',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              '${worker.name} sedang bekerja sejak ${worker.clockIn ?? '-'}.\n\n'
              'Memindahkan sekarang akan otomatis melakukan clock out di proyek ini.\n\n'
              'Jam kerja hari ini ($hoursStr) tetap tercatat di proyek ini.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSub,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    Text('Batal', style: TextStyle(color: AppColors.textSub)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Ya, Pindahkan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
