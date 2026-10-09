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
      );
}
