import 'institute_program_requirements.dart';

class InstituteOpportunity {
  final String id;
  final String instituteId;

  /// One of: course, admission, scholarship.
  final String kind;
  final String title;
  final String academicYear;
  final String intake;
  final String status;
  final String openingDate;
  final String deadline;
  final String eligibility;
  final String feeDetails;
  final String coverage;
  final String deliveryMode;
  final String applicationUrl;
  final String description;
  final String provider;
  final String createdBy;

  /// Exact category/name keys, scoped by instituteId; never inferred by title.
  final List<String> programKeys;
  final Map<String, String> requirements;
  final Map<String, String> programDetails;
  final Map<String, Map<String, String>> programOverrides;

  const InstituteOpportunity({
    required this.id,
    required this.instituteId,
    required this.kind,
    required this.title,
    this.academicYear = '',
    this.intake = '',
    this.status = 'Not announced',
    this.openingDate = '',
    this.deadline = '',
    this.eligibility = '',
    this.feeDetails = '',
    this.coverage = '',
    this.deliveryMode = '',
    this.applicationUrl = '',
    this.description = '',
    this.provider = '',
    this.createdBy = '',
    this.programKeys = const [],
    this.requirements = const {},
    this.programDetails = const {},
    this.programOverrides = const {},
  });

  Map<String, dynamic> toMap() => {
    'instituteId': instituteId,
    'kind': kind,
    'title': title,
    'academicYear': academicYear,
    'intake': intake,
    'status': status,
    'openingDate': openingDate,
    'deadline': deadline,
    'eligibility': eligibility,
    'feeDetails': feeDetails,
    'coverage': coverage,
    'deliveryMode': deliveryMode,
    'applicationUrl': applicationUrl,
    'description': description,
    'provider': provider,
    'createdBy': createdBy,
    'programKeys': programKeys,
    'requirements': requirements,
    'programDetails': programDetails,
    'programOverrides': programOverrides,
  };

  factory InstituteOpportunity.fromMap(String id, Map<String, dynamic> map) =>
      InstituteOpportunity(
        id: id,
        instituteId: (map['instituteId'] ?? '').toString(),
        kind: (map['kind'] ?? 'course').toString(),
        title: (map['title'] ?? '').toString(),
        academicYear: (map['academicYear'] ?? '').toString(),
        intake: (map['intake'] ?? '').toString(),
        status: (map['status'] ?? 'Not announced').toString(),
        openingDate: (map['openingDate'] ?? '').toString(),
        deadline: (map['deadline'] ?? '').toString(),
        eligibility: (map['eligibility'] ?? '').toString(),
        feeDetails: (map['feeDetails'] ?? '').toString(),
        coverage: (map['coverage'] ?? '').toString(),
        deliveryMode: (map['deliveryMode'] ?? '').toString(),
        applicationUrl: (map['applicationUrl'] ?? '').toString(),
        description: (map['description'] ?? '').toString(),
        provider: (map['provider'] ?? '').toString(),
        createdBy: (map['createdBy'] ?? '').toString(),
        programKeys: map['programKeys'] is List
            ? (map['programKeys'] as List).whereType<String>().toSet().toList()
            : const [],
        requirements: InstituteProgramRequirements.read(map['requirements']),
        programDetails: InstituteProgramRequirements.read(
          map['programDetails'],
        ),
        programOverrides: map['programOverrides'] is Map
            ? {
                for (final entry in (map['programOverrides'] as Map).entries)
                  entry.key.toString(): InstituteProgramRequirements.read(
                    entry.value,
                  ),
              }
            : const {},
      );

  Map<String, String> requirementsFor(
    String key, [
    Map<String, String> baseline = const {},
  ]) => {
    ...baseline,
    for (final entry in requirements.entries)
      if (entry.value.trim().isNotEmpty) entry.key: entry.value,
    for (final entry
        in (programOverrides[key] ?? const <String, String>{}).entries)
      if (InstituteProgramRequirements.labels.containsKey(entry.key))
        entry.key: entry.value,
  };

  InstituteOpportunity forProgram(
    String key, [
    Map<String, String> baseline = const {},
  ]) {
    final override = programOverrides[key] ?? const <String, String>{};
    return InstituteOpportunity.fromMap('$id:$key', {
      ...toMap(),
      'programKeys': <String>[],
      'programOverrides': <String, dynamic>{},
      'requirements': requirementsFor(key, baseline),
      for (final field in [
        'openingDate',
        'deadline',
        'status',
        'applicationUrl',
        'eligibility',
      ])
        if (override.containsKey(field)) field: override[field],
    });
  }

  String statusAt([DateTime? now]) {
    final stated = status.trim().toLowerCase();
    if (!{'open', 'upcoming'}.contains(stated)) return status;
    final time = now ?? DateTime.now();
    final today = DateTime(time.year, time.month, time.day);
    final end = DateTime.tryParse(deadline);
    final start = DateTime.tryParse(openingDate);
    if (end != null && today.isAfter(end)) return 'Closed';
    if (start != null && today.isBefore(start)) return 'Upcoming';
    if (start != null && !today.isBefore(start)) return 'Open';
    return stated == 'open' ? 'Open' : 'Upcoming';
  }

  String get displayStatus {
    if (kind != 'admission' || programKeys.isEmpty) return statusAt();
    final statuses = programKeys
        .map((key) => forProgram(key).statusAt())
        .toSet();
    if (statuses.contains('Open')) return 'Open';
    if (statuses.contains('Upcoming')) return 'Upcoming';
    if (statuses.length == 1) return statuses.single;
    return 'No active admissions';
  }

  bool get hasActiveAdmissions =>
      kind == 'admission' &&
      (programKeys.isEmpty
          ? {'Open', 'Upcoming'}.contains(statusAt())
          : programKeys.any(
              (key) =>
                  {'Open', 'Upcoming'}.contains(forProgram(key).statusAt()),
            ));
}
