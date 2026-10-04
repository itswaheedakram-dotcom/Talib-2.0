class Institute {
  final String id;
  final String name;
  final String type;
  final String campus;
  final String province;
  final String city;
  final String sector;
  final String address;
  final String description;
  final String website;
  final String submissionMode;
  final String eligibility;
  final List<String> programs;
  final String contact;
  final String status;

  const Institute({
    required this.id,
    required this.name,
    required this.type,
    this.campus = '',
    this.province = '',
    required this.city,
    this.sector = 'Private',
    this.address = '',
    this.description = '',
    this.website = '',
    this.submissionMode = 'Online',
    this.eligibility = '',
    this.programs = const [],
    this.contact = '',
    this.status = 'approved',
  });

  Map<String, dynamic> toMap() => {
    'name': name, 'type': type, 'campus': campus, 'province': province,
    'city': city, 'sector': sector, 'address': address, 'description': description,
    'website': website, 'submissionMode': submissionMode, 'eligibility': eligibility,
    'programs': programs, 'contact': contact, 'status': status,
  };

  factory Institute.fromMap(String id, Map<String, dynamic> map) => Institute(
    id: id,
    name: (map['name'] ?? '').toString(),
    type: (map['type'] ?? 'universities').toString(),
    campus: (map['campus'] ?? '').toString(),
    province: (map['province'] ?? '').toString(),
    city: (map['city'] ?? '').toString(),
    sector: (map['sector'] ?? 'Private').toString(),
    address: (map['address'] ?? '').toString(),
    description: (map['description'] ?? '').toString(),
    website: (map['website'] ?? '').toString(),
    submissionMode: (map['submissionMode'] ?? 'Online').toString(),
    eligibility: (map['eligibility'] ?? '').toString(),
    programs: List<String>.from((map['programs'] ?? const []).map((e) => e.toString())),
    contact: (map['contact'] ?? '').toString(),
    status: (map['status'] ?? 'approved').toString(),
  );
}
