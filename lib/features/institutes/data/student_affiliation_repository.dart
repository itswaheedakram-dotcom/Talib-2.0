import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/active_profile_controller.dart';
import '../../../core/services/demo_data_service.dart';
import '../../models/institute.dart';
import 'institute_access.dart';
import 'institute_repository.dart';

/// Student-selected institute is visible immediately; only the institute may
/// approve the affiliation and award the institute-specific badge.
class StudentAffiliationRepository extends ChangeNotifier {
  StudentAffiliationRepository._();
  static final instance = StudentAffiliationRepository._();
  final Map<String, Map<String, dynamic>> _demoProfiles = {};
  final Map<String, Map<String, Map<String, dynamic>>> _demoRequests = {};
  int _demoSequence = 0;

  String? get _uid => InstituteAccess.uid;

  Future<Map<String, dynamic>> profile(String uid) async {
    if (InstituteAccess.isDemo) {
      return Map<String, dynamic>.from(_demoProfiles[uid] ?? const {});
    }
    final data = (await FirebaseFirestore.instance.collection('users').doc(uid).get()).data();
    return {
      'studentInstituteId': data?['studentInstituteId'] ?? '',
      'studentInstituteName': data?['studentInstituteName'] ?? '',
      'studentProgram': data?['studentProgram'] ?? '',
      'studentVerificationStatus': data?['studentVerificationStatus'] ?? 'not_requested',
    };
  }

  Stream<Map<String, dynamic>> watchProfile(String uid) {
    if (InstituteAccess.isDemo) {
      Map<String, dynamic> current() => Map<String, dynamic>.from(_demoProfiles[uid] ?? const {});
      return Stream.multi((controller) {
        controller.add(current());
        final sub = addListenerStream(() => controller.add(current()));
        controller.onCancel = sub;
      });
    }
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data() ?? const <String, dynamic>{};
      return {
        'studentInstituteId': data['studentInstituteId'] ?? '',
        'studentInstituteName': data['studentInstituteName'] ?? '',
        'studentProgram': data['studentProgram'] ?? '',
        'studentVerificationStatus': data['studentVerificationStatus'] ?? 'not_requested',
      };
    });
  }

  Future<void> select(Institute institute, String program) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) throw StateError('Sign in to add your university.');
    if (institute.type != 'universities') throw ArgumentError('Choose a university.');
    if (program.trim().isEmpty) throw ArgumentError('Choose your program.');
    final availablePrograms = institute.programGroups.values.expand((items) => items).toSet();
    final validPrograms = availablePrograms.isNotEmpty ? availablePrograms : institute.programs.toSet();
    if (!validPrograms.contains(program.trim())) throw ArgumentError('Choose a program listed by this university.');
    final current = await profile(uid);
    if (current['studentVerificationStatus'] == 'approved') {
      throw StateError('Your university has already verified this affiliation. Contact the university to change it.');
    }
    final previousInstituteId = (current['studentInstituteId'] ?? '').toString();
    final next = {
      'studentInstituteId': institute.id,
      'studentInstituteName': institute.name,
      'studentProgram': program.trim(),
      'studentVerificationStatus': 'pending',
    };
    if (InstituteAccess.isDemo) {
      final request = {
        'id': uid, 'studentId': uid,
        'studentName': ActiveProfileController.instance.effectiveName ?? 'Demo student',
        'instituteId': institute.id, 'instituteName': institute.name,
        'program': program.trim(), 'status': 'pending', 'updatedAt': DateTime.now(),
      };
      _demoProfiles[uid] = next;
      if (previousInstituteId.isNotEmpty && previousInstituteId != institute.id) {
        _demoRequests[previousInstituteId]?.remove(uid);
      }
      (_demoRequests[institute.id] ??= {})[uid] = request;
      DemoDataService.instance.addNotification('demo-user-6', {
        'type': 'student_affiliation', 'text': '${request['studentName']} asked to verify student status at ${institute.name}.',
        'instituteId': institute.id, 'createdAt': DateTime.now(), 'read': false,
      });
      notifyListeners();
      return;
    }
    final db = FirebaseFirestore.instance;
    final request = db.collection('institutes').doc(institute.id)
        .collection('studentAffiliations').doc(uid);
    final user = db.collection('users').doc(uid);
    final ownerId = institute.ownerId;
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
    await db.runTransaction((tx) async {
      final existing = await tx.get(request);
      if (existing.exists && existing.data()?['status'] == 'approved') {
        throw StateError('This university has already verified your student status.');
      }
      if (previousInstituteId.isNotEmpty && previousInstituteId != institute.id) {
        final previous = db.collection('institutes').doc(previousInstituteId).collection('studentAffiliations').doc(uid);
        final oldRequest = await tx.get(previous);
        if (oldRequest.exists && oldRequest.data()?['status'] == 'approved') {
          throw StateError('Your previous university has already verified this affiliation. Contact it before changing universities.');
        }
        if (oldRequest.exists) tx.delete(previous);
      }
      tx.set(request, {
        'studentId': uid, 'studentName': name?.isNotEmpty == true ? name : 'Student',
        'instituteId': institute.id, 'program': program.trim(), 'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(user, next, SetOptions(merge: true));
      if (ownerId.isNotEmpty) {
        final notification = db.collection('users').doc(ownerId).collection('notifications').doc();
        tx.set(notification, {
          'type': 'student_affiliation', 'text': '${name?.isNotEmpty == true ? name : 'A student'} asked to verify student status.',
          'instituteId': institute.id, 'fromId': uid,
          'createdAt': FieldValue.serverTimestamp(), 'read': false,
        });
      }
    });
    notifyListeners();
  }

  Stream<List<Map<String, dynamic>>> requests(Institute institute) {
    if (!InstituteAccess.canManage(institute)) return Stream.value(const []);
    if (InstituteAccess.isDemo) {
      List<Map<String, dynamic>> current() => (_demoRequests[institute.id]?.values ?? const <Map<String, dynamic>>[])
          .where((r) => r['status'] == 'pending').map(Map<String, dynamic>.from).toList();
      return Stream.multi((controller) {
        controller.add(current());
        final sub = addListenerStream(() => controller.add(current()));
        controller.onCancel = sub;
      });
    }
    return FirebaseFirestore.instance.collection('institutes').doc(institute.id)
        .collection('studentAffiliations').where('status', isEqualTo: 'pending').snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  VoidCallback addListenerStream(void Function() callback) {
    addListener(callback);
    return () => removeListener(callback);
  }

  Future<void> review(Institute institute, String studentId, String status) async {
    if (!InstituteAccess.canManage(institute)) throw StateError('Only this university’s authorized representative can review requests.');
    if (!const {'approved', 'rejected'}.contains(status)) throw ArgumentError('Invalid verification decision.');
    if (InstituteAccess.isDemo) {
      final request = _demoRequests[institute.id]?[studentId];
      if (request == null || request['status'] != 'pending') throw StateError('This request has already been reviewed.');
      request['status'] = status;
      request['updatedAt'] = DateTime.now();
      final profile = _demoProfiles[studentId];
      if (profile?['studentInstituteId'] == institute.id) profile?['studentVerificationStatus'] = status;
      DemoDataService.instance.addNotification(studentId, {
        'type': 'student_affiliation_result',
        'text': status == 'approved' ? '${institute.name} verified your student affiliation.' : '${institute.name} could not verify your student affiliation.',
        'instituteId': institute.id, 'createdAt': DateTime.now(), 'read': false,
      });
      notifyListeners();
      return;
    }
    final db = FirebaseFirestore.instance;
    final request = db.collection('institutes').doc(institute.id).collection('studentAffiliations').doc(studentId);
    final user = db.collection('users').doc(studentId);
    await db.runTransaction((tx) async {
      final snapshot = await tx.get(request);
      final data = snapshot.data();
      if (data == null || data['status'] != 'pending') throw StateError('This request has already been reviewed.');
      final profile = await tx.get(user);
      tx.update(request, {'status': status, 'reviewedAt': FieldValue.serverTimestamp(), 'reviewedBy': InstituteAccess.uid});
      if (profile.data()?['studentInstituteId'] == institute.id) {
        tx.set(user, {'studentVerificationStatus': status}, SetOptions(merge: true));
      }
      final notification = db.collection('users').doc(studentId).collection('notifications').doc();
      tx.set(notification, {
        'type': 'student_affiliation_result',
        'text': status == 'approved' ? '${institute.name} verified your student affiliation.' : '${institute.name} could not verify your student affiliation.',
        'instituteId': institute.id, 'fromId': InstituteAccess.uid,
        'createdAt': FieldValue.serverTimestamp(), 'read': false,
      });
    });
    notifyListeners();
  }

  Future<int> verifiedStudentCount(String instituteId) async {
    if (InstituteAccess.isDemo) {
      return (_demoRequests[instituteId]?.values ?? const <Map<String, dynamic>>[])
          .where((r) => r['status'] == 'approved').map((r) => r['studentId']).toSet().length;
    }
    final result = await FirebaseFirestore.instance.collection('users')
        .where('studentInstituteId', isEqualTo: instituteId)
        .where('studentVerificationStatus', isEqualTo: 'approved').count().get();
    return result.count ?? 0;
  }

  @visibleForTesting
  void resetDemoForTest() { _demoProfiles.clear(); _demoRequests.clear(); notifyListeners(); }
}
