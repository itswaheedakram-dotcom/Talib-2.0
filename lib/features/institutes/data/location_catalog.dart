import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/active_profile_controller.dart';
import '../../../core/services/firebase_service.dart';

/// Updateable, country-neutral location suggestions.
///
/// Real location documents live in the Firestore `locationCatalog` collection:
/// { name, type, parentName, country, enabled }. Supported types are country,
/// region, district, city and area. Parent names are matched case-insensitively.
/// Users can still type a location if the maintained catalogue has no match.
class LocationCatalog extends ChangeNotifier {
  LocationCatalog._();
  static final instance = LocationCatalog._();

  List<Map<String, String>> _entries = [];
  bool loading = false;
  String? error;
  bool _loaded = false;

  static const List<String> defaultCountries = [
    'Pakistan', 'United Arab Emirates', 'Saudi Arabia', 'Qatar', 'Oman',
    'Bahrain', 'Kuwait', 'United Kingdom', 'United States', 'Canada',
    'Australia', 'Malaysia', 'Turkey',
  ];

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    if (ActiveProfileController.instance.isDemo || !FirebaseService.initialized) {
      _entries = [];
      _loaded = true;
      loading = false;
      error = null;
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('locationCatalog')
          .where('enabled', isEqualTo: true)
          .get();
      _entries = snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, String>{
          'id': doc.id,
          'name': (data['name'] ?? '').toString().trim(),
          'type': (data['type'] ?? '').toString().trim().toLowerCase(),
          'parentName': (data['parentName'] ?? '').toString().trim(),
          'country': (data['country'] ?? '').toString().trim(),
        };
      }).where((entry) => entry['name']!.isNotEmpty && entry['type']!.isNotEmpty).toList();
      _loaded = true;
    } catch (e) {
      error = e.toString();
      _entries = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<String> options({
    required String type,
    String parentName = '',
    String country = '',
  }) {
    final normalizedParent = parentName.trim().toLowerCase();
    final normalizedCountry = country.trim().toLowerCase();
    final values = _entries.where((entry) {
      if (entry['type'] != type.toLowerCase()) return false;
      if (normalizedParent.isNotEmpty &&
          entry['parentName']!.toLowerCase() != normalizedParent) return false;
      if (normalizedCountry.isNotEmpty &&
          entry['country']!.toLowerCase() != normalizedCountry) return false;
      return true;
    }).map((entry) => entry['name']!).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return List.unmodifiable(values);
  }

  bool get hasRemoteEntries => _entries.isNotEmpty;
}
