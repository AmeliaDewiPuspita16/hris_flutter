import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/tap_fade.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../shared/domain/role.dart';

/// Panel hijau di atas: avatar inisial, sapaan, jabatan, dan lonceng notifikasi.
///
/// Warnanya sengaja dibiarkan naik sampai ke balik status bar — karena itu
/// layar pemanggilnya tidak boleh membungkus bagian ini dengan SafeArea atas,
/// dan jarak amannya ditambahkan manual di sini.
class HomeTopHeader extends StatelessWidget {
  const HomeTopHeader({
    super.key,
    required this.role,
    this.user,
    this.onNotificationTap,
    this.unreadCount = 0,
  });

  final Role role;

  /// Pengguna yang sedang masuk. Null berarti belum ada sesi — tampilan
  /// jatuh kembali ke data demo milik [role].
  final AuthUser? user;

  final VoidCallback? onNotificationTap;

  /// Jumlah notifikasi belum dibaca — menentukan muncul tidaknya titik
  /// penanda di lonceng.
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    // API tidak mengirim jabatan; `section` adalah keterangan unit kerja
    // terdekat yang tersedia. Kalau itu pun kosong, pakai jabatan demo.
    final initials = user?.initials ?? role.initials;
    final greetingName = user?.firstName ?? role.firstName;
    final subtitle = user?.section ?? role.demoUserTitle;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
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
          _NotificationButton(
            onTap: onNotificationTap,
            hasUnread: unreadCount > 0,
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({this.onTap, this.hasUnread = false});

  final VoidCallback? onTap;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          // Titik penanda — hanya muncul kalau memang ada yang belum dibaca.
          if (hasUnread)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accentLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
