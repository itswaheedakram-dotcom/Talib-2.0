import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/demo_data_service.dart';
import '../../models/institute_opportunity.dart';
import '../../models/institute_program_requirements.dart';
import 'institute_repository.dart';
import 'institute_access.dart';

/// Keeps demo offerings completely separate from the real Firestore records.
class InstituteOpportunityRepository extends ChangeNotifier {
  InstituteOpportunityRepository._() {
    _seedDemoAdmissions();
  }

  String _dateOffset(int days) {
    final date = DateTime.now().add(Duration(days: days));
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Clearly marked demo fixtures make the News Feed testable without
  /// writing fake admissions into Firebase. Replace these with verified
  /// institute announcements before using the app with real applicants.
  void _seedDemoAdmissions() {
    final opened = _dateOffset(-14);
    final deadline = _dateOffset(30);
    final upcomingOpening = _dateOffset(45);
    final upcomingDeadline = _dateOffset(75);
    _demoItems.addAll({
      'university-31': [
        InstituteOpportunity(
          id: 'demo-admission-arid-open',
          instituteId: 'university-31',
          kind: 'admission',
          title: 'Undergraduate Admissions (Demo)',
          programKeys: [for (final name in ['BS Computer Science (Demo)', 'BS Education (Demo)', 'BS English (Demo)'])
            InstituteProgramRequirements.key('Undergraduate', name)],
          requirements: const {'qualification': 'Intermediate or equivalent (Demo)',
            'scoreScale': 'Percentage', 'minScore': '50', 'documents': 'Academic certificates, identity document and photograph (Demo)'},
          programOverrides: {InstituteProgramRequirements.key('Undergraduate', 'BS Computer Science (Demo)'):
            {'subjects': 'Mathematics or institute-approved equivalent (Demo)'}},
          academicYear: DateTime.now().year.toString(),
          intake: 'Fall intake',
          status: 'Open',
          openingDate: opened,
          deadline: deadline,
          description: 'Demo testing record only. Confirm dates with the institute before applying.',
        ),
      ],
      'university-2': [
        InstituteOpportunity(
          id: 'demo-admission-iub-open',
          instituteId: 'university-2',
          kind: 'admission',
          title: 'Undergraduate Admissions (Demo)',
          programKeys: [for (final name in ['BS Computer Science (Demo)', 'BS Education (Demo)', 'BS English (Demo)'])
            InstituteProgramRequirements.key('Undergraduate', name)],
          requirements: const {'qualification': 'Intermediate or equivalent (Demo)',
            'scoreScale': 'Percentage', 'minScore': '50', 'documents': 'Academic certificates, identity document and photograph (Demo)'},
          programOverrides: {InstituteProgramRequirements.key('Undergraduate', 'BS Computer Science (Demo)'):
            {'subjects': 'Mathematics or institute-approved equivalent (Demo)'}},
          academicYear: DateTime.now().year.toString(),
          intake: 'Current intake',
          status: 'Open',
          openingDate: opened,
          deadline: deadline,
          description: 'Demo testing record only. Confirm dates with the institute before applying.',
        ),
      ],
      'university-3': [
        InstituteOpportunity(
          id: 'demo-admission-uet-upcoming',
          instituteId: 'university-3',
          kind: 'admission',
          title: 'Engineering Admissions (Demo)',
          academicYear: (DateTime.now().year + 1).toString(),
          intake: 'Next intake',
          status: 'Upcoming',
          openingDate: upcomingOpening,
          deadline: upcomingDeadline,
          description: 'Demo testing record only. Dates are placeholders, not an official announcement.',
        ),
      ],
    });
    // Permanent sample information is confined to built-in demo universities.
    for (final id in ['university-2', 'university-31']) {
      final groups = <String, List<String>>{
        'Undergraduate': ['BS Computer Science (Demo)', 'BS Education (Demo)', 'BS English (Demo)'],
        'Graduate': ['MS Education (Demo)', 'MS Computer Science (Demo)'],
        'PhD': ['PhD Education (Demo)'],
      };
      for (final group in groups.entries) {
        for (final name in group.value) {
          final undergraduate = group.key == 'Undergraduate';
          final doctoral = group.key == 'PhD';
          _demoItems[id]!.add(InstituteOpportunity(
            id: 'demo-program-$id-${InstituteProgramRequirements.key(group.key, name)}',
            instituteId: id, kind: 'course', title: name,
            programKeys: [InstituteProgramRequirements.key(group.key, name)],
            programDetails: {'duration': undergraduate ? '4 years (Demo)' : doctoral ? '3–5 years (Demo)' : '2 years (Demo)', 'studyMode': 'On campus (Demo)'},
            requirements: {'qualification': undergraduate ? 'Intermediate or equivalent (Demo)' : doctoral ? 'MS / MPhil or equivalent (Demo)' : 'Relevant 16-year degree (Demo)',
              'scoreScale': undergraduate ? 'Percentage' : 'CGPA / 4',
              'minScore': undergraduate ? '50' : doctoral ? '3.0' : '2.5',
              if (doctoral) 'research': 'Research proposal and interview (Demo)'},
            description: 'Demo sample criteria only. Not an official admission policy. Confirm actual requirements with the institute.',
          ));
        }
      }
    }
  }
  static final instance = InstituteOpportunityRepository._();

  final Map<String, List<InstituteOpportunity>> _demoItems = {};
  final Map<String, List<InstituteOpportunity>> _realItems = {};
  bool loading = false;
  String? error;

  bool get isDemoMode =>
      InstituteAccess.isDemo;

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
          .where('published', isEqualTo: true)
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

  List<InstituteOpportunity> get allItems {
    final source = isDemoMode ? _demoItems : _realItems;
    return List.unmodifiable(source.values.expand((items) => items));
  }

  Future<void> loadAll() async {
    error = null;
    if (isDemoMode) {
      loading = false;
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('opportunities')
          .where('published', isEqualTo: true)
          .get();
      final grouped = <String, List<InstituteOpportunity>>{};
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final parentId = doc.reference.parent.parent?.id ?? '';
        if ((data['instituteId'] ?? '').toString().isEmpty) {
          data['instituteId'] = parentId;
        }
        final item = InstituteOpportunity.fromMap(doc.id, data);
        if (item.instituteId.isEmpty) continue;
        (grouped[item.instituteId] ??= []).add(item);
      }
      for (final items in grouped.values) {
        items.sort((a, b) {
          final aDate = DateTime.tryParse(a.openingDate) ?? DateTime(9999);
          final bDate = DateTime.tryParse(b.openingDate) ?? DateTime(9999);
          return aDate.compareTo(bDate);
        });
      }
      _realItems
        ..clear()
        ..addAll(grouped);
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
      final institute = await InstituteRepository.instance.loadById(item.instituteId);
      if (institute == null || !InstituteAccess.canManage(institute)) throw StateError('Institute management access required.');
      _validate(item, institute.programGroups);
      if (isDemoMode) {
        final created = InstituteOpportunity.fromMap(
          'demo-opportunity-${DateTime.now().microsecondsSinceEpoch}',
          item.toMap(),
        );
        (_demoItems[item.instituteId] ??= []).insert(0, created);
        await _notifyBookmarkedUsers(created);
        notifyListeners();
        return created;
      }
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        error = 'Sign in is required to publish an institute update.';
        return null;
      }
      final data = item.toMap()
        ..['createdBy'] = user.uid
        ..['published'] = true;
      final ref = await FirebaseFirestore.instance
          .collection('institutes')
          .doc(item.instituteId)
          .collection('opportunities')
          .add(data);
      final created = InstituteOpportunity.fromMap(ref.id, data);
      (_realItems[item.instituteId] ??= []).insert(0, created);
      await _notifyBookmarkedUsers(created);
      notifyListeners();
      return created;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Map<String, String> baselineFor(String instituteId, String key) {
    for (final item in forInstitute(instituteId)) {
      if (item.kind == 'course' && item.programKeys.contains(key)) return item.requirements;
    }
    return const {};
  }

  void _validate(InstituteOpportunity item, Map<String, List<String>> groups) {
    final keys = {for (final entry in groups.entries) for (final name in entry.value)
      InstituteProgramRequirements.key(entry.key, name)};
    if (item.programKeys.any((key) => !keys.contains(key))) throw StateError('Selected program is no longer offered.');
    if (item.kind == 'course' && item.programKeys.isNotEmpty) {
      if (item.programKeys.length != 1) throw StateError('Program details must link exactly one program.');
      if (forInstitute(item.instituteId).any((other) => other.kind == 'course' && other.id != item.id &&
          other.programKeys.any(item.programKeys.contains))) throw StateError('This program already has details. Edit the existing program.');
    }
    if (item.programOverrides.keys.any((key) => !item.programKeys.contains(key))) throw StateError('Overrides must belong to selected programs.');
    final commonError = InstituteProgramRequirements.validate(item.requirements);
    if (commonError != null) throw StateError(commonError);
    for (final key in item.programKeys.isEmpty ? [''] : item.programKeys) {
      final resolved = key.isEmpty ? item : item.forProgram(key, baselineFor(item.instituteId, key));
      final error = InstituteProgramRequirements.validate(resolved.requirements);
      if (error != null) throw StateError(error);
      final opening = DateTime.tryParse(resolved.openingDate);
      final deadline = DateTime.tryParse(resolved.deadline);
      if (opening != null && deadline != null && deadline.isBefore(opening)) throw StateError('Deadline cannot precede opening date.');
    }
  }

  Future<void> _notifyBookmarkedUsers(InstituteOpportunity item) async {
    final instituteName = InstituteRepository.instance.byId(item.instituteId)?.name ?? 'An institute you saved';
    final kindLabel = switch (item.kind) {
      'scholarship' => 'scholarship',
      'course' => 'program / course',
      _ => 'admission update',
    };
    final text = 'New $kindLabel: ${item.title} at $instituteName';
    try {
      if (isDemoMode) {
        for (final uid in DemoDataService.instance.usersWhoBookmarkedInstitute(item.instituteId)) {
          DemoDataService.instance.addNotification(uid, {
            'type': 'institute_update',
            'text': text,
            'instituteId': item.instituteId,
            'opportunityId': item.id,
            'createdAt': DateTime.now(),
            'read': false,
          });
        }
        return;
      }
      // Real notifications are generated by the trusted opportunity-created function.
      // Clients cannot read other users' private bookmark collections.
    } catch (_) {
      // Listing publication must not fail if notification delivery has a problem.
    }
  }

  Future<bool> update(InstituteOpportunity item) async {
    error = null;
    try {
      final institute = await InstituteRepository.instance.loadById(item.instituteId);
      if (institute == null || !InstituteAccess.canManage(institute)) throw StateError('Institute management access required.');
      _validate(item, institute.programGroups);
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
      final data = item.toMap()
        ..remove('createdBy')
        ..['published'] = true;
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
      final institute = await InstituteRepository.instance.loadById(item.instituteId);
      if (institute == null || !InstituteAccess.canManage(institute)) throw StateError('Institute management access required.');
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
