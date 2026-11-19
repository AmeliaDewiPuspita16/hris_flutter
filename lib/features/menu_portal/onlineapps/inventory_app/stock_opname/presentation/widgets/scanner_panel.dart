import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_text_styles.dart';

/// Camera preview + scan frame. Supports both linear barcodes and QR codes.
/// The controller lifecycle (start/stop) is managed by the screen using it.
class ScannerPanel extends StatelessWidget {
  final MobileScannerController controller;
  final ValueChanged<String> onCode;

  const ScannerPanel({
    super.key,
    required this.controller,
    required this.onCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.text,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final value = capture.barcodes.firstOrNull?.rawValue?.trim();
              if (value != null && value.isNotEmpty) onCode(value);
            },
            errorBuilder: (context, error) => _CameraError(error: error),
          ),
          const Center(child: _ScanFrame()),
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              children: [
                ValueListenableBuilder<MobileScannerState>(
                  valueListenable: controller,
                  builder: (context, state, _) => IconButton(
                    tooltip: 'Flashlight',
                    color: Colors.white,
                    icon: Icon(
                      state.torchState == TorchState.on
                          ? Icons.flash_on
                          : Icons.flash_off,
                    ),
                    onPressed: controller.toggleTorch,
                  ),
                ),
                IconButton(
                  tooltip: 'Switch camera',
                  color: Colors.white,
                  icon: const Icon(Icons.cameraswitch_outlined),
                  onPressed: controller.switchCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white70, width: 2),
            ),
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.rejected,
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;

  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: Colors.white70, size: 40),
            const SizedBox(height: 10),
            Text(
              denied
                  ? 'Camera permission denied. Enable it in your phone settings.'
                  : 'Unable to open the camera.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
