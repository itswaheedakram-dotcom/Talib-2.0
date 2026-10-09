import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../models/institute.dart';
import '../../data/institute_repository.dart';

class InstituteDashboardScreen extends StatelessWidget {
  const InstituteDashboardScreen({super.key});

  Widget _buildDemoDashboard(BuildContext context) {
    final uid = ActiveProfileController.instance.effectiveUid;
    final owned = uid == null ? <Institute>[] : InstituteRepository.instance.items.where((item) => item.ownerId == uid).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Institute Dashboard')),
      body: owned.isEmpty
          ? ListView(padding: const EdgeInsets.all(20), children: [
              const Icon(Icons.business_outlined, size: 64, color: AppColors.primaryGreen),
              const SizedBox(height: 14),
              const Text('No approved institute claims yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Submit a demo claim from an institute profile. Demo Admin can approve it without changing Firebase.', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => context.go('/institutes'), child: const Text('Browse Institutes')),
            ])
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Your Demo Institutes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...owned.map((institute) => Card(child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.business_outlined)),
                title: Text(institute.name),
                subtitle: const Text('Demo ownership approved'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/institute/${institute.id}'),
              ))),
            ]),
    );
  }

  @override Widget build(BuildContext context) {
    if (ActiveProfileController.instance.isDemo || !FirebaseService.initialized) {
      return _buildDemoDashboard(context);
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Please sign in.')));
    return Scaffold(
      appBar: AppBar(title: const Text('Institute Dashboard')),
      body: StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
        stream: FirebaseFirestore.instance.collection('instituteClaims')
          .where('representativeId', isEqualTo: user.uid).where('status', isEqualTo: 'approved').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? const [];
          if (docs.isEmpty) return ListView(padding: const EdgeInsets.all(20), children: [
            const Icon(Icons.business_outlined, size: 64),
            const SizedBox(height: 14),
            const Text('No approved institute yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Claim an existing institute profile. Once admin approves your claim, it will appear here.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => context.go('/institutes'), child: const Text('Browse Institutes')),
          ]);
          return ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Your Institutes', style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...docs.map((d) {
              final data=d.data();
              return Card(child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.business)),
                title: Text((data['instituteName'] ?? 'Institute').toString()),
                subtitle: const Text('Verified institute representative access'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/institute-admin/' + d.id),
              ));
            }),
          ]);
        },
      ),
    );
  }
}
