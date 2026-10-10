import 'package:flutter/material.dart';

/// Illustration shares the app's light/dark semantic palette.
class AuthArtwork extends StatelessWidget {
  const AuthArtwork({super.key});
  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final panel = theme.inputDecorationTheme.fillColor ?? colors.surface;
    final divider = theme.dividerTheme.color ?? colors.onSurface.withOpacity(.2);
    return ExcludeSemantics(child: Stack(alignment: Alignment.center, children: [
      Positioned(left: 0, top: 12, right: 0, bottom: 8, child: DecoratedBox(decoration: BoxDecoration(
        color: panel, borderRadius: BorderRadius.circular(65)))),
      Positioned(left: 8, top: 29, child: Transform.rotate(angle: -.25,
        child: Icon(Icons.menu_book_rounded, color: colors.primary.withOpacity(.65), size: 38))),
      Positioned(left: 39, top: 22, bottom: 14, width: 62, child: Container(
        padding: const EdgeInsets.fromLTRB(7, 9, 7, 8), decoration: BoxDecoration(color: colors.surface,
          borderRadius: BorderRadius.circular(13), border: Border.all(color: divider, width: 3),
          boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(.08), blurRadius: 12, offset: const Offset(0, 5))]),
        child: Column(children: [
          Container(width: 18, height: 3, decoration: BoxDecoration(color: divider, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 9), Icon(Icons.person_rounded, size: 23, color: colors.primary), const SizedBox(height: 6),
          _line(panel), const SizedBox(height: 6), _line(panel), const SizedBox(height: 9),
          Container(height: 12, decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(3))),
        ]))),
      Positioned(right: 0, top: 6, child: Transform.rotate(angle: .18, child: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.lock_outline_rounded, color: colors.onPrimary, size: 25)))),
      Positioned(left: 12, bottom: 6, child: Icon(Icons.eco_rounded, color: colors.primary, size: 37)),
      Positioned(right: 6, bottom: 8, child: Icon(Icons.check_circle_rounded, color: colors.secondary, size: 22)),
    ]));
  }
  Widget _line(Color color) => Container(height: 5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
}
