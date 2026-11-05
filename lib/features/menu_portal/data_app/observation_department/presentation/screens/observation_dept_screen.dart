import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../shared/presentation/widgets/portal_category_page.dart';
import '../../data/observation_repository.dart';
import '../../domain/observation_item.dart';
import '../bloc/observation_list_cubit.dart';
import '../bloc/observation_list_state.dart';
import '../widgets/observation_close_sheet.dart';
import '../widgets/observation_filter_sheet.dart';
import '../widgets/observation_list_tab.dart';
import '../widgets/observation_tab_bar.dart';
import 'add_observation_screen.dart';
import 'observation_detail_screen.dart';

/// Layar Observation Department (menu Data).
///
/// Padanan halaman "All Observations" di web, dipecah jadi dua tab:
/// - **My Dept Open** — tabel "OPEN Observations from Your Department",
///   dengan tombol Close di tiap kartu.
/// - **All Observations** — semua observasi, dengan filter Month / Relevant
///   Dept. / Category.
///
/// Kolom search di atas berlaku di kedua tab; tombol filter hanya muncul di
/// tab All Observations. FAB oranye membuka form Add. Ketuk kartu untuk
/// detail (isi PDF di web, ditampilkan langsung di layar).
///
/// Data masih DEMO lewat [ObservationRepository] (belum ada endpoint).
class ObservationDeptScreen extends StatefulWidget {
  const ObservationDeptScreen({super.key});

  @override
  State<ObservationDeptScreen> createState() => _ObservationDeptScreenState();
}

class _ObservationDeptScreenState extends State<ObservationDeptScreen> {
  static const _myOpenTab = 0;
  static const _allTab = 1;

  late final ObservationRepository _repository;
  late final ObservationListCubit _cubit;
  final _searchController = TextEditingController();
  int _tabIndex = _myOpenTab;

  @override
  void initState() {
    super.initState();
    // Satu instance dipakai bersama layar Add / Detail (data demo tersimpan
    // di memori instance ini).
    _repository = ObservationRepository();
    _cubit = ObservationListCubit(repository: _repository)..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddObservationScreen(repository: _repository),
      ),
    );
    if (saved != true || !mounted) return;
    _showMessage('Observation added.');
    // Observasi baru selalu open dan milik dept sendiri: tampil di My Dept Open.
    setState(() => _tabIndex = _myOpenTab);
    await _cubit.load();
  }

  Future<void> _openDetail(ObservationItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ObservationDetailScreen(
          item: item,
          repository: _repository,
        ),
      ),
    );
    if (changed == true && mounted) await _cubit.load();
  }

  Future<void> _closeItem(ObservationItem item) async {
    final closed = await ObservationCloseSheet.show(
      context,
      item: item,
      repository: _repository,
    );
    if (closed == null || !mounted) return;
    _showMessage('Observation closed.');
    await _cubit.load();
  }

  Future<void> _openFilter(ObservationListState state) async {
    final result = await ObservationFilterSheet.show(
      context,
      initial: state.filter,
      months: state.monthOptions,
    );
    if (result != null) _cubit.setFilter(result);
  }

  @override
  Widget build(BuildContext context) {
    return PortalModulePage(
      eyebrow: 'OBSERVATION DEPARTMENT',
      title: 'Observation',
      subtitle: 'Report findings and follow up on department observations.',
      illustrationAsset: PortalCategoryPage.monitorIllustration,
      // FAB oranye di kanan-bawah, sama pola dengan Indent Vehicle, IT
      // Request, HSE, dan EST.
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppColors.solid(AppColors.orange),
        foregroundColor: Colors.white,
        tooltip: 'Add Observation',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<ObservationListCubit, ObservationListState>(
          bloc: _cubit,
          builder: (context, state) => Column(
            children: [
              // Search + tab bar fixed di luar area scroll, sama dengan
              // Indent Vehicle.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchRow(state),
                    const SizedBox(height: 12),
                    ObservationTabBar(
                      labels: const ['My Dept Open', 'All Observations'],
                      activeIndex: _tabIndex,
                      badgeCounts: {_myOpenTab: state.myOpen.length},
                      onChanged: (i) => setState(() => _tabIndex = i),
                    ),
                  ],
                ),
              ),
              // IndexedStack: kedua tab tetap "hidup" di belakang layar.
              // Tab tersembunyi dilepas dari scroll header, lihat
              // `PortalTabScrollScope`.
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    PortalTabScrollScope(
                      active: _tabIndex == _myOpenTab,
                      child: ObservationListTab(
                        state: state,
                        items: state.visibleMyOpen,
                        onRefresh: _cubit.load,
                        onOpen: _openDetail,
                        onClose: _closeItem,
                        emptyTitle: 'No open observations',
                        emptyMessage:
                            'Open observations reported by your department will appear here.',
                      ),
                    ),
                    PortalTabScrollScope(
                      active: _tabIndex == _allTab,
                      child: ObservationListTab(
                        state: state,
                        items: state.visibleAll,
                        onRefresh: _cubit.load,
                        onOpen: _openDetail,
                        onClose: _closeItem,
                        emptyTitle: 'No observations yet',
                        emptyMessage:
                            'Observations from all departments will appear here.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchRow(ObservationListState state) {
    final showFilter = _tabIndex == _allTab;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppTextField(
              controller: _searchController,
              hint: 'Search observation...',
              icon: Icons.search,
              onChanged: _cubit.setQuery,
            ),
          ),
          if (showFilter) ...[
            const SizedBox(width: 10),
            _FilterButton(
              active: state.filter.isActive,
              onTap: () => _openFilter(state),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tombol filter persegi di samping kolom search; berwarna penuh dan
/// bertitik saat ada filter aktif.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: active ? null : Border.all(color: AppColors.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 22,
                color: active ? Colors.white : AppColors.text,
              ),
              if (active)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.solid(AppColors.orange),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
