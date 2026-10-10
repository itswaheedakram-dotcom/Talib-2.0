import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/demo_data_service.dart';
import '../../../../app/theme.dart';
import '../widgets/student_affiliation_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const green = AppColors.primaryGreen, darkGreen = AppColors.darkGreen, lightGreen = AppColors.softGreen;
  final name = TextEditingController(), level = TextEditingController(), institute = TextEditingController(), program = TextEditingController(), city = TextEditingController();
  bool loading = false, saving = false;
  User? get user => FirebaseService.initialized ? FirebaseAuth.instance.currentUser : null;

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
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save profile: $error')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override void dispose() { for (final c in [name, level, institute, program, city]) c.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final active = ActiveProfileController.instance.active;
    if (active != null) {
      return AnimatedBuilder(
        animation: ActiveProfileController.instance,
        builder: (context, _) {
          final p = ActiveProfileController.instance.active!;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              actions: [
                IconButton(
                  tooltip: 'Exit test profile',
                  onPressed: () => ActiveProfileController.instance.clear(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: lightGreen, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: green,
                      child: Text(p.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(p.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: darkGreen))),
                        const Icon(Icons.verified, color: green),
                      ]),
                      if (p.username.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('@${p.username}', style: const TextStyle(color: green, fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 4),
                      Text(p.city, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 7),
                      const Text('Active temporary test profile', style: TextStyle(color: green, fontWeight: FontWeight.w600)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 14),
                _section('Profile Information', Column(children: [
                  _demoInfo(Icons.school_outlined, 'Education Level', p.level),
                  _demoInfo(Icons.menu_book_outlined, 'Program / Degree', p.program),
                  _demoInfo(Icons.location_on_outlined, 'City', p.city),
                ])),
                const SizedBox(height: 12),
                StudentAffiliationCard(uid: p.id, editable: true),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: DemoDataService.instance,
                  builder: (context, _) {
                    final reviews = DemoDataService.instance.reviews(p.id);
                    var sum = 0;
                    for (final review in reviews) {
                      sum += (review['rating'] as num?)?.toInt() ?? 0;
                    }
                    final average = reviews.isEmpty ? 0.0 : sum / reviews.length;
                    return _section(
                      'My Reputation',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.star_rounded, color: green, size: 28),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              reviews.isEmpty ? 'No reviews yet' : '${average.toStringAsFixed(1)} / 5',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkGreen),
                            )),
                            Text('${reviews.length} reviews'),
                          ]),
                          const SizedBox(height: 8),
                          Text('${DemoDataService.instance.followerCount(p.id)} followers'),
                          if (reviews.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...reviews.map((review) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: lightGreen,
                                child: Text(((review['reviewerName'] ?? 'S').toString().isEmpty ? 'S' : (review['reviewerName'] ?? 'S').toString()[0]).toUpperCase()),
                              ),
                              title: Text((review['reviewerName'] ?? 'Student').toString()),
                              subtitle: Text((review['text'] ?? '').toString()),
                              trailing: Text('${review['rating'] ?? 0}/5'),
                            )),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _section('My Activity', _action(Icons.article_outlined, 'My Posts', 'View posts created by ${p.name}', () => context.push('/community?authorId=${Uri.encodeComponent(p.id)}'))),
                const SizedBox(height: 12),
                _section('Test Mode', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('The app is currently using this temporary profile for profile-related testing.'),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => context.push('/temporary-profiles'),
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Switch Test Profile'),
                  ),
                ])),
              ],
            ),
          );
        },
      );
    }
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
      if (u != null) StudentAffiliationCard(uid: u.uid, editable: true),
      if (u != null) const SizedBox(height: 12),
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
          'Community Reputation',
          FutureBuilder<Map<String,dynamic>>(
            future: DatabaseService().reputation(u.uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
              final d=snap.data??{};
              final badges=List<String>.from(d['badges']??const []);
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                Row(children:[
                  const Icon(Icons.emoji_events_outlined, color: green, size: 30),
                  const SizedBox(width:10),
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text('${d['score']??0} Reputation',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:darkGreen)),
                    Text('${d['posts']??0} posts • ${d['comments']??0} comments • ${d['likes']??0} likes',style:const TextStyle(color:Colors.black54)),
                  ])),
                ]),
                const SizedBox(height:10),
                if(badges.isEmpty) const Text('Keep helping the community to unlock badges.',style:TextStyle(color:Colors.black54)),
                if(badges.isNotEmpty) Wrap(spacing:6,runSpacing:6,children:badges.map((b)=>Chip(avatar:const Icon(Icons.military_tech_outlined,size:16),label:Text(b))).toList()),
              ]);
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
                () => context.push('/community?authorId=${Uri.encodeComponent(u.uid)}'),
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

  static Widget _demoInfo(IconData icon, String label, String value) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.circle, size: 8, color: green), title: Text(value), subtitle: Text(label));

  static Widget _field(TextEditingController c, String label, IconData icon) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: green))));

  static Widget _action(IconData icon, String title, String sub, VoidCallback tap) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, color: green), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(sub), trailing: const Icon(Icons.chevron_right), onTap: tap);
}
