import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../data/est_project_repository.dart';
import '../../domain/executive_dashboard.dart';
import '../../domain/project_worker.dart';
import '../bloc/worker_transfer/worker_transfer_bloc.dart';
import '../bloc/worker_transfer/worker_transfer_event.dart';
import '../bloc/worker_transfer/worker_transfer_state.dart';

/// Bottom sheet "Pindahkan Worker": pilih proyek tujuan (selain proyek asal)
/// dan alasan opsional. Butuh [WorkerTransferBloc] di context.
class EstTransferSheet extends StatefulWidget {
  const EstTransferSheet({
    super.key,
    required this.worker,
    required this.fromProject,
    required this.repository,
  });

  final ProjectWorkerModel worker;
  final ExecutiveProjectModel fromProject;
  final EstProjectRepository repository;

  @override
  State<EstTransferSheet> createState() => _EstTransferSheetState();
}

class _EstTransferSheetState extends State<EstTransferSheet> {
  ExecutiveProjectModel? _selectedProject;
  final _reasonController = TextEditingController();
  List<ExecutiveProjectModel> _otherProjects = [];
  bool _loadingProjects = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final all = await widget.repository.fetchActiveProjects();
      final projects = all.where((p) => p.id != widget.fromProject.id).toList();
      if (!mounted) return;
      setState(() {
        _otherProjects = projects;
        _loadingProjects = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProjects = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.presentBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.primaryText,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pindahkan Worker',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      widget.worker.name,
                      style: TextStyle(fontSize: 12, color: AppColors.textSub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Proyek Tujuan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          _buildProjectPicker(),
          const SizedBox(height: 16),
          Text(
            'Alasan (opsional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            maxLength: 500,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  'Mis. Proyek ini hampir selesai, butuh tenaga di proyek baru',
              hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
              border: _border(AppColors.border),
              enabledBorder: _border(AppColors.border),
              focusedBorder: _border(AppColors.primaryText),
              contentPadding: const EdgeInsets.all(12),
              counterStyle: TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 4),
          BlocConsumer<WorkerTransferBloc, WorkerTransferState>(
            listener: (context, state) {
              if (state is WorkerTransferSuccess ||
                  state is WorkerTransferFailure) {
                Navigator.pop(context);
              }
            },
            builder: (context, state) {
              final isLoading = state is WorkerTransferLoading;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedProject == null || isLoading)
                      ? null
                      : () {
                          final reason = _reasonController.text.trim();
                          context.read<WorkerTransferBloc>().add(
                                SubmitWorkerTransfer(
                                  fromProjectId: widget.fromProject.id,
                                  workerIds: [widget.worker.workerId],
                                  targetProjectId: _selectedProject!.id,
                                  reason: reason.isEmpty ? null : reason,
                                ),
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Pindahkan Sekarang',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectPicker() {
    if (_loadingProjects) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(
            color: AppColors.primaryText,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_otherProjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Tidak ada proyek lain yang tersedia',
          style: TextStyle(fontSize: 13, color: AppColors.textSub),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ExecutiveProjectModel>(
          value: _selectedProject,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'Pilih proyek tujuan',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          items: _otherProjects
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      p.name,
                      style: TextStyle(fontSize: 13, color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedProject = v),
        ),
      ),
    );
  }
}
