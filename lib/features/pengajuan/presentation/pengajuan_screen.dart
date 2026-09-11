import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../shared/domain/role.dart';

import '../domain/leave_type.dart';
import 'widgets/ringkasan_tab.dart';
import 'widgets/ajukan_tab.dart';
import 'widgets/status_tab.dart';

enum _SubmitTab { 
  ringkasan, 
  ajukan, 
  status 
}


class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({
    super.key, 
    required this.role
  });

  final Role role;

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  _SubmitTab _tab = _SubmitTab.ringkasan;

  LeaveType _leaveType = LeaveType.cutiTahunan;
  LeaveCategory _izinCategory = LeaveCategory.mcSakit;

  bool _submitted = false;

  void _handleSubmit() {
    setState(() => _submitted = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      setState(() {
        _submitted = false;
        _tab = _SubmitTab.status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),

            Expanded(
              child: switch (_tab) {
                _SubmitTab.ringkasan => RingkasanTab(role: widget.role),
                _SubmitTab.ajukan => AjukanTab(
                  role: widget.role,
                  leaveType: _leaveType,
                  izinCategory: _izinCategory,
                  submitted: _submitted,

                  onLeaveTypeChanged: (value) {
                    setState(() => _leaveType = value);
                  },

                  onIzinCategoryChanged: (value) {
                    setState(() => _izinCategory = value);
                  },
                  onSubmit: _handleSubmit,
                ),

                _SubmitTab.status => StatusTab(role: widget.role),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Widget tabButton(_SubmitTab tab, String label) {
      final active = _tab == tab;

      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = tab),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active 
                    ? AppColors.primary 
                    : Colors.transparent, 
                  width: 2.5
                )
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: 
                FontWeight.w700, 
                color: active 
                  ? AppColors.primary 
                  : AppColors.textMuted
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: const BoxDecoration(
        color: Colors.white, 
        border: Border(
          bottom: BorderSide(
            color: AppColors.border
          )
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text('Pengajuan', style: AppTextStyles.h2),
          ),

          Row(
            children: [
              tabButton(_SubmitTab.ringkasan, 'Ringkasan'),
              tabButton(_SubmitTab.ajukan, 'Ajukan'),
              tabButton(_SubmitTab.status, 'Status'),
            ],
          ),
        ],
      ),
    );
  }
}