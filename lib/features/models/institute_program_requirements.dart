/// Shared schema for permanent program information and intake eligibility.
/// Sparse overrides inherit missing fields; an explicit empty value clears one.
class InstituteProgramRequirements {
  static const labels = <String, String>{
    'qualification': 'Previous qualification / education years',
    'scoreScale': 'Academic score scale',
    'minScore': 'Minimum marks / CGPA',
    'subjects': 'Required subjects / relevant disciplines',
    'testName': 'Entry test / exemption',
    'testScore': 'Minimum test score / scale',
    'testValidity': 'Test validity',
    'testDate': 'Test date',
    'interview': 'Interview requirements / date',
    'research': 'Research proposal / supervisor requirements',
    'experience': 'Experience requirements',
    'restrictions': 'Age / domicile / quota requirements',
    'documents': 'Required documents',
    'applicationFee': 'Application fee',
    'closingMerit': 'Previous closing merit (reference only)',
    'notes': 'Additional requirements',
  };
  static const metadataLabels = <String, String>{
    'duration': 'Duration / semesters',
    'campus': 'Campus',
    'studyMode': 'Study mode / shift',
    'tuitionFee': 'Tuition fee / frequency',
  };
  static const scales = ['Not specified', 'Percentage', 'CGPA / 4', 'CGPA / 5'];

  static String key(String group, String name) =>
      '${Uri.encodeComponent(group.trim())}/${Uri.encodeComponent(name.trim())}';
  static String name(String key) => Uri.decodeComponent(key.split('/').last);
  static String group(String key) => Uri.decodeComponent(key.split('/').first);
  static Map<String, String> read(dynamic value) => value is Map
      ? {
          for (final entry in value.entries)
            entry.key.toString(): entry.value?.toString() ?? '',
        }
      : {};
  static String? validate(Map<String, String> values) {
    final raw = values['minScore']?.trim() ?? '';
    if (raw.isEmpty) return null;
    final scale = values['scoreScale'];
    final max = switch (scale) {
      'Percentage' => 100.0,
      'CGPA / 4' => 4.0,
      'CGPA / 5' => 5.0,
      _ => null,
    };
    if (max == null) return 'Choose a score scale for minimum marks / CGPA.';
    final score = double.tryParse(raw);
    if (score == null || !score.isFinite || score < 0 || score > max)
      return 'Minimum score must be between 0 and $max.';
    return null;
  }
}
