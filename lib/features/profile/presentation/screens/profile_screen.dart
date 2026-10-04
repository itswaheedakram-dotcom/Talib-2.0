import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const green = Color(0xFF00A66A), darkGreen = Color(0xFF00543D), lightGreen = Color(0xFFEAF8F2);
  final name = TextEditingController(), level = TextEditingController(), institute = TextEditingController(), program = TextEditingController(), city = TextEditingController();
  bool loading = true, saving = false;
  User? get user => FirebaseAuth.instance.currentUser;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final u = user;
    if (u == null) { if (mounted) setState(() => loading = false); return; }
    name.text = u.displayName ?? '';
    if (FirebaseService.initialized) {
      final d = (await FirebaseFirestore.instance.collection('users').doc(u.uid).get()).data() ?? {};
      name.text = (d['name'] ?? name.text).toString();
      level.text = (d['educationLevel'] ?? '').toString();
      institute.text = (d['institute'] ?? '').toString();
      program.text = (d['program'] ?? '').toString();
      city.text = (d['city'] ?? '').toString();
    }
    if (mounted) setState(() => loading = false);
  }
  Future<void> _save() async {
    final u = user;
    if (u == null || !FirebaseService.initialized) return;
    setState(() => saving = true);
    await FirebaseFirestore.instance.collection('users').doc(u.uid).set({'name': name.text.trim(), 'email': u.email ?? '', 'educationLevel': level.text.trim(), 'institute': institute.text.trim(), 'program': program.text.trim(), 'city': city.text.trim(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    await u.updateDisplayName(name.text.trim().isEmpty ? null : name.text.trim());
    if (mounted) { setState(() => saving = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated'))); }
  }
  @override void dispose() { for (final c in [name, level, institute, program, city]) c.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    if (!FirebaseService.initialized) return _message('Profile', 'Profile will be available after Firebase is connected.');
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final u = user;
    if (u == null) return Scaffold(appBar: AppBar(title: const Text('Profile')), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person_outline, size: 70, color: green), const SizedBox(height: 12), const Text('Sign in to create and manage your profile', textAlign: TextAlign.center), const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton(onPressed: () => context.push('/signin'), style: FilledButton.styleFrom(backgroundColor: green), child: const Text('Sign In')))]))));
    final display = name.text.trim().isEmpty ? 'Student' : name.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), actions: [IconButton(onPressed: saving ? null : _save, icon: const Icon(Icons.save_outlined))]),
      body: ListView(padding: const EdgeInsets.fromLTRB(14, 12, 14, 28), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(14)), child: Row(children: [
          CircleAvatar(radius: 38, backgroundColor: green, child: Text(display.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(display, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: darkGreen)), const SizedBox(height: 4), Text(u.email ?? '', style: const TextStyle(color: Colors.black54)), const SizedBox(height: 7), const Text('Student / Community Member', style: TextStyle(color: green, fontWeight: FontWeight.w600))])),
        ])),
        const SizedBox(height: 14),
        _section('Profile Information', Column(children: [_field(name, 'Name', Icons.person_outline), _field(level, 'Education Level', Icons.school_outlined), _field(institute, 'Institute', Icons.account_balance_outlined), _field(program, 'Program / Degree', Icons.menu_book_outlined), _field(city, 'City', Icons.location_on_outlined), const SizedBox(height: 5), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: saving ? null : _save, style: FilledButton.styleFrom(backgroundColor: green), icon: const Icon(Icons.save_outlined), label: Text(saving ? 'Saving...' : 'Save Profile')))])),
        const SizedBox(height: 12),
        _section('My Reputation', StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('users').doc(u.uid).collection('reviews').snapshots(), builder: (context, snap) { final docs = snap.data?.docs ?? []; var sum = 0; for (final d in docs) sum += (d.data()['rating'] as num?)?.toInt() ?? 0; final avg = docs.isEmpty ? 0 : sum / docs.length; return Row(children: [const Icon(Icons.star, color: green, size: 30), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(docs.isEmpty ? 'No reviews yet' : '${avg.toStringAsFixed(1)} / 5', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkGreen)), Text('${docs.length} public reviews', style: const TextStyle(color: Colors.black54))])), const Icon(Icons.verified_outlined, color: green)]); })),
        const SizedBox(height: 12),
        _section('My Activity', Column(children: [_action(Icons.article_outlined, 'My Posts', 'View posts you have created', () => context.push('/community')), _action(Icons.bookmark_outline, 'Saved Items', 'Open saved posts and resources', () => context.push('/bookmarks')), _action(Icons.logout, 'Log Out', 'Sign out of this account', () async { await FirebaseAuth.instance.signOut(); if (mounted) context.go('/'); })])),
      ],
      ),
    );
  }
  Widget _message(String title, String msg) => Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(msg, textAlign: TextAlign.center))));
  static Widget _section(String title, Widget child) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: darkGreen)), const SizedBox(height: 10), child])));
  static Widget _field(TextEditingController c, String label, IconData icon) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: green))));
  static Widget _action(IconData icon, String title, String sub, VoidCallback tap) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, color: green), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(sub), trailing: const Icon(Icons.chevron_right), onTap: tap);
}
