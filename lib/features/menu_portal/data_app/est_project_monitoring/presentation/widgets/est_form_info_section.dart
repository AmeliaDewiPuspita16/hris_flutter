import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'est_form_fields.dart';
import 'est_form_section.dart';

/// Seksi "Informasi Proyek": nama, lokasi, titik peta, dan budget jam.
class EstFormInfoSection extends StatelessWidget {
  const EstFormInfoSection({
    super.key,
    required this.nameController,
    required this.locationController,
    required this.budgetHoursController,
    required this.latitude,
    required this.longitude,
    required this.onOpenMap,
  });

  final TextEditingController nameController;
  final TextEditingController locationController;
  final TextEditingController budgetHoursController;
  final double? latitude;
  final double? longitude;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return EstFormSection(
      title: 'Informasi Proyek',
      icon: Icons.domain_outlined,
      children: [
        EstFormTextField(
          controller: nameController,
          label: 'Nama Proyek',
          hint: 'Contoh: Sunrise Tower Construction',
          icon: Icons.drive_file_rename_outline,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Nama proyek wajib diisi';
            return null;
          },
        ),
        const SizedBox(height: 14),
        EstFormTextField(
          controller: locationController,
          label: 'Lokasi Proyek',
          hint: 'Contoh: Jl. Sudirman No. 1, Jakarta Selatan',
          icon: Icons.location_on_outlined,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Lokasi wajib diisi';
            return null;
          },
        ),
        const SizedBox(height: 10),
        EstFormMapButton(
          latitude: latitude,
          longitude: longitude,
          onTap: onOpenMap,
        ),
        const SizedBox(height: 14),
        EstFormTextField(
          controller: budgetHoursController,
          label: 'Budget Jam Kerja',
          hint: 'Contoh: 5000',
          icon: Icons.schedule_outlined,
          suffix: 'jam',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.isEmpty) return 'Budget jam wajib diisi';
            if (int.tryParse(v) == null || int.parse(v) <= 0) {
              return 'Budget jam tidak valid';
            }
            return null;
          },
        ),
      ],
    );
  }
}
