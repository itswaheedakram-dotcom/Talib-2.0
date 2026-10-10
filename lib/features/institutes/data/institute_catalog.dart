import '../../../core/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/active_profile_controller.dart';
import '../../../core/services/firebase_service.dart';

@immutable
class InstituteTypeOption {
  final String id;
  final String label;
  final String iconKey;
  final List<String> subcategories;
  final List<String> programSuggestions;
  final List<String> facilitySuggestions;
  final String programLabel;
  final String eligibilityLabel;
  final String featuredProgramLabel;
  final bool showMinimumScore;
  final bool enabled;
  final int sortOrder;

  const InstituteTypeOption({
    required this.id,
    required this.label,
    this.iconKey = 'school',
    this.subcategories = const [],
    this.programSuggestions = const [],
    this.facilitySuggestions = const [],
    this.programLabel = 'Programs / courses',
    this.eligibilityLabel = 'Eligibility criteria',
    this.featuredProgramLabel = 'Featured / next program',
    this.showMinimumScore = true,
    this.enabled = true,
    this.sortOrder = 100,
  });

  IconData get icon => switch (iconKey) {
    'college' => Icons.account_balance_rounded,
    'university' => Icons.castle_rounded,
    'academy' => Icons.menu_book_rounded,
    'technical' => Icons.build_circle_outlined,
    'medical' => Icons.medical_services_outlined,
    'religious' => Icons.menu_book_outlined,
    'training' => Icons.workspace_premium_outlined,
    _ => Icons.school_rounded,
  };

  factory InstituteTypeOption.fromMap(String id, Map<String, dynamic> data) {
    return InstituteTypeOption(
      id: id,
      label: (data['label'] ?? data[ProfileFields.name] ?? id).toString(),
      iconKey: (data['iconKey'] ?? 'school').toString(),
      subcategories: List<String>.from(
        (data['subcategories'] as List? ?? const []).map((value) => value.toString()),
      ),
      programSuggestions: List<String>.from(
        (data['programSuggestions'] as List? ?? const []).map((value) => value.toString()),
      ),
      facilitySuggestions: List<String>.from(
        (data['facilitySuggestions'] as List? ?? const []).map((value) => value.toString()),
      ),
      programLabel: (data['programLabel'] ?? InstituteCatalog._defaultProgramLabel(id)).toString(),
      eligibilityLabel: (data['eligibilityLabel'] ?? InstituteCatalog._defaultEligibilityLabel(id)).toString(),
      featuredProgramLabel: (data['featuredProgramLabel'] ?? InstituteCatalog._defaultFeaturedProgramLabel(id)).toString(),
      showMinimumScore: data['showMinimumScore'] is bool ? data['showMinimumScore'] as bool : InstituteCatalog._defaultShowMinimumScore(id),
      enabled: data['enabled'] != false,
      sortOrder: int.tryParse((data['sortOrder'] ?? 100).toString()) ?? 100,
    );
  }
}

/// One catalogue for all institute categories, subcategories and type labels.
/// Firestore documents under instituteTypes can extend or override defaults.
class InstituteCatalog extends ChangeNotifier {
  InstituteCatalog._();
  static final instance = InstituteCatalog._();

  static const List<InstituteTypeOption> _defaults = [
    InstituteTypeOption(
      id: 'schools',
      label: 'Schools',
      iconKey: 'school',
      sortOrder: 10,
      subcategories: ['Montessori / Early Years', 'Primary', 'Middle', 'High School (Matric)', 'Higher Secondary', 'O-Level', 'A-Level', 'Special Education'],
      programLabel: 'Classes / levels',
      eligibilityLabel: 'Age / admission requirements',
      featuredProgramLabel: 'Featured class / level',
      showMinimumScore: false,
    ),
    InstituteTypeOption(
      id: 'colleges',
      label: 'Colleges',
      iconKey: 'college',
      sortOrder: 20,
      subcategories: ['Intermediate College', 'Degree College', 'Commerce College', 'Science College', 'Medical College', 'Engineering College', 'Law College', 'Arts & Humanities College', 'Women’s College'],
      programLabel: 'Degrees / programs',
      eligibilityLabel: 'Admission eligibility / merit',
      featuredProgramLabel: 'Featured program',
      showMinimumScore: true,
    ),
    InstituteTypeOption(
      id: 'universities',
      label: 'Universities',
      iconKey: 'university',
      sortOrder: 30,
      subcategories: ['General', 'Engineering & Technology', 'Medical & Health Sciences', 'Business & Management', 'Arts & Design', 'Agriculture & Veterinary', 'Women’s University', 'Open & Distance Learning', 'Islamic University'],
      programLabel: 'Degrees / departments',
      eligibilityLabel: 'Admission eligibility / merit',
      featuredProgramLabel: 'Featured degree / department',
      showMinimumScore: true,
    ),
    InstituteTypeOption(
      id: 'academies',
      label: 'Academies & Coaching',
      iconKey: 'academy',
      sortOrder: 40,
      subcategories: ['Entry Test', 'MDCAT', 'ECAT', 'CSS / PMS', 'Tuition', 'Subject Coaching', 'Language Academy', 'Competitive Exams'],
      programLabel: 'Courses / preparation tracks',
      eligibilityLabel: 'Entry requirements',
      featuredProgramLabel: 'Featured course / preparation track',
      showMinimumScore: false,
    ),
    InstituteTypeOption(
      id: 'technical_vocational',
      label: 'Technical & Vocational Institutes',
      iconKey: 'technical',
      sortOrder: 50,
      subcategories: ['Technical Diploma', 'Vocational Training', 'Trade Skills', 'Polytechnic', 'Electrical', 'Mechanical / Auto', 'Civil Technology', 'IT & Computing'],
      programLabel: 'Diplomas / skills / trades',
      eligibilityLabel: 'Entry requirements',
      featuredProgramLabel: 'Featured diploma / skill',
      showMinimumScore: false,
    ),
    InstituteTypeOption(
      id: 'professional_training',
      label: 'Professional Training Centers',
      iconKey: 'training',
      sortOrder: 60,
      subcategories: ['IT & Programming', 'Game Development', 'Freelancing', 'Professional Certification', 'Languages', 'Digital Marketing', 'Graphic Design', 'Business Skills'],
      programLabel: 'Courses / certifications',
      eligibilityLabel: 'Entry requirements',
      featuredProgramLabel: 'Featured course / certification',
      showMinimumScore: false,
    ),
    InstituteTypeOption(
      id: 'medical_allied_health',
      label: 'Medical & Allied Health Institutes',
      iconKey: 'medical',
      sortOrder: 70,
      subcategories: ['Nursing', 'Pharmacy', 'Paramedical', 'Medical Lab', 'Allied Health', 'Dental Technology', 'Radiology', 'Physiotherapy'],
      programLabel: 'Degrees / diplomas / courses',
      eligibilityLabel: 'Admission eligibility / merit',
      featuredProgramLabel: 'Featured health program',
      showMinimumScore: true,
    ),
    InstituteTypeOption(
      id: 'madaris',
      label: 'Madaris & Religious Education',
      iconKey: 'religious',
      sortOrder: 80,
      subcategories: ['Hifz-ul-Quran', 'Nazra Quran', 'Tajweed & Qiraat', 'Dars-e-Nizami', 'Islamic Studies', 'Jamia / Dar-ul-Uloom', 'Girls’ Madrasa'],
      programLabel: 'Deeni courses / levels',
      eligibilityLabel: 'Admission requirements',
      featuredProgramLabel: 'Featured deeni course / level',
      showMinimumScore: false,
    ),
    InstituteTypeOption(
      id: 'special_education',
      label: 'Special Education & Learning Support',
      iconKey: 'school',
      sortOrder: 90,
      subcategories: ['Special Education School', 'Learning Support Center', 'Speech & Language Support', 'Inclusive Education'],
      programLabel: 'Learning programs / support services',
      eligibilityLabel: 'Assessment / admission requirements',
      featuredProgramLabel: 'Support service / learning program',
      showMinimumScore: false,
    ),
    InstituteTypeOption(
      id: 'research_institutes',
      label: 'Research & Educational Institutes',
      iconKey: 'university',
      sortOrder: 100,
      subcategories: ['Research Center', 'Educational Research', 'Science & Technology', 'Policy & Social Research'],
      programLabel: 'Research areas / programs',
      eligibilityLabel: 'Eligibility / participation requirements',
      featuredProgramLabel: 'Featured research area',
      showMinimumScore: false,
    ),
  ];

  static const List<String> sectors = [
    'Private', 'Government', 'Semi-government', 'Non-profit',
  ];
  static const List<String> submissionModes = [
    'Online', 'Physical', 'Online / Physical', 'Not applicable',
  ];
  static const List<String> admissionStatuses = [
    'Open', 'Upcoming', 'Closed', 'Not announced',
  ];

  final Map<String, InstituteTypeOption> _demoOverrides = {};
  List<InstituteTypeOption> _types = List.unmodifiable(_defaults);
  bool loading = false;
  String? error;

  List<InstituteTypeOption> get allTypes => List.unmodifiable(
    _types.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
  );

  List<InstituteTypeOption> get types => List.unmodifiable(
    _types.where((type) => type.enabled).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
  );

  InstituteTypeOption? byId(String id) {
    for (final type in _types) {
      if (type.id == id) return type;
    }
    return null;
  }

  String labelFor(String id) => byId(id)?.label ?? _fallbackLabel(id);
  IconData iconFor(String id) => byId(id)?.icon ?? Icons.account_balance_outlined;
  List<String> subcategoriesFor(String id) => byId(id)?.subcategories ?? const [];

  List<String> programSuggestionsFor(String id) {
    final configured = byId(id)?.programSuggestions ?? const <String>[];
    return configured.isNotEmpty ? configured : _defaultProgramSuggestions(id);
  }

  List<String> facilitySuggestionsFor(String id) {
    final configured = byId(id)?.facilitySuggestions ?? const <String>[];
    return configured.isNotEmpty ? configured : _defaultFacilitySuggestions(id);
  }

  Future<void> load() async {
    // Demo mode must never read or mutate the real catalogue.
    if (ActiveProfileController.instance.isDemo || !FirebaseService.initialized) {
      _types = List.unmodifiable({
        for (final type in _defaults) type.id: type,
        ..._demoOverrides,
      }.values);
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance.collection('instituteTypes').get();
      final merged = <String, InstituteTypeOption>{
        for (final type in _defaults) type.id: type,
      };
      for (final doc in snapshot.docs) {
        merged[doc.id] = InstituteTypeOption.fromMap(doc.id, doc.data());
      }
      _types = List.unmodifiable(merged.values);
    } catch (e) {
      error = e.toString();
      _types = List.unmodifiable(_defaults);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveType(InstituteTypeOption type) async {
    if (type.id.trim().isEmpty || type.label.trim().isEmpty) {
      throw ArgumentError('Category ID and display name are required.');
    }
    if (ActiveProfileController.instance.isDemo || !FirebaseService.initialized) {
      _demoOverrides[type.id] = type;
      _types = List.unmodifiable({
        for (final item in _defaults) item.id: item,
        ..._demoOverrides,
      }.values);
      notifyListeners();
      return;
    }
    await FirebaseFirestore.instance.collection('instituteTypes').doc(type.id).set({
      'label': type.label.trim(),
      'iconKey': type.iconKey,
      'subcategories': type.subcategories,
      'programSuggestions': type.programSuggestions,
      'facilitySuggestions': type.facilitySuggestions,
      'programLabel': type.programLabel,
      'eligibilityLabel': type.eligibilityLabel,
      'featuredProgramLabel': type.featuredProgramLabel,
      'showMinimumScore': type.showMinimumScore,
      'enabled': type.enabled,
      'sortOrder': type.sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await load();
  }

  static List<String> _defaultProgramSuggestions(String id) => switch (id) {
    'schools' => ['Montessori', 'Primary', 'Middle', 'Matric', 'O-Level', 'A-Level'],
    'colleges' => ['FA', 'FSc Pre-Medical', 'FSc Pre-Engineering', 'ICS', 'ICom', 'ADP', 'BS'],
    'universities' => ['Undergraduate', 'Graduate', 'PhD', 'Computer Science', 'Business', 'Engineering'],
    'academies' => ['Entry Test', 'MDCAT', 'ECAT', 'CSS / PMS', 'Tuition', 'Languages'],
    'technical_vocational' => ['IT & Programming', 'Electrical', 'Plumbing', 'Welding', 'Auto Mechanics'],
    'professional_training' => ['Freelancing', 'Digital Marketing', 'Graphic Design', 'Certification'],
    'medical_allied_health' => ['Nursing', 'Pharmacy', 'Medical Lab', 'Radiology', 'Physiotherapy'],
    'madaris' => ['Hifz-ul-Quran', 'Nazra Quran', 'Tajweed', 'Dars-e-Nizami', 'Islamic Studies'],
    'special_education' => ['Learning Support', 'Speech & Language', 'Inclusive Education'],
    'research_institutes' => ['Science & Technology', 'Educational Research', 'Policy Research'],
    _ => ['General Studies', 'Professional Course'],
  };

  static List<String> _defaultFacilitySuggestions(String id) => [
    'Library',
    'Computer Lab',
    'Science Lab',
    'Transport',
    'Hostel',
    'Sports',
    'Cafeteria',
    if (id == 'schools' || id == 'colleges') 'Playground',
    if (id == 'universities' || id == 'medical_allied_health') 'Research Lab',
    if (id == 'madaris') 'Residential Facility',
  ];

  static String _defaultProgramLabel(String id) {
    switch (id) {
      case 'schools': return 'Classes / levels';
      case 'colleges': return 'Degrees / programs';
      case 'universities': return 'Degrees / departments';
      case 'madaris': return 'Deeni courses / levels';
      case 'academies': return 'Courses / preparation tracks';
      case 'technical_vocational': return 'Diplomas / skills / trades';
      case 'professional_training': return 'Courses / certifications';
      case 'medical_allied_health': return 'Degrees / diplomas / courses';
      case 'special_education': return 'Learning programs / support services';
      case 'research_institutes': return 'Research areas / programs';
      default: return 'Programs / courses';
    }
  }

  static String _defaultEligibilityLabel(String id) => switch (id) {
    'schools' => 'Age / admission requirements',
    'colleges' || 'universities' || 'medical_allied_health' => 'Admission eligibility / merit',
    'madaris' => 'Admission requirements',
    'special_education' => 'Assessment / admission requirements',
    'research_institutes' => 'Eligibility / participation requirements',
    _ => 'Entry requirements',
  };

  static String _defaultFeaturedProgramLabel(String id) => switch (id) {
    'schools' => 'Featured class / level',
    'colleges' => 'Featured program',
    'universities' => 'Featured degree / department',
    'academies' => 'Featured course / preparation track',
    'technical_vocational' => 'Featured diploma / skill',
    'professional_training' => 'Featured course / certification',
    'medical_allied_health' => 'Featured health program',
    'madaris' => 'Featured deeni course / level',
    'special_education' => 'Support service / learning program',
    'research_institutes' => 'Featured research area',
    _ => 'Featured / next program',
  };

  static bool _defaultShowMinimumScore(String id) => const {
    'colleges', 'universities', 'medical_allied_health',
  }.contains(id);

  static String _fallbackLabel(String value) => value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
