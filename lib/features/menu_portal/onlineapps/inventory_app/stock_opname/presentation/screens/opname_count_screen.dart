import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../../../../core/network/api_exception.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../data/inventory_stock_opname_repository.dart';
import '../../domain/opname_item.dart';
import '../widgets/opname_line_tile.dart';
import '../widgets/scanner_panel.dart';
import '../widgets/code_search_sheet.dart';
import '../widgets/item_info_sheet.dart';
import 'opname_detail_screen.dart';
import '../widgets/opname_app_bar.dart';
import '../widgets/opname_chip_row.dart';
import '../widgets/opname_text_styles.dart';
import '../widgets/opname_theme.dart';

/// Camera + item list screen. Labels carry the same code as a QR code
/// (square) and a Code 128 barcode (bars); both are read.
///
/// - Scan a STORE (`STR...`) -> the list shows only the items in that store.
/// - Scan a RACK (`PUT...`)  -> the list shows only the items on that rack.
/// - Scan an ITEM (`ESTM...` or its internal reference) -> opens the item
///   detail directly. An item that is not in the list is looked up on the
///   server: its data and stock per location are shown, and it can be counted
///   at the scanned store / rack.
/// - Edit button in the list -> opens the item detail.
class OpnameCountScreen extends StatefulWidget {
  const OpnameCountScreen({super.key, this.countedBy});

  /// Name of the logged-in user, sent as `counted_by` when the count is
  /// submitted. Falls back to "Mobile" when null.
  final String? countedBy;

  @override
  State<OpnameCountScreen> createState() => _OpnameCountScreenState();
}

class _OpnameCountScreenState extends State<OpnameCountScreen>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
    facing: CameraFacing.back,
    // Square codes (QR, Data Matrix) and bar codes. Inventory labels print
    // a QR code and a Code 128 barcode of the same code.
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.itf14,
      BarcodeFormat.codabar,
    ],
  );

  /// If true, the count is confirmed on the server right away and CHANGES
  /// STOCK (cannot be undone). If false, it is only saved as a draft and
  /// confirmed via the portal. Switch to true once this flow is tested.
  static const bool _confirmOnSubmit = false;

  List<OpnameItem> _items = const [];
  OpnameLocations _locations = const OpnameLocations();
  _Scope? _scope; // the active store / rack (from a store or rack scan)
  bool _cameraOn = true;
  bool _busy = false; // true while a code is processed / the detail is open
  bool _loading = true;
  bool _submitting = false;
  int _filter = 0; // 0 all, 1 not counted, 2 counted
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
    _load();
  }

  // ---------------------------------------------------------------- data

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final repo = context.read<InventoryStockOpnameRepository>();
    try {
      final items = await repo.fetchCountableItems();
      // The store / rack list is only supplementary (to recognize store and
      // rack codes). If it fails, scanning still works via location labels.
      final locations = await repo
          .fetchLocations()
          .catchError((_) => const OpnameLocations());
      if (!mounted) return;
      setState(() {
        _items = items;
        _locations = locations;
        _scope = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraOn || _busy) return;
    if (state == AppLifecycleState.resumed) {
      _startCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera();
    }
  }

  Future<void> _startCamera() async {
    try {
      await _controller.start();
    } catch (_) {
      // Camera errors are shown by the errorBuilder in ScannerPanel.
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _controller.stop();
    } catch (_) {}
  }

  void _toggleCamera() {
    setState(() => _cameraOn = !_cameraOn);
    _cameraOn ? _startCamera() : _stopCamera();
  }

  // ---------------------------------------------------------------- scan

  Future<void> _onCode(String raw) async {
    if (_busy || _loading || _submitting || _loadError != null) return;
    _busy = true;
    HapticFeedback.mediumImpact();
    try {
      await _handleCode(raw);
    } finally {
      _busy = false;
    }
  }

  Future<void> _handleCode(String raw) async {
    final code = raw.trim().toLowerCase();

    // 1) Store / rack code -> filter the list to that store / rack.
    final scope = _scopeForCode(code);
    if (scope != null) {
      setState(() => _scope = scope);
      if (!_items.any(scope.contains)) {
        _showMessage(
          '${scope.label} has no items in the list yet. Scan an item to '
          'count it here.',
        );
      }
      return;
    }

    // 2) Item code (or internal reference) -> go straight to the detail.
    var matches = _items.where((e) => e.matchesCode(code)).toList();
    if (matches.isEmpty) {
      // Not in the list (e.g. no stock row anywhere yet): ask the server.
      await _lookUp(raw.trim());
      return;
    }

    final active = _scope;
    if (active != null) {
      final inScope = matches.where(active.contains).toList();
      if (inScope.isNotEmpty) {
        matches = inScope;
      } else {
        // The item exists, but somewhere else: count it here, or open it
        // where the system has it.
        final choice = await _askOtherLocation(matches, active);
        if (choice == null || !mounted) return;
        if (choice == _OtherLocation.countHere) {
          await _addAndOpen(active.rowFor(matches.first));
          return;
        }
        setState(() => _scope = null); // clear the store / rack filter
      }
    }

    final item = matches.length == 1
        ? matches.first
        : await _pickLocation(matches);
    if (item == null || !mounted) return;
    await _openDetail(item);
  }

  /// The store / rack a scanned or typed code stands for: a location label
  /// from the list, a rack code (`PUT...`) or a store code (`STR...`).
  _Scope? _scopeForCode(String code) {
    final byLabel = _scopeForLabel(code);
    if (byLabel != null) return byLabel;

    final rack = _locations.racks
        .where((r) => r.code.toLowerCase() == code)
        .firstOrNull;
    if (rack != null) {
      final store =
          _locations.stores.where((s) => s.id == rack.storeId).firstOrNull;
      return _Scope.location(
        storeId: rack.storeId,
        putawayId: rack.id,
        label: store == null ? rack.name : '${store.name} / ${rack.name}',
      );
    }

    final store = _locations.stores
        .where((s) => s.code.toLowerCase() == code)
        .firstOrNull;
    if (store != null) {
      return _Scope.store(storeId: store.id, label: store.name);
    }
    return null;
  }

  /// The exact location of the list whose label is [label] (case-insensitive).
  _Scope? _scopeForLabel(String label) {
    final l = label.trim().toLowerCase();
    final row = _items.where((e) => e.location.toLowerCase() == l).firstOrNull;
    return row == null
        ? null
        : _Scope.location(
            storeId: row.storeLocationId,
            putawayId: row.putawayId,
            label: row.location,
          );
  }

  Future<_OtherLocation?> _askOtherLocation(
    List<OpnameItem> matches,
    _Scope scope,
  ) {
    final places = matches.map((e) => e.location).join('\n');
    return showDialog<_OtherLocation>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Item is somewhere else'),
        content: Text(
          '${matches.first.code} · ${matches.first.name} is not recorded in '
          '${scope.label}.\n\nThe system has it in:\n$places',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _OtherLocation.openThere),
            child: const Text('Open there'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _OtherLocation.countHere),
            child: const Text('Count here'),
          ),
        ],
      ),
    );
  }

  /// Looks an item up by its code on the server and shows its data. The
  /// user can then count it at one of its locations, or at the scanned
  /// store / rack.
  Future<void> _lookUp(String code) async {
    final repo = context.read<InventoryStockOpnameRepository>();
    final OpnameLookup info;
    try {
      info = await repo.lookupItem(code);
    } on ApiException catch (e) {
      _showMessage(e.message);
      return;
    }
    if (!mounted) return;

    final row = await showModalBottomSheet<OpnameItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ItemInfoSheet(
        info: info,
        scopeLabel: _scope?.label,
        onCountAt: (location) => location == null
            ? _scope!.rowFromLookup(info)
            : info.rowAt(
                storeLocationId: location.storeLocationId,
                putawayId: location.putawayId,
                label: location.label,
              ),
      ),
    );
    if (row == null || !mounted) return;
    await _addAndOpen(row);
  }

  /// Opens [row], adding it to the list first if it is a new location.
  Future<void> _addAndOpen(OpnameItem row) async {
    final existing = _items.where((e) => e.id == row.id).firstOrNull;
    if (existing == null) {
      setState(() => _items = [..._items, row]);
    }
    await _openDetail(existing ?? row);
  }

  Future<void> _openDetail(OpnameItem item) async {
    final wasBusy = _busy;
    _busy = true; // block new scans while the detail is open
    if (_cameraOn) await _stopCamera();

    if (!mounted) return;
    final result = await Navigator.push<double>(
      context,
      opnameRoute<double>(OpnameDetailScreen(item: item)),
    );

    if (!mounted) return;
    if (result != null) {
      setState(() {
        _items = _items
            .map((e) => e.id == item.id ? e.withCount(result) : e)
            .toList();
      });
    }
    if (_cameraOn) await _startCamera();
    _busy = wasBusy;
  }

  Future<OpnameItem?> _pickLocation(List<OpnameItem> options) {
    return showModalBottomSheet<OpnameItem>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Choose a location', style: OpnameTextStyles.bodyBold),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${options.first.code} is on several racks. Scan the rack '
                'first to go straight to the right item.',
                style: AppTextStyles.caption,
              ),
            ),
            for (final o in options)
              ListTile(
                leading: Icon(
                  Icons.place_outlined,
                  color: AppColors.primaryText,
                ),
                title: Text(o.location, style: AppTextStyles.body),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(ctx, o),
              ),
          ],
        ),
      ),
    );
  }

  /// The "Enter code" button: opens the rack/item search.
  Future<void> _manualInput() async {
    // Keep camera scans from triggering other actions while the sheet is open.
    _busy = true;
    final result = await showCodeSearchSheet(context, items: _items);
    _busy = false;

    if (result == null || !mounted) return;

    if (result.rack != null) {
      // Rack picked: filter the list to that rack (same as a rack scan).
      setState(() => _scope = _scopeForLabel(result.rack!));
    } else if (result.item != null) {
      // Item picked: open the detail of that exact item.
      await _openDetail(result.item!);
    } else if (result.rawCode != null) {
      // Enter on the keyboard: process like a scan result.
      _onCode(result.rawCode!);
    }
  }

  // ------------------------------------------------------------- confirm

  int get _countedTotal => _items.where((e) => e.isCounted).length;

  Future<void> _confirm() async {
    final counted = _items.where((e) => e.isCounted).toList();
    if (counted.isEmpty || _submitting) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_confirmOnSubmit ? 'Confirm count?' : 'Save count?'),
        content: Text(
          _confirmOnSubmit
              ? '${_itemsLabel(counted.length)} will be confirmed. System '
                  'stock will be updated to match the count, and this cannot '
                  'be undone.'
              : '${_itemsLabel(counted.length)} will be saved as a draft. '
                  'System stock will not change until confirmed in the portal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_confirmOnSubmit ? 'Confirm' : 'Save'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final repo = context.read<InventoryStockOpnameRepository>();
    final countedBy = widget.countedBy ?? 'Mobile';

    setState(() => _submitting = true);
    try {
      await repo.submit(
        counted: counted,
        countedBy: countedBy,
        confirm: _confirmOnSubmit,
        notes: 'From the mobile app',
      );
      if (!mounted) return;
      _showMessage(
        _confirmOnSubmit
            ? '${_itemsLabel(counted.length)} confirmed.'
            : '${_itemsLabel(counted.length)} saved as a draft.',
      );
      setState(() => _submitting = false);
      await _load(); // reload: the count has been submitted
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // The counts on screen are kept so the submission can be retried.
      _showMessage(e.message);
    }
  }

  static String _itemsLabel(int n) => n == 1 ? '1 item' : '$n items';

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final scope = _scope;
    final visible =
        scope == null ? _items : _items.where(scope.contains).toList();

    final visibleCounted = visible.where((e) => e.isCounted).length;
    final shown = switch (_filter) {
      1 => visible.where((e) => !e.isCounted).toList(),
      2 => visible.where((e) => e.isCounted).toList(),
      _ => visible,
    };

    // Per-location totals (ignoring the filter) for the group headers.
    final groupTotal = <String, int>{};
    final groupDone = <String, int>{};
    for (final e in visible) {
      groupTotal[e.location] = (groupTotal[e.location] ?? 0) + 1;
      if (e.isCounted) {
        groupDone[e.location] = (groupDone[e.location] ?? 0) + 1;
      }
    }

    // Flatten into one list (location header + items) so the ListView only
    // builds the cards on screen. The order of appearance is preserved.
    final rows = <Object>[];
    String? lastLocation;
    for (final e in shown) {
      if (e.location != lastLocation) {
        rows.add(_GroupRow(
          e.location,
          groupDone[e.location] ?? 0,
          groupTotal[e.location] ?? 0,
        ));
        lastLocation = e.location;
      }
      rows.add(e);
    }

    // The camera takes about a quarter of the screen: enough to aim on a
    // compact phone, without pushing the list off screen on a tall one.
    final cameraHeight =
        (MediaQuery.sizeOf(context).height * 0.27).clamp(170.0, 280.0);

    return Scaffold(
      appBar: OpnameAppBar(
        title: 'Stock Opname',
        actions: [
          IconButton(
            tooltip: _cameraOn ? 'Close camera' : 'Open camera',
            onPressed: _toggleCamera,
            style: IconButton.styleFrom(
              backgroundColor: _cameraOn
                  ? AppColors.primary
                  : AppColors.primaryLight,
            ),
            icon: Icon(
              Icons.qr_code_scanner,
              color: _cameraOn ? Colors.white : AppColors.primaryText,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_cameraOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: cameraHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ScannerPanel(controller: _controller, onCode: _onCode),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: _CameraChip(
                          icon: Icons.fact_check_outlined,
                          label: '$_countedTotal/${_items.length} counted',
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 10,
                        child: IgnorePointer(
                          child: Center(
                            child: _CameraChip(
                              label: 'Point at a barcode or QR code',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _ScanStepBanner(
            location: scope?.label,
            counted: visibleCounted,
            total: visible.length,
            onClearLocation: () => setState(() => _scope = null),
          ),
          if (!_loading && _loadError == null && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: OpnameChipRow(
                soft: true,
                labels: [
                  'All (${visible.length})',
                  'Not counted (${visible.length - visibleCounted})',
                  'Counted ($visibleCounted)',
                ],
                selectedIndex: _filter,
                onChanged: (i) => setState(() => _filter = i),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? _LoadError(message: _loadError!, onRetry: _load)
                    : _items.isEmpty
                        ? const Center(
                            child: Text('No items available to count yet.'),
                          )
                        : rows.isEmpty
                            ? const Center(
                                child: Text('No items match this filter.'),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: rows.length,
                                itemBuilder: (_, i) {
                                  final row = rows[i];
                                  if (row is _GroupRow) {
                                    return _LocationHeader(
                                      name: row.name,
                                      counted: row.counted,
                                      total: row.total,
                                    );
                                  }
                                  final item = row as OpnameItem;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: OpnameLineTile(
                                      item: item,
                                      onEdit: () => _openDetail(item),
                                    ),
                                  );
                                },
                              ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading || _loadError != null ? null : _manualInput,
                    icon: const Icon(Icons.keyboard_outlined, size: 20),
                    label: const Text('Enter code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _countedTotal == 0 || _submitting ? null : _confirm,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _confirmOnSubmit
                                ? 'Confirm ($_countedTotal)'
                                : 'Save ($_countedTotal)',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _OtherLocation { countHere, openThere }

/// The store or rack the list is filtered to, from a store / rack scan.
class _Scope {
  /// One exact location: a rack, or a store without a rack.
  const _Scope.location({
    required this.storeId,
    required this.putawayId,
    required this.label,
  }) : wholeStore = false;

  /// A whole store: every location in it, racks included.
  const _Scope.store({required int this.storeId, required this.label})
      : putawayId = null,
        wholeStore = true;

  final int? storeId;
  final int? putawayId;
  final bool wholeStore;
  final String label;

  bool contains(OpnameItem e) =>
      e.storeLocationId == storeId && (wholeStore || e.putawayId == putawayId);

  /// [base]'s item counted here: on the rack, or in the store itself (no
  /// rack) for a whole store. The system has nothing here yet, so its
  /// quantity is 0 and the whole count is a surplus.
  OpnameItem rowFor(OpnameItem base) => OpnameItem(
        id: '${base.itemId}|${storeId ?? 0}:${putawayId ?? 0}',
        itemId: base.itemId,
        storeLocationId: storeId,
        putawayId: putawayId,
        code: base.code,
        internalReference: base.internalReference,
        name: base.name,
        unit: base.unit,
        location: label,
        systemQty: 0,
      );

  OpnameItem rowFromLookup(OpnameLookup info) =>
      info.rowAt(storeLocationId: storeId, putawayId: putawayId, label: label);
}

/// Step hint: "Scan a rack" first (optional), then "Scan an item", with a
/// progress bar of how many of the visible items have been counted.
class _ScanStepBanner extends StatelessWidget {
  final String? location;
  final int counted;
  final int total;
  final VoidCallback onClearLocation;

  const _ScanStepBanner({
    required this.location,
    required this.counted,
    required this.total,
    required this.onClearLocation,
  });

  @override
  Widget build(BuildContext context) {
    final hasRack = location != null;
    final progress = total == 0 ? 0.0 : counted / total;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasRack ? Icons.sell_outlined : Icons.warehouse_outlined,
                color: AppColors.primaryText,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasRack ? 'Scan items here' : 'Scan a store, rack or item',
                      style: OpnameTextStyles.bodyBold.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                    Text(
                      hasRack
                          ? location!
                          : 'Scan a store or rack (QR or barcode) to see its items, or an item to count it right away',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasRack)
                TextButton(
                  onPressed: onClearLocation,
                  child: const Text('Show all'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$counted/$total counted',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One location group marker in the flattened list.
class _GroupRow {
  final String name;
  final int counted;
  final int total;

  const _GroupRow(this.name, this.counted, this.total);
}

class _LocationHeader extends StatelessWidget {
  final String name;
  final int counted;
  final int total;

  const _LocationHeader({
    required this.name,
    required this.counted,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.place, size: 16, color: AppColors.primaryText),
          const SizedBox(width: 6),
          Expanded(child: Text(name, style: OpnameTextStyles.bodyBold)),
          Text('$counted/$total counted', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// A small semi-transparent label over the camera preview.
class _CameraChip extends StatelessWidget {
  final IconData? icon;
  final String label;

  const _CameraChip({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
