import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/overtime_format.dart';
import '../../domain/overtime_request_entry.dart';
import '../bloc/requests/overtime_requests_bloc.dart';
import '../bloc/requests/overtime_requests_event.dart';
import '../bloc/requests/overtime_requests_state.dart';

enum _Filter {
  all('All'),
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  const _Filter(this.label);

  final String label;

  bool matches(AppStatus status) => switch (this) {
        _Filter.all => true,
        _Filter.pending => status == AppStatus.pending,
        _Filter.approved => status == AppStatus.present,
        _Filter.rejected => status == AppStatus.rejected,
      };
}

/// Tab "Status" — riwayat pengajuan lembur dengan filter status. Datanya
/// dimuat [OvertimeRequestsBloc].
class OvertimeStatusTab extends StatefulWidget {
  const OvertimeStatusTab({super.key});

  @override
  State<OvertimeStatusTab> createState() => _OvertimeStatusTabState();
}

class _OvertimeStatusTabState extends State<OvertimeStatusTab> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OvertimeRequestsBloc, OvertimeRequestsState>(
      builder: (context, state) => switch (state.status) {
        OvertimeRequestsStatus.initial ||
        OvertimeRequestsStatus.loading =>
          const _RequestsSkeleton(),
        OvertimeRequestsStatus.failure => _ErrorState(
            message: state.errorMessage ?? 'Failed to load overtime requests.',
            onRetry: () => context
                .read<OvertimeRequestsBloc>()
                .add(const OvertimeRequestsLoaded()),
          ),
        OvertimeRequestsStatus.success => _buildList(state.requests),
      },
    );
  }

  Widget _buildList(List<OvertimeRequestEntry> requests) {
    final items = [
      for (final entry in requests)
        if (_filter.matches(entry.status)) entry,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            itemCount: _Filter.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final filter = _Filter.values[index];
              final selected = filter == _filter;

              return InkWell(
                onTap: () => setState(() => _filter = filter),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primaryText : AppColors.border,
                    ),
                  ),
                  child: Text(
                    filter.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textMid,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No overtime requests found.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _RequestCard(entry: items[index]),
                ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.entry});

  final OvertimeRequestEntry entry;

  String get _dateText {
    final date = entry.date;
    return date == null ? '-' : DateFormat('EEE, d MMM yyyy', 'en_US').format(date);
  }

  String get _detailText {
    final hours = entry.durationHours;
    return hours == null
        ? entry.timeRange
        : '${entry.timeRange} · ${formatOvertimeDuration((hours * 60).round())}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _dateText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              StatusBadge(status: entry.status, label: entry.statusLabel),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _detailText,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            entry.reason,
            style: TextStyle(fontSize: 12, color: AppColors.textMid, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 32, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryText,
              side: BorderSide(color: AppColors.primaryText),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

/// Skeleton daftar pengajuan, meniru [_RequestCard].
class _RequestsSkeleton extends StatelessWidget {
  const _RequestsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const ShimmerCard(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLine(width: 130, height: 13),
            SizedBox(height: 8),
            ShimmerLine(width: 110, height: 10),
            SizedBox(height: 12),
            ShimmerLine(width: 200, height: 11),
          ],
        ),
      ),
    );
  }
}
