import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../shared/domain/role.dart';
import '../../domain/leave_history_entry.dart';
import '../../domain/leave_type.dart';
import '../bloc/history/leave_history_bloc.dart';
import '../bloc/history/leave_history_state.dart';
import 'leave_detail_sheet.dart';

enum _StatusFilter { all, pending, approved, rejected }

/// Tab "Status" — riwayat pengajuan dengan pencarian & filter (status dan/atau
/// jenis cuti).
///
/// Sumber datanya [LeaveHistoryBloc]. Pencarian dan filter di sini murni state
/// tampilan (menyaring data yang sudah termuat), bukan sumber data itu
/// sendiri — jadi tetap disimpan lokal di widget ini, bukan di bloc.
class StatusTab extends StatefulWidget {
  const StatusTab({super.key, required this.role});

  final Role role;

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  final _searchController = TextEditingController();
  String _query = '';
  _StatusFilter _statusFilter = _StatusFilter.all;
  String _typeFilter = 'all';

  bool get _hasActiveFilter => _statusFilter != _StatusFilter.all || _typeFilter != 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LeaveHistoryEntry> _applyFilter(List<LeaveHistoryEntry> items) {
    final query = _query.trim().toLowerCase();

    return items.where((history) {
      if (_statusFilter == _StatusFilter.pending && history.status != AppStatus.pending) {
        return false;
      }
      if (_statusFilter == _StatusFilter.approved && history.status != AppStatus.present) {
        return false;
      }
      if (_statusFilter == _StatusFilter.rejected && history.status != AppStatus.rejected) {
        return false;
      }
      if (_typeFilter != 'all' && history.type != _typeFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final haystack =
            '${history.type} ${history.date} ${history.note} ${history.reason ?? ''}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaveHistoryBloc, LeaveHistoryState>(
      builder: (context, state) {
        if (state.status == LeaveHistoryStatus.loading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == LeaveHistoryStatus.failure && state.items.isEmpty) {
          return Center(
            child: Text(
              state.errorMessage ?? 'Failed to load history.',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          );
        }

        final filtered = _applyFilter(state.items);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchBar(),
            Expanded(child: filtered.isEmpty ? _buildEmpty() : _buildHistory(filtered)),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(fontSize: 13, color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Search leave requests',
                  hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _openFilterSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _hasActiveFilter ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 18,
                color: _hasActiveFilter ? Colors.white : AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet filter: bisa pilih berdasarkan status, jenis cuti, atau
  /// keduanya sekaligus. Pilihan baru berlaku setelah tombol Apply ditekan.
  void _openFilterSheet() {
    var status = _statusFilter;
    var type = _typeFilter;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Filter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setSheetState(() {
                          status = _StatusFilter.all;
                          type = 'all';
                        }),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const _SheetLabel('Status'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _StatusFilter.values.map((filter) {
                      final label = filter.name[0].toUpperCase() + filter.name.substring(1);
                      return _FilterChip(
                        label: label,
                        selected: status == filter,
                        onTap: () => setSheetState(() => status = filter),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  const _SheetLabel('Leave Type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: type == 'all',
                        onTap: () => setSheetState(() => type = 'all'),
                      ),
                      ...LeaveTypeX.optionsFor(widget.role).map(
                        (option) => _FilterChip(
                          label: option.label,
                          selected: type == option.label,
                          onTap: () => setSheetState(() => type = option.label),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _statusFilter = status;
                          _typeFilter = type;
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistory(List<LeaveHistoryEntry> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final history = items[index];
        final icon = LeaveTypeX.fromLabel(history.type)?.icon ?? Icons.event_note_outlined;

        return AppCard(
          padding: const EdgeInsets.all(14),
          // Tap kartu = lihat detail, sama seperti baris di tab Ringkasan.
          onTap: () => showLeaveDetailSheet(context, history),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: history.typeBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: history.typeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            history.type,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        StatusBadge(status: history.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      history.date,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      history.note,
                      style: TextStyle(
                        fontSize: 11,
                        color: history.status == AppStatus.rejected
                            ? AppColors.rejected
                            : AppColors.textMuted,
                        fontWeight: history.status == AppStatus.rejected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔍', style: TextStyle(fontSize: 36)),
          SizedBox(height: 12),
          Text(
            'No data found',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
