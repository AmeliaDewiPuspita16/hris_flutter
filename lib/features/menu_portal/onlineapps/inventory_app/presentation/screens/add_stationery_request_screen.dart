import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/logging/app_logger.dart';
import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/back_header.dart';
import '../../../../../../core/widgets/field_label_row.dart';
import '../../data/inventory_stationery_repository.dart';
import '../../domain/stationery_item_option.dart';
import '../../domain/stationery_request_item.dart';
import '../../domain/stationery_request_line.dart';
import '../widgets/stationery_item_picker_sheet.dart';

/// Layar "Add Request", sekaligus form "Edit Request" bila [initialItem]
/// diisi. Padanan modal "Request Item" / "Edit Request" di web.
///
/// - Mode tambah: boleh beberapa baris barang sekaligus (tombol "Add Form"
///   di web) dalam satu kali submit.
/// - Mode edit: satu baris; barangnya terkunci dan hanya jumlah +
///   keterangan yang bisa diubah. "Existing quantity" = stok barang.
///
/// Menutup diri dengan `true` lewat Navigator.pop bila tersimpan di server
/// (pemanggil lalu memuat ulang daftar), atau null bila ditutup tanpa
/// submit. Galat ditangani dengan setState lokal, pola sama dengan
/// `AddEstRequestScreen`.
class AddStationeryRequestScreen extends StatefulWidget {
  const AddStationeryRequestScreen({
    super.key,
    this.repository,
    this.initialItem,
  });

  /// Harus instance yang sama dengan layar daftar supaya data demo
  /// konsisten. Kalau kosong, dibuat repository demo baru.
  final InventoryStationeryRepository? repository;

  /// Null = mode tambah. Diisi = mode edit untuk request ini.
  final StationeryRequestItem? initialItem;

  @override
  State<AddStationeryRequestScreen> createState() =>
      _AddStationeryRequestScreenState();
}

/// Satu baris isian: barang + jumlah + keterangan.
class _LineForm {
  _LineForm({this.item});

  StationeryItemOption? item;
  final quantity = TextEditingController();
  final description = TextEditingController();
  final key = UniqueKey();

  void dispose() {
    quantity.dispose();
    description.dispose();
  }
}

class _AddStationeryRequestScreenState
    extends State<AddStationeryRequestScreen> {
  static const int _maxDescriptionLength = 500;

  late final InventoryStationeryRepository _repository;
  final List<_LineForm> _lines = [];

  List<StationeryItemOption> _items = const [];
  bool _itemsLoading = false;
  String? _itemsError;

  bool _submitting = false;

  bool get _isEdit => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? InventoryStationeryRepository();

    final initial = widget.initialItem;
    if (initial != null) {
      final line = _LineForm();
      line.quantity.text = formatInventoryQuantity(initial.quantity);
      line.description.text = initial.description;
      _lines.add(line);
    } else {
      _lines.add(_LineForm());
      _loadItems();
    }
  }

  @override
  void dispose() {
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
      final items = await _repository.fetchItems();
      if (!mounted) return;
      setState(() => _items = items);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _itemsError = e.message);
    } catch (e, stack) {
      AppLogger.error('Daftar barang stationery gagal dimuat', e, stack);
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

    final picked = await StationeryItemPickerSheet.show(
      context,
      items: _items,
      selectedId: line.item?.id,
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Hasilnya galat pertama yang ditemukan (teks siap tampil) atau null.
  String? _validate() {
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final prefix = _lines.length > 1 ? 'Item ${i + 1}: ' : '';

      if (!_isEdit && line.item == null) {
        return '${prefix}Please select an item.';
      }

      final qty = int.tryParse(line.quantity.text.trim());
      if (qty == null || qty <= 0) {
        return '${prefix}Quantity must be greater than 0.';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final error = _validate();
    if (error != null) {
      _toast(error);
      return;
    }

    setState(() => _submitting = true);
    try {
      if (_isEdit) {
        final line = _lines.first;
        await _repository.update(
          widget.initialItem!.id,
          quantity: int.parse(line.quantity.text.trim()),
          description: line.description.text,
        );
      } else {
        await _repository.create([
          for (final line in _lines)
            StationeryRequestLine(
              itemId: line.item!.id,
              quantity: int.parse(line.quantity.text.trim()),
              description: line.description.text,
            ),
        ]);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (e, stack) {
      AppLogger.error(
        '${_isEdit ? 'Edit' : 'Submit'} request stationery gagal tak terduga',
        e,
        stack,
      );
      if (!mounted) return;
      _toast('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _fieldDecoration(String hint, {String? suffixText}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        suffixText: suffixText,
        suffixStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        filled: true,
        fillColor: AppColors.card,
        counterText: '',
        contentPadding: const EdgeInsets.all(12),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primaryMidText),
      );

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: _isEdit ? 'Edit Request' : 'Add Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (_itemsError != null) _buildItemsError(),
          for (var i = 0; i < _lines.length; i++) ...[
            _buildLineCard(_lines[i], i),
            const SizedBox(height: 14),
          ],
          if (!_isEdit)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _submitting ? null : _addLine,
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add Form',
                  style: AppTextStyles.buttonText
                      .copyWith(color: AppColors.primaryText, fontSize: 13),
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
                      _isEdit ? 'Update' : 'Save',
                      style:
                          AppTextStyles.buttonText.copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.rejectedBg,
        borderRadius: BorderRadius.circular(10),
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
    final unit = _isEdit ? widget.initialItem!.unit : item?.unit ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        key: line.key,
        children: [
          if (_lines.length > 1)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item ${index + 1}',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: _submitting ? null : () => _removeLine(line),
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: 18, color: AppColors.rejected),
                ),
              ],
            ),
          const FieldLabelRow(label: 'Item', required: true),
          _SelectField(
            text: _isEdit ? widget.initialItem!.itemLabel : item?.displayLabel,
            hint: _itemsLoading ? 'Loading items...' : 'Select Item',
            // Mode edit: barang terkunci (abu-abu), sama seperti di web.
            locked: _isEdit,
            onTap: () => _pickItem(line),
          ),
          if (_isEdit && widget.initialItem!.stock != null) ...[
            const SizedBox(height: 4),
            Text(
              'Existing quantity: ${formatInventoryQuantity(widget.initialItem!.stock)}',
              style: AppTextStyles.caption,
            ),
          ] else if (item?.stock != null) ...[
            const SizedBox(height: 4),
            Text('Stock: ${item!.stockLabel}', style: AppTextStyles.caption),
          ],
          const SizedBox(height: 16),
          const FieldLabelRow(label: 'Quantity', required: true),
          TextField(
            controller: line.quantity,
            enabled: !_submitting,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            style: AppTextStyles.body,
            decoration: _fieldDecoration(
              '0',
              suffixText: unit.isEmpty ? 'Unit' : unit,
            ),
          ),
          const SizedBox(height: 16),
          const FieldLabelRow(label: 'Description'),
          TextField(
            controller: line.description,
            enabled: !_submitting,
            minLines: 2,
            maxLines: 4,
            maxLength: _maxDescriptionLength,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.body,
            decoration: _fieldDecoration('Reason for the request'),
          ),
        ],
      ),
    );
  }
}

/// Kolom pilihan yang tampak seperti field tapi membuka sheet saat diketuk.
class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.text,
    required this.hint,
    required this.onTap,
    this.locked = false,
  });

  final String? text;
  final String hint;
  final VoidCallback onTap;

  /// True = tampil abu-abu dan tidak bisa diketuk.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final hasText = text != null && text!.isNotEmpty;

    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: locked ? AppColors.neutralBg : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasText ? text! : hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: hasText ? AppColors.text : AppColors.textMuted,
                ),
              ),
            ),
            if (!locked)
              Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
