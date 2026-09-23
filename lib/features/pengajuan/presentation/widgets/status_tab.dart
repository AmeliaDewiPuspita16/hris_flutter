import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../shared/domain/role.dart';
import '../../domain/leave_type.dart';

enum _StatusFilter {
  semua,
  menunggu,
  disetujui,
  ditolak,
}

class StatusTab extends StatefulWidget {
  const StatusTab({
    super.key,
    required this.role,
  });

  final Role role;

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  _StatusFilter _statusFilter = _StatusFilter.semua;

  String _typeFilter = 'semua';

  static const historyItems = [
    _HistoryItem(
      'Cuti Tahunan',
      AppColors.primaryMid,
      AppColors.primaryLight,
      '17–19 Jul 2026',
      AppStatus.present,
      'Disetujui oleh Dewi Kusuma',
    ),
    _HistoryItem(
      'Lembur',
      Color(0xFF6B46C1),
      Color(0xFFFAF5FF),
      '28 Agu 2026 · 18:30–20:45',
      AppStatus.pending,
      'Menunggu persetujuan',
    ),
    _HistoryItem(
      'Cek Kesehatan',
      AppColors.presentMid,
      AppColors.presentBg,
      '10 Agu 2026',
      AppStatus.present,
      'Disetujui',
    ),
    _HistoryItem(
      'MC/Sakit',
      AppColors.rejected,
      AppColors.rejectedBg,
      '5–6 Agu 2026',
      AppStatus.rejected,
      'Ditolak: Surat dokter tidak lengkap',
    ),
    _HistoryItem(
      'Izin',
      AppColors.pending,
      AppColors.pendingBg,
      '25 Jul 2026 · Setengah Hari',
      AppStatus.present,
      'Disetujui',
    ),
    _HistoryItem(
      'Cuti Tahunan',
      AppColors.primaryMid,
      AppColors.primaryLight,
      '1–3 Jul 2026',
      AppStatus.present,
      'Disetujui',
    ),
  ];

  List<_HistoryItem> get filteredHistory {
    return historyItems.where((history) {
      if (_statusFilter == _StatusFilter.menunggu &&
          history.status != AppStatus.pending) {
        return false;
      }

      if (_statusFilter == _StatusFilter.disetujui &&
          history.status != AppStatus.present) {
        return false;
      }

      if (_statusFilter == _StatusFilter.ditolak &&
          history.status != AppStatus.rejected) {
        return false;
      }

      if (_typeFilter != 'semua' && history.type != _typeFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilter(),
        Expanded(
          child: filteredHistory.isEmpty ? _buildEmpty() : _buildHistory(),
        ),
      ],
    );
  }

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ..._StatusFilter.values.map((filter) {
              final active = _statusFilter == filter;

              final label =
                  filter.name[0].toUpperCase() + filter.name.substring(1);

              return Padding(
                padding: const EdgeInsets.only(
                  right: 6,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _statusFilter = filter;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
              margin: const EdgeInsets.symmetric(
                horizontal: 6,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border,
                  width: 1.5,
                ),
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
                    const DropdownMenuItem(
                      value: 'semua',
                      child: Text('Semua Jenis'),
                    ),
                    ...LeaveTypeX.optionsFor(widget.role).map(
                      (type) {
                        return DropdownMenuItem(
                          value: type.label,
                          child: Text(type.label),
                        );
                      },
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _typeFilter = value ?? 'semua';
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: filteredHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final history = filteredHistory[index];

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge Tipe (Kiri)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: history.typeBg,
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
                  // Badge Status (Kanan)
                  StatusBadge(
                    status: history.status,
                  ),
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
          Text(
            '🔍',
            style: TextStyle(fontSize: 36),
          ),
          SizedBox(height: 12),
          Text(
            'Tidak ada data ditemukan',
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

class _HistoryItem {
  const _HistoryItem(
    this.type,
    this.typeColor,
    this.typeBg,
    this.date,
    this.status,
    this.note,
  );

  final String type;
  final Color typeColor;
  final Color typeBg;
  final String date;
  final AppStatus status;
  final String note;
}
