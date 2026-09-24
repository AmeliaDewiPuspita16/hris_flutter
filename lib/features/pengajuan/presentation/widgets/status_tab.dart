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

enum _StatusFilter { all, pending, approved, rejected }

/// Tab "Status" — riwayat pengajuan dengan filter status & jenis.
///
/// Sumber datanya [LeaveHistoryBloc]. Filter di sini murni state tampilan
/// (menyaring data yang sudah termuat), bukan sumber data itu sendiri —
/// jadi tetap disimpan lokal di widget ini, bukan di bloc.
class StatusTab extends StatefulWidget {
  const StatusTab({super.key, required this.role});

  final Role role;

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  _StatusFilter _statusFilter = _StatusFilter.all;
  String _typeFilter = 'all';

  List<LeaveHistoryEntry> _applyFilter(List<LeaveHistoryEntry> items) {
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
            _buildFilter(),
            Expanded(child: filtered.isEmpty ? _buildEmpty() : _buildHistory(filtered)),
          ],
        );
      },
    );
  }

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._StatusFilter.values.map((filter) {
              final active = _statusFilter == filter;
              final label = filter.name[0].toUpperCase() + filter.name.substring(1);

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _statusFilter = filter),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }),
            Container(
              width: 1,
              height: 20,
              color: AppColors.border,
              margin: const EdgeInsets.symmetric(horizontal: 6),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _typeFilter,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Types')),
                    ...LeaveTypeX.optionsFor(widget.role).map(
                      (type) => DropdownMenuItem(value: type.label, child: Text(type.label)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _typeFilter = value ?? 'all'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(List<LeaveHistoryEntry> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final history = items[index];

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: history.typeBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      history.type,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: history.typeColor,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
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
