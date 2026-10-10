/// Percentage and CGPA scales must never be compared as raw interchangeable numbers.
abstract final class InstituteScore {
  static const labels = <String, String>{
    'unspecified': 'Scale not specified',
    'percentage': 'Percentage (0–100)',
    'cgpa4': 'CGPA (0–4)',
    'cgpa5': 'CGPA (0–5)',
  };
  static double? maximum(String scale) => switch (scale) {
    'percentage' => 100,
    'cgpa4' => 4,
    'cgpa5' => 5,
    _ => null,
  };
  static String? validate(String text, String scale) {
    if (text.trim().isEmpty) return null;
    final value = double.tryParse(text.trim());
    final max = maximum(scale);
    if (max == null) return 'Choose the score scale.';
    if (value == null || !value.isFinite || value < 0 || value > max)
      return 'Enter a score from 0 to $max.';
    return null;
  }

  static bool eligible({
    required double score,
    required String scale,
    required double minimum,
    required String minimumScale,
  }) =>
      validate(score.toString(), scale) == null &&
      (minimum == 0 ||
          (scale == minimumScale && minimum.isFinite && score >= minimum));
  static String display(double value, String scale) => switch (scale) {
    'percentage' => '$value%',
    'cgpa4' => '$value / 4 CGPA',
    'cgpa5' => '$value / 5 CGPA',
    _ => '$value (scale not specified)',
  };
}
