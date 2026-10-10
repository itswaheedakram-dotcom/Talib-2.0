import 'package:flutter/material.dart';
import '../../data/institute_score.dart';

class InstituteScoreField extends StatelessWidget {
  final TextEditingController controller;
  final String scale;
  final ValueChanged<String> onScaleChanged;
  final ValueChanged<String>? onChanged;
  final String label;
  const InstituteScoreField({
    super.key,
    required this.controller,
    required this.scale,
    required this.onScaleChanged,
    this.onChanged,
    this.label = 'Minimum score (optional)',
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      DropdownButtonFormField<String>(
        initialValue: InstituteScore.labels.containsKey(scale)
            ? scale
            : 'unspecified',
        decoration: const InputDecoration(labelText: 'Score scale'),
        items: InstituteScore.labels.entries
            .map(
              (entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onScaleChanged(value);
        },
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.school_outlined),
        ),
        validator: (value) => InstituteScore.validate(value ?? '', scale),
        onChanged: onChanged,
      ),
      const SizedBox(height: 12),
    ],
  );
}
