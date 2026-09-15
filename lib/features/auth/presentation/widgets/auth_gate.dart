import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../home/presentation/screens/beranda_screen.dart';
import '../../../shared/domain/role.dart';
import '../../../splash/presentation/screens/splash_screen.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../screens/login_screen.dart';

/// Memilih layar pembuka aplikasi berdasarkan status sesi.
///
/// Satu-satunya tempat yang memutuskan Splash / Login / Beranda, sehingga
/// login, logout, dan sesi kedaluwarsa semuanya lewat jalur yang sama dan
/// tidak ada layar yang perlu menavigasi sendiri.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.minimumSplashDuration = SplashScreen.displayDuration,
  });

  /// Splash tetap tampil selama ini walaupun status sesi sudah diketahui
  /// lebih cepat, supaya animasinya tidak berkedip sekilas lalu hilang.
  final Duration minimumSplashDuration;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _splashTimer;
  bool _splashFinished = false;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(widget.minimumSplashDuration, () {
      if (mounted) setState(() => _splashFinished = true);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (!_splashFinished || state.status == AuthStatus.unknown) {
          return const SplashScreen();
        }

        return switch (state.status) {
          // SEMENTARA: role UI masih dipatok sampai pemetaan role dari API
          // (gmo, it media, daily-worker, ...) ke enum Role diputuskan.
          AuthStatus.authenticated =>
            const BerandaScreen(role: Role.hrPublisher),
          _ => const LoginScreen(),
        };
      },
    );
  }
}
