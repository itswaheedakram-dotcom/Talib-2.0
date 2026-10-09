import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../data/institute_image_service.dart';
import 'institute_image_preview.dart';

/// Reusable image picker, uploader, URL field and preview for institute forms.
class InstituteImageField extends StatefulWidget {
  final TextEditingController controller;
  final IconData fallbackIcon;
  final String label;
  final double height;

  const InstituteImageField({
    super.key,
    required this.controller,
    required this.fallbackIcon,
    required this.label,
    this.height = 150,
  });

  @override
  State<InstituteImageField> createState() => _InstituteImageFieldState();
}

class _InstituteImageFieldState extends State<InstituteImageField> {
  bool _uploading = false;

  Future<void> _chooseImage() async {
    setState(() => _uploading = true);
    try {
      final source = await InstituteImageService.instance.pickAndUpload();
      if (source != null && mounted) {
        widget.controller.text = source;
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select/upload image: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      InstituteImagePreview(
        source: widget.controller.text,
        fallbackIcon: widget.fallbackIcon,
        label: widget.label,
        height: widget.height,
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _uploading ? null : _chooseImage,
        icon: _uploading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.photo_library_outlined),
        label: Text(_uploading ? 'Uploading image...' : 'Choose image from gallery'),
      ),
      TextFormField(
        controller: widget.controller,
        onChanged: (_) => setState(() {}),
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: 'Or paste an image URL',
          prefixIcon: Icon(Icons.image_outlined),
        ),
      ),
      const SizedBox(height: 12),
      const Text('Demo images stay on this device; real images are uploaded to your Firebase Storage account.',
          style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
    ],
  );
}
