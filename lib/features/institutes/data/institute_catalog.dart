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
  final bool enabled;
  final int sortOrder;

  const InstituteTypeOption({
    required this.id,
    required this.label,
    this.iconKey = 'school',
    this.subcategories = const [],
    this.enabled = true,
    this.sortOrder = 100,
  });

  IconData get icon => switch (iconKey) {
    'college' => Icons.account_balance_rounded,
    'university' => Icons.castle_rounded,
    'academy' => Icons.menu_book_rounded,
    'technical' => Icons.build_circle_outlined,
    'medical' => Icons.medical_services_outlined,
    'religious' => Icons.mosque_outlined,
    'training' => Icons.workspace_premium_outlined,
    _ => Icons.school_rounded,
  };

  factory InstituteTypeOption.fromMap(String id, Map<String, dynamic> data) {
    return InstituteTypeOption(
      id: id,
      label: (data['label'] ?? data['name'] ?? id).toString(),
      iconKey: (data['iconKey'] ?? 'school').toString(),
      subcategories: List<String>.from(
        (data['subcategories'] as List? ?? const []).map((value) => value.toString()),
      ),
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
      subcategories: ['Early Years', 'Primary', 'Middle', 'Secondary', 'Higher Secondary', 'O-Level', 'A-Level'],
    ),
    InstituteTypeOption(
      id: 'colleges',
      label: 'Colleges',
      iconKey: 'college',
      sortOrder: 20,
      subcategories: ['Intermediate', 'Degree College', 'Commerce College', 'Government College', 'Private College'],
    ),
    InstituteTypeOption(
      id: 'universities',
      label: 'Universities',
      iconKey: 'university',
      sortOrder: 30,
      subcategories: ['General', 'Engineering', 'Medical', 'Business', 'Arts & Design', 'Agriculture'],
    ),
    InstituteTypeOption(
      id: 'academies',
      label: 'Academies & Coaching',
      iconKey: 'academy',
      sortOrder: 40,
      subcategories: ['Entry Test', 'MDCAT', 'ECAT', 'CSS / PMS', 'Tuition', 'Subject Coaching', 'Language Academy'],
    ),
    InstituteTypeOption(
      id: 'technical_vocational',
      label: 'Technical & Vocational Institutes',
      iconKey: 'technical',
      sortOrder: 50,
      subcategories: ['Technical Diploma', 'Vocational Training', 'Trade Skills', 'Polytechnic'],
    ),
    InstituteTypeOption(
      id: 'professional_training',
      label: 'Professional Training Centers',
      iconKey: 'training',
      sortOrder: 60,
      subcategories: ['IT & Programming', 'Game Development', 'Freelancing', 'Professional Certification', 'Languages'],
    ),
    InstituteTypeOption(
      id: 'medical_allied_health',
      label: 'Medical & Allied Health Institutes',
      iconKey: 'medical',
      sortOrder: 70,
      subcategories: ['Nursing', 'Pharmacy', 'Paramedical', 'Medical Lab', 'Allied Health'],
    ),
    InstituteTypeOption(
      id: 'madaris',
      label: 'Madaris & Religious Education',
      iconKey: 'religious',
      sortOrder: 80,
      subcategories: ['Madrasa', 'Quran Education', 'Islamic Studies'],
    ),
  ];

  List<InstituteTypeOption> _types = List.unmodifiable(_defaults);
  bool loading = false;
  String? error;

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

  Future<void> load() async {
    // Demo mode must never read or mutate the real catalogue.
    if (ActiveProfileController.instance.isDemo || !FirebaseService.initialized) {
      _types = List.unmodifiable(_defaults);
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

  static String _fallbackLabel(String value) => value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
