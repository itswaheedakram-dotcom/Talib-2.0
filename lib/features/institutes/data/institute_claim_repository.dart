import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/demo_data_service.dart';
import '../../models/institute.dart';
import 'institute_access.dart';
import 'institute_repository.dart';

/// Both claim screens and dashboards use this backend boundary.
class InstituteClaimRepository {
  InstituteClaimRepository._();
  static final instance = InstituteClaimRepository._();
  final _institutes = InstituteRepository.instance;

  Stream<List<Map<String, dynamic>>> watch({bool pendingOnly = false}) {
    final uid = InstituteAccess.uid;
    if (uid == null || (pendingOnly && !InstituteAccess.canReviewClaims))
      return Stream.value(const []);
    if (InstituteAccess.isDemo) {
      List<Map<String, dynamic>> current() => pendingOnly
          ? DemoDataService.instance.pendingInstituteClaims()
          : DemoDataService.instance.instituteClaimsFor(uid);
      return Stream.multi((controller) {
        controller.add(current());
        final subscription = DemoDataService.instance.changes.listen(
          (_) => controller.add(current()),
        );
        controller.onCancel = subscription.cancel;
      });
    }
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'instituteClaims',
    );
    query = pendingOnly
        ? query.where('status', isEqualTo: 'pending')
        : query.where('representativeId', isEqualTo: uid);
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
    );
  }

  Future<Map<String, dynamic>?> get(String claimId) async {
    final uid = InstituteAccess.uid;
    if (uid == null) return null;
    if (InstituteAccess.isDemo) {
      for (final claim in DemoDataService.instance.instituteClaimsFor(uid)) {
        if (claim['id'] == claimId) return claim;
      }
      return null;
    }
    final doc = await FirebaseFirestore.instance
        .collection('instituteClaims')
        .doc(claimId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['representativeId'] != uid && !InstituteAccess.canReviewClaims)
      return null;
    return {...data, 'id': doc.id};
  }

  Future<void> submit(
    Institute institute, {
    required String designation,
    required String method,
    required String details,
  }) async {
    final uid = InstituteAccess.uid;
    if (uid == null)
      throw StateError('Activate a demo profile or sign in to submit a claim.');
    if (designation.trim().isEmpty || details.trim().isEmpty)
      throw ArgumentError('Complete the verification details.');
    if (institute.ownerId.isNotEmpty)
      throw StateError('This institute already has an owner.');
    if (InstituteAccess.isDemo) {
      DemoDataService.instance.claimInstitute(
        uid,
        institute.id,
        instituteName: institute.name,
        designation: designation.trim(),
        method: method,
        details: details.trim(),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;
    // Deterministic ID prevents duplicate claims from concurrent submissions.
    final ref = db.collection('instituteClaims').doc('${institute.id}_$uid');
    await db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists)
        throw StateError('You already submitted a claim for this institute.');
      tx.set(ref, {
        'instituteId': institute.id,
        'instituteName': institute.name,
        'representativeId': uid,
        'representativeName': user.displayName ?? 'Representative',
        'representativeEmail': user.email ?? '',
        'designation': designation.trim(),
        'verificationMethod': method,
        'verificationDetails': details.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> review(String claimId, String status) async {
    if (!InstituteAccess.canReviewClaims)
      throw StateError('Claim review access required.');
    if (!const {'approved', 'rejected'}.contains(status))
      throw ArgumentError('Invalid review status.');
    if (InstituteAccess.isDemo) {
      final claims = DemoDataService.instance.pendingInstituteClaims().where(
        (claim) => claim['id'] == claimId,
      );
      if (claims.isEmpty)
        throw StateError('This claim has already been reviewed.');
      final claim = claims.first;
      if (status == 'approved') {
        final instituteId = claim['instituteId'].toString();
        final uid = claim['representativeId'].toString();
        final institute = _institutes.byId(instituteId);
        if (institute == null ||
            (institute.ownerId.isNotEmpty && institute.ownerId != uid))
          throw StateError('Institute is missing or already owned.');
        _institutes.applyDemoOwnership(instituteId, uid);
      }
      DemoDataService.instance.reviewInstituteClaim(claimId, status);
      return;
    }
    final db = FirebaseFirestore.instance;
    final ref = db.collection('instituteClaims').doc(claimId);
    String? instituteId;
    await db.runTransaction((tx) async {
      final claim = await tx.get(ref);
      final data = claim.data();
      if (data == null || data['status'] != 'pending')
        throw StateError('This claim has already been reviewed.');
      instituteId = data['instituteId'].toString();
      final uid = data['representativeId'].toString();
      final instituteRef = db.collection('institutes').doc(instituteId);
      if (status == 'approved') {
        final institute = await tx.get(instituteRef);
        if (!institute.exists)
          throw StateError(
            'Institute must be published before approving ownership.',
          );
        final owner = (institute.data()?['ownerId'] ?? '').toString();
        if (owner.isNotEmpty && owner != uid)
          throw StateError('This institute already has an owner.');
        tx.update(instituteRef, {
          'ownerId': uid,
          'representativeId': uid,
          'ownershipVerified': true,
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.set(db.collection('users').doc(uid), {
          'role': 'instituteRepresentative',
          'instituteAdmin': true,
          'instituteId': instituteId,
          'instituteName': data['instituteName'],
          'designation': data['designation'],
        }, SetOptions(merge: true));
      }
      tx.update(ref, {
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    });
    if (instituteId != null) await _institutes.loadById(instituteId!);
  }
}
