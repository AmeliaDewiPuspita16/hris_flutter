import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../../../core/widgets/app_shimmer.dart';
import '../../../../../../core/widgets/flash_highlight.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../work_order/est_request/presentation/widgets/est_request_tab_bar.dart';
import '../../data/hse_work_request_repository.dart';
import '../../domain/hse_work_request.dart';
import '../bloc/hse_approval_cubit.dart';
import '../bloc/hse_permit_list_cubit.dart';
import '../widgets/hse_page_chrome.dart';
import '../widgets/hse_request_card.dart';
import '../widgets/hse_status_tabs.dart';
import 'hse_work_request_detail_screen.dart';
import 'hse_work_request_form_screen.dart';

/// Layar HSE Work Permit: daftar semua permit (filter status di server,
/// infinite scroll) dan — khusus approver HOD/HSE — tab antrean approval.
///
/// Tab approval tidak ditentukan dari role di aplikasi: antrean langsung
/// diminta ke server, dan tab disembunyikan bila server membalas 403.
class HseWorkRequestListScreen extends StatefulWidget {
  const HseWorkRequestListScreen({
    super.key,
    this.initialTabIndex = 0,
    this.highlightId,
  });

  /// Tab saat layar dibuka: 0 Semua Permit, 1 Approval. Dipakai banner
  /// "Approvals waiting" dan notifikasi approver. Bila akun ternyata bukan
  /// approver, tab Approval tidak muncul dan layar tetap di daftar.
  final int initialTabIndex;

  /// id permit dari notifikasi yang di-tap; kartunya dinaikkan ke atas dan
  /// dikedipkan di tab [initialTabIndex]. Null = tanpa penanda.
  final int? highlightId;

  @override
  State<HseWorkRequestListScreen> createState() =>
      _HseWorkRequestListScreenState();
}

class _HseWorkRequestListScreenState extends State<HseWorkRequestListScreen> {
  late final HsePermitListCubit _listCubit;
  late final HseApprovalCubit _approvalCubit;

  late int _tabIndex = widget.initialTabIndex;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final repository = context.read<HseWorkRequestRepository>();
    _listCubit = HsePermitListCubit(repository: repository)..applyFilter(null);
    _approvalCubit = HseApprovalCubit(repository: repository)..load();
  }

  @override
  void dispose() {
    _listCubit.close();
    _approvalCubit.close();
    super.dispose();
  }

  void _refreshAll() {
    _listCubit.refresh();
    if (!_approvalCubit.state.denied) _approvalCubit.refresh();
  }

  Future<void> _openForm() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const HseWorkRequestFormScreen()),
    );
    if (submitted == true && mounted) _refreshAll();
  }

  Future<void> _openDetail(HseWorkRequest request,
      {bool canDecide = false}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HseWorkRequestDetailScreen(
          request: request,
          canDecide: canDecide,
        ),
      ),
    );
    if (changed == true && mounted) _refreshAll();
  }

  Future<void> _decide(HseWorkRequest item, {required bool approved}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          approved ? 'Approve Permit?' : 'Reject Permit?',
          style: AppTextStyles.h2.copyWith(fontSize: 16),
        ),
        content: Text(
          '${item.idRegister ?? '#${item.id}'} — ${item.pic}',
          style: AppTextStyles.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: approved
                  ? AppColors.primary
                  : AppColors.solid(AppColors.rejected),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(approved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _approvalCubit.decide(item, approved: approved);
    }
  }

  /// Pencarian hanya menyaring permit yang SUDAH dimuat.
  List<HseWorkRequest> _search(List<HseWorkRequest> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((r) {
      return r.pic.toLowerCase().contains(q) ||
          (r.idRegister ?? '').toLowerCase().contains(q) ||
          r.location.toLowerCase().contains(q) ||
          r.department.toLowerCase().contains(q);
    }).toList();
  }

  /// id yang dikedipkan di [tab] — hanya tab tujuan notifikasi.
  int? _highlightFor(int tab) =>
      widget.initialTabIndex == tab ? widget.highlightId : null;

  /// Permit dari notifikasi dinaikkan ke paling atas supaya langsung
  /// terlihat, sama seperti EST Request.
  List<HseWorkRequest> _withHighlightFirst(
    List<HseWorkRequest> items, {
    required int tab,
  }) {
    final id = _highlightFor(tab);
    final at = id == null ? -1 : items.indexWhere((r) => r.id == id);
    if (at <= 0) return items;
    return [items[at], ...items.take(at), ...items.skip(at + 1)];
  }

  Widget _highlighted(
    HseWorkRequest request, {
    required int tab,
    required Widget child,
  }) {
    return FlashHighlight(
      key: ValueKey('hl-$tab-${request.id}'),
      active: request.id == _highlightFor(tab),
      borderRadius: 18,
      child: child,
    );
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 &&
        n.metrics.axis == Axis.vertical &&
        n.metrics.extentAfter < 300) {
      _listCubit.loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HseApprovalCubit, HseApprovalState>(
      bloc: _approvalCubit,
      listenWhen: (prev, curr) =>
          curr.notice != null && !identical(prev.notice, curr.notice),
      listener: (context, state) {
        final notice = state.notice!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notice.message),
            backgroundColor:
                notice.isError ? AppColors.solid(AppColors.rejected) : null,
          ),
        );
        if (!notice.isError) _listCubit.refresh();
      },
      child: HsePageBackdrop(
        floatingActionButton: _tabIndex == 0
            ? FloatingActionButton(
                onPressed: _openForm,
                backgroundColor: AppColors.solid(AppColors.orange),
                foregroundColor: Colors.white,
                tooltip: 'Add Permit',
                child: const Icon(Icons.add),
              )
            : null,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<HseApprovalCubit, HseApprovalState>(
            bloc: _approvalCubit,
            buildWhen: (p, c) =>
                p.confirmed != c.confirmed || p.pending != c.pending,
            builder: (context, approval) {
              // Tab baru muncul setelah server memastikan akun ini approver;
              // sebelum itu (atau bila 403) tampil seperti user biasa.
              final isApprover = approval.confirmed;
              final tab = isApprover ? _tabIndex : 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BlocBuilder<HsePermitListCubit, HsePermitListState>(
                    bloc: _listCubit,
                    buildWhen: (p, c) => p.mine != c.mine,
                    builder: (context, state) => _TopBar(
                      onBack: () => Navigator.of(context).pop(),
                      // Filter "milik saya" hanya berlaku di daftar permit.
                      onFilter: tab == 0 ? () => _openFilter(state.mine) : null,
                      filterActive: state.mine,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _SearchField(
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  if (isApprover)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: EstRequestTabBar(
                        labels: const ['All Permits', 'Approval'],
                        icons: const [
                          Icons.format_list_bulleted_rounded,
                          Icons.check_circle_outline_rounded,
                        ],
                        activeIndex: tab,
                        badgeCounts: {1: approval.pending},
                        onChanged: (i) => setState(() => _tabIndex = i),
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (tab == 0)
                    BlocBuilder<HsePermitListCubit, HsePermitListState>(
                      bloc: _listCubit,
                      buildWhen: (p, c) => p.filter != c.filter,
                      builder: (context, state) => HseStatusTabs(
                        selected: state.filter,
                        onChanged: _listCubit.applyFilter,
                      ),
                    )
                  else
                    _StageChips(cubit: _approvalCubit),
                  const SizedBox(height: 6),
                  Expanded(
                    child: IndexedStack(
                      index: tab,
                      children: [
                        _buildPermitList(),
                        isApprover
                            ? _buildApprovalList()
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Sheet filter tambahan: hanya permit milik sendiri (`?mine=1`).
  Future<void> _openFilter(bool mine) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(mine: mine),
    );
    if (result != null && mounted) await _listCubit.setMine(result);
  }

  Widget _buildPermitList() {
    return BlocBuilder<HsePermitListCubit, HsePermitListState>(
      bloc: _listCubit,
      builder: (context, state) {
        if (state.isFirstLoad) return const _HseListSkeleton();
        if (state.status == HseListStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load HSE permits.',
            onRetry: _listCubit.refresh,
          );
        }

        final items = _withHighlightFirst(_search(state.items), tab: 0);
        return RefreshIndicator(
          onRefresh: _listCubit.refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: items.isEmpty
                ? const _EmptyView(
                    message: 'No HSE permits match this filter.')
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    // Padding bawah ekstra supaya kartu terakhir tidak
                    // tertutup FAB.
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: items.length + (state.loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const AppShimmer(child: _CardSkeleton());
                      }
                      final request = items[index];
                      return _highlighted(
                        request,
                        tab: 0,
                        child: HseRequestCard(
                          request: request,
                          onTap: () => _openDetail(request),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildApprovalList() {
    return BlocBuilder<HseApprovalCubit, HseApprovalState>(
      bloc: _approvalCubit,
      builder: (context, state) {
        if (state.isFirstLoad) return const _HseListSkeleton();
        if (state.status == HseApprovalStatus.failure) {
          return AppErrorView(
            message: state.errorMessage ?? 'Failed to load the approval queue.',
            onRetry: _approvalCubit.refresh,
          );
        }

        final items = _withHighlightFirst(_search(state.items), tab: 1);
        return RefreshIndicator(
          onRefresh: _approvalCubit.refresh,
          child: items.isEmpty
              ? const _EmptyView(
                  message: 'No permits are waiting for approval.')
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final busy = state.busyIds.contains(item.id);
                    return _highlighted(
                      item,
                      tab: 1,
                      child: HseRequestCard(
                        request: item,
                        onTap: () => _openDetail(item, canDecide: true),
                        footer: _DecisionButtons(
                          busy: busy,
                          onReject: () => _decide(item, approved: false),
                          onApprove: () => _decide(item, approved: true),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: AppColors.border),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search register ID, name, or location...',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(Icons.search, size: 22, color: AppColors.textMuted),
          ),
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: AppColors.primaryText, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Baris atas: tombol kembali, judul hijau di tengah, tombol filter.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onFilter,
    required this.filterActive,
  });

  final VoidCallback onBack;

  /// Null = tombol filter disembunyikan (mis. di tab Approval).
  final VoidCallback? onFilter;
  final bool filterActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          HseCircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: onBack,
          ),
          Expanded(
            child: Text(
              'HSE Work Permit',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h2.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText,
              ),
            ),
          ),
          // Lebar tetap supaya judul tetap di tengah saat tombol tersembunyi.
          SizedBox.square(
            dimension: 44,
            child: onFilter == null
                ? null
                : HseCircleButton(
                    icon: Icons.tune_rounded,
                    tooltip: 'Filter',
                    onTap: onFilter,
                    showDot: filterActive,
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.mine});

  final bool mine;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _mine = widget.mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Filter', style: AppTextStyles.h2.copyWith(fontSize: 17)),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _mine,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(() => _mine = v),
                title: Text(
                  'My permits only',
                  style:
                      AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Show only permits I submitted.',
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Apply',
                onPressed: () => Navigator.of(context).pop(_mine),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter stage di tab approval — hanya tampil bila user memegang lebih
/// dari satu stage (mis. HOD sekaligus HSE).
class _StageChips extends StatelessWidget {
  const _StageChips({required this.cubit});

  final HseApprovalCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HseApprovalCubit, HseApprovalState>(
      bloc: cubit,
      buildWhen: (p, c) => p.summary != c.summary || p.stage != c.stage,
      builder: (context, state) {
        if (state.summary.length < 2) return const SizedBox.shrink();

        final stages = <String?>[null, ...state.summary.keys];
        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final stage = stages[i];
              final selected = stage == state.stage;
              final label = stage == null
                  ? 'All (${state.pending})'
                  : '${stage.toUpperCase()} (${state.summary[stage]})';
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => cubit.load(stage: stage),
                labelStyle: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textMid,
                ),
                backgroundColor: AppColors.card,
                selectedColor: AppColors.primary,
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                visualDensity: VisualDensity.compact,
                showCheckmark: false,
              );
            },
          ),
        );
      },
    );
  }
}

class _DecisionButtons extends StatelessWidget {
  const _DecisionButtons({
    required this.busy,
    required this.onReject,
    required this.onApprove,
  });

  final bool busy;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: onReject,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.rejected,
            side: BorderSide(color: AppColors.rejected),
            minimumSize: const Size(88, 36),
          ),
          child: const Text('Reject'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onApprove,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(88, 36),
          ),
          child: const Text('Approve'),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // ListView supaya tarik-untuk-refresh tetap bisa saat kosong.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
      ],
    );
  }
}

/// Skeleton daftar permit selagi data pertama dimuat.
class _HseListSkeleton extends StatelessWidget {
  const _HseListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      children: [
        ShimmerList(itemCount: 5, itemBuilder: (_) => const _CardSkeleton()),
      ],
    );
  }
}

/// Meniru [HseRequestCard]: judul + status, dua baris keterangan, lalu
/// baris lokasi dan tanggal.
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ShimmerLine(width: 150, height: 14),
                ),
              ),
              SizedBox(width: 8),
              ShimmerBox(width: 64, height: 20, borderRadius: 20),
            ],
          ),
          SizedBox(height: 10),
          ShimmerLine(height: 11),
          SizedBox(height: 6),
          ShimmerLine(width: 180, height: 11),
          SizedBox(height: 12),
          Row(
            children: [
              ShimmerLine(width: 90, height: 10),
              SizedBox(width: 16),
              ShimmerLine(width: 70, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
