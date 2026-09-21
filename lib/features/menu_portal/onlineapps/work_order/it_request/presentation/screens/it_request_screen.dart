import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../domain/approve_request_demo_data.dart';
import '../../domain/approve_request_item.dart';
import '../widgets/approve_request_tab.dart';
import '../widgets/it_form_and_media_tab.dart';
import '../widgets/it_request_tab_bar.dart';
import '../widgets/list_request_tab.dart';
import '../widgets/report_tab_placeholder.dart';

/// Halaman IT Request.
///
/// SEMENTARA: pembagian staff vs tim IT masih lewat flag [isItTeam] lokal,
/// bukan dari `Role` HRIS — pemetaan role asli (HOD IT, Admin IT, dst dari
/// API) ke akses ini belum diputuskan, sama seperti catatan role di
/// auth_gate.dart. Tinggal ganti sumbernya nanti kalau sudah ada.
///
/// - Staff biasa (`isItTeam: false`): cuma "Form IT & Media", tanpa tab.
/// - Tim IT (`isItTeam: true`): tab Form IT & Media / Approve Request /
///   List Request / Report. Report masih placeholder kosong di iterasi ini.
class ItRequestScreen extends StatefulWidget {
  const ItRequestScreen({
    super.key,
    this.isItTeam = true,
    this.initialTabIndex = 0,
  });

  final bool isItTeam;

  /// Tab yang aktif saat layar ini dibuka (lihat urutan di [_buildTeamView]:
  /// 0 Form IT & Media, 1 Approve Request, 2 List Request, 3 Report).
  /// Dipakai tag "IT" di banner approval Beranda untuk masuk langsung ke
  /// tab Approve Request. Diabaikan kalau [isItTeam] false.
  final int initialTabIndex;

  @override
  State<ItRequestScreen> createState() => _ItRequestScreenState();
}

class _ItRequestScreenState extends State<ItRequestScreen> {
  late int _tabIndex = widget.initialTabIndex;
  List<ApproveRequestItem> _pendingApprovals = ApproveRequestDemoData.items();

  void _decide(ApproveRequestItem item, {required bool approved}) {
    setState(() {
      _pendingApprovals = _pendingApprovals.where((i) => i.id != item.id).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved
              ? 'Permintaan ${item.requesterName} disetujui'
              : 'Permintaan ${item.requesterName} ditolak',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'IT Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: widget.isItTeam ? _buildTeamView() : const ItFormAndMediaTab(),
    );
  }

  Widget _buildTeamView() {
    // IndexedStack menjaga semua tab tetap "hidup" di belakang layar, jadi
    // scroll position dan state form/filter tiap tab tidak reset saat
    // pindah-pindah tab.
    final tabs = [
      const ItFormAndMediaTab(),
      ApproveRequestTab(
        items: _pendingApprovals,
        onApprove: (item) => _decide(item, approved: true),
        onReject: (item) => _decide(item, approved: false),
      ),
      const ListRequestTab(),
      const ReportTabPlaceholder(),
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
          badgeCounts: {1: _pendingApprovals.length},
          onChanged: (i) => setState(() => _tabIndex = i),
        ),
        const SizedBox(height: 10),
        Expanded(child: IndexedStack(index: _tabIndex, children: tabs)),
      ],
    );
  }
}
