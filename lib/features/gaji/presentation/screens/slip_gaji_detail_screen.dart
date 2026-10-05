/// Halaman detail slip gaji untuk satu bulan.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../domain/payslip.dart';
import '../widgets/payslip_hero_card.dart';
import '../widgets/payslip_item_section.dart';

/// Rincian pendapatan & potongan untuk satu periode slip gaji.
///
/// StatefulWidget hanya untuk satu hal: tombol mata yang menyamarkan nominal.
/// Itu murni keadaan tampilan, jadi tidak perlu bloc.
class SlipGajiDetailScreen extends StatefulWidget {
  const SlipGajiDetailScreen({super.key, required this.payslip});

  final Payslip payslip;

  @override
  State<SlipGajiDetailScreen> createState() => _SlipGajiDetailScreenState();
}

class _SlipGajiDetailScreenState extends State<SlipGajiDetailScreen> {
  bool _hidden = false;

  Payslip get _payslip => widget.payslip;

  void _downloadPdf() {
    // TODO(fitur-download-slip): ganti dengan unduh PDF asli begitu API siap.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Unduh slip gaji belum tersedia.')));
  }

  /// "Nama · NIK · Bagian" dari sesi yang sedang masuk.
  String? _identityLine() {
    final user = context.read<AuthBloc>().state.session?.user;
    if (user == null) return null;

    final List<String?> raw = [user.name, user.nik, user.section];
    final parts = raw.map((v) => v?.toString().trim() ?? '').where((v) => v.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: _payslip.periodLabel,
        onBack: () => Navigator.of(context).pop(),
        trailing: InkWell(
          onTap: () => setState(() => _hidden = !_hidden),
          child: Icon(
            _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: AppColors.primary,
            semanticLabel: _hidden ? 'Tampilkan nominal' : 'Sembunyikan nominal',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PayslipHeroCard(payslip: _payslip, hidden: _hidden, identity: _identityLine()),
            if (_payslip.paidDate != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'Dibayarkan ${_payslip.paidDate}'
                  '${_payslip.bankInfo != null ? ' · Rekening ${_payslip.bankInfo}' : ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
            const SizedBox(height: 20),
            PayslipItemSection(
              title: 'Pendapatan',
              items: _payslip.earnings,
              totalLabel: 'Total pendapatan',
              total: _payslip.totalEarnings,
              hidden: _hidden,
            ),
            const SizedBox(height: 16),
            PayslipItemSection(
              title: 'Potongan',
              items: _payslip.deductions,
              totalLabel: 'Total potongan',
              total: _payslip.totalDeductions,
              hidden: _hidden,
              isDeduction: true,
            ),
            if (!_payslip.isPaid) ...[
              const SizedBox(height: 12),
              const Text(
                'Slip masih dalam proses payroll dan dapat berubah sebelum tanggal pembayaran.',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 20),
            AppButton(label: 'Unduh PDF', onPressed: _downloadPdf),
          ],
        ),
      ),
    );
  }
}
