import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../core/network/api_exception.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/date_formatter.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_error_view.dart';
import '../../../../shared/presentation/widgets/portal_category_page.dart';
import '../../data/hse_work_request_repository.dart';
import '../../domain/hse_form_options.dart';
import '../../domain/hse_request_category.dart';
import '../../domain/hse_request_status.dart';
import '../../domain/hse_work_request.dart';
import '../widgets/hse_close_permit_sheet.dart';
import '../widgets/hse_page_chrome.dart';

/// Detail satu permit HSE dari `GET /hse_permit/{id}`, plus aksinya:
/// tutup (pemilik, On Progress), hapus (pemilik, Waiting — lewat menu ⋯),
/// serta approve/reject bila dibuka dari tab approval ([canDecide]).
///
/// Pop dengan `true` bila permit berubah, supaya daftar dimuat ulang.
class HseWorkRequestDetailScreen extends StatefulWidget {
  const HseWorkRequestDetailScreen({
    super.key,
    required this.request,
    this.canDecide = false,
  });

  /// Versi ringkas dari daftar — tampil selagi detail lengkap dimuat.
  final HseWorkRequest request;

  /// Dibuka dari antrean approval: tampilkan tombol Approve/Reject.
  final bool canDecide;

  @override
  State<HseWorkRequestDetailScreen> createState() =>
      _HseWorkRequestDetailScreenState();
}

class _HseWorkRequestDetailScreenState
    extends State<HseWorkRequestDetailScreen> {
  late final HseWorkRequestRepository _repository;
  late HseWorkRequest _request = widget.request;
  bool _loading = true;
  bool _loadedOnce = false;
  String? _error;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _repository = context.read<HseWorkRequestRepository>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _repository.fetchDetail(widget.request.id);
      if (mounted) {
        setState(() {
          _request = detail;
          _loadedOnce = true;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memuat detail permit.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.solid(AppColors.rejected) : null,
      ),
    );
  }

  void _pop() => Navigator.of(context).pop(_changed);

  /// Menu ⋯: muat ulang, dan aksi pemilik yang tidak perlu menonjol.
  Future<void> _openMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet(
        actions: [
          (
            id: 'refresh',
            icon: Icons.refresh_rounded,
            label: 'Muat ulang',
            danger: false,
          ),
          if (_request.canClose)
            (
              id: 'close',
              icon: Icons.task_alt_rounded,
              label: 'Tutup Permit',
              danger: false,
            ),
          if (_request.canDelete)
            (
              id: 'delete',
              icon: Icons.delete_outline_rounded,
              label: 'Hapus Permit',
              danger: true,
            ),
        ],
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'refresh':
        await _load();
      case 'close':
        await _closePermit();
      case 'delete':
        await _deletePermit();
    }
  }

  Future<void> _closePermit() async {
    final result = await showModalBottomSheet<HsePermitResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HseClosePermitSheet(
        permitId: _request.id,
        repository: _repository,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _request = result.permit;
      _changed = true;
    });
    _snack(result.message);
  }

  Future<void> _deletePermit() async {
    final ok = await _confirm(
      title: 'Hapus Permit?',
      message: 'Permit ${_request.idRegister ?? ''} akan dihapus permanen.',
      confirmLabel: 'Hapus',
      danger: true,
    );
    if (!ok || !mounted) return;

    await _run(() async {
      final message = await _repository.delete(_request.id);
      if (!mounted) return;
      _snack(message);
      Navigator.of(context).pop(true);
    });
  }

  Future<void> _decide({required bool approved}) async {
    final ok = await _confirm(
      title: approved ? 'Approve Permit?' : 'Reject Permit?',
      message: approved
          ? 'Permit ${_request.idRegister ?? ''} akan disetujui.'
          : 'Permit ${_request.idRegister ?? ''} akan ditolak.',
      confirmLabel: approved ? 'Approve' : 'Reject',
      danger: !approved,
    );
    if (!ok || !mounted) return;

    await _run(() async {
      final result = approved
          ? await _repository.approve(_request.id)
          : await _repository.reject(_request.id);
      if (!mounted) return;
      _snack(result.message);
      Navigator.of(context).pop(true);
    });
  }

  /// Menjalankan aksi ke server dengan tombol terkunci; galat jadi snackbar.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, error: true);
    } catch (_) {
      if (mounted) _snack('Terjadi kesalahan. Coba lagi.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title, style: AppTextStyles.h2.copyWith(fontSize: 16)),
            content: Text(message, style: AppTextStyles.bodyMuted),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    Text('Batal', style: TextStyle(color: AppColors.textSub)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: danger
                      ? AppColors.solid(AppColors.rejected)
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pop();
      },
      child: HsePageBackdrop(
        bottomNavigationBar: _buildActions(request),
        body: SafeArea(
          bottom: false,
          child: _error != null && !_loadedOnce
              ? Column(
                  children: [
                    _DetailTopBar(onBack: _pop, onMore: null),
                    Expanded(
                      child: AppErrorView(message: _error!, onRetry: _load),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      _DetailHeader(
                        request: request,
                        onBack: _pop,
                        onMore: _openMenu,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusPill(request: request),
                          _InfoPill(
                            icon: Icons.calendar_month_outlined,
                            text: hseDateRange(
                              request.dateStart,
                              request.dateEnd,
                            ),
                          ),
                        ],
                      ),
                      if (_loading) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(minHeight: 2),
                      ],
                      const SizedBox(height: 16),
                      _JobDetailCard(request: request),
                      const SizedBox(height: 14),
                      _ApprovalSection(request: request),
                      ..._checklistSections(request),
                      if (request.documents.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        HseSectionCard(
                          title: 'Dokumen',
                          child: Column(
                            children: [
                              for (final entry in request.documents.entries)
                                _LinkRow(
                                  icon: Icons.picture_as_pdf_outlined,
                                  label:
                                      HseFormOptions.documentLabel(entry.key),
                                  url: entry.value,
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (request.closing != null) ...[
                        const SizedBox(height: 14),
                        _ClosingCard(closing: request.closing!),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  List<Widget> _checklistSections(HseWorkRequest request) {
    final general = [
      ...request.generalChecklist,
      if (request.otherGeneralChecklist != null) request.otherGeneralChecklist!,
    ];
    final types = [
      ...request.typeOfWorks,
      if (request.otherTypeOfWork != null) request.otherTypeOfWork!,
    ];
    final ppe = [
      ...request.ppe,
      if (request.otherPpe != null) request.otherPpe!,
    ];

    return [
      if (general.isNotEmpty) ...[
        const SizedBox(height: 14),
        HseSectionCard(
          title: 'General Checklist',
          child: Column(
            children: [for (final item in general) _CheckRow(label: item)],
          ),
        ),
      ],
      if (types.isNotEmpty) ...[
        const SizedBox(height: 14),
        HseSectionCard(title: 'Type of Works', child: _ChipWrap(items: types)),
      ],
      if (ppe.isNotEmpty) ...[
        const SizedBox(height: 14),
        HseSectionCard(
          title: 'Personal Protective Equipment',
          child: _ChipWrap(items: ppe),
        ),
      ],
    ];
  }

  /// Bar bawah: Approve/Reject (dari tab approval) atau Tutup Permit.
  /// Hapus sengaja tidak di sini — ada di menu ⋯ karena aksinya merusak.
  Widget? _buildActions(HseWorkRequest request) {
    if (!_loadedOnce) return null;

    final List<Widget> buttons;
    if (widget.canDecide && request.status == HseRequestStatus.onWaiting) {
      buttons = [
        Expanded(
          child: AppButton(
            label: 'Reject',
            variant: AppButtonVariant.danger,
            onPressed: _busy ? null : () => _decide(approved: false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: 'Approve',
            isLoading: _busy,
            onPressed: () => _decide(approved: true),
          ),
        ),
      ];
    } else if (request.canClose) {
      buttons = [
        Expanded(
          child: AppButton(
            label: 'Tutup Permit',
            onPressed: _busy ? null : _closePermit,
          ),
        ),
      ];
    } else {
      return null;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(top: false, child: Row(children: buttons)),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.onBack, required this.onMore});

  final VoidCallback onBack;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          HseCircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Kembali',
            onTap: onBack,
          ),
          const Spacer(),
          if (onMore != null)
            HseCircleButton(
              icon: Icons.more_horiz_rounded,
              tooltip: 'Lainnya',
              onTap: onMore,
            ),
        ],
      ),
    );
  }
}

/// Tombol atas, ilustrasi laptop di kanan, lalu nomor register, nama PIC,
/// dan departemen. Teks dibatasi lebarnya supaya tidak menimpa ilustrasi.
class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.request,
    required this.onBack,
    required this.onMore,
  });

  final HseWorkRequest request;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final department = hseDepartmentLine(request.department, request.section);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -8,
          top: 44,
          child: SvgPicture.asset(
            PortalCategoryPage.laptopIllustration,
            width: 170,
            excludeFromSemantics: true,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailTopBar(onBack: onBack, onMore: onMore),
            const SizedBox(height: 28),
            FractionallySizedBox(
              widthFactor: 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.idRegister ?? '#${request.id}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.pic,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  if (department.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      department,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Ruang minimum agar ilustrasi tidak menabrak pill di bawahnya.
            const SizedBox(height: 12),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.request});

  final HseWorkRequest request;

  @override
  Widget build(BuildContext context) {
    final status = request.status;
    final icon = switch (status) {
      HseRequestStatus.onWaiting => Icons.hourglass_top_rounded,
      HseRequestStatus.onProgress => Icons.verified_user_rounded,
      HseRequestStatus.done => Icons.check_circle_rounded,
      HseRequestStatus.reject => Icons.cancel_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: status.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: status.color),
          const SizedBox(width: 6),
          Text(
            request.displayStatus,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

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
          Text(
            text,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobDetailCard extends StatelessWidget {
  const _JobDetailCard({required this.request});

  final HseWorkRequest request;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _InfoRow(
        icon: Icons.sell_outlined,
        label: 'Kategori',
        value: request.categoryLabel ?? request.category.label,
      ),
      _InfoRow(
        icon: Icons.location_on_outlined,
        label: 'Location',
        value: request.location,
      ),
      _InfoRow(
        icon: Icons.inventory_2_outlined,
        label: 'Materials',
        child: _MaterialsText(materials: request.materials),
      ),
      _InfoRow(
        icon: Icons.storefront_outlined,
        label: 'Vendor',
        value: request.vendor ?? '-',
      ),
      _InfoRow(
        icon: Icons.person_outline_rounded,
        label: 'Total Workers',
        value: '${request.totalWorkers}',
      ),
      _InfoRow(
        icon: Icons.calendar_month_outlined,
        label: 'Date of Work',
        value: hseDateRange(request.dateStart, request.dateEnd),
      ),
    ];

    return HseSectionCard(
      title: 'Detail Pekerjaan',
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Satu baris info: ikon hijau, label abu, lalu nilai (teks atau [child]).
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.child,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryText),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: child ??
                Text(
                  (value == null || value!.trim().isEmpty) ? '-' : value!,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Materials berisi beberapa baris jadi daftar bernomor; nomor yang sudah
/// diketik user ("1. Pipa …") dibuang dulu supaya tidak dobel.
class _MaterialsText extends StatelessWidget {
  const _MaterialsText({required this.materials});

  final String materials;

  static final _leadingNumber = RegExp(r'^\s*\d+[.)]\s*');

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    final lines = materials
        .split('\n')
        .map((l) => l.replaceFirst(_leadingNumber, '').trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.length < 2) {
      return Text(materials.trim().isEmpty ? '-' : materials.trim(),
          style: style);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 20, child: Text('${i + 1}.', style: style)),
                Expanded(child: Text(lines[i], style: style)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Acknowledge & Approval — dua approver dengan tahap berbeda.
class _ApprovalSection extends StatelessWidget {
  const _ApprovalSection({required this.request});

  final HseWorkRequest request;

  @override
  Widget build(BuildContext context) {
    final rejected = request.status == HseRequestStatus.reject;

    Widget row(String label, String? name) {
      final done = name != null;
      final (icon, color) = done
          ? (Icons.verified_rounded, AppColors.present)
          : rejected
              ? (Icons.cancel_outlined, AppColors.rejected)
              : (Icons.hourglass_top_rounded, AppColors.pending);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            SizedBox(
              width: 96,
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name ?? (rejected ? '-' : 'Menunggu'),
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: done ? AppColors.text : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return HseSectionCard(
      title: 'Persetujuan',
      child: Column(
        children: [
          row('Acknowledge', request.acknowledgeBy),
          Divider(height: 1, color: AppColors.border),
          row('Approval', request.approvalBy),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 20, color: AppColors.present),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.presentBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClosingCard extends StatelessWidget {
  const _ClosingCard({required this.closing});

  final HsePermitClosing closing;

  @override
  Widget build(BuildContext context) {
    return HseSectionCard(
      title: 'Penutupan',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.notes_rounded,
            label: 'Deskripsi',
            value: closing.description,
          ),
          Divider(height: 1, color: AppColors.border),
          _InfoRow(
            icon: Icons.event_available_outlined,
            label: 'Ditutup',
            value: closing.closedAt == null
                ? '-'
                : DateFormatter.dateTimeID(closing.closedAt!),
          ),
          if (closing.evidenceUrl != null) ...[
            Divider(height: 1, color: AppColors.border),
            _LinkRow(
              icon: Icons.attach_file_rounded,
              label: 'Evidence',
              url: closing.evidenceUrl!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Baris berkas yang dibuka di aplikasi bawaan perangkat.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final uri = Uri.tryParse(url);
        if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

typedef _SheetAction = ({String id, IconData icon, String label, bool danger});

/// Sheet aksi untuk menu ⋯. Pop dengan `id` aksi yang dipilih.
class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.actions});

  final List<_SheetAction> actions;

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
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              for (final a in actions)
                ListTile(
                  leading: Icon(
                    a.icon,
                    color:
                        a.danger ? AppColors.rejected : AppColors.primaryText,
                  ),
                  title: Text(
                    a.label,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: a.danger ? AppColors.rejected : AppColors.text,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(a.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
