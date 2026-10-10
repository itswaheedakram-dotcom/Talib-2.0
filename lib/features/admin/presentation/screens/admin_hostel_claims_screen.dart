import '../../../../core/widgets/user_identity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/admin_access_service.dart';
import '../../../hostels/data/hostel_claim.dart';
import '../../../hostels/data/hostel_repository.dart';

class AdminHostelClaimsScreen extends StatelessWidget {
  const AdminHostelClaimsScreen({super.key});

  Future<void> _setStatus(
    BuildContext context,
    String claimId,
    String status, {
    required bool demo,
  }) async {
    final access = AdminAccessService.instance;
    if (!access.isSuperAdmin &&
        !access.isDemoSuperAdmin &&
        !access.can('ownership_claim_review')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to review claims.')),
      );
      return;
    }
    try {
      if (demo) {
        if (!access.isDemoSuperAdmin) {
          throw StateError('Demo claims can only be reviewed by Demo Super Admin.');
        }
        await HostelRepository.setDemoClaimStatus(claimId, status);
      } else {
        if (access.isDemoSuperAdmin) {
          throw StateError('Demo Super Admin cannot change real Firebase claims.');
        }
        await FirebaseFirestore.instance.collection('hostelClaims').doc(claimId).update({
          'status': status,
          'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'approved' ? 'Hostel claim approved.' : 'Hostel claim rejected.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update claim: $error')),
        );
      }
    }
  }

  Widget _claimCard(
    BuildContext context, {
    required String id,
    required String hostelName,
    required String userName,
    required String userId,
    required String contact,
    required String note,
    required bool demo,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hostelName, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGreen,
            )),
            const SizedBox(height: 6),
            UserIdentity(uid: userId, name: userName),
            Text('Contact: $contact'),
            if (note.trim().isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text(note)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _setStatus(context, id, 'rejected', demo: demo),
                child: const Text('Reject'),
              )),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(
                onPressed: () => _setStatus(context, id, 'approved', demo: demo),
                child: const Text('Approve'),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoClaims(BuildContext context) {
    return StreamBuilder<List<HostelClaim>>(
      stream: HostelRepository.watchDemoClaims(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Demo claims could not be loaded.'));
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final claims = (snapshot.data ?? const <HostelClaim>[])
            .where((claim) => claim.status == 'pending').toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        if (claims.isEmpty) return const Center(child: Text('No pending demo hostel claims.'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: claims.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final claim = claims[index];
            return _claimCard(
              context, id: claim.id, hostelName: claim.hostelName,
              userName: claim.userName, userId: claim.userId, contact: claim.contact,
              note: claim.note, demo: true,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final access = AdminAccessService.instance;
    if (access.isDemoSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Demo Hostel Ownership Claims')),
        body: Column(children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softGreen, borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Demo records only. Approvals and rejections never write to Firebase.'),
          ),
          Expanded(child: _buildDemoClaims(context)),
        ]),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Hostel Ownership Claims')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('hostelClaims')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Claims could not be loaded. Check your admin permissions.'));
          }
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) return const Center(child: Text('No pending hostel claims.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return _claimCard(
                context, id: doc.id,
                hostelName: (data['hostelName'] ?? 'Hostel').toString(),
                userName: (data['userName'] ?? 'Unknown').toString(),
                userId: (data['userId'] ?? '').toString(),
                contact: (data['contact'] ?? 'Not provided').toString(),
                note: (data['note'] ?? '').toString(),
                demo: false,
              );
            },
          );
        },
      ),
    );
  }
}
