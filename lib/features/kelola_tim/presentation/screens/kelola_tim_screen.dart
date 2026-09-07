import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/team_member.dart';
import 'ajukan_untuk_karyawan_screen.dart';

// Padanan menu web "Manage Leave Request Department" — daftar karyawan
// dalam satu departemen, Admin/HOD bisa ajukan cuti/izin atas nama mereka.
class KelolaTimScreen extends StatefulWidget {
  const KelolaTimScreen({super.key});

  @override
  State<KelolaTimScreen> createState() => _KelolaTimScreenState();
}

class _KelolaTimScreenState extends State<KelolaTimScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TeamMember> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return TeamMember.dummyTeam;
    return TeamMember.dummyTeam.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Text('Kelola Tim', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 33),
                    child: Text('${TeamMember.dummyTeam.length} pegawai · Departemen IT & MEDIA ', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari nama karyawan...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.bg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text('Karyawan tidak ditemukan', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final m = _filtered[i];
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AjukanUntukKaryawanScreen(member: m)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                                child: Text(
                                  m.name.trim().isNotEmpty ? m.name.trim()[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryMid),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                                    const SizedBox(height: 2),
                                    Text('${m.position} · ${m.department}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${m.leaveRemaining.toStringAsFixed(m.leaveRemaining.truncateToDouble() == m.leaveRemaining ? 0 : 1)}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryMid)),
                                  const Text('sisa cuti', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}