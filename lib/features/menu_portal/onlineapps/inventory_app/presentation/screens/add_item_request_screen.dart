import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../../core/widgets/field_label_row.dart';
import '../../data/inventory_item_request_repository.dart';
import '../../domain/item_request_stock_option.dart';
import '../../domain/item_request_entry.dart';
import '../../domain/item_request_line.dart';
import '../widgets/item_request_stock_picker_sheet.dart';

/// Layar "Add Request", sekaligus form "Edit Request" bila [initialItem]
/// diisi.
///
/// - Mode tambah: boleh beberapa baris barang sekaligus.
/// - Mode edit: satu baris; barangnya terkunci dan hanya jumlah +
///   keterangan yang bisa diubah. "Existing quantity" = stok barang.
///
/// Menutup diri dengan pesan sukses dari server lewat Navigator.pop bila
/// tersimpan (pemanggil lalu memuat ulang daftar dan menampilkan pesannya),
/// atau null bila ditutup tanpa submit. Galat ditampilkan lewat snackbar.
///
/// Barang diambil dari `GET /options`; kolom alasan (`reason`) wajib.
///
/// Galat validasi tampil di bawah kolomnya (setelah Save pertama kali
/// ditekan), bukan lagi lewat snackbar satu per satu.
class AddItemRequestScreen extends StatefulWidget {
  const AddItemRequestScreen(
      {super.key, required this.repository, this.initialItem, this.onOutdated});

  final InventoryItemRequestRepository repository;

  /// Null = mode tambah. Diisi = mode edit untuk line ini.
  final ItemRequestEntry? initialItem;

  /// Dipanggil saat edit ditolak karena line sudah diputuskan di server
  /// ("no longer pending"), supaya pemanggil memuat ulang daftarnya dan
  /// tombol edit hilang dari line itu
  final VoidCallback? onOutdated;

  @override
  State<AddItemRequestScreen> createState() => _AddItemRequestScreenState();
}

/// Satu baris isian: barang + jumlah + alasan.
class _LineForm {
  _LineForm({this.item});

  ItemRequestStockOption? item;
  final quantity = TextEditingController();
  final reason = TextEditingController();
  final key = GlobalKey();

  void dispose() {
    quantity.dispose();
    reason.dispose();
  }
}

class _AddItemRequestScreenState extends State<AddItemRequestScreen> {
  /// Batas server untuk `reason`.
  static const int _maxReasonLength = 5000;

  InventoryItemRequestRepository get _repository => widget.repository;
  final List<_LineForm> _lines = [];

  List<ItemRequestStockOption> _items = const [];
  bool _itemsLoading = false;
  String? _itemsError;

  bool _submitting = false;

  /// Galat per kolom baru ditampilkan setelah Save ditekan sekali.
  bool _showErrors = false;

  final _scrollController = ScrollController();

  bool get _isEdit => widget.initialItem != null;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialItem;
    if (initial != null) {
      final line = _LineForm();
      line.quantity.text = formatInventoryQuantity(initial.quantity);
      line.reason.text = initial.hasReason ? initial.description : '';
      _lines.add(line);
    } else {
      _lines.add(_LineForm());
      _loadItems();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _itemsLoading = true;
      _itemsError = null;
    });

    try {
      final options = await _repository.fetchOptions();
      if (!mounted) return;
      setState(() => _items = options.items);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _itemsError = e.message);
    } catch (e, stack) {
      AppLogger.error('Daftar barang gagal dimuat', e, stack);
      if (!mounted) return;
      setState(() => _itemsError = 'Failed to load the item list.');
    } finally {
      if (mounted) setState(() => _itemsLoading = false);
    }
  }

  Future<void> _pickItem(_LineForm line) async {
    if (_submitting || _isEdit) return;

    if (_itemsLoading) {
      _toast('Items are still loading, please wait.');
      return;
    }
    if (_items.isEmpty) {
      _toast(_itemsError ?? 'No items available.');
      return;
    }

    final picked = await ItemRequestStockPickerSheet.show(
      context,
      items: _items,
      selectedId: line.item?.id,
      // Server menolak barang dobel dalam satu request.
      takenIds: {
        for (final other in _lines)
          if (other != line && other.item != null) other.item!.id,
      },
    );
    if (picked == null || !mounted) return;

    setState(() => line.item = picked);
  }

  void _addLine() {
    if (_submitting) return;
    setState(() => _lines.add(_LineForm()));
  }

  void _removeLine(_LineForm line) {
    if (_submitting || _lines.length == 1) return;
    setState(() => _lines.remove(line));
    line.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Galat per kolom untuk satu baris, null = kolom itu sah.
  _LineErrors _errorsFor(int index) {
    final line = _lines[index];

    String? item;
    if (!_isEdit) {
      if (line.item == null) {
        item = 'Please select an item.';
      } else if (_lines
          .take(index)
          .any((other) => other.item?.id == line.item!.id)) {
        item = 'This item is already in another line.';
      }
    }

    String? quantity;
    final qty = parseInventoryQuantity(line.quantity.text);
    if (qty == null) {
      quantity = line.quantity.text.trim().isEmpty
          ? 'Enter a quantity.'
          : 'Enter a valid number (up to 4 decimals).';
    } else if (qty <= 0) {
      quantity = 'Quantity must be greater than 0.';
    }

    final reason =
        line.reason.text.trim().isEmpty ? 'Please enter a reason.' : null;

    return _LineErrors(item: item, quantity: quantity, reason: reason);
  }

  /// Indeks baris pertama yang punya galat, atau -1.
  int get _firstInvalidLine {
    for (var i = 0; i < _lines.length; i++) {
      if (_errorsFor(i).any) return i;
    }
    return -1;
  }

  /// Tombol − / +: ubah jumlah 1 satuan. Hasil tidak boleh 0 atau kurang.
  void _step(_LineForm line, num delta) {
    if (_submitting) return;

    final current = parseInventoryQuantity(line.quantity.text) ?? 0;
    // Dibulatkan ke 4 angka supaya 0.1 + 0.2 tidak jadi 0.30000000000000004.
    final next = ((current + delta) * 10000).round() / 10000;
    if (next <= 0) return;

    setState(() => line.quantity.text = formatInventoryQuantity(next));
  }

  void _scrollToLine(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _lines[index].key.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    setState(() => _showErrors = true);
    final invalid = _firstInvalidLine;
    if (invalid != -1) {
      _toast('Please check the highlighted fields.');
      _scrollToLine(invalid);
      return;
    }

    setState(() => _submitting = true);
    try {
      final String? message;
      if (_isEdit) {
        final line = _lines.first;
        message = await _repository.updateLine(
          widget.initialItem!.id,
          itemId: widget.initialItem!.itemId!,
          quantity: parseInventoryQuantity(line.quantity.text)!,
          reason: line.reason.text,
        );
      } else {
        message = await _repository.submitRequest([
          for (final line in _lines)
            ItemRequestLine(
              itemId: line.item!.id,
              quantity: parseInventoryQuantity(line.quantity.text)!,
              reason: line.reason.text,
            ),
        ]);
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        message ?? (_isEdit ? 'Request updated' : 'Request submitted'),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
      // Line sudah diputuskan di server: daftar di belakang layar ini sudah
      // basi, minta pemanggil memuat ulang.
      if (_isEdit && e.message.toLowerCase().contains('no longer pending')) {
        widget.onOutdated?.call();
      }
    } catch (e, stack) {
      AppLogger.error(
        '${_isEdit ? 'Edit' : 'Submit'} item request gagal tak terduga',
        e,
        stack,
      );
      if (!mounted) return;
      _toast('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _fieldDecoration(
    String hint, {
    String? suffixText,
    String? errorText,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        suffixText: suffixText,
        suffixStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        errorText: errorText,
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.rejected),
        filled: true,
        fillColor: AppColors.bg,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        disabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primaryMidText, width: 1.5),
        errorBorder: _border(AppColors.rejected),
        focusedErrorBorder: _border(AppColors.rejected, width: 1.5),
      );

  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: _isEdit ? 'Edit Request' : 'Add Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (_itemsError != null) _buildItemsError(),
                for (var i = 0; i < _lines.length; i++) ...[
                  _buildLineCard(_lines[i], i),
                  const SizedBox(height: 14),
                ],
                if (!_isEdit)
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _submitting ? null : _addLine,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(
                        'Add another item',
                        style: AppTextStyles.buttonText.copyWith(
                          color: AppColors.text,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side: BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// Bar bawah yang selalu terlihat: ringkasan jumlah barang + tombol Save,
  /// jadi tombol tidak perlu dicari di ujung form yang panjang.
  Widget _buildBottomBar() {
    final count = _lines.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (!_isEdit) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count ${count == 1 ? 'item' : 'items'}',
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text('in this request', style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Update' : 'Submit request',
                            style: AppTextStyles.buttonText
                                .copyWith(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _itemsError!,
              style: AppTextStyles.caption.copyWith(color: AppColors.rejected),
            ),
          ),
          TextButton(
            onPressed: _itemsLoading ? null : _loadItems,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLineCard(_LineForm line, int index) {
    final item = line.item;
    final initial = widget.initialItem;
    final unit = _isEdit ? initial!.unit : item?.unit ?? '';
    final stock = _isEdit ? initial!.stock : item?.stock;
    final errors = _showErrors ? _errorsFor(index) : const _LineErrors();

    final qty = parseInventoryQuantity(line.quantity.text);
    final overStock = qty != null && stock != null && qty > stock;

    final title = _isEdit ? initial!.itemName : item?.name;
    final code = _isEdit ? initial!.itemCode : item?.code;
    final category = _isEdit ? initial!.category : item?.category;
    final subtitle = [
      if (code != null && code.isNotEmpty) code,
      if (category != null && category.isNotEmpty) category,
    ].join(' · ');

    return Container(
      key: line.key,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_lines.length > 1) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item ${index + 1}',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                InkResponse(
                  onTap: _submitting ? null : () => _removeLine(line),
                  radius: 20,
                  child: Tooltip(
                    message: 'Remove',
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.neutralBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.textMid,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          const FieldLabelRow(label: 'Item', required: true),
          _SelectField(
            title: title,
            subtitle: subtitle,
            hint: _itemsLoading ? 'Loading items...' : 'Select item',
            // Mode edit: barang terkunci (abu-abu), sama seperti di web.
            locked: _isEdit,
            error: errors.item,
            onTap: () => _pickItem(line),
          ),
          if (stock != null) ...[
            const SizedBox(height: 8),
            _StockNote(
              label: _isEdit ? 'Current stock' : 'Stock',
              value: formatInventoryQuantity(stock),
              unit: unit,
            ),
          ],
          const SizedBox(height: 18),
          const FieldLabelRow(label: 'Quantity', required: true),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                tooltip: 'Decrease',
                onTap: _submitting ? null : () => _step(line, -1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: line.quantity,
                  enabled: !_submitting,
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  maxLength: 12,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: _fieldDecoration(
                    '0',
                    suffixText: unit.isEmpty ? null : unit,
                    errorText: errors.quantity,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StepButton(
                icon: Icons.add_rounded,
                tooltip: 'Increase',
                onTap: _submitting ? null : () => _step(line, 1),
              ),
            ],
          ),
          if (overStock) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'More than the current stock. You can still submit, but '
                    'it may not be approved until stock is available.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.accent, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          const FieldLabelRow(label: 'Reason', required: true),
          TextField(
            controller: line.reason,
            enabled: !_submitting,
            minLines: 3,
            maxLines: 5,
            maxLength: _maxReasonLength,
            onChanged: (_) {
              // Galat "wajib diisi" hilang begitu mulai mengetik.
              if (_showErrors) setState(() {});
            },
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.body,
            decoration: _fieldDecoration(
              'Why do you need this item?',
              errorText: errors.reason,
            ),
          ),
        ],
      ),
    );
  }
}

/// Galat per kolom untuk satu baris isian; null = sah.
class _LineErrors {
  const _LineErrors({this.item, this.quantity, this.reason});

  final String? item;
  final String? quantity;
  final String? reason;

  bool get any => item != null || quantity != null || reason != null;
}

/// Kolom pilihan barang: tampak seperti field, membuka sheet saat diketuk.
/// Setelah dipilih menampilkan nama barang (tebal) dengan kode + kategori di
/// bawahnya, bukan satu teks panjang.
class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.onTap,
    this.locked = false,
    this.error,
  });

  final String? title;
  final String subtitle;
  final String hint;
  final VoidCallback onTap;

  /// True = tampil abu-abu dan tidak bisa diketuk.
  final bool locked;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasText = title != null && title!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: locked ? AppColors.neutralBg : AppColors.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: error != null ? AppColors.rejected : AppColors.border,
            ),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onTap: locked ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: hasText
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              hint,
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ),
                  ),
                  if (!locked)
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.rejected),
            ),
          ),
        ],
      ],
    );
  }
}

/// "Stock 100 PCS" dalam chip netral di bawah kolom barang.
class _StockNote extends StatelessWidget {
  const _StockNote({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.neutralBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$label  $value${unit.isEmpty ? '' : ' $unit'}',
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textMid,
          ),
        ),
      ),
    );
  }
}

/// Tombol − / + di samping kolom jumlah.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 50,
            child: Icon(
              icon,
              size: 22,
              color: onTap == null ? AppColors.textMuted : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
