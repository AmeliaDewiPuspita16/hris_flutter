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
import '../widgets/opname_theme.dart';
import 'opname_count_screen.dart';

/// Detail of a single opname: document info, a status note, then the counted
/// items grouped by location. A draft (`can_edit`) can be continued,
/// confirmed or deleted from here; a confirmed opname is read-only.
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
  bool _acting = false; // a confirm / delete request is running
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
    } catch (e, st) {
      debugPrint('Stock opname detail failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load detail: $e';
        _loading = false;
      });
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _continueCounting(OpnameDetail d) async {
    final changed = await Navigator.push<bool>(
      context,
      opnameRoute<bool>(OpnameCountScreen(draft: d)),
    );
    if (changed == true && mounted) _load();
  }

  Future<void> _confirmDraft(OpnameDetail d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm this opname?'),
        content: const Text(
          'The stock of every counted location will be set to the counted '
          'quantity and the differences will be booked as stock '
          'transactions. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _acting = true);
    try {
      final updated =
          await context.read<InventoryStockOpnameRepository>().confirm(d.id);
      if (!mounted) return;
      setState(() {
        _detail = updated;
        _acting = false;
      });
      _showMessage('Stock opname confirmed. Stock has been adjusted.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      _showMessage(e.message);
    }
  }

  Future<void> _deleteDraft(OpnameDetail d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this draft?'),
        content: Text('${d.code} and its counted rows will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _acting = true);
    try {
      await context.read<InventoryStockOpnameRepository>().delete(d.id);
      if (!mounted) return;
      _showMessage('Draft deleted.');
      Navigator.pop(context); // the history list reloads on return
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      _showMessage(e.message);
    }
  }

  Widget? _actionBar(OpnameDetail? d) {
    if (d == null || !d.canEdit) return null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Delete draft',
                onPressed: _acting ? null : () => _deleteDraft(d),
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: OutlinedButton(
                  onPressed: _acting ? null : () => _continueCounting(d),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _acting ? null : () => _confirmDraft(d),
                  child: _acting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OpnameAppBar(title: widget.code.isEmpty ? 'Detail Opname' : widget.code),
      bottomNavigationBar: _actionBar(_detail),
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
          if (d.locationLabel.isNotEmpty) _row('Location', d.locationLabel),
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
        'Draft: stock has not changed. System quantities may still change '
            'until the draft is confirmed; the difference is final only then.',
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
