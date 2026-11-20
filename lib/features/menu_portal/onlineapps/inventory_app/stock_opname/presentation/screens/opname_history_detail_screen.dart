import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../data/inventory_stock_opname_repository.dart';
import '../../domain/opname_record.dart';
import '../widgets/opname_confirm_dialog.dart';
import '../widgets/opname_detail_action_bar.dart';
import '../widgets/opname_detail_header.dart';
import '../widgets/opname_detail_sections.dart';
import '../widgets/opname_theme.dart';
import 'opname_count_screen.dart';

/// Detail of a single opname: document info, a status note, then the counted
/// items grouped by location. A draft (`can_edit`) can be edited,
/// confirmed or deleted from here; a confirmed opname is read-only.
///
/// The page holds the state and the actions, plus its own frame (background
/// image and back button, at the bottom of this file). The blocks on it live
/// in `widgets/`: the header with its stats (`opname_detail_header`), the cards
/// and the item list (`opname_detail_sections`), the action bar and the
/// confirm dialog.
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
      final d = await context
          .read<InventoryStockOpnameRepository>()
          .fetchDetail(widget.id);
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

  /// "5 counted rows", for the confirm and delete dialogs.
  String _rowsLabel(OpnameDetail d) {
    final n = d.items.where((e) => e.isCounted).length;
    return '$n counted ${n == 1 ? 'row' : 'rows'}';
  }

  Future<void> _continueCounting(OpnameDetail d) async {
    final changed = await Navigator.push<bool>(
      context,
      opnameRoute<bool>(OpnameCountScreen(draft: d)),
    );
    if (changed == true && mounted) _load();
  }

  Future<void> _confirmDraft(OpnameDetail d) async {
    final ok = await showOpnameConfirmDialog(
      context,
      title: 'Confirm this opname?',
      message: 'The stock of every counted location will be set to the '
          'counted quantity and the differences will be booked as stock '
          'transactions. This cannot be undone.',
      confirmLabel: 'Confirm',
      icon: Icons.fact_check_outlined,
      subject: d.code,
      subjectNote: _rowsLabel(d),
    );
    if (!ok || !mounted) return;

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
    final ok = await showOpnameConfirmDialog(
      context,
      title: 'Delete this draft?',
      message: 'The draft and all of its counted rows will be permanently '
          'deleted. This cannot be undone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      danger: true,
      subject: d.code,
      subjectNote: _rowsLabel(d),
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
    return OpnameDetailActionBar(
      detail: d,
      acting: _acting,
      onDelete: () => _deleteDraft(d),
      onEdit: () => _continueCounting(d),
      onConfirm: () => _confirmDraft(d),
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

    // Spinner only on the first load; a refresh keeps the old content.
    final detail = _detail;
    if (detail == null && _loading) {
      return Column(
        children: [
          _DetailTopBar(onBack: back),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (_error != null) {
      return Column(
        children: [
          _DetailTopBar(onBack: back),
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
    final notes = d.notes?.trim() ?? '';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _DetailTopBar(onBack: onBack),
          const SizedBox(height: 10),
          OpnameDetailHeader(detail: d),
          const SizedBox(height: 16),
          OpnameStatsCard(stats: opnameStatsOf(d)),
          const SizedBox(height: 12),
          OpnameStatusNote(detail: d),
          const SizedBox(height: 12),
          OpnameImpactCard(detail: d),
          const SizedBox(height: 12),
          OpnameDetailsCard(detail: d),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            OpnameNotesCard(notes: notes),
          ],
          const SizedBox(height: 12),
          OpnameProgressCard(detail: d),
          OpnameItemsSection(items: d.items),
        ],
      ),
    );
  }
}

/// Kerangka halaman detail opname: gambar latar portal di balik bagian atas
/// yang memudar ke warna halaman, jadi layar tidak memakai app bar dan header
/// langsung berada di atas gambar (gaya yang sama dengan detail work permit).
class _DetailBackdrop extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;

  const _DetailBackdrop({
    required this.child,
    this.bottomNavigationBar,
  });

  /// Tinggi gambar di bawah status bar; ujung bawahnya dipudarkan.
  static const double _imageHeight = 230;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Gambarnya terang, jadi ikon status bar harus gelap.
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
              // Mode terang saja; mode gelap cukup memakai `portalBackdrop`.
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

/// Tombol kembali bulat di atas gambar latar.
class _DetailTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _DetailTopBar({required this.onBack});

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
