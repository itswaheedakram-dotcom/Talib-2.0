import '../../../../core/widgets/user_identity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/admin_access_service.dart';
import '../../../hostels/data/hostel_repository.dart';
import '../../../models/hostel.dart';

class AdminHostelSubmissionsScreen extends StatelessWidget {
  const AdminHostelSubmissionsScreen({super.key});

  Future<void> _review(
    BuildContext context,
    Hostel hostel,
    String status, {
    required bool demo,
  }) async {
    final access = AdminAccessService.instance;
    if (!access.isSuperAdmin &&
        !access.isDemoSuperAdmin &&
        !access.can('manage_hostels')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to review hostel submissions.')),
      );
      return;
    }
    try {
      if (demo) {
        if (!access.isDemoSuperAdmin) {
          throw StateError('Demo submissions can only be reviewed by Demo Super Admin.');
        }
        await HostelRepository.setDemoHostelStatus(hostel.id, status);
      } else {
        if (access.isDemoSuperAdmin) {
          throw StateError('Demo Super Admin cannot change real Firebase hostels.');
        }
        await FirebaseFirestore.instance.collection('hostels').doc(hostel.id).update({
          'status': status,
          'isVerified': status == 'approved',
          'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'approved'
              ? 'Hostel approved and published.'
              : 'Hostel submission rejected.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update hostel status: $error')),
        );
      }
    }
  }

  Widget _card(BuildContext context, Hostel hostel, {required bool demo}) {
    final location = [hostel.area, hostel.city]
        .where((part) => part.trim().isNotEmpty)
        .join(', ');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hotel_outlined, color: AppColors.darkGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hostel.name, style: const TextStyle(
                    color: AppColors.darkGreen, fontSize: 17, fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(height: 4),
                  Text(location.isEmpty ? 'Location not provided' : location),
                  UserIdentity(uid: hostel.ownerId, name: hostel.ownerName.isEmpty ? 'Unknown owner' : hostel.ownerName),
                ]),
              ),
              const Chip(label: Text('Pending')),
            ]),
            const SizedBox(height: 10),
            if (hostel.address.trim().isNotEmpty)
              Text('Address: ${hostel.address}'),
            if (hostel.price.trim().isNotEmpty)
              Text('Price: ${hostel.price}'),
            if (hostel.phone.trim().isNotEmpty)
              Text('Contact: ${hostel.phone}'),
            if (hostel.description.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(hostel.description, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _review(context, hostel, 'rejected', demo: demo),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _review(context, hostel, 'approved', demo: demo),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _empty() => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.task_alt_rounded, size: 54, color: AppColors.primaryGreen),
        SizedBox(height: 12),
        Text('No pending hostel submissions', style: TextStyle(
          color: AppColors.darkGreen, fontSize: 17, fontWeight: FontWeight.w700,
        )),
        SizedBox(height: 5),
        Text('New hostel listings will appear here for review.', textAlign: TextAlign.center),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final access = AdminAccessService.instance;
    final demo = access.isDemoSuperAdmin;
    if (!demo && !access.isSuperAdmin && !access.can('manage_hostels')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hostel Submissions')),
        body: const Center(child: Text('You do not have permission to review hostel submissions.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(demo ? 'Demo Hostel Submissions' : 'Hostel Submissions')),
      body: Column(children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.softGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(demo
              ? 'Demo records only. Review actions never write to Firebase.'
              : 'Review new listings here. Only approved hostels are visible to students.'),
        ),
        Expanded(
          child: StreamBuilder<List<Hostel>>(
            stream: demo
                ? HostelRepository.watchDemoHostels()
                : FirebaseFirestore.instance.collection('hostels')
                    .where('status', isEqualTo: 'pending')
                    .snapshots()
                    .map((snapshot) => snapshot.docs.map(Hostel.fromDoc).toList()),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Hostel submissions could not be loaded. Check admin access and connection.'));
              }
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final pending = (snapshot.data ?? const <Hostel>[])
                  .where((hostel) => hostel.status.toLowerCase() == 'pending')
                  .toList()
                ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              if (pending.isEmpty) return _empty();
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                itemCount: pending.length,
                itemBuilder: (context, index) => _card(context, pending[index], demo: demo),
              );
            },
          ),
        ),
      ]),
    );
  }
}
