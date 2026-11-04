import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../data/est_project_repository.dart';
import '../../domain/est_substitute_candidate.dart';
import '../bloc/substitute/substitute_bloc.dart';
import '../bloc/substitute/substitute_event.dart';
import '../bloc/substitute/substitute_state.dart';

/// Bottom sheet "Assign Pengganti" untuk mandor ([role] 'mandor') atau worker
/// ('worker'). Butuh [SubstituteBloc] di context.
class EstSubstituteSheet extends StatefulWidget {
  const EstSubstituteSheet({
    super.key,
    required this.projectId,
    required this.role,
    required this.substituteForId,
    required this.substituteForName,
    required this.repository,
  });

  final int projectId;
  final String role;
  final int substituteForId;
  final String substituteForName;
  final EstProjectRepository repository;

  @override
  State<EstSubstituteSheet> createState() => _EstSubstituteSheetState();
}

class _EstSubstituteSheetState extends State<EstSubstituteSheet> {
  final _reasonController = TextEditingController();

  List<EstSubstituteCandidate> _candidates = [];
  EstSubstituteCandidate? _selected;
  bool _loading = true;

  bool get _isMandor => widget.role == 'mandor';

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadCandidates() async {
    try {
      final list =
          await widget.repository.fetchSubstituteCandidates(mandor: _isMandor);
      if (!mounted) return;
      setState(() {
        _candidates = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final roleLabel = _isMandor ? 'Mandor' : 'Worker';

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
                  color: AppColors.orangeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_add_alt_1_outlined,
                  color: AppColors.orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign Pengganti $roleLabel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      '${widget.substituteForName} berhalangan hadir',
                      style: TextStyle(fontSize: 12, color: AppColors.textSub),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orangeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.substituteForName} tetap tercatat di proyek. '
                    'Pengganti hanya bersifat sementara.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.orange,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pilih $roleLabel Pengganti',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          _buildPicker(),
          const SizedBox(height: 16),
          Text(
            'Alasan Penggantian (opsional)',
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
            maxLength: 300,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Mis. Sakit demam, izin keluarga...',
              hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
              border: _border(AppColors.border),
              enabledBorder: _border(AppColors.border),
              focusedBorder: _border(AppColors.primaryText),
              contentPadding: const EdgeInsets.all(12),
              counterStyle: TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 8),
          BlocConsumer<SubstituteBloc, SubstituteState>(
            listener: (context, state) {
              if (state is SubstituteSuccess || state is SubstituteFailure) {
                Navigator.pop(context);
              }
            },
            builder: (context, state) {
              final isLoading = state is SubstituteLoading;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_selected == null || isLoading)
                      ? null
                      : () {
                          final reason = _reasonController.text.trim();
                          context.read<SubstituteBloc>().add(
                                AssignSubstitute(
                                  projectId: widget.projectId,
                                  role: widget.role,
                                  substituteFor: widget.substituteForId,
                                  replacementId: _selected!.id,
                                  reason: reason.isEmpty ? null : reason,
                                ),
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.solid(AppColors.orange),
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.person_add_alt_1_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                  label: Text(
                    isLoading ? 'Menyimpan...' : 'Tugaskan Pengganti',
                    style: const TextStyle(
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

  Widget _buildPicker() {
    if (_loading) {
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
    if (_candidates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Tidak ada kandidat pengganti yang tersedia',
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
        child: DropdownButton<EstSubstituteCandidate>(
          value: _selected,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'Pilih pengganti...',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          items: _candidates
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      c.name,
                      style: TextStyle(fontSize: 13, color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selected = v),
        ),
      ),
    );
  }
}
