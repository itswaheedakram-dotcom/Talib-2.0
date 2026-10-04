import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const green = Color(0xFF00A66A), darkGreen = Color(0xFF00543D), lightGreen = Color(0xFFEAF8F2);
  final name = TextEditingController(), level = TextEditingController(), institute = TextEditingController(), program = TextEditingController(), city = TextEditingController();
  bool loading = false, saving = false;
  User? get user => FirebaseAuth.instance.currentUser;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final u = user;
    if (u == null) return;

    // Show the profile UI immediately. Firestore must never block the screen.
    if (mounted) setState(() => loading = false);
    name.text = u.displayName ?? '';

    try {
      final d = (await FirebaseFirestore.instance.collection('users').doc(u.uid).get()).data() ?? {};
      if (!mounted) return;
      name.text = (d['name'] ?? name.text).toString();
      level.text = (d['educationLevel'] ?? '').toString();
      institute.text = (d['institute'] ?? '').toString();
      program.text = (d['program'] ?? '').toString();
      city.text = (d['city'] ?? '').toString();
      setState(() {});
    } catch (_) {
      // Keep the profile usable even when Firebase/Firestore is unavailable.
    }
  }

  Future<void> _save() async {
    final u = user;
    if (u == null) return;
    if (mounted) setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
        'name': name.text.trim(),
        'email': u.email ?? '',
        'educationLevel': level.text.trim(),
        'institute': institute.text.trim(),
        'program': program.text.trim(),
        'city': city.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await u.updateDisplayName(name.text.trim().isEmpty ? null : name.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save profile. Please try again.')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override void dispose() { for (final c in [name, level, institute, program, city]) c.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final u = user;
    final display = name.text.trim().isEmpty ? 'Student' : name.text.trim();

    final sections = <Widget>[
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: lightGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: green,
              child: Text(
                display.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    display,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    u?.email ?? 'Basic student profile',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Student / Community Member',
                    style: TextStyle(
                      color: green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _section(
        'Profile Information',
        Column(
          children: [
            _field(name, 'Name', Icons.person_outline),
            _field(level, 'Education Level', Icons.school_outlined),
            _field(institute, 'Institute', Icons.account_balance_outlined),
            _field(program, 'Program / Degree', Icons.menu_book_outlined),
            _field(city, 'City', Icons.location_on_outlined),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: u == null ? () => context.push('/signin') : (saving ? null : _save),
                style: FilledButton.styleFrom(backgroundColor: green),
                icon: Icon(u == null ? Icons.login : Icons.save_outlined),
                label: Text(u == null ? 'Sign In to Save Profile' : (saving ? 'Saving...' : 'Save Profile')),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
    ];

    if (u != null) {
      sections.add(
        _section(
          'My Reputation',
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(u.uid)
                .collection('reviews')
                .snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              var sum = 0;
              for (final d in docs) {
                sum += (d.data()['rating'] as num?)?.toInt() ?? 0;
              }
              final avg = docs.isEmpty ? 0.0 : sum / docs.length;
              return Row(
                children: [
                  const Icon(Icons.star, color: green, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          docs.isEmpty ? 'No reviews yet' : avg.toStringAsFixed(1) + ' / 5',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkGreen,
                          ),
                        ),
                        Text(
                          docs.length.toString() + ' public reviews',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_outlined, color: green),
                ],
              );
            },
          ),
        ),
      );
      sections.add(const SizedBox(height: 12));
      sections.add(
        _section(
          'My Activity',
          Column(
            children: [
              _action(
                Icons.article_outlined,
                'My Posts',
                'View posts you have created',
                () => context.push('/community'),
              ),
              _action(
                Icons.bookmark_outline,
                'Saved Items',
                'Open saved posts and resources',
                () => context.push('/bookmarks'),
              ),
              _action(
                Icons.logout,
                'Log Out',
                'Sign out of this account',
                () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) context.go('/');
                },
              ),
            ],
          ),
        ),
      );
    } else {
      sections.add(
        _section(
          'Account',
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.login, color: green),
            title: const Text(
              'Sign In',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Sign in to save and sync your profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/signin'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (u != null)
            IconButton(
              onPressed: saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: sections,
      ),
    );
  }

  static Widget _section(String title, Widget child) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: darkGreen)),
    const SizedBox(height: 10),
    child
  ])));

  static Widget _field(TextEditingController c, String label, IconData icon) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: green))));

  static Widget _action(IconData icon, String title, String sub, VoidCallback tap) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, color: green), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(sub), trailing: const Icon(Icons.chevron_right), onTap: tap);
}
