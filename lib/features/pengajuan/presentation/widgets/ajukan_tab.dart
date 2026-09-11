import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_text_field.dart';

import '../../../shared/domain/role.dart';
import '../../domain/leave_type.dart';

enum _DurationType {
  full,
  half,
  hourly,
}

class AjukanTab extends StatefulWidget {
  const AjukanTab({
    super.key,
    required this.role,
    required this.leaveType,
    required this.izinCategory,
    required this.submitted,
    required this.onLeaveTypeChanged,
    required this.onIzinCategoryChanged,
    required this.onSubmit,
  });

  final Role role;
  final LeaveType leaveType;
  final LeaveCategory izinCategory;
  final bool submitted;

  final ValueChanged<LeaveType> onLeaveTypeChanged;
  final ValueChanged<LeaveCategory> onIzinCategoryChanged;
  final VoidCallback onSubmit;

  @override
  State<AjukanTab> createState() => _AjukanTabState();
}

class _AjukanTabState extends State<AjukanTab> {
  _DurationType _durationType =
      _DurationType.full;

  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController(text: '09:00');
  final _endTimeCtrl = TextEditingController(text: '12:00');
  String? _fileName;

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

  @override
  Widget build(BuildContext context) {
    if (widget.submitted) {
      return _buildSubmitted();
    }

    final options =
        LeaveTypeX.optionsFor(widget.role);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'DETAIL PENGAJUAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 14),

                const Divider(
                  height: 1,
                  color: AppColors.border,
                ),

                const SizedBox(height: 16),

                AppDropdown<LeaveType>(
                  label: 'Jenis Pengajuan',
                  value: widget.leaveType,
                  required: true,
                  items: options
                      .map(
                        (o) => (
                          value: o,
                          label: o.label,
                        ),
                      )
                      .toList(),
                  onChanged:
                      widget.onLeaveTypeChanged,
                ),

                const SizedBox(height: 16),

                ..._buildDynamicFields(),
              ],
            ),
          ),

          const SizedBox(height: 18),

          AppButton(
            label: 'Kirim Pengajuan',
            variant: AppButtonVariant.green,
            onPressed: widget.onSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitted() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 40),
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
                border: Border.all(
                  color: AppColors.presentMid,
                  width: 2,
                ),
              ),
              child: const Text(
                '✅',
                style: TextStyle(fontSize: 36),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Pengajuan Terkirim!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.present,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Mengarahkan ke halaman status...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    switch (widget.leaveType) {
      case LeaveType.cutiTahunan:
      case LeaveType.cutiPengganti:
        return [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Tanggal Mulai',
                  controller: _startDateCtrl,
                  hint: 'DD/MM/YYYY',
                  required: true,
                  icon: Icons.calendar_today_outlined,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: AppTextField(
                  label: 'Tanggal Selesai',
                  controller: _endDateCtrl,
                  hint: 'DD/MM/YYYY',
                  required: true,
                  icon: Icons.calendar_today_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _reasonField(hint: 'Contoh: Liburan keluarga...'),
        ];

      case LeaveType.izin:
        return [
          AppDropdown<LeaveCategory>(
            label: 'Kategori Izin',
            value: widget.izinCategory,
            required: true,
            items: LeaveCategoryX.all
                .map(
                  (category) => (
                    value: category,
                    label: category.label,
                  ),
                )
                .toList(),
            onChanged: widget.onIzinCategoryChanged,
          ),

          const SizedBox(height: 16),

          AppTextField(
            label: 'Tanggal Izin',
            controller: _dateCtrl,
            hint: 'DD/MM/YYYY',
            required: true,
            icon: Icons.calendar_today_outlined,
          ),

          const SizedBox(height: 16),

          _durationSelector(),

          if (_durationType != _DurationType.full) ...[
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Mulai',
                    controller: _startTimeCtrl,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: AppTextField(
                    label: 'Selesai',
                    controller: _endTimeCtrl,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          _reasonField(hint: 'Contoh: Keperluan medis...'),
        ];

      case LeaveType.lembur:
        return [
          AppTextField(
            label: 'Tanggal Lembur',
            controller: _dateCtrl,
            hint: 'DD/MM/YYYY',
            required: true,
            icon: Icons.calendar_today_outlined,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Waktu Mulai',
                  controller: _startTimeCtrl,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: AppTextField(
                  label: 'Waktu Selesai',
                  controller: _endTimeCtrl,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _reasonField(
            label: 'Uraian Pekerjaan',
            hint:
                'Contoh: Penyelesaian laporan Q2...',
          ),
        ];

      case LeaveType.cekKesehatan:
        return [
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              border: Border.all(
                color: AppColors.accentLight,
              ),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Text(
              '🩺 Jadwalkan pemeriksaan kesehatan tahunan. Surat dokter wajib diunggah setelah pemeriksaan.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF744210),
              ),
            ),
          ),

          const SizedBox(height: 16),

          AppTextField(
            label: 'Tanggal Cek Kesehatan',
            controller: _dateCtrl,
            hint: 'DD/MM/YYYY',
            required: true,
            icon: Icons.calendar_today_outlined,
          ),

          const SizedBox(height: 16),

          _uploadField(
            label: 'Surat / Bukti Pemeriksaan',
            required: true,
            defaultFile:
                'bukti_cek_kesehatan.pdf',
          ),
        ];
    }
  }

  Widget _reasonField({
    String label = 'Alasan',
    required String hint,
    int maxLines = 3,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label,
        ),

        const SizedBox(height: 6),

        TextField(
          controller: _reasonCtrl,
          maxLines: maxLines,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1.5,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primaryMid,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _durationSelector() {
    const options = [
      (
        _DurationType.full,
        'Seharian',
      ),
      (
        _DurationType.half,
        'Setengah Hari',
      ),
      (
        _DurationType.hourly,
        'Per Jam',
      ),
    ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Durasi',
          style: AppTextStyles.label,
        ),

        const SizedBox(height: 8),

        Row(
          children: options.map((option) {
            final active =
                _durationType == option.$1;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right:
                      option == options.last
                          ? 0
                          : 8,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _durationType =
                          option.$1;
                    });
                  },
                  borderRadius:
                      BorderRadius.circular(9),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 9,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(9),
                      border: Border.all(
                        color: active
                            ? AppColors.primary
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      option.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                        color: active
                            ? Colors.white
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _uploadField({
    required String label,
    bool required = false,
    required String defaultFile,
  }) {
    final hasFile = _fileName != null;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.label,
            children: [
              TextSpan(text: label),

              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.rejected,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        InkWell(
          onTap: () {
            setState(() {
              _fileName =
                  hasFile ? null : defaultFile;
            });
          },
          borderRadius:
              BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hasFile
                  ? AppColors.presentBg
                  : const Color(0xFFFAFAFA),
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: hasFile
                    ? AppColors.presentMid
                    : AppColors.border,
                width: 2,
              ),
            ),
            child: hasFile
                ? Text(
                    '📄 $_fileName',
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          AppColors.presentMid,
                    ),
                  )
                : const Column(
                    children: [
                      Icon(
                        Icons.upload_outlined,
                        color:
                            AppColors.textMuted,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap untuk unggah',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppColors.textSub,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PDF, JPG, PNG · Maks. 5MB',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}