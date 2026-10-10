import 'package:flutter/material.dart';

/// Scalable illustration built from app-native shapes; no remote image dependency.
class AuthArtwork extends StatelessWidget {
  const AuthArtwork({super.key});
  static const green = Color(0xFF009B70);
  @override Widget build(BuildContext context) => ExcludeSemantics(child: Stack(alignment: Alignment.center, children: [
    Positioned(left: 0, top: 12, right: 0, bottom: 8, child: DecoratedBox(decoration: BoxDecoration(
      color: const Color(0xFFE6F3EC), borderRadius: BorderRadius.circular(65)))),
    Positioned(left: 8, top: 29, child: Transform.rotate(angle: -.25,
      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF83CBB2), size: 38))),
    Positioned(left: 39, top: 22, bottom: 14, width: 62, child: Container(
      padding: const EdgeInsets.fromLTRB(7, 9, 7, 8), decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFBDDACE), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x15005A3A), blurRadius: 12, offset: Offset(0, 5))]),
      child: Column(children: [
        Container(width: 18, height: 3, decoration: BoxDecoration(color: const Color(0xFFB3CDBF), borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 9), const Icon(Icons.person_rounded, size: 23, color: green), const SizedBox(height: 6),
        _line(), const SizedBox(height: 6), _line(), const SizedBox(height: 9),
        Container(height: 12, decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(3))),
      ]))),
    Positioned(right: 0, top: 6, child: Transform.rotate(angle: .18, child: Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 25)))),
    const Positioned(left: 12, bottom: 6, child: Icon(Icons.eco_rounded, color: green, size: 37)),
    const Positioned(right: 6, bottom: 8, child: Icon(Icons.check_circle_rounded, color: Color(0xFF68CDA7), size: 22)),
  ]));
  Widget _line() => Container(height: 5, decoration: BoxDecoration(color: const Color(0xFFD5EEE2), borderRadius: BorderRadius.circular(2)));
}
