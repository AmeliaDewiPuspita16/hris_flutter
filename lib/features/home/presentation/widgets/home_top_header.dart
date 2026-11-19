import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/header_background.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../shared/domain/role.dart';
import '../../../weather/domain/weather_forecast.dart';
import '../../../weather/presentation/widgets/weather_header_chip.dart';

/// Panel hijau di atas: avatar inisial, sapaan, jabatan, dan (bila ada)
/// chip cuaca di kanan.
///
/// Warnanya sengaja dibiarkan naik sampai ke balik status bar — karena itu
/// layar pemanggilnya tidak boleh membungkus bagian ini dengan SafeArea atas,
/// dan jarak amannya ditambahkan manual di sini.
class HomeTopHeader extends StatelessWidget {
  const HomeTopHeader({
    super.key,
    required this.role,
    this.user,
    this.weather,
    this.onWeatherTap,
  });

  final Role role;

  /// Pengguna yang sedang masuk. Null berarti belum ada sesi — tampilan
  /// jatuh kembali ke data demo milik [role].
  final AuthUser? user;

  /// Slot cuaca saat ini; null = chip cuaca tidak ditampilkan.
  final WeatherSlot? weather;
  final VoidCallback? onWeatherTap;

  @override
Widget build(BuildContext context) {
  final initials = user?.initials ?? role.initials;
  final greetingName = user?.firstName ?? role.firstName;
  final subtitle = user?.section ?? role.demoUserTitle;

  return HeaderBackground(
    child: Row(
      children: [
        UserAvatar(
          initials: initials,
          photoUrl: user?.photoUrl,
          radius: 22,
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          fontSize: 15,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $greetingName',
                style: AppTextStyles.h3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (weather != null) ...[
          const SizedBox(width: 10),
          WeatherHeaderChip(slot: weather!, onTap: onWeatherTap),
        ],
      ],
    ),
  );
}
}
