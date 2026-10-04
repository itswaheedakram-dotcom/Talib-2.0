import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../models/institute.dart';
import '../../data/institute_repository.dart';
import '../../../../core/services/firebase_service.dart';

class InstituteDetailScreen extends StatelessWidget {
  final String id;
  const InstituteDetailScreen({super.key, required this.id});

  static const green = Color(0xFF00A66A);
  static const darkGreen = Color(0xFF00543D);
  static const lightGreen = Color(0xFFEAF8F2);

  @override Widget build(BuildContext context) {
    final institute = InstituteRepository.instance.byId(id);
    if (institute == null) return const Scaffold(body: Center(child: Text('Institute not found')));
    final typeLabel = institute.type == 'schools' ? 'School' : institute.type == 'colleges' ? 'College' : 'University';
    final image = institute.type == 'schools'
        ? 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=1200&q=80'
        : institute.type == 'colleges'
            ? 'https://images.unsplash.com/photo-1564981797816-1043664bf78d?auto=format&fit=crop&w=1200&q=80'
            : 'https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=1200&q=80';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
        title: Text(typeLabel),
        actions: const [Icon(Icons.notifications_none), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 185,
              child: Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
                color: lightGreen,
                child: const Icon(Icons.account_balance, size: 70, color: green),
              )),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(institute.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: darkGreen)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 17, color: green),
                const SizedBox(width: 3),
                Expanded(child: Text(institute.address, style: const TextStyle(color: Colors.black54))),
              ]),
            ])),
            IconButton(onPressed: () {}, icon: const Icon(Icons.location_on_outlined, color: green)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border, color: green)),
          ]),
          const SizedBox(height: 10),
          Card(
            color: lightGreen,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.campaign_outlined, color: green),
                const SizedBox(width: 8),
                const Expanded(child: Text('Admissions', style: TextStyle(fontWeight: FontWeight.w700, color: darkGreen))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(14)),
                  child: const Text('OPEN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          _section('Institute Information', Column(children: [
            _info(Icons.info_outline, 'About', institute.description),
            _info(Icons.location_on_outlined, 'City', institute.city),
            _info(Icons.account_balance_outlined, 'Type', typeLabel),
          ])),
          const SizedBox(height: 10),
          _section('Admission', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 7, runSpacing: 7, children: institute.programs.map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(18)),
              child: Text(p, style: const TextStyle(color: darkGreen, fontWeight: FontWeight.w600)),
            )).toList()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => context.push('/institute/' + institute.id + '/programs'),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Programs'),
              )),
              const SizedBox(width: 9),
              Expanded(child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(backgroundColor: green),
                child: const Text('Apply / Details'),
              )),
            ]),
            const SizedBox(height: 9),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () => context.push('/institute/' + institute.id + '/community?name=' + Uri.encodeComponent(institute.name)),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('Institute Community'),
            )),
          ])),
          const SizedBox(height: 10),
          _section('Facilities', const Column(children: [
            _Facility(Icons.school_outlined, 'Scholarships'),
            _Facility(Icons.local_library_outlined, 'Library'),
            _Facility(Icons.wifi_rounded, 'Internet / Wi-Fi'),
            _Facility(Icons.sports_soccer_outlined, 'Sports Facilities'),
          ])),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseService.initialized
                ? FirebaseFirestore.instance.collection('instituteClaims').where('instituteId', isEqualTo: institute.id).where('status', isEqualTo: 'pending').limit(1).snapshots()
                : const Stream.empty(),
            builder: (context, snap) {
              final pending = snap.data?.docs.isNotEmpty == true;
              final signedIn = FirebaseService.initialized && FirebaseAuth.instance.currentUser != null;
              return Card(child: ListTile(
                leading: Icon(pending ? Icons.hourglass_top : Icons.business_outlined, color: green),
                title: Text(pending ? 'Claim under review' : 'Manage this institute'),
                subtitle: Text(pending ? 'Waiting for admin verification.' : 'Institute representatives can claim this profile.'),
                trailing: pending ? null : FilledButton(
                  onPressed: signedIn
                      ? () => context.push('/institute/' + institute.id + '/claim?name=' + Uri.encodeComponent(institute.name))
                      : () => context.push('/signin'),
                  style: FilledButton.styleFrom(backgroundColor: green),
                  child: Text(signedIn ? 'Claim' : 'Sign In'),
                ),
              ));
            },
          ),
        ],
      ),
    );
  }

  static Widget _section(String title, Widget child) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: darkGreen)),
      const SizedBox(height: 9),
      child,
    ])),
  );

  static Widget _info(IconData icon, String title, String value) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: green),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(value),
  );
}

class _Facility extends StatelessWidget {
  final IconData icon;
  final String title;
  const _Facility(this.icon, this.title);
  @override Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: InstituteDetailScreen.green),
    title: Text(title),
  );
}
