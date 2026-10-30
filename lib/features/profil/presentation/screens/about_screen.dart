import 'package:flutter/material.dart';

import '../../../../core/config/app_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/back_header.dart';
import '../../../../core/widgets/profile_ui.dart';

/// Halaman "About this app": identitas aplikasi, versi terpasang, dan
/// lisensi open-source.
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
              const SectionLabel('INFORMATION'),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const TintedIcon(Icons.description_outlined),
                  title: Text(
                    'Open-source licenses',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: _appName,
                    applicationVersion: version,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Crafted with extra ❤️ by IT Solution',
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
            'assets/images/m_logo.jpg',
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
