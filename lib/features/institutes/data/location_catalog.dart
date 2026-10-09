import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final List<Map<String, String>> _demoEntries = [];
  bool loading = false;
  String? error;
  bool _loaded = false;

  static const List<String> defaultCountries = [
    'Pakistan', 'United Arab Emirates', 'Saudi Arabia', 'Qatar', 'Oman',
    'Bahrain', 'Kuwait', 'United Kingdom', 'United States', 'Canada',
    'Australia', 'Malaysia', 'Turkey',
  ];

  bool get isDemoMode => ActiveProfileController.instance.isDemo || !FirebaseService.initialized;

  List<Map<String, String>> get entries => List.unmodifiable(
    (isDemoMode ? _demoEntries : _entries).map((entry) => Map<String, String>.unmodifiable(entry)),
  );

  Future<void> load({bool force = false}) async {
    if (isDemoMode) {
      _loaded = false;
      loading = false;
      error = null;
      notifyListeners();
      return;
    }
    if (_loaded && !force) return;

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
    final source = isDemoMode ? _demoEntries : _entries;
    final values = source.where((entry) {
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

  Future<bool> addEntry({
    required String name,
    required String type,
    required String parentName,
    required String country,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      error = 'Location name is required.';
      return false;
    }
    final normalizedType = type.trim().toLowerCase();
    if (!const {'country', 'region', 'district', 'city', 'area'}.contains(normalizedType)) {
      error = 'Unsupported location level.';
      return false;
    }
    final entry = <String, String>{
      'name': cleanName,
      'type': normalizedType,
      'parentName': parentName.trim(),
      'country': normalizedType == 'country' ? cleanName : country.trim(),
    };
    try {
      if (isDemoMode) {
        entry['id'] = 'demo-location-${DateTime.now().microsecondsSinceEpoch}';
        _demoEntries.add(entry);
      } else {
        if (FirebaseAuth.instance.currentUser == null) {
          error = 'Sign in is required to manage locations.';
          return false;
        }
        final ref = await FirebaseFirestore.instance.collection('locationCatalog').add({
          ...entry,
          'enabled': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        entry['id'] = ref.id;
        _entries.add(entry);
      }
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    try {
      if (isDemoMode) {
        _demoEntries.removeWhere((entry) => entry['id'] == id);
      } else {
        if (FirebaseAuth.instance.currentUser == null) {
          error = 'Sign in is required to manage locations.';
          return false;
        }
        await FirebaseFirestore.instance.collection('locationCatalog').doc(id).delete();
        _entries.removeWhere((entry) => entry['id'] == id);
      }
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    }
  }
}
