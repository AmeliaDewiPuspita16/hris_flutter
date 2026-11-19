import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/hris_sub_header.dart';
import '../../../shared/domain/role.dart';

import '../../data/pengajuan_repository.dart';
import '../bloc/balance/leave_balance_bloc.dart';
import '../bloc/balance/leave_balance_event.dart';
import '../bloc/history/leave_history_bloc.dart';
import '../bloc/history/leave_history_event.dart';
import '../widgets/ajukan_tab.dart';
import '../widgets/ringkasan_tab.dart';
import '../widgets/status_tab.dart';

enum _SubmitTab { ringkasan, ajukan, status }

/// Shell tab Pengajuan (Ringkasan / Ajukan / Status).
///
/// Menyediakan [LeaveBalanceBloc] dan [LeaveHistoryBloc] di sini, satu
/// tingkat di atas ketiga tab, supaya [AjukanTab] bisa menyisipkan hasil
/// submit ke [LeaveHistoryBloc] yang sama yang dibaca [StatusTab] — tanpa
/// kedua bloc itu perlu saling kenal satu sama lain.
///
/// Dibuka dari menu HRIS (push), bukan lagi tab bottom nav, jadi header
/// punya tombol kembali ([showBack]).
class PengajuanScreen extends StatelessWidget {
  const PengajuanScreen({
    super.key,
    required this.role,
    this.repository,
    this.showBack = true,
  });

  final Role role;

  /// Tampilkan tombol kembali di header.
  final bool showBack;

  /// Diisi test; di aplikasi diambil dari [RepositoryProvider].
  final PengajuanRepository? repository;

  @override
  Widget build(BuildContext context) {
    final pengajuan = repository ?? context.read<PengajuanRepository>();

    // Repository juga disediakan ke subpohon ini karena AjukanTab mengambilnya
    // lewat context — supaya tetap jalan saat [repository] diisi dari test.
    return RepositoryProvider.value(
      value: pengajuan,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => LeaveBalanceBloc(repository: pengajuan, role: role)
              ..add(const LeaveBalanceStarted()),
          ),
          BlocProvider(
            create: (_) => LeaveHistoryBloc(repository: pengajuan)
              ..add(const LeaveHistoryStarted()),
          ),
        ],
        // Header mint (terang) sampai ke balik status bar → ikon status bar
        // gelap. Diset di sini karena layar ini dibuka lewat push, di luar
        // AnnotatedRegion milik BerandaScreen.
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: HrisSubHeader.overlayStyle,
          // Scaffold dibutuhkan sebagai ancestor Material (InkWell, dst.):
          // layar ini di-push sebagai route sendiri, tidak lagi berada di
          // dalam Scaffold milik BerandaScreen.
          child: Scaffold(
            backgroundColor: HrisSubHeader.background,
            body: _PengajuanView(role: role, showBack: showBack),
          ),
        ),
      ),
    );
  }
}

class _PengajuanView extends StatefulWidget {
  const _PengajuanView({required this.role, required this.showBack});

  final Role role;
  final bool showBack;

  @override
  State<_PengajuanView> createState() => _PengajuanViewState();
}

class _PengajuanViewState extends State<_PengajuanView> {
  _SubmitTab _tab = _SubmitTab.ringkasan;

  @override
  Widget build(BuildContext context) {
    // Strip status bar memakai warna header (mint), bukan warna halaman —
    // kalau tidak, ada garis beda warna tepat di atas header. Badan halaman
    // memakai AppColors.bg supaya sama dengan Home.
    return ColoredBox(
      color: HrisSubHeader.background,
      child: SafeArea(
        bottom: false,
        child: ColoredBox(
          color: AppColors.bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Expanded(
                child: switch (_tab) {
                  _SubmitTab.ringkasan => RingkasanTab(
                      onSeeAll: () => setState(() => _tab = _SubmitTab.status),
                    ),
                  _SubmitTab.ajukan => AjukanTab(
                      role: widget.role,
                      onSubmitted: () =>
                          setState(() => _tab = _SubmitTab.status),
                    ),
                  _SubmitTab.status => StatusTab(role: widget.role),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return HrisSubHeader(
      title: 'Leave Request',
      subtitle: 'Balance, requests and status',
      showBack: widget.showBack,
      tabs: const [
        HrisHeaderTab('Summary', Icons.pie_chart_outline_rounded),
        HrisHeaderTab('Submit', Icons.edit_outlined),
        HrisHeaderTab('Status', Icons.calendar_month_outlined),
      ],
      selectedIndex: _tab.index,
      onTabChanged: (i) => setState(() => _tab = _SubmitTab.values[i]),
    );
  }
}
