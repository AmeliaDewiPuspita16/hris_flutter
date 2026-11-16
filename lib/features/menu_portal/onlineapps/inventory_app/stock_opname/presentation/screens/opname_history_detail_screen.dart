import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/opname_formatters.dart';
import '../../data/inventory_stock_opname_repository.dart';
import '../../domain/opname_item.dart';
import '../../domain/opname_record.dart';
import '../widgets/difference_label.dart';
import '../widgets/opname_line_tile.dart';
import '../widgets/opname_card.dart';
import '../widgets/opname_confirm_dialog.dart';
import '../widgets/opname_text_styles.dart';
import '../widgets/opname_theme.dart';
import 'opname_count_screen.dart';

/// Detail of a single opname: document info, a status note, then the counted
/// items grouped by location. A draft (`can_edit`) can be edited,
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
    final counted = d.items.where((e) => e.isCounted).length;
    final ok = await showOpnameConfirmDialog(
      context,
      title: 'Delete this draft?',
      message: 'The draft and all of its counted rows will be permanently '
          'deleted. This cannot be undone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      danger: true,
      subject: d.code,
      subjectNote: '$counted counted ${counted == 1 ? 'row' : 'rows'}',
    );
    if (!ok || !mounted) return;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The result of confirming, right next to the button.
              Align(
                alignment: Alignment.centerLeft,
                child: _StatsChips(stats: _statsOf(d)),
              ),
              const SizedBox(height: 10),
              Row(
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
                  child: const Text('Edit'),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DetailBackdrop(
      bottomNavigationBar: _actionBar(_detail),
      child: SafeArea(
        bottom: false,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    void back() => Navigator.of(context).maybePop();

    // First load: the code is already known, so show it under the top bar.
    final detail = _detail;
    if (detail == null && _loading) {
      return Column(
        children: [
          _TopBar(onBack: back),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (_error != null) {
      return Column(
        children: [
          _TopBar(onBack: back),
          Expanded(
            child: Center(
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
            ),
          ),
        ],
      );
    }

    return _content(detail!, onBack: back);
  }

  Widget _content(OpnameDetail d, {required VoidCallback onBack}) {
    // Group by location, preserving the order of appearance.
    final groups = <String, List<OpnameItem>>{};
    for (final e in d.items) {
      groups.putIfAbsent(e.location, () => []).add(e);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _TopBar(onBack: onBack),
          const SizedBox(height: 10),
          _Header(detail: d),
          const SizedBox(height: 16),
          _StatsCard(stats: _statsOf(d)),
          const SizedBox(height: 12),
          _StatusNote(detail: d),
          const SizedBox(height: 12),
          _ImpactCard(detail: d),
          const SizedBox(height: 12),
          _DetailsCard(detail: d),
          const SizedBox(height: 12),
          _ProgressCard(detail: d),
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Text(
              d.items.length == 1 ? 'Item' : 'Items (${d.items.length})',
              style: OpnameTextStyles.bodyBold.copyWith(fontSize: 16),
            ),
          ),
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
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            for (final item in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                // no onEdit = read-only
                child: OpnameLineTile(item: item),
              ),
          ],
        ],
      ),
    );
  }
}

/// Counted lines, and how many of them are a surplus or a shortage. Lines are
/// counted rather than summed, because the items can have different units.
({int counted, int surplus, int shortage}) _statsOf(OpnameDetail d) {
  final counted = d.items.where((e) => e.isCounted).toList();
  return (
    counted: counted.length,
    surplus: counted.where((e) => (e.difference ?? 0) > 0).length,
    shortage: counted.where((e) => (e.difference ?? 0) < 0).length,
  );
}

/// The page frame: the portal background image behind the top, fading into
/// the page colour, so the screen has no app bar and the header sits straight
/// on the image (same look as the work-permit detail).
class _DetailBackdrop extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;

  const _DetailBackdrop({required this.child, this.bottomNavigationBar});

  /// Height of the image below the status bar; its lower edge is faded out.
  static const double _imageHeight = 230;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The image is light, so the status bar icons must be dark.
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            AppColors.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            AppColors.isDark ? Brightness.dark : Brightness.light,
      ),
      child: DecoratedBox(
        decoration: AppColors.portalBackdrop,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: bottomNavigationBar,
          body: Stack(
            children: [
              // Light mode only; dark mode uses `portalBackdrop` alone.
              if (!AppColors.isDark) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topInset + _imageHeight,
                  child: SvgPicture.asset(
                    'assets/icons/header-background.svg',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: topInset + _imageHeight - 40,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.bg.withValues(alpha: 0),
                          AppColors.bg,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Round back button on the image.
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: AppColors.card,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: Colors.black12,
          child: InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: Tooltip(
              message: 'Back',
              child: SizedBox.square(
                dimension: 44,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The top of the detail: a small label, the opname code, then pills for the
/// status, date and counter.
class _Header extends StatelessWidget {
  final OpnameDetail detail;

  const _Header({required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STOCK OPNAME',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          d.code,
          style: OpnameTextStyles.title.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusPill(status: d.status),
            _InfoPill(
              icon: Icons.calendar_today_outlined,
              text: d.date == null ? '-' : formatShortDate(d.date!),
            ),
            _InfoPill(icon: Icons.person_outline, text: d.countedBy),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final OpnameStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, label, fg, bg) = switch (status) {
      OpnameStatus.draft => (
          Icons.edit_note_rounded,
          'Draft',
          AppColors.pending,
          AppColors.pending.withValues(alpha: 0.14),
        ),
      OpnameStatus.confirmed => (
          Icons.verified_rounded,
          'Confirmed',
          AppColors.present,
          AppColors.presentBg,
        ),
      OpnameStatus.other => (
          Icons.help_outline_rounded,
          'Unknown',
          AppColors.textMuted,
          AppColors.neutralBg,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.primaryText),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The result at a glance: counted, surplus and shortage as three big
/// numbers in one card.
class _StatsCard extends StatelessWidget {
  final ({int counted, int surplus, int shortage}) stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final divider = Container(width: 1, height: 40, color: AppColors.border);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.fact_check_outlined,
              value: stats.counted,
              label: 'Counted',
              color: AppColors.primaryText,
              background: AppColors.primaryLight,
            ),
          ),
          divider,
          Expanded(
            child: _StatTile(
              icon: Icons.arrow_upward_rounded,
              value: stats.surplus,
              label: 'Surplus',
              color: OpnameTextStyles.success,
              background: AppColors.presentBg,
            ),
          ),
          divider,
          Expanded(
            child: _StatTile(
              icon: Icons.arrow_downward_rounded,
              value: stats.shortage,
              label: 'Shortage',
              color: AppColors.rejected,
              background: AppColors.rejectedBg,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final Color background;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

/// "N counted · N surplus · N shortage" as three small pills.
class _StatsChips extends StatelessWidget {
  final ({int counted, int surplus, int shortage}) stats;

  const _StatsChips({required this.stats});

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, String text, Color fg, Color bg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        chip(
          Icons.fact_check_outlined,
          '${stats.counted} counted',
          AppColors.primaryText,
          AppColors.card,
        ),
        chip(
          Icons.arrow_upward_rounded,
          '${stats.surplus} surplus',
          OpnameTextStyles.success,
          AppColors.presentBg,
        ),
        chip(
          Icons.arrow_downward_rounded,
          '${stats.shortage} shortage',
          AppColors.rejected,
          AppColors.rejectedBg,
        ),
      ],
    );
  }
}

/// "What will change" (draft) / "What changed" (confirmed): the lines whose
/// count differs from the system stock, as `system -> counted` with the
/// difference. Lines that match are only mentioned in one sentence.
class _ImpactCard extends StatelessWidget {
  final OpnameDetail detail;

  const _ImpactCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final draft = d.status != OpnameStatus.confirmed;
    final counted = d.items.where((e) => e.isCounted).toList();
    final changed = counted.where((e) => (e.difference ?? 0) != 0).toList();
    final same = counted.length - changed.length;

    return _SectionCard(
      title: draft ? 'What will change' : 'What changed',
      icon: Icons.swap_vert_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (changed.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                draft
                    ? 'No stock will change: every count matches the system '
                        'stock.'
                    : 'No stock was changed: every count matched the system '
                        'stock.',
                style: AppTextStyles.body.copyWith(color: AppColors.textMid),
              ),
            )
          else
            for (var i = 0; i < changed.length; i++)
              _ImpactRow(item: changed[i], last: i == changed.length - 1),
          if (same > 0 && changed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                same == 1
                    ? '1 more item matches the system stock.'
                    : '$same more items match the system stock.',
                style: AppTextStyles.caption,
              ),
            ),
          if (draft)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                'Based on the current stock. It is recalculated when the '
                'draft is confirmed.',
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final OpnameItem item;
  final bool last;

  const _ImpactRow({required this.item, required this.last});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: OpnameTextStyles.bodyBold.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.code} · ${item.location}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          formatQty(item.systemQty),
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textMid,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${formatQty(item.countedQty!)} ${item.unit}',
                          style: OpnameTextStyles.bodyBold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DifferenceLabel(difference: item.difference, unit: item.unit),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

/// A white card with an icon + title, used for each block of the detail.
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return OpnameCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryText),
              const SizedBox(width: 8),
              Text(title, style: OpnameTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Location, counter and notes as icon rows separated by thin lines.
class _DetailsCard extends StatelessWidget {
  final OpnameDetail detail;

  const _DetailsCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final rows = <(IconData, String, String)>[
      if (d.locationLabel.isNotEmpty)
        (Icons.place_outlined, 'Location', d.locationLabel),
      (Icons.person_outline, 'Counted by', d.countedBy),
      if (d.notes != null) (Icons.notes_rounded, 'Notes', d.notes!),
    ];

    return _SectionCard(
      title: 'Opname Details',
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            _DetailRow(
              icon: rows[i].$1,
              label: rows[i].$2,
              value: rows[i].$3,
              last: i == rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: AppColors.primaryText),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: Text(label, style: AppTextStyles.caption),
              ),
              Expanded(child: Text(value, style: AppTextStyles.body)),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

/// Who saved the count and who confirmed it (or that it is still waiting),
/// shown like the approvals block of the work-permit detail.
class _ProgressCard extends StatelessWidget {
  final OpnameDetail detail;

  const _ProgressCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final confirmed = d.status == OpnameStatus.confirmed;

    return _SectionCard(
      title: 'Progress',
      icon: Icons.timeline_rounded,
      child: Column(
        children: [
          _StepRow(
            done: true,
            label: 'Counted & saved by',
            value: d.createdBy ?? d.countedBy,
            when: d.createdAt == null ? null : formatShortDateTime(d.createdAt!),
            last: false,
          ),
          _StepRow(
            done: confirmed,
            label: 'Confirmed by',
            value: confirmed
                ? (d.confirmedBy ?? '-')
                : 'Waiting for confirmation',
            when: confirmed && d.confirmedAt != null
                ? formatShortDateTime(d.confirmedAt!)
                : null,
            last: true,
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final bool done;
  final String label;
  final String value;
  final String? when;
  final bool last;

  const _StepRow({
    required this.done,
    required this.label,
    required this.value,
    required this.when,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                done ? Icons.check_circle : Icons.hourglass_empty_rounded,
                size: 20,
                color: done ? OpnameTextStyles.success : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.caption),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: done ? null : AppColors.textMid,
                      ),
                    ),
                    if (when != null) ...[
                      const SizedBox(height: 2),
                      Text(when!, style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: AppColors.border),
      ],
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
        'Draft: stock has not changed yet. System stock and differences use '
            'the current stock of each location and are recalculated when the '
            'opname is confirmed.',
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
            color: confirmed ? OpnameTextStyles.success : AppColors.primaryText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.label.copyWith(
                color: confirmed
                    ? OpnameTextStyles.success
                    : AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
