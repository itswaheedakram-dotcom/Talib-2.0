import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../models/institute.dart';
import '../../../../core/services/firebase_service.dart';

class InstituteDetailScreen extends StatelessWidget {
  final String id;
  const InstituteDetailScreen({super.key, required this.id});
  static const green = Color(0xFF00A66A), darkGreen = Color(0xFF00543D), lightGreen = Color(0xFFEAF8F2);
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
    final matches = _data.where((i) => i.id == id).toList();
    if (matches.isEmpty) return const Scaffold(body: Center(child: Text('Institute not found')));
    final institute = matches.first;
    final typeLabel = institute.type == 'schools' ? 'School' : institute.type == 'colleges' ? 'College' : 'University';

    return Scaffold(
      appBar: AppBar(title: Text(typeLabel)),
      body: ListView(padding: const EdgeInsets.fromLTRB(12, 10, 12, 28), children: [
        Container(height: 155, decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(12)), child: Center(child: Container(width: 82, height: 82, decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(18)), child: Icon(institute.type == 'universities' ? Icons.account_balance_rounded : Icons.school_rounded, color: Colors.white, size: 44)))),
        const SizedBox(height: 12),
        Text(institute.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: darkGreen)),
        const SizedBox(height: 5),
        Row(children: [const Icon(Icons.location_on_outlined, size: 18, color: green), const SizedBox(width: 4), Expanded(child: Text(institute.address, style: const TextStyle(color: Colors.black54)))]),
        const SizedBox(height: 14),
        _section('Institute Information', Column(children: [_info(Icons.info_outline, 'About', institute.description), _info(Icons.location_on_outlined, 'City', institute.city), _info(Icons.account_balance_outlined, 'Type', typeLabel)])),
        const SizedBox(height: 12),
        _section('Admission', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Programs offered', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8), Wrap(spacing: 7, runSpacing: 7, children: institute.programs.map((p) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(18)), child: Text(p, style: const TextStyle(color: darkGreen, fontWeight: FontWeight.w600)))).toList()), const SizedBox(height: 12), const Text('Admission dates and application details will be shown here when the institute provides updated information.', style: TextStyle(color: Colors.black54, height: 1.4))])),
        const SizedBox(height: 12),
        _section('Facilities', const Column(children: [_Facility(Icons.local_library_outlined, 'Library'), _Facility(Icons.computer_outlined, 'Computer / IT Labs'), _Facility(Icons.sports_soccer_outlined, 'Sports Facilities'), _Facility(Icons.wifi_rounded, 'Internet / Wi-Fi')])),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseService.initialized ? FirebaseFirestore.instance.collection('instituteClaims').where('instituteId', isEqualTo: institute.id).where('status', isEqualTo: 'pending').limit(1).snapshots() : const Stream.empty(),
          builder: (context, snap) {
            final pending = snap.data?.docs.isNotEmpty == true;
            final signedIn = FirebaseService.initialized && FirebaseAuth.instance.currentUser != null;
            return Card(child: ListTile(leading: Icon(pending ? Icons.hourglass_top : Icons.business_outlined, color: green), title: Text(pending ? 'Claim under review' : 'Institute profile'), subtitle: Text(pending ? 'A representative has submitted a claim for admin verification.' : 'Want to manage this institute? Claim this profile.'), trailing: pending ? null : FilledButton(onPressed: signedIn ? () => context.push('/institute/${institute.id}/claim?name=${Uri.encodeComponent(institute.name)}') : () => context.push('/signin'), style: FilledButton.styleFrom(backgroundColor: green), child: Text(signedIn ? 'Claim' : 'Sign In'))));
          },
        ),
      ]),
    );
  }

  static Widget _section(String title, Widget child) => Card(margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: darkGreen)), const SizedBox(height: 10), child])));
  static Widget _info(IconData icon, String title, String value) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.info_outline, color: green), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(value));
}

class _Facility extends StatelessWidget {
  final IconData icon;
  final String title;
  const _Facility(this.icon, this.title);
  @override Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, color: InstituteDetailScreen.green), title: Text(title));
}
