import 'package:flutter/material.dart';

/// The "Start Counting" button at the bottom of the home screen.
/// Used as the bottomNavigationBar, so it already uses a SafeArea.
class HomeStartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const HomeStartButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: const Text('Start Counting'),
        ),
      ),
    );
  }
}
