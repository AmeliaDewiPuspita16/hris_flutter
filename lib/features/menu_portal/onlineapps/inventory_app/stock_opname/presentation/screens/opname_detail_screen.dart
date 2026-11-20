import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';
import '../../domain/opname_formatters.dart';
import '../../../../../../../core/widgets/app_button.dart';
import '../../domain/opname_item.dart';
import '../widgets/difference_label.dart';
import '../widgets/opname_app_bar.dart';
import '../widgets/opname_card.dart';
import '../widgets/opname_text_styles.dart';

/// What the item detail screen hands back.
class OpnameCountResult {
  /// The counted quantity; null when the count is removed.
  final double? qty;

  /// The note of this row (optional); null = none.
  final String? notes;

  const OpnameCountResult.counted(double this.qty, {this.notes});

  /// The user cleared the count: the row goes back to "not counted".
  const OpnameCountResult.removed()
      : qty = null,
        notes = null;

  bool get isRemoval => qty == null;
}

/// Detail of a single item: enter the counted quantity and an optional note,
/// then Save (returns an [OpnameCountResult]), Remove count (returns a
/// removal) or Cancel (returns null).
///
/// The quantity is the hero: a large number between a - and a + button, with
/// the system stock and the live difference right next to it. Tapping the
/// number selects it, so typing replaces it. The note is tucked away behind
/// "Add a note" until it is needed.
class OpnameDetailScreen extends StatefulWidget {
  final OpnameItem item;

  const OpnameDetailScreen({super.key, required this.item});

  @override
  State<OpnameDetailScreen> createState() => _OpnameDetailScreenState();
}

class _OpnameDetailScreenState extends State<OpnameDetailScreen> {
  late final TextEditingController _qty;
  late final TextEditingController _notes;
  final _focus = FocusNode();
  late bool _showNotes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(
      text: formatQty(widget.item.countedQty ?? widget.item.systemQty),
    );
    _notes = TextEditingController(text: widget.item.notes ?? '');
    _showNotes = _notes.text.isNotEmpty;
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    _qty.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? _parse() => double.tryParse(_qty.text.trim().replaceAll(',', '.'));

  void _set(double value) {
    setState(() {
      _qty.text = formatQty(value);
      _error = null;
    });
  }

  void _adjust(double delta) {
    final next = ((_parse() ?? 0) + delta).clamp(0, double.infinity).toDouble();
    _set(next);
  }

  void _save() {
    final v = _parse();
    if (v == null) {
      setState(() => _error =
          'Enter a quantity first. Enter 0 if the item is missing.');
      return;
    }
    final note = _notes.text.trim();
    Navigator.pop(
      context,
      OpnameCountResult.counted(v, notes: note.isEmpty ? null : note),
    );
  }

  /// Back to "not counted": the row will not be saved.
  void _remove() => Navigator.pop(context, const OpnameCountResult.removed());

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final live = _parse();
    final diff = live == null ? null : live - item.systemQty;

    return Scaffold(
      appBar: const OpnameAppBar(title: 'Item Detail'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Item ────────────────────────────────────────────────────
            OpnameCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.textMid,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.code,
                              style: AppTextStyles.caption
                                  .copyWith(letterSpacing: 0.6),
                            ),
                            const SizedBox(height: 2),
                            Text(item.name, style: OpnameTextStyles.bodyBold),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 24, color: AppColors.border),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.location, style: AppTextStyles.body),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Count ───────────────────────────────────────────────────
            OpnameCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Counted quantity', style: AppTextStyles.label),
                      Text(
                        'System ${formatQty(item.systemQty)} ${item.unit}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StepButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Minus 1',
                        onTap: () => _adjust(-1),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _numberField(item)),
                      const SizedBox(width: 12),
                      _StepButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Plus 1',
                        filled: true,
                        onTap: () => _adjust(1),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickChip(label: 'Set to 0', onTap: () => _set(0)),
                      if (live != item.systemQty)
                        _QuickChip(
                          label: 'Same as system',
                          onTap: () => _set(item.systemQty),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Difference ', style: AppTextStyles.caption),
                      if (diff == null)
                        Text('-', style: AppTextStyles.caption)
                      else
                        DifferenceLabel(difference: diff, unit: item.unit),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Note ────────────────────────────────────────────────────
            if (_showNotes)
              OpnameCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes (optional)', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notes,
                      autofocus: _notes.text.isEmpty,
                      minLines: 2,
                      maxLines: 3,
                      maxLength: 255, // the API accepts up to 255 characters
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 2 boxes damaged, moved from Rak B',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showNotes = true),
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text('Add a note'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryText,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // An item that was already counted can be taken out again.
              if (item.isCounted)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _remove,
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('Remove count'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.ghost,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(label: 'Save', onPressed: _save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The big number in a soft well. The well gets a green outline while it
  /// is being edited. Tapping selects the whole number so typing replaces it.
  Widget _numberField(OpnameItem item) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focus.hasFocus ? AppColors.primaryText : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _qty,
            focusNode: _focus,
            textAlign: TextAlign.center,
            style: OpnameTextStyles.quantity.copyWith(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onTap: () => _qty.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _qty.text.length,
            ),
            onChanged: (_) => setState(() => _error = null),
            decoration: const InputDecoration(
              hintText: '0',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 2),
          Text(item.unit, style: AppTextStyles.label),
        ],
      ),
    );
  }
}

/// Round - / + button. The + one is filled: counting mostly goes up, so it is
/// the one strong green on this screen next to Save.
class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool filled;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? AppColors.primaryText : AppColors.bg,
        shape: CircleBorder(
          side: filled ? BorderSide.none : BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 56,
            child: Icon(
              icon,
              size: 26,
              color: filled ? AppColors.card : AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small neutral pill for a shortcut ("Set to 0", "Same as system").
class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: StadiumBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }
}
