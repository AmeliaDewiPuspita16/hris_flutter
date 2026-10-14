import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/overtime_format.dart';
import '../../domain/overtime_request_entry.dart';

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

/// Tab "Status" — riwayat pengajuan lembur dengan filter status.
class OvertimeStatusTab extends StatefulWidget {
  const OvertimeStatusTab({super.key, required this.requests});

  final List<OvertimeRequestEntry> requests;

  @override
  State<OvertimeStatusTab> createState() => _OvertimeStatusTabState();
}

class _OvertimeStatusTabState extends State<OvertimeStatusTab> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final entry in widget.requests)
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
                      color: selected ? AppColors.primary : AppColors.border,
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
              ? const Center(
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
                  DateFormat('EEE, d MMM yyyy', 'en_US').format(entry.date),
                  style: const TextStyle(
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
            '${entry.timeRange} · ${formatOvertimeDuration(entry.minutes)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            entry.reason,
            style: const TextStyle(fontSize: 12, color: AppColors.textMid, height: 1.4),
          ),
        ],
      ),
    );
  }
}
