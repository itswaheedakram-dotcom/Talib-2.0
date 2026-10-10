/// Public User IDs; account relationships continue to use the permanent Auth UID.
abstract final class UsernameRules {
  static String normalize(String value) => value.trim().toLowerCase();
  static bool valid(String value) => RegExp(r'^[a-z][a-z0-9_]{2,23}$').hasMatch(value);
  static String fromName(String name) {
    var base = normalize(name).replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.isEmpty) base = 'student';
    if (!RegExp(r'^[a-z]').hasMatch(base)) base = 'student_$base';
    if (base.length < 3) base = '${base}_user';
    return base.length > 24 ? base.substring(0, 24) : base;
  }
  static String candidate(String name, int attempt) {
    final base = fromName(name);
    final suffix = attempt == 0 ? '' : '$attempt';
    final availableLength = 24 - suffix.length;
    return '${base.length > availableLength ? base.substring(0, availableLength) : base}$suffix';
  }
  /// claim must reserve the ID atomically with the profile write.
  static Future<void> assign(String name, Future<bool> Function(String) claim) async {
    for (var attempt = 0; attempt < 1000; attempt++) {
      if (await claim(candidate(name, attempt))) return;
    }
    throw StateError('Could not allocate a User ID. Please retry.');
  }
}
