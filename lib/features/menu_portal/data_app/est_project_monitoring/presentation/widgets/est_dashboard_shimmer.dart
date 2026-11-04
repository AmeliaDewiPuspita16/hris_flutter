import 'package:flutter/material.dart';

import '../../../../../../core/widgets/app_shimmer.dart';

/// Kerangka loading dashboard: tiga kartu ringkasan lalu tiga kartu proyek.
class EstDashboardShimmer extends StatelessWidget {
  const EstDashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                3,
                (_) => const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ShimmerBox(height: 90, borderRadius: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const ShimmerBox(width: 150, height: 20),
            const SizedBox(height: 16),
            ...List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerBox(height: 160, borderRadius: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
