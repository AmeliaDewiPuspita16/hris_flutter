import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../data/est_project_repository.dart';
import '../../domain/est_available_worker.dart';
import '../bloc/add_workers/add_workers_bloc.dart';
import '../bloc/add_workers/add_workers_event.dart';
import '../bloc/add_workers/add_workers_state.dart';

/// Bottom sheet "Tambah Worker": cari worker yang tersedia, pilih banyak,
/// lalu kirim lewat [AddWorkersBloc] (harus tersedia di context).
class EstAddWorkerSheet extends StatefulWidget {
  const EstAddWorkerSheet({
    super.key,
    required this.projectId,
    required this.repository,
  });

  final int projectId;
  final EstProjectRepository repository;

  @override
  State<EstAddWorkerSheet> createState() => _EstAddWorkerSheetState();
}

class _EstAddWorkerSheetState extends State<EstAddWorkerSheet> {
  final _searchCtrl = TextEditingController();

  List<EstAvailableWorker> _workers = [];
  // Persist pilihan antar pencarian
  final Map<int, EstAvailableWorker> _selected = {};
  bool _loading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchWorkers({String search = ''}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.repository.fetchAvailableWorkers(
        query: {
          'project_id': widget.projectId.toString(),
          if (search.isNotEmpty) 'search': search,
        },
      );
      if (!mounted) return;
      setState(() {
        _workers = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat daftar worker';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchWorkers(search: value.trim());
    });
  }

  void _toggle(EstAvailableWorker w) {
    setState(() {
      if (_selected.containsKey(w.id)) {
        _selected.remove(w.id);
      } else {
        _selected[w.id] = w;
      }
    });
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.only(bottom: bottomInset),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                    Icons.person_add_alt_1_outlined,
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
                        'Tambah Worker',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'Pilih DW untuk ditambahkan ke proyek ini',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari nama / NIK worker...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon:
                    Icon(Icons.search, size: 18, color: AppColors.textMuted),
                isDense: true,
                border: _border(AppColors.border),
                enabledBorder: _border(AppColors.border),
                focusedBorder: _border(AppColors.primaryText),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(child: _buildList()),
            const SizedBox(height: 12),
            BlocConsumer<AddWorkersBloc, AddWorkersState>(
              listener: (context, state) {
                if (state is AddWorkersSuccess || state is AddWorkersFailure) {
                  Navigator.pop(context);
                }
              },
              builder: (context, state) {
                final isLoading = state is AddWorkersLoading;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_selected.isEmpty || isLoading)
                        ? null
                        : () {
                            context.read<AddWorkersBloc>().add(
                                  SubmitAddWorkers(
                                    projectId: widget.projectId,
                                    workerIds: _selected.keys.toList(),
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
                      isLoading
                          ? 'Menyimpan...'
                          : _selected.isEmpty
                              ? 'Tambah Worker'
                              : 'Tambah ${_selected.length} Worker',
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
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryText,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.rejectedBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.rejected, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(fontSize: 12, color: AppColors.rejected),
              ),
            ),
            TextButton(
              onPressed: () => _fetchWorkers(search: _searchCtrl.text.trim()),
              child: Text(
                'Coba Lagi',
                style: TextStyle(color: AppColors.rejected, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    if (_workers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Tidak ada worker yang tersedia',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _workers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final w = _workers[i];
        final isSelected = _selected.containsKey(w.id);
        return GestureDetector(
          onTap: () => _toggle(w),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.presentBg : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primaryText : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textSub,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        w.placement == null || w.placement!.isEmpty
                            ? w.skills
                            : '${w.skills} · ${w.placement}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textSub),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: isSelected ? AppColors.primaryText : AppColors.border,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
