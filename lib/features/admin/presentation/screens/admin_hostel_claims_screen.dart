import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/admin_access_service.dart';

class AdminHostelClaimsScreen extends StatelessWidget {
  const AdminHostelClaimsScreen({super.key});

  Future<void> _setStatus(BuildContext context, String claimId, String status) async {
    final access = AdminAccessService.instance;
    if (!access.isSuperAdmin && !access.can('ownership_claim_review')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to review claims.')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('hostelClaims').doc(claimId).update({
        'status': status,
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
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

  @override
  Widget build(BuildContext context) {
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
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (data['hostelName'] ?? 'Hostel').toString(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGreen),
                      ),
                      const SizedBox(height: 6),
                      Text('Claimant: ${data['userName'] ?? 'Unknown'}'),
                      Text('Contact: ${data['contact'] ?? 'Not provided'}'),
                      if ((data['note'] ?? '').toString().trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(data['note'].toString()),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _setStatus(context, doc.id, 'rejected'),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _setStatus(context, doc.id, 'approved'),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
