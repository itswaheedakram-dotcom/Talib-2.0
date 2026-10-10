class Institute {
  final String id;
  final String name;
  final String type;
  final String subcategory;
  final String ownerId;
  final String representativeId;
  final String createdBy;
  final String campus;
  final String country;
  final String province;
  final String district;
  final String city;
  final String area;
  final String board;
  final String town;
  final String sector;
  final String address;
  final String description;
  final String website;
  final String applicationUrl;
  final String submissionMode;
  final String eligibility;
  final List<String> programs;
  final String contact;
  final String status;
  final double minScore;
  final String nextProgram;
  final String admissionStatus;
  final String admissionDeadline;
  final String feeRange;
  final bool entryTestRequired;
  final String imageUrl;
  final List<String> facilities;

  const Institute({
    required this.id,
    required this.name,
    required this.type,
    this.subcategory = '',
    this.ownerId = '',
    this.representativeId = '',
    this.createdBy = '',
    this.campus = '',
    this.country = 'Pakistan',
    this.province = '',
    this.district = '',
    required this.city,
    this.area = '',
    this.board = '',
    this.town = '',
    this.sector = 'Private',
    this.address = '',
    this.description = '',
    this.website = '',
    this.applicationUrl = '',
    this.submissionMode = 'Online',
    this.eligibility = '',
    this.programs = const [],
    this.contact = '',
    this.status = 'approved',
    this.minScore = 0,
    this.nextProgram = '',
    this.admissionStatus = 'Open',
    this.admissionDeadline = '',
    this.feeRange = '',
    this.entryTestRequired = false,
    this.imageUrl = '',
    this.facilities = const [],
  });

  Map<String, dynamic> toMap() => {
    'name': name, 'type': type, 'subcategory': subcategory, 'ownerId': ownerId, 'representativeId': representativeId, 'createdBy': createdBy, 'campus': campus, 'country': country, 'province': province,
    'district': district, 'city': city, 'area': area, 'board': board, 'town': town, 'sector': sector, 'address': address, 'description': description,
    'website': website, 'applicationUrl': applicationUrl, 'submissionMode': submissionMode, 'eligibility': eligibility,
    'programs': programs, 'contact': contact, 'status': status, 'minScore': minScore, 'nextProgram': nextProgram,
    'admissionStatus': admissionStatus, 'admissionDeadline': admissionDeadline, 'feeRange': feeRange, 'entryTestRequired': entryTestRequired,
    'imageUrl': imageUrl, 'facilities': facilities,
  };

  /// Reads list fields written by both the current form and older records.
  /// Legacy documents may contain a comma-separated string instead of an array.
  static List<String> _readStringList(dynamic value) {
    if (value == null) return const <String>[];
    final Iterable<dynamic> values;
    if (value is Iterable) {
      values = value;
    } else if (value is String) {
      values = value.split(RegExp(r'[,;\\n]'));
    } else {
      values = <dynamic>[value];
    }
    return values
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  factory Institute.fromMap(String id, Map<String, dynamic> map) => Institute(
    id: id,
    name: (map['name'] ?? '').toString(),
    type: (map['type'] ?? 'universities').toString(),
    subcategory: (map['subcategory'] ?? '').toString(),
    ownerId: (map['ownerId'] ?? '').toString(),
    representativeId: (map['representativeId'] ?? '').toString(),
    createdBy: (map['createdBy'] ?? '').toString(),
    campus: (map['campus'] ?? '').toString(),
    country: (map['country'] ?? 'Pakistan').toString(),
    province: (map['province'] ?? map['region'] ?? '').toString(),
    district: (map['district'] ?? '').toString(),
    city: (map['city'] ?? '').toString(),
    area: (map['area'] ?? map['locality'] ?? '').toString(),
    board: (map['board'] ?? map['educationBoard'] ?? '').toString(),
    town: (map['town'] ?? '').toString(),
    sector: (map['sector'] ?? 'Private').toString(),
    address: (map['address'] ?? '').toString(),
    description: (map['description'] ?? '').toString(),
    website: (map['website'] ?? '').toString(),
    applicationUrl: (map['applicationUrl'] ?? '').toString(),
    submissionMode: (map['submissionMode'] ?? 'Online').toString(),
    eligibility: (map['eligibility'] ?? '').toString(),
    programs: _readStringList(map['programs']),
    contact: (map['contact'] ?? '').toString(),
    status: (map['status'] ?? 'approved').toString(),
    minScore: double.tryParse((map['minScore'] ?? 0).toString()) ?? 0,
    nextProgram: (map['nextProgram'] ?? '').toString(),
    admissionStatus: (map['admissionStatus'] ?? 'Open').toString(),
    admissionDeadline: (map['admissionDeadline'] ?? '').toString(),
    feeRange: (map['feeRange'] ?? '').toString(),
    entryTestRequired: map['entryTestRequired'] == true,
    imageUrl: (map['imageUrl'] ?? '').toString(),
    facilities: _readStringList(map['facilities']),
  );
}
