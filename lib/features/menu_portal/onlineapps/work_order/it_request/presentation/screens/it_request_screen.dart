import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/widgets/back_header.dart';
import '../../../../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../widgets/it_form_and_media_tab.dart';
import '../widgets/it_request_tab_bar.dart';
import '../widgets/list_request_tab.dart';
import '../widgets/report_tab.dart';

/// Halaman IT Request.
///
/// - Role lain (bukan tim IT): cuma "Form IT & Media", tanpa tab.
/// - Role `it media` / `admin` (lihat `AuthUser.canManageItRequest`): tab
///   Form IT & Media / List Request / Report.
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
  /// 0 Form IT & Media, 1 List Request, 2 Report). Diabaikan kalau tab
  /// tim IT tidak tampil.
  final int initialTabIndex;

  @override
  State<ItRequestScreen> createState() => _ItRequestScreenState();
}

class _ItRequestScreenState extends State<ItRequestScreen> {
  late final bool _isItTeam;
  late int _tabIndex = widget.initialTabIndex;

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

  Widget _buildTeamView() {
    // IndexedStack menjaga semua tab tetap "hidup" di belakang layar, jadi
    // scroll position dan state form/filter tiap tab tidak reset saat
    // pindah-pindah tab.
    final tabs = const [
      ItFormAndMediaTab(),
      ListRequestTab(),
      ReportTab(),
    ];

    return Column(
      children: [
        const SizedBox(height: 12),
        ItRequestTabBar(
          labels: const ['Form IT & Media', 'List Request', 'Report'],
          activeIndex: _tabIndex,
          onChanged: (i) => setState(() => _tabIndex = i),
        ),
        const SizedBox(height: 10),
        Expanded(child: IndexedStack(index: _tabIndex, children: tabs)),
      ],
    );
  }
}
