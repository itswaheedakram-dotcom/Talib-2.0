import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../models/institute.dart';
import '../../../../core/services/firebase_service.dart';

class InstituteDetailScreen extends StatelessWidget {
  final String id;
  const InstituteDetailScreen({super.key, required this.id});

  static const _data = <Institute>[
    Institute(id: 'school-1', name: 'The Educators', type: 'schools', city: 'Lahore', address: 'Lahore, Punjab', description: 'A school offering foundational and secondary education.', programs: ['Primary', 'Middle', 'Matric']),
    Institute(id: 'school-2', name: 'Beaconhouse School System', type: 'schools', city: 'Lahore', address: 'Lahore, Punjab', description: 'A private school network providing education from early years through secondary levels.', programs: ['Early Years', 'Primary', 'Secondary']),
    Institute(id: 'college-1', name: 'Government College Lahore', type: 'colleges', city: 'Lahore', address: 'Lahore, Punjab', description: 'A historic public college offering intermediate and degree programs.', programs: ['FA', 'FSc', 'ICS', 'BS']),
    Institute(id: 'college-2', name: 'Government College of Science', type: 'colleges', city: 'Lahore', address: 'Lahore, Punjab', description: 'A public institution focused on science and degree education.', programs: ['FSc', 'BS']),
    Institute(id: 'university-1', name: 'University of the Punjab', type: 'universities', city: 'Lahore', address: 'Quaid-e-Azam Campus, Lahore', description: 'A major public university with a broad range of academic disciplines.', programs: ['Undergraduate', 'Graduate', 'PhD']),
    Institute(id: 'university-2', name: 'Islamia University Bahawalpur', type: 'universities', city: 'Bahawalpur', address: 'Bahawalpur, Punjab', description: 'A public-sector university serving students across multiple disciplines.', programs: ['Undergraduate', 'Graduate', 'PhD']),
  ];

  @override
  Widget build(BuildContext context) {
    final institute = _data.cast<Institute?>().firstWhere((i) => i!.id == id, orElse: () => null);
    if (institute == null) return const Scaffold(body: Center(child: Text('Institute not found')));
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (institute.type) { 'schools' => Icons.school_rounded, 'colleges' => Icons.account_balance_rounded, _ => Icons.castle_rounded };
    return Scaffold(
      appBar: AppBar(title: const Text('Institute Details')),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [scheme.primary, scheme.primaryContainer]), borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(radius: 32, backgroundColor: scheme.onPrimary.withValues(alpha: .14), child: Icon(icon, color: scheme.onPrimary, size: 30)),
            const SizedBox(height: 18),
            Text(institute.name, style: TextStyle(color: scheme.onPrimary, fontSize: 25, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [Icon(Icons.location_on_outlined, size: 18, color: scheme.onPrimary), const SizedBox(width: 5), Expanded(child: Text(institute.address, style: TextStyle(color: scheme.onPrimary.withValues(alpha: .88))))]),
          ]),
        ),
        const SizedBox(height: 16),
        Text('About', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Text(institute.description),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseService.initialized ? FirebaseFirestore.instance.collection('instituteClaims').where('instituteId', isEqualTo: institute.id).where('status', isEqualTo: 'pending').limit(1).snapshots() : const Stream.empty(),
          builder: (context, claimSnap) {
            final pending = claimSnap.data?.docs.isNotEmpty == true;
            return Card(child: ListTile(
              leading: Icon(pending ? Icons.hourglass_top : Icons.business_outlined, color: scheme.primary),
              title: Text(pending ? 'Claim under review' : 'Institute profile'),
              subtitle: Text(pending ? 'A representative has submitted a claim for admin verification.' : FirebaseService.initialized ? 'This institute is currently listed on Talib.' : 'This institute is listed on Talib. Firebase features are not configured yet.'),
              trailing: pending ? null : FilledButton(
                onPressed: !FirebaseService.initialized || FirebaseAuth.instance.currentUser == null ? () => context.push('/signin') : () => context.push('/institute/' + institute.id + '/claim?name=' + Uri.encodeComponent(institute.name)),
                child: Text(FirebaseService.initialized && FirebaseAuth.instance.currentUser != null ? 'Claim' : 'Sign In to Claim'),
              ),
            ));
          },
        ),
        const SizedBox(height: 22),
        Text('Programs', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: institute.programs.map((p) => Chip(label: Text(p))).toList()),
        const SizedBox(height: 22),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Location'), subtitle: Text(institute.address)),
          const Divider(height: 1),
          const ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('Institute type'), subtitle: Text('Educational institute')),
          const Divider(height: 1),
          const ListTile(leading: Icon(Icons.phone_outlined), title: const Text('Contact'), subtitle: Text('Contact information will be connected to Firebase')),
        ])),
      ]),
    );
  }
}
