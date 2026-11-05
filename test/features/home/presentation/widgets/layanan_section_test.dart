import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/theme/app_colors.dart';
import 'package:hris_mobile/features/home/domain/service_shortcut.dart';
import 'package:hris_mobile/features/home/presentation/widgets/layanan_section.dart';

void main() {
  tearDown(() => AppColors.setDark(false));

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LayananSection(
            services: [
              ServiceShortcut(
                icon: Icons.description_outlined,
                label: 'Record',
                subtitle: 'Documents & Archive',
                color: Colors.green,
                background: Colors.green.shade50,
                featured: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('kartu featured tidak overflow di mode terang', (tester) async {
    AppColors.setDark(false);
    await pumpSection(tester);
    expect(tester.takeException(), isNull);
  });

  // Konten kartu setinggi 147px dari 148px: border yang ikut memakan layout
  // (2px) membuatnya overflow 1px, jadi border harus digambar di atas konten.
  testWidgets('border kartu featured di mode gelap tidak memakan tinggi konten', (
    tester,
  ) async {
    AppColors.setDark(true);
    await pumpSection(tester);
    expect(tester.takeException(), isNull);
  });
}
