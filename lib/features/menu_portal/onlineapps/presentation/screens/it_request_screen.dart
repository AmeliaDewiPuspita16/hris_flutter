import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/back_header.dart';
import '../../domain/it_request_demo_data.dart';
import '../../domain/it_request_item.dart';
import '../widgets/it_request_card.dart';
import '../widgets/it_request_feedback_banner.dart';
import '../widgets/it_request_feedback_sheet.dart';

/// Halaman IT Request untuk staff biasa (bukan HOD IT / Admin IT).
///
/// Staff cuma melihat form + riwayat permintaan sendiri, tanpa tab
/// "Approve Request" / "List Request" / "Report", lewat flag akses yang terpisah
/// dari [Role] HRIS biasa (karena "HOD IT" bukan role HOD secara umum).
///
/// Aturan intinya: kalau ada permintaan yang sudah selesai dikerjakan tim
/// IT tapi staff belum kasih feedback, tombol "+ Ajukan Request"
/// disembunyikan dan diganti kartu feedback — staff mau tidak mau harus
/// menyelesaikan feedback itu dulu sebelum bisa mengajukan lagi.
class ItRequestScreen extends StatefulWidget {
  const ItRequestScreen({super.key});

  @override
  State<ItRequestScreen> createState() => _ItRequestScreenState();
}

class _ItRequestScreenState extends State<ItRequestScreen> {
  List<ItRequestItem> _myRequests = ItRequestDemoData.myRequests();

  List<ItRequestItem> get _awaitingFeedback =>
      _myRequests.where((r) => r.awaitingFeedback).toList();

  bool get _canAddRequest => _awaitingFeedback.isEmpty;

  Future<void> _giveFeedback(ItRequestItem item) async {
    final rating = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ItRequestFeedbackSheet(description: item.description),
    );

    if (rating == null || !mounted) return;

    setState(() {
      _myRequests = [
        for (final r in _myRequests)
          if (r.id == item.id) r.copyWith(awaitingFeedback: false) else r,
      ];
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terima kasih atas feedbacknya!')),
    );
  }

  void _addRequest() {
    // Form pengajuan IT Request sendiri belum dibuat di iterasi ini.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form pengajuan belum tersedia')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Item yang menunggu feedback sudah tampil sebagai banner di atas, jadi
    // di sini cuma sisanya supaya tidak dobel.
    final history = _myRequests.where((r) => !r.awaitingFeedback).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'IT Request',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (final item in _awaitingFeedback) ...[
            ItRequestFeedbackBanner(
              item: item,
              onGiveFeedback: () => _giveFeedback(item),
            ),
            const SizedBox(height: 12),
          ],
          if (_canAddRequest)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _addRequest,
                icon: const Icon(Icons.add, size: 18),
                label: Text('Ajukan Request', style: AppTextStyles.buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selesaikan feedback di atas dulu untuk membuka '
                      'pengajuan baru.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.text,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 20, bottom: 10, left: 2),
            child: Text('Riwayat Saya', style: AppTextStyles.sectionTitle),
          ),
          for (var i = 0; i < history.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            ItRequestCard(item: history[i]),
          ],
        ],
      ),
    );
  }
}