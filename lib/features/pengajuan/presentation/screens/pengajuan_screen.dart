import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/header_title_row.dart';
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
    final pengajuan = repository ?? PengajuanRepository(apiClient: ApiClient());

    return MultiBlocProvider(
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
      // Header hijau sampai ke balik status bar → ikon status bar terang.
      // Diset di sini karena layar ini dibuka lewat push, di luar
      // AnnotatedRegion milik BerandaScreen.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        // Scaffold dibutuhkan sebagai ancestor Material (InkWell, dst.):
        // layar ini di-push sebagai route sendiri, tidak lagi berada di
        // dalam Scaffold milik BerandaScreen.
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: _PengajuanView(role: role, showBack: showBack),
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
    // Strip status bar memakai warna header (primary), bukan warna halaman —
    // kalau tidak, ada garis beda warna tepat di atas header. Badan halaman
    // memakai AppColors.bg supaya sama dengan Home.
    return ColoredBox(
      color: AppColors.primary,
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
                      onSubmitted: () => setState(() => _tab = _SubmitTab.status),
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
    Widget tabButton(_SubmitTab tab, String label, IconData icon) {
      final active = _tab == tab;

      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = tab),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              // Aktif: pil putih dengan teks primary. Tidak aktif: transparan
              // di atas header hijau dengan teks putih pudar.
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      // Solid primary, sudut bawah bulat — sama dengan header Log Absensi.
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeaderTitleRow(title: 'Leave Request', showBack: widget.showBack),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                tabButton(_SubmitTab.ringkasan, 'Summary', Icons.pie_chart_outline_rounded),
                tabButton(_SubmitTab.ajukan, 'Submit', Icons.edit_outlined),
                tabButton(_SubmitTab.status, 'Status', Icons.calendar_month_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
