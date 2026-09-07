import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../shared/domain/role.dart';
import '../../domain/leave_type.dart';

enum _SubmitTab { ringkasan, ajukan, status }

enum _DurationType { full, half, hourly }

enum _StatusFilter { semua, menunggu, disetujui, ditolak }

class _SaldoCard {
  const _SaldoCard(this.label, this.used, this.total, this.unit, this.color, this.bg);
  final String label;
  final num used;
  final num? total;
  final String unit;
  final Color color;
  final Color bg;
}

class _HistoryItem {
  const _HistoryItem(this.type, this.typeColor, this.typeBg, this.date, this.status, this.note);
  final String type;
  final Color typeColor;
  final Color typeBg;
  final String date;
  final AppStatus status;
  final String note;
}

/// Padanan `function PengajuanScreen({ role })` di App.tsx.
class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({super.key, required this.role});

  final Role role;

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  _SubmitTab _tab = _SubmitTab.ringkasan;
  late LeaveType _leaveType;
  LeaveCategory _izinCategory = LeaveCategory.mcSakit;
  _DurationType _durationType = _DurationType.full;
  bool _submitted = false;
  _StatusFilter _statusFilter = _StatusFilter.semua;
  String _typeFilter = 'semua';

  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController(text: '09:00');
  final _endTimeCtrl = TextEditingController(text: '12:00');
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _leaveType = LeaveType.cutiTahunan;
  }

  @override
  void dispose() {
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _dateCtrl.dispose();
    _reasonCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  List<_SaldoCard> get _saldoCards {
    final showLembur = LeaveTypeX.showPersonalLembur(widget.role);
    return [
      const _SaldoCard('Cuti Tahunan', 4, 12, 'Hari', AppColors.primaryMid, AppColors.primaryLight),
      const _SaldoCard('Cuti Sakit', 0, null, 'Hari', AppColors.rejected, AppColors.rejectedBg),
      const _SaldoCard('Izin', 2, 6, 'Hari', AppColors.pending, AppColors.pendingBg),
      if (showLembur)
        const _SaldoCard('Lembur', 14.5, null, 'Jam', Color(0xFF6B46C1), Color(0xFFFAF5FF))
      else
        const _SaldoCard('Cuti Pengganti', 2, 5, 'Hari', Color(0xFF2C7A7B), Color(0xFFE6FFFA)),
      const _SaldoCard('Cek Kesehatan', 0, 1, 'Kali', AppColors.presentMid, AppColors.presentBg),
    ];
  }

  static const _historyItems = [
    _HistoryItem('Cuti Tahunan', AppColors.primaryMid, AppColors.primaryLight, '17–19 Jul 2026', AppStatus.present, 'Disetujui oleh Dewi Kusuma'),
    _HistoryItem('Lembur', Color(0xFF6B46C1), Color(0xFFFAF5FF), '28 Agu 2026 · 18:30–20:45', AppStatus.pending, 'Menunggu persetujuan'),
    _HistoryItem('Cek Kesehatan', AppColors.presentMid, AppColors.presentBg, '10 Agu 2026', AppStatus.present, 'Disetujui'),
    _HistoryItem('Cuti Sakit', AppColors.rejected, AppColors.rejectedBg, '5–6 Agu 2026', AppStatus.rejected, 'Ditolak: Surat dokter tidak lengkap'),
    _HistoryItem('Izin', AppColors.pending, AppColors.pendingBg, '25 Jul 2026 · Setengah Hari', AppStatus.present, 'Disetujui'),
    _HistoryItem('Cuti Tahunan', AppColors.primaryMid, AppColors.primaryLight, '1–3 Jul 2026', AppStatus.present, 'Disetujui'),
  ];

  List<_HistoryItem> get _filteredHistory {
    return _historyItems.where((h) {
      if (_statusFilter == _StatusFilter.menunggu && h.status != AppStatus.pending) return false;
      if (_statusFilter == _StatusFilter.disetujui && h.status != AppStatus.present) return false;
      if (_statusFilter == _StatusFilter.ditolak && h.status != AppStatus.rejected) return false;
      if (_typeFilter != 'semua' && h.type != _typeFilter) return false;
      return true;
    }).toList();
  }

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
                _SubmitTab.ringkasan => _buildRingkasan(),
                _SubmitTab.ajukan => _buildAjukan(),
                _SubmitTab.status => _buildStatus(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Widget tabButton(_SubmitTab t, String label) {
      final active = _tab == t;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = t),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 2.5)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? AppColors.primary : AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
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

  // ── TAB: RINGKASAN ──────────────────────────────────────────────
  Widget _buildRingkasan() {
    final year = DateTime.now().year;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Saldo cuti & izin tahun $year', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          ..._saldoCards.map((s) {
            final sisa = s.total != null ? s.total! - s.used : s.used;
            final ratio = s.total != null ? (s.used / s.total!).clamp(0, 1).toDouble() : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(6)),
                                child: Text(s.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: s.color)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s.total != null
                                    ? 'Terpakai ${s.used} dari ${s.total} ${s.unit}'
                                    : 'Terkumulasi: ${s.used} ${s.unit}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$sisa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: s.color, height: 1)),
                            Text(s.total != null ? 'Tersisa' : 'Saldo', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    if (ratio != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(s.color),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── TAB: AJUKAN ──────────────────────────────────────────────────
  Widget _buildAjukan() {
    if (_submitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.presentBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.presentMid, width: 2),
                ),
                child: const Text('✅', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 16),
              const Text('Pengajuan Terkirim!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.present)),
              const SizedBox(height: 8),
              const Text('Mengarahkan ke halaman status...', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    final options = LeaveTypeX.optionsFor(widget.role);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('DETAIL PENGAJUAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.3)),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                AppDropdown<LeaveType>(
                  label: 'Jenis Pengajuan',
                  value: _leaveType,
                  required: true,
                  items: options.map((o) => (value: o, label: o.label)).toList(),
                  onChanged: (v) => setState(() => _leaveType = v),
                ),
                const SizedBox(height: 16),
                ..._buildDynamicFields(),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton(label: 'Kirim Pengajuan', variant: AppButtonVariant.green, onPressed: _handleSubmit),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    switch (_leaveType) {
      case LeaveType.cutiTahunan:
      case LeaveType.cutiPengganti:
        return [
          Row(
            children: [
              Expanded(child: AppTextField(label: 'Tanggal Mulai', controller: _startDateCtrl, hint: 'DD/MM/YYYY', required: true, icon: Icons.calendar_today_outlined)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'Tanggal Selesai', controller: _endDateCtrl, hint: 'DD/MM/YYYY', required: true, icon: Icons.calendar_today_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          _reasonField(hint: 'Contoh: Liburan keluarga...'),
        ];
      case LeaveType.cutiSakit:
        return [
          AppTextField(label: 'Tanggal Mulai Sakit', controller: _dateCtrl, hint: 'DD/MM/YYYY', required: true, icon: Icons.calendar_today_outlined),
          const SizedBox(height: 16),
          _reasonField(label: 'Keluhan', hint: 'Contoh: Demam tinggi...', maxLines: 2),
          const SizedBox(height: 16),
          _uploadField(label: 'Surat Dokter', required: true, defaultFile: 'surat_dokter.pdf', doneLabel: '· Siap diunggah'),
        ];
      case LeaveType.izin:
        return [
          AppDropdown<LeaveCategory>(
            label: 'Kategori Izin',
            value: _izinCategory,
            required: true,
            items: LeaveCategory.values.map((c) => (value: c, label: c.label)).toList(),
            onChanged: (v) => setState(() => _izinCategory = v),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Tanggal Izin', controller: _dateCtrl, hint: 'DD/MM/YYYY', required: true, icon: Icons.calendar_today_outlined),
          const SizedBox(height: 16),
          _durationSelector(),
          if (_durationType != _DurationType.full) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: AppTextField(label: 'Mulai', controller: _startTimeCtrl)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Selesai', controller: _endTimeCtrl)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _reasonField(hint: 'Contoh: Keperluan medis...'),
        ];
      case LeaveType.lembur:
        return [
          AppTextField(label: 'Tanggal Lembur', controller: _dateCtrl, hint: 'DD/MM/YYYY', required: true, icon: Icons.calendar_today_outlined),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: AppTextField(label: 'Waktu Mulai', controller: _startTimeCtrl)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'Waktu Selesai', controller: _endTimeCtrl)),
            ],
          ),
          const SizedBox(height: 16),
          _reasonField(label: 'Uraian Pekerjaan', hint: 'Contoh: Penyelesaian laporan Q2...'),
        ];
      case LeaveType.cekKesehatan:
        return [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              border: Border.all(color: AppColors.accentLight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '🩺 Jadwalkan pemeriksaan kesehatan tahunan. Surat dokter wajib diunggah setelah pemeriksaan.',
              style: TextStyle(fontSize: 12, color: Color(0xFF744210)),
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Tanggal Cek Kesehatan', controller: _dateCtrl, hint: 'DD/MM/YYYY', required: true, icon: Icons.calendar_today_outlined),
          const SizedBox(height: 16),
          _uploadField(label: 'Surat / Bukti Pemeriksaan', required: true, defaultFile: 'bukti_cek_kesehatan.pdf'),
        ];
    }
  }

  Widget _reasonField({String label = 'Alasan', required String hint, int maxLines = 3}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: _reasonCtrl,
          maxLines: maxLines,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryMid, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _durationSelector() {
    const options = [(_DurationType.full, 'Seharian'), (_DurationType.half, 'Setengah Hari'), (_DurationType.hourly, 'Per Jam')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Durasi', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Row(
          children: options.map((o) {
            final active = _durationType == o.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: o == options.last ? 0 : 8),
                child: InkWell(
                  onTap: () => setState(() => _durationType = o.$1),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1.5),
                    ),
                    child: Text(o.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textMuted)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _uploadField({required String label, bool required = false, required String defaultFile, String doneLabel = ''}) {
    final hasFile = _fileName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.label,
            children: [
              TextSpan(text: label),
              if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.rejected)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => setState(() => _fileName = hasFile ? null : defaultFile),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasFile ? AppColors.presentBg : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hasFile ? AppColors.presentMid : AppColors.border, width: 2),
            ),
            child: hasFile
                ? Text('📄 $_fileName $doneLabel', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.presentMid))
                : Column(
                    children: const [
                      Icon(Icons.upload_outlined, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text('Tap untuk unggah', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSub)),
                      SizedBox(height: 4),
                      Text('PDF, JPG, PNG · Maks. 5MB', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ── TAB: STATUS ──────────────────────────────────────────────────
  Widget _buildStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._StatusFilter.values.map((f) {
                  final active = _statusFilter == f;
                  final label = f.name[0].toUpperCase() + f.name.substring(1);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => setState(() => _statusFilter = f),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 1.5),
                        ),
                        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textMuted)),
                      ),
                    ),
                  );
                }),
                Container(width: 1, height: 20, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 6)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border, width: 1.5)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _typeFilter,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      items: [
                        const DropdownMenuItem(value: 'semua', child: Text('Semua Jenis')),
                        ...LeaveTypeX.optionsFor(widget.role).map((o) => DropdownMenuItem(
                              value: o.label.replaceFirst(RegExp(r'^[^\s]+\s'), ''),
                              child: Text(o.label),
                            )),
                      ],
                      onChanged: (v) => setState(() => _typeFilter = v ?? 'semua'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _filteredHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔍', style: TextStyle(fontSize: 36)),
                      SizedBox(height: 12),
                      Text('Tidak ada data ditemukan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _filteredHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final h = _filteredHistory[i];
                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: h.typeBg, borderRadius: BorderRadius.circular(6)),
                                child: Text(h.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: h.typeColor)),
                              ),
                              StatusBadge(status: h.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(h.date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                          const SizedBox(height: 3),
                          Text(
                            h.note,
                            style: TextStyle(
                              fontSize: 11,
                              color: h.status == AppStatus.rejected ? AppColors.rejected : AppColors.textMuted,
                              fontWeight: h.status == AppStatus.rejected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}