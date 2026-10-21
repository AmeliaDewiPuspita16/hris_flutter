import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../../../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../domain/approve_request_demo_data.dart';
import '../../domain/approve_request_item.dart';
import '../widgets/approve_request_tab.dart';
import '../widgets/it_form_and_media_tab.dart';
import '../widgets/it_request_tab_bar.dart';
import '../widgets/list_request_tab.dart';
import '../widgets/report_tab.dart';

/// Halaman IT Request.
///
/// - Role lain (bukan tim IT): cuma "Form IT & Media", tanpa tab.
/// - Role `it media` / `admin` (lihat `AuthUser.canManageItRequest`): tab
///   Form IT & Media / Approve Request / List Request / Report (urutan sama
///   dengan web).
///
/// SEMENTARA: tab Approve Request tampil untuk semua yang melihat tab tim IT
/// dan masih memakai data demo — role yang boleh melihatnya dan API-nya
/// belum ditentukan.
class ItRequestScreen extends StatefulWidget {
  const ItRequestScreen({
    super.key,
    this.isItTeam,
    this.initialTabIndex = 0,
  });

  /// Null berarti dihitung dari role user yang sedang login lewat
  /// [AuthBloc] (`AuthUser.canManageItRequest`). Diisi test untuk override
  /// tanpa perlu menyediakan `AuthBloc` sungguhan.
  final bool? isItTeam;

  /// Tab yang aktif saat layar ini dibuka (lihat urutan di [_buildTeamView]:
  /// 0 Form IT & Media, 1 Approve Request, 2 List Request, 3 Report). Diabaikan kalau tab
  /// tim IT tidak tampil.
  final int initialTabIndex;

  @override
  State<ItRequestScreen> createState() => _ItRequestScreenState();
}

class _ItRequestScreenState extends State<ItRequestScreen> {
  late final bool _isItTeam;
  late int _tabIndex = widget.initialTabIndex;

  // SEMENTARA: data demo, belum dari API.
  List<ApproveRequestItem> _approvals = ApproveRequestDemoData.items();

  @override
  void initState() {
    super.initState();
    _isItTeam = widget.isItTeam ??
        (context.read<AuthBloc>().state.session?.user.canManageItRequest ??
            false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'IT Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: _isItTeam ? _buildTeamView() : const ItFormAndMediaTab(),
    );
  }

  /// Keputusan di tab Approve Request: request keluar dari daftar. Ada
  /// dialog konfirmasi dulu karena keputusan tidak bisa dibatalkan dari
  /// aplikasi (sama seperti Supervisor Approval di Indent Vehicle).
  ///
  /// TODO(api): kirim keputusan ke server; sekarang hanya mengubah daftar
  /// lokal.
  Future<void> _decide(
    ApproveRequestItem item, {
    required bool approved,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approved ? 'Approve request?' : 'Reject request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.requesterName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(approved ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _approvals = _approvals.where((r) => r.id != item.id).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved
              ? 'Request from ${item.requesterName} approved'
              : 'Request from ${item.requesterName} rejected',
        ),
      ),
    );
  }

  Widget _buildTeamView() {
    // IndexedStack menjaga semua tab tetap "hidup" di belakang layar, jadi
    // scroll position dan state form/filter tiap tab tidak reset saat
    // pindah-pindah tab.
    final tabs = [
      const ItFormAndMediaTab(),
      ApproveRequestTab(
        items: _approvals,
        onApprove: (item) => _decide(item, approved: true),
        onReject: (item) => _decide(item, approved: false),
      ),
      const ListRequestTab(),
      const ReportTab(),
    ];

    return Column(
      children: [
        const SizedBox(height: 12),
        ItRequestTabBar(
          labels: const [
            'Form IT & Media',
            'Approve Request',
            'List Request',
            'Report',
          ],
          activeIndex: _tabIndex,
          badgeCounts: {1: _approvals.length},
          onChanged: (i) => setState(() => _tabIndex = i),
        ),
        const SizedBox(height: 10),
        Expanded(child: IndexedStack(index: _tabIndex, children: tabs)),
      ],
    );
  }
}
