import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/opname_formatters.dart';
import '../../data/inventory_stock_opname_repository.dart';
import '../../domain/opname_record.dart';
import '../widgets/opname_status_badge.dart';
import 'opname_history_detail_screen.dart';
import '../widgets/opname_app_bar.dart';
import '../widgets/opname_card.dart';
import '../widgets/opname_chip_row.dart';
import '../widgets/opname_text_styles.dart';
import '../widgets/opname_theme.dart';

/// Opname history (read-only): a list of documents with a status filter.
/// Loaded page by page; the next page is fetched when the list is scrolled
/// near the end.
class OpnameHistoryScreen extends StatefulWidget {
  const OpnameHistoryScreen({super.key});

  @override
  State<OpnameHistoryScreen> createState() => _OpnameHistoryScreenState();
}

class _OpnameHistoryScreenState extends State<OpnameHistoryScreen> {
  static const _filters = <(String, OpnameStatus?)>[
    ('All', null),
    ('Draft', OpnameStatus.draft),
    ('Confirmed', OpnameStatus.confirmed),
  ];

  final _scroll = ScrollController();

  int _filter = 0;
  List<OpnameSummary> _rows = const [];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true; // loading the first page
  bool _loadingMore = false;
  String? _error;

  /// Incremented whenever the filter changes or the list is refreshed, so a
  /// late response to an old request does not overwrite the new list.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadFirst();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final nearEnd = _scroll.position.extentAfter < 300;
    if (nearEnd && _hasMore && !_loading && !_loadingMore && _error == null) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    try {
      final page = await context
          .read<InventoryStockOpnameRepository>()
          .fetchHistory(status: _filters[_filter].$2, page: 1);
      if (!mounted || gen != _generation) return;
      setState(() {
        _rows = page.items;
        _page = page.currentPage;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final gen = _generation;
    setState(() => _loadingMore = true);
    try {
      final page = await context
          .read<InventoryStockOpnameRepository>()
          .fetchHistory(status: _filters[_filter].$2, page: _page + 1);
      if (!mounted || gen != _generation) return;
      setState(() {
        _rows = [..._rows, ...page.items];
        _page = page.currentPage;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _setFilter(int i) {
    if (i == _filter) return;
    setState(() {
      _filter = i;
      _rows = const [];
    });
    _loadFirst();
  }

  Future<void> _open(OpnameSummary row) async {
    await Navigator.push(
      context,
      opnameRoute(OpnameHistoryDetailScreen(id: row.id, code: row.code)),
    );
    // The status may change in the portal while the detail is open; refresh.
    if (mounted) _loadFirst();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpnameAppBar(title: 'Opname History'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: OpnameChipRow(
              labels: [for (final f in _filters) f.$1],
              selectedIndex: _filter,
              onChanged: _setFilter,
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        text: _error!,
        actionLabel: 'Try again',
        onAction: _loadFirst,
      );
    }
    if (_rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFirst,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            _Message(
              icon: Icons.history,
              text: 'No opname history yet.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _rows.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i >= _rows.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final row = _rows[i];
          return _HistoryCard(row: row, onTap: () => _open(row));
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final OpnameSummary row;
  final VoidCallback onTap;

  const _HistoryCard({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = row.date == null ? '-' : formatShortDate(row.date!);
    return OpnameCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.code,
                    style: AppTextStyles.caption.copyWith(letterSpacing: 0.6)),
                const SizedBox(height: 2),
                Text(date, style: OpnameTextStyles.bodyBold),
                const SizedBox(height: 6),
                Text(
                  '${row.countedBy} · ${row.itemsCount} '
                  '${row.itemsCount == 1 ? 'item' : 'items'}',
                  style: AppTextStyles.label,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OpnameStatusBadge(status: row.status),
              const SizedBox(height: 10),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
