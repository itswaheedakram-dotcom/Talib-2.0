import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/demo_data_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../models/institute.dart';
import '../../data/institute_repository.dart';

class AdminInstituteClaimsScreen extends StatelessWidget {
  const AdminInstituteClaimsScreen({super.key});

  bool get _demoMode =>
      ActiveProfileController.instance.isDemo || !FirebaseService.initialized;

  Future<void> _setRealStatus(
    BuildContext context,
    String claimId,
    Map<String, dynamic> data,
    String status,
  ) async {
    final db = FirebaseFirestore.instance;
    final claimRef = db.collection('instituteClaims').doc(claimId);
    final batch = db.batch();
    batch.update(claimRef, {
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'approved') {
      final instituteId = (data['instituteId'] ?? '').toString();
      final representativeId = (data['representativeId'] ?? '').toString();
      if (instituteId.isEmpty || representativeId.isEmpty) {
        throw StateError('Claim is missing its institute or representative ID.');
      }
      final instituteRef = db.collection('institutes').doc(instituteId);
      final existingInstitute = await instituteRef.get();
      final ownership = {
        'ownerId': representativeId,
        'representativeId': representativeId,
        'ownershipVerified': true,
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (existingInstitute.exists) {
        batch.update(instituteRef, ownership);
      } else {
        final rawSnapshot = data['instituteSnapshot'];
        if (rawSnapshot is! Map) {
          throw StateError('This institute is not in Firebase and has no seed snapshot.');
        }
        final snapshot = Map<String, dynamic>.from(rawSnapshot);
        batch.set(instituteRef, {
          ...snapshot,
          ...ownership,
          'status': 'approved',
          'createdBy': (snapshot['createdBy'] ?? '').toString().isEmpty
              ? 'system_seed'
              : snapshot['createdBy'],
        });
      }
      batch.set(db.collection('users').doc(representativeId), {
        'role': 'instituteRepresentative',
        'instituteAdmin': true,
        'instituteId': instituteId,
        'instituteName': data['instituteName'],
        'designation': data['designation'],
      }, SetOptions(merge: true));
    }

    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'approved'
            ? 'Claim approved and ownership linked.'
            : 'Claim rejected.')),
      );
    }
  }

  Future<void> _setDemoStatus(
    BuildContext context,
    Map<String, dynamic> claim,
    String status,
  ) async {
    final instituteId = (claim['instituteId'] ?? '').toString();
    final representativeId = (claim['representativeId'] ?? '').toString();
    DemoDataService.instance.reviewInstituteClaim(
      (claim['id'] ?? '').toString(),
      status,
    );
    if (status == 'approved') {
      final institute = InstituteRepository.instance.byId(instituteId);
      if (institute != null && representativeId.isNotEmpty) {
        await InstituteRepository.instance.update(Institute.fromMap(
          institute.id,
          {
            ...institute.toMap(),
            'ownerId': representativeId,
            'representativeId': representativeId,
          },
        ));
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'approved'
            ? 'Demo claim approved. The demo profile can now manage this institute.'
            : 'Demo claim rejected.')),
      );
    }
  }

  Widget _claimCard(
    BuildContext context,
    Map<String, dynamic> data,
    String id,
    Future<void> Function(String status) onReview,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((data['instituteName'] ?? 'Institute').toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Representative: ${data['representativeName'] ?? ''}'),
        if ((data['designation'] ?? '').toString().isNotEmpty)
          Text('Designation: ${data['designation']}'),
        if ((data['representativeEmail'] ?? '').toString().isNotEmpty)
          Text('Email: ${data['representativeEmail']}'),
        if ((data['verificationMethod'] ?? '').toString().isNotEmpty)
          Text('Method: ${data['verificationMethod']}'),
        if ((data['verificationDetails'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text((data['verificationDetails'] ?? '').toString()),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => onReview('rejected'),
            child: const Text('Reject'),
          )),
          const SizedBox(width: 10),
          Expanded(child: FilledButton(
            onPressed: () => onReview('approved'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Approve'),
          )),
        ]),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_demoMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Institute Claims')),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          initialData: DemoDataService.instance.pendingInstituteClaims(),
          stream: DemoDataService.instance.changes.map(
            (_) => DemoDataService.instance.pendingInstituteClaims(),
          ),
          builder: (context, snapshot) {
            final claims = snapshot.data ?? const <Map<String, dynamic>>[];
            if (claims.isEmpty) {
              return const Center(child: Text('No pending institute claims.'));
            }
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('Demo claim reviews never write to Firebase.'),
                ),
                ...claims.map((claim) => _claimCard(
                  context,
                  claim,
                  (claim['id'] ?? '').toString(),
                  (status) => _setDemoStatus(context, claim, status),
                )),
              ],
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Institute Claims')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('instituteClaims')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load claims. Check admin permissions and try again.'));
          }
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) return const Center(child: Text('No pending claims.'));
          return ListView(
            padding: const EdgeInsets.all(12),
            children: docs.map((doc) => _claimCard(
              context,
              doc.data(),
              doc.id,
              (status) => _setRealStatus(context, doc.id, doc.data(), status),
            )).toList(),
          );
        },
      ),
    );
  }
}
