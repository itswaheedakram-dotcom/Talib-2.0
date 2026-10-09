import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/active_profile_controller.dart';
import '../../../core/services/firebase_service.dart';
import '../../models/institute_opportunity.dart';

/// Keeps demo offerings completely separate from the real Firestore records.
class InstituteOpportunityRepository extends ChangeNotifier {
  InstituteOpportunityRepository._();
  static final instance = InstituteOpportunityRepository._();

  final Map<String, List<InstituteOpportunity>> _demoItems = {};
  final Map<String, List<InstituteOpportunity>> _realItems = {};
  bool loading = false;
  String? error;

  bool get isDemoMode =>
      ActiveProfileController.instance.isDemo || !FirebaseService.initialized;

  List<InstituteOpportunity> forInstitute(String instituteId) =>
      List.unmodifiable((isDemoMode ? _demoItems : _realItems)[instituteId] ?? const []);

  Future<void> load(String instituteId) async {
    error = null;
    if (isDemoMode) {
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(instituteId)
          .collection('opportunities')
          .get();
      _realItems[instituteId] = snapshot.docs
          .map((doc) => InstituteOpportunity.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.academicYear.compareTo(a.academicYear));
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<InstituteOpportunity?> add(InstituteOpportunity item) async {
    error = null;
    try {
      if (isDemoMode) {
        final created = InstituteOpportunity.fromMap(
          'demo-opportunity-${DateTime.now().microsecondsSinceEpoch}',
          item.toMap(),
        );
        (_demoItems[item.instituteId] ??= []).insert(0, created);
        notifyListeners();
        return created;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        error = 'Sign in is required to publish an institute update.';
        return null;
      }
      final data = item.toMap()..['createdBy'] = user.uid;
      final ref = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(item.instituteId)
          .collection('opportunities')
          .add(data);
      final created = InstituteOpportunity.fromMap(ref.id, data);
      (_realItems[item.instituteId] ??= []).insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> update(InstituteOpportunity item) async {
    error = null;
    try {
      if (isDemoMode) {
        final items = _demoItems[item.instituteId] ?? [];
        final index = items.indexWhere((entry) => entry.id == item.id);
        if (index < 0) return false;
        items[index] = item;
        notifyListeners();
        return true;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        error = 'Sign in is required to update this listing.';
        return false;
      }
      final data = item.toMap()..remove('createdBy');
      await FirebaseFirestore.instance
          .collection('institutes')
          .doc(item.instituteId)
          .collection('opportunities')
          .doc(item.id)
          .update(data);
      final items = _realItems[item.instituteId] ?? [];
      final index = items.indexWhere((entry) => entry.id == item.id);
      if (index >= 0) items[index] = item;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(InstituteOpportunity item) async {
    error = null;
    try {
      if (isDemoMode) {
        _demoItems[item.instituteId]?.removeWhere((entry) => entry.id == item.id);
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          error = 'Sign in is required to remove this listing.';
          return false;
        }
        await FirebaseFirestore.instance
            .collection('institutes')
            .doc(item.instituteId)
            .collection('opportunities')
            .doc(item.id)
            .delete();
        _realItems[item.instituteId]?.removeWhere((entry) => entry.id == item.id);
      }
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
