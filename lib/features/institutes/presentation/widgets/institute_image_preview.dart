import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class InstituteImagePreview extends StatelessWidget {
  final String source;
  final IconData fallbackIcon;
  final String label;
  final double height;

  const InstituteImagePreview({
    super.key,
    required this.source,
    required this.fallbackIcon,
    required this.label,
    this.height = 170,
  });

  Widget _fallback() => Container(
    height: height,
    width: double.infinity,
    color: AppColors.softGreen,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(fallbackIcon, size: 58, color: AppColors.primaryGreen),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w600)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final value = source.trim();
    if (value.isEmpty) {
      return ClipRRect(borderRadius: BorderRadius.circular(14), child: _fallback());
    }
    final uri = Uri.tryParse(value);
    final isNetwork = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final image = isNetwork
        ? Image.network(value, height: height, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback())
        : Image.file(File(value), height: height, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback());
    return ClipRRect(borderRadius: BorderRadius.circular(14), child: image);
  }
}
