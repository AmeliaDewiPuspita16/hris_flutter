import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

import '../../data/inventory_stock_opname_repository.dart';
import '../../domain/opname_item.dart';
import '../widgets/home_guide_card.dart';
import '../widgets/home_header_content.dart';
import '../widgets/home_start_button.dart';
import 'opname_count_screen.dart';
import 'opname_history_screen.dart';
import '../widgets/opname_hero_header.dart';
import '../widgets/opname_scan_badge.dart';
import '../widgets/opname_text_styles.dart';
import '../widgets/opname_theme.dart';

/// The stock opname start screen, opened from Inventory > Management: soft green
/// header, round scan button in the middle, then a 4-step guide. One tap
/// opens the camera.
/// This screen only composes widgets; each part lives in widgets/home_*.dart.
class OpnameHomeScreen extends StatefulWidget {
  const OpnameHomeScreen({super.key, this.countedBy});

  /// Name of the logged-in user, passed on to the count screen.
  final String? countedBy;

  @override
  State<OpnameHomeScreen> createState() => _OpnameHomeScreenState();
}

class _OpnameHomeScreenState extends State<OpnameHomeScreen> {
  List<OpnameItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  /// Only for the numbers in the header. On failure the numbers stay at 0,
  /// and the count screen shows its own error with a retry button.
  Future<void> _loadCounts() async {
    try {
      final items = await context.read<InventoryStockOpnameRepository>().fetchCountableItems();
      if (mounted) setState(() => _items = items);
    } catch (_) {}
  }

  Future<void> _start(BuildContext context) async {
    await Navigator.push(
      context,
      opnameRoute(OpnameCountScreen(countedBy: widget.countedBy)),
    );
    // After returning, stock may have changed (a new count was submitted).
    if (mounted) _loadCounts();
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      opnameRoute(const OpnameHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _items.length;
    final rackCount = _items.map((e) => e.location).toSet().length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: OpnameHeroHeader.overlayStyle,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header + scan button overlapping its bottom edge
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: OpnameHeroHeader(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 64),
                      child: HomeHeaderContent(
                        itemCount: itemCount,
                        rackCount: rackCount,
                        onHistoryTap: () => _openHistory(context),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: OpnameScanBadge(onTap: () => _start(context)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to scan',
                style: OpnameTextStyles.bodyBold.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Works with barcodes or QR codes',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: HomeGuideCard(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: HomeStartButton(
          onPressed: () => _start(context),
        ),
      ),
    );
  }
}
