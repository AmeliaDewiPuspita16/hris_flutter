import 'package:flutter/material.dart';

import '../../../../core/config/app_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/profile_ui.dart';

/// Halaman "About this app": identitas aplikasi, versi terpasang,
/// dan deskripsi aplikasi internal (dikembangkan Dept. ITM).
///
/// "Report a problem" dan "Privacy policy" sengaja belum ada — menunggu
/// kontak IT dan URL kebijakan privasinya ditetapkan.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _appName = 'BIIE Portal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: BackHeader(
        title: 'About this app',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: FutureBuilder<String>(
        future: AppInfo.versionLabel(),
        builder: (context, snapshot) {
          final version = snapshot.data;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            children: [
              _AppIdentity(name: _appName, version: version),
              const SizedBox(height: 28),
              const SectionLabel('ABOUT'),
              const SizedBox(height: 8),
              const _AboutCard(),
              const SizedBox(height: 40),
              Text(
                'Crafted with extra ❤️',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 2),
              Text(
                '© 2026 PT Bintan Inti Industrial Estate',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppIdentity extends StatelessWidget {
  const _AppIdentity({required this.name, required this.version});

  final String name;

  /// Null selama versi belum terbaca.
  final String? version;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/launcher/app_icon.png',
            width: 84,
            height: 84,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          version == null ? ' ' : 'Version $version',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Deskripsi aplikasi: portal internal karyawan, apa yang bisa dilakukan,
/// dan siapa yang mengembangkannya.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  static const _paragraphs = [
    'BIIE Portal is the internal employee app of PT Bintan Inti Industrial '
        'Estate. It brings daily HR tasks and internal work requests together '
        'in one place, so employees and supervisors can get things done '
        'quickly from their phone, wherever they are.',
    'Employees can view their monthly attendance log recorded from the '
        'office fingerprint machines, submit leave, and send requests to '
        'other departments, such as IT support, EST work orders, '
        'procurement, company vehicles, and HSE work permits. Every request '
        'can be tracked from submission to completion.',
    'Supervisors and approvers receive real-time notifications and can '
        'review and approve requests directly from the app, helping work '
        'move faster with less paperwork and a clear record of every step.',
  ];

  @override
  Widget build(BuildContext context) {
    final body = AppTextStyles.body.copyWith(
      fontSize: 13.5,
      height: 1.55,
      color: AppColors.textMid,
    );

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.presentBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 13, color: AppColors.primaryText),
                const SizedBox(width: 5),
                Text(
                  'Internal use only',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final (i, paragraph) in _paragraphs.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            Text(paragraph, style: body),
          ],
          Divider(height: 20, color: AppColors.border),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.code_rounded,
                    size: 19, color: AppColors.primaryText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developed by',
                      style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                    ),
                    Text(
                      'ITM Department',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Accounts are provided by the company. For access or technical '
            'issues, please contact the ITM Department.',
            style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
