import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/opname_formatters.dart';
import '../../data/inventory_stock_opname_repository.dart';
import '../../domain/opname_item.dart';
import '../../domain/opname_record.dart';
import '../widgets/opname_line_tile.dart';
import '../widgets/opname_status_badge.dart';
import '../widgets/opname_app_bar.dart';
import '../widgets/opname_card.dart';
import '../widgets/opname_text_styles.dart';

/// Detail of a single opname (read-only): document info, a status note,
/// then the counted items grouped by location.
class OpnameHistoryDetailScreen extends StatefulWidget {
  final int id;

  /// The code (e.g. SOP00003), used as the title while the content loads.
  final String code;

  const OpnameHistoryDetailScreen({
    super.key,
    required this.id,
    required this.code,
  });

  @override
  State<OpnameHistoryDetailScreen> createState() =>
      _OpnameHistoryDetailScreenState();
}

class _OpnameHistoryDetailScreenState extends State<OpnameHistoryDetailScreen> {
  OpnameDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await context.read<InventoryStockOpnameRepository>().fetchDetail(widget.id);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OpnameAppBar(title: widget.code.isEmpty ? 'Detail Opname' : widget.code),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_outlined,
                            size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _load,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _content(_detail!),
    );
  }

  Widget _content(OpnameDetail d) {
    // Group by location, preserving the order of appearance.
    final groups = <String, List<OpnameItem>>{};
    for (final e in d.items) {
      groups.putIfAbsent(e.location, () => []).add(e);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _InfoCard(detail: d),
          const SizedBox(height: 10),
          _StatusNote(detail: d),
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.place, size: 16, color: AppColors.primaryText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: OpnameTextStyles.bodyBold,
                    ),
                  ),
                  Text(
                      entry.value.length == 1
                          ? '1 item'
                          : '${entry.value.length} items',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            for (final item in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OpnameLineTile(item: item), // no onEdit = read-only
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final OpnameDetail detail;

  const _InfoCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    return OpnameCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.date == null ? '-' : formatShortDate(d.date!),
                  style: OpnameTextStyles.bodyBold,
                ),
              ),
              OpnameStatusBadge(status: d.status),
            ],
          ),
          Divider(height: 24, color: AppColors.border),
          _row('Counted by', d.countedBy),
          if (d.createdAt != null)
            _row('Saved', formatShortDateTime(d.createdAt!)),
          if (d.status == OpnameStatus.confirmed && d.confirmedBy != null)
            _row(
              'Confirmed',
              d.confirmedAt == null
                  ? d.confirmedBy!
                  : '${d.confirmedBy} · ${formatShortDateTime(d.confirmedAt!)}',
            ),
          if (d.notes != null) _row('Notes', d.notes!),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

/// A short explanation of the status, so staff know whether stock has
/// changed yet.
class _StatusNote extends StatelessWidget {
  final OpnameDetail detail;

  const _StatusNote({required this.detail});

  @override
  Widget build(BuildContext context) {
    final confirmed = detail.status == OpnameStatus.confirmed;
    final text = switch (detail.status) {
      OpnameStatus.draft =>
        'Draft: awaiting admin confirmation on the website. Stock has not changed.',
      OpnameStatus.confirmed =>
        'Confirmed. Stock has been adjusted to match this count.',
      OpnameStatus.other => 'The app does not recognize this opname status.',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: confirmed ? AppColors.presentBg : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            confirmed ? Icons.check_circle_outline : Icons.info_outline,
            size: 20,
            color: confirmed ? AppColors.present : AppColors.primaryText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.label.copyWith(
                color: confirmed ? AppColors.present : AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
