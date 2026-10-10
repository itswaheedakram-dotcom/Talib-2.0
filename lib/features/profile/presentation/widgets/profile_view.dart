import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/user_profile_repository.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/demo_data_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/widgets/user_identity.dart';
import 'profile_editor.dart';
import 'student_affiliation_card.dart';

class ProfileView extends StatefulWidget {
  final String uid;
  final bool publicView;
  const ProfileView({super.key, required this.uid, this.publicView = false});
  @override State<ProfileView> createState() => _ProfileViewState();
}
class _ProfileViewState extends State<ProfileView> {
  late Stream<UserProfile> profileStream;
  final repo = UserProfileRepository.instance;
  @override void initState() { super.initState(); profileStream = repo.watch(widget.uid); }
  @override void didUpdateWidget(ProfileView oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.uid != widget.uid) profileStream = repo.watch(widget.uid); }
  Widget _card(String title, List<Widget> children) => Card(child: Padding(padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12), ...children,
    ])));
  Future<void> _edit(UserProfile profile) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ProfileEditor(profile: profile)));
    if (saved == true && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }
  Future<void> _copy(UserProfile profile) async {
    final route = '/profile/${Uri.encodeComponent(profile.uid)}';
    final value = Uri.base.scheme.startsWith('http') ? Uri.base.resolve('/#$route').toString() : 'Talib profile — ${profile.name}\nUID: ${profile.uid}';
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile details copied')));
  }
  Future<void> _review(UserProfile target) async {
    final uid = repo.currentUid;
    if (uid == null || uid == target.uid) return;
    if (repo.isDemo(uid) != repo.isDemo(target.uid)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo users can review demo users only.'))); return;
    }
    var stars = 5;
    final text = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (_, setDialog) => AlertDialog(
      title: Text('Review ${target.name}'), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Wrap(children: List.generate(5, (i) => IconButton(onPressed: () => setDialog(() => stars = i + 1), icon: Icon(i < stars ? Icons.star : Icons.star_border)))),
        TextField(controller: text, maxLength: 300, maxLines: 3, decoration: const InputDecoration(labelText: 'How did this person help you?')),
      ])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: () { if (text.text.trim().isNotEmpty) Navigator.pop(dialogContext, true); }, child: const Text('Publish'))],
    )));
    if (result == true) {
      try {
        final name = repo.isDemo(uid) ? repo.demoProfile(uid).name : FirebaseAuth.instance.currentUser?.displayName ?? 'Student';
        if (repo.isDemo(uid)) {
          await DatabaseService().addDemoReview(target.uid, uid, name, stars, text.text.trim());
        } else {
          await FirebaseFirestore.instance.collection('users').doc(target.uid).collection('reviews').doc(uid).set({
            ProfileFields.reviewerId: uid, 'reviewerName': name, 'rating': stars, 'text': text.text.trim(), 'createdAt': FieldValue.serverTimestamp(),
          });
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review published')));
      } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not publish review. Please retry.'))); }
    }
    await Future<void>.delayed(const Duration(milliseconds: 300)); text.dispose();
  }
  Widget _reviews(UserProfile profile, bool owner) {
    final demo = repo.isDemo(profile.uid);
    final stream = demo ? Stream<List<Map<String, dynamic>>>.multi((controller) {
      controller.add(DemoDataService.instance.reviews(profile.uid));
      final sub = DemoDataService.instance.changes.listen((_) => controller.add(DemoDataService.instance.reviews(profile.uid)));
      controller.onCancel = sub.cancel;
    }) : FirebaseFirestore.instance.collection('users').doc(profile.uid).collection('reviews').orderBy('createdAt', descending: true).snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());
    return StreamBuilder<List<Map<String, dynamic>>>(stream: stream, builder: (context, snapshot) {
      if (snapshot.hasError) return _card('Community reviews', [const Text('Could not load reviews. Try again later.')]);
      final reviews = snapshot.data ?? const [];
      final average = reviews.isEmpty ? 0.0 : reviews.fold<double>(0, (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 0)) / reviews.length;
      return _card('Community reviews', [
        Text(reviews.isEmpty ? 'No reviews yet.' : '${average.toStringAsFixed(1)} / 5 • ${reviews.length} reviews'),
        if (!owner && repo.currentUid != null) TextButton.icon(onPressed: () => _review(profile), icon: const Icon(Icons.rate_review_outlined), label: const Text('Rate & Comment')),
        ...reviews.map((r) => ListTile(contentPadding: EdgeInsets.zero,
          title: UserIdentity(uid: (r[ProfileFields.reviewerId] ?? '').toString(), name: (r['reviewerName'] ?? 'Student').toString()),
          subtitle: Text((r['text'] ?? '').toString()), trailing: Text('${r['rating'] ?? 0}/5'))),
      ]);
    });
  }
  Future<void> _moderate(UserProfile profile, String action) async {
    final uid = repo.currentUid;
    if (uid == null || repo.isDemo(uid)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use your real account to report or block.'))); return;
    }
    if (action == 'block') {
      final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('Block ${profile.name}?'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Block'))]));
      if (ok == true) { await DatabaseService().blockUser(uid, profile.uid); if (mounted) context.pop(); }
    } else {
      if (!mounted) return;
      final reason = await showDialog<String>(context: context, builder: (dialogContext) => SimpleDialog(title: const Text('Report profile'),
        children: ['Spam', 'Harassment', 'Fake information', 'Scam', 'Other'].map((r) => SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, r), child: Text(r))).toList()));
      if (reason != null) { await DatabaseService().report(reporterId: uid, targetId: profile.uid, targetType: 'user', reason: reason);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted'))); }
    }
  }
  Widget _social(UserProfile profile) {
    final uid = repo.currentUid;
    if (uid == null || uid == profile.uid || repo.isDemo(uid) != repo.isDemo(profile.uid)) return const SizedBox.shrink();
    final demo = repo.isDemo(uid);
    final follow = demo ? Stream<bool>.multi((c) {
      c.add(DemoDataService.instance.isFollowing(uid, profile.uid));
      final sub = DemoDataService.instance.changes.listen((_) => c.add(DemoDataService.instance.isFollowing(uid, profile.uid))); c.onCancel = sub.cancel;
    }) : DatabaseService().followingStream(uid, profile.uid);
    return StreamBuilder<bool>(stream: follow, builder: (context, snapshot) {
      final following = snapshot.data == true;
      final mutual = demo ? Stream.value(DemoDataService.instance.isMutual(uid, profile.uid)) : DatabaseService().mutualFollowStream(uid, profile.uid);
      return Wrap(spacing: 8, runSpacing: 8, children: [
        FilledButton.icon(onPressed: () async {
          if (demo) { DemoDataService.instance.toggleFollow(uid, profile.uid, !following); }
          else { await DatabaseService().toggleFollow(uid, profile.uid, !following); }
        }, icon: Icon(following ? Icons.person_remove_outlined : Icons.person_add_outlined), label: Text(following ? 'Following' : 'Follow')),
        StreamBuilder<bool>(stream: mutual, builder: (_, s) => s.data != true ? const SizedBox.shrink() : OutlinedButton.icon(
          onPressed: () => context.push('/chat/${demo ? ([uid, profile.uid]..sort()).join('|') : DatabaseService().conversationId(uid, profile.uid)}?uid=${profile.uid}&name=${Uri.encodeComponent(profile.name)}'),
          icon: const Icon(Icons.chat_bubble_outline), label: const Text('Message'))),
      ]);
    });
  }
  @override Widget build(BuildContext context) => StreamBuilder<UserProfile>(stream: profileStream, builder: (context, snapshot) {
    final owner = repo.currentUid == widget.uid;
    return Scaffold(appBar: AppBar(title: const Text('Profile'), actions: [
      if (snapshot.hasData) IconButton(tooltip: 'Copy profile details', onPressed: () => _copy(snapshot.data!), icon: const Icon(Icons.share_outlined)),
      if (!owner && snapshot.hasData) PopupMenuButton<String>(onSelected: (a) => _moderate(snapshot.data!, a),
        itemBuilder: (_) => const [PopupMenuItem(value: 'report', child: Text('Report')), PopupMenuItem(value: 'block', child: Text('Block'))]),
    ]), body: snapshot.hasError ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.lock_outline), const SizedBox(height: 12), Text(snapshot.error is FirebaseException && (snapshot.error as FirebaseException).code == 'permission-denied'
        ? 'This profile is private or access is limited.'
        : snapshot.error is StateError ? 'This profile is not available.' : 'Could not load profile. Check your connection and retry.', textAlign: TextAlign.center),
      TextButton(onPressed: () => setState(() => profileStream = repo.watch(widget.uid)), child: const Text('Retry')),
    ]))) : !snapshot.hasData ? const Center(child: CircularProgressIndicator()) : _body(snapshot.data!, owner));
  });
  Widget _body(UserProfile p, bool owner) {
    if (p.privateProfile && !owner) return const Center(child: Text('Private profile'));
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ProfileAvatar(name: p.name, photoUrl: p.photoUrl), const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            if (p.username.isNotEmpty) UserIdLabel(uid: p.username, showLabel: false),
            UserIdLabel(uid: p.uid), Text(p.roleLabel),
            if (p.city.isNotEmpty) Text(p.city),
          ])),
        ]),
        if (p.bio.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 14), child: Text(p.bio)),
        const SizedBox(height: 14),
        if (owner) Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: () => _edit(p), icon: const Icon(Icons.edit_outlined), label: const Text('Edit profile')),
          if (!widget.publicView) OutlinedButton(onPressed: () => context.push('/profile/${p.uid}'), child: const Text('View public profile')),
        ]) else _social(p),
      ]))),
      StudentAffiliationCard(uid: p.uid, editable: owner && !widget.publicView),
      if (p.educationLevel.isNotEmpty || p.semester.isNotEmpty || p.graduationYear.isNotEmpty)
        _card('Education', [
          if (p.educationLevel.isNotEmpty) Text(p.educationLevel),
          if (p.semester.isNotEmpty) Text('Semester / study year: ${p.semester}'),
          if (p.graduationYear.isNotEmpty) Text('Graduation: ${p.graduationYear}'),
        ]),
      if (p.skills.isNotEmpty) _card('Skills & interests', [Wrap(spacing: 6, runSpacing: 6, children: p.skills.map((s) => Chip(label: Text(s))).toList())]),
      if (p.portfolioUrl.isNotEmpty) _card('Projects & portfolio', [TextButton.icon(onPressed: () async {
        final uri = Uri.tryParse(p.portfolioUrl); if (uri != null && ['http', 'https'].contains(uri.scheme)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      }, icon: const Icon(Icons.open_in_new), label: const Text('Open portfolio'))]),
      _card('Community activity', [
        StreamBuilder<int>(stream: repo.isDemo(p.uid) ? Stream.value(DemoDataService.instance.followerCount(p.uid)) : DatabaseService().followerCountStream(p.uid),
          builder: (_, s) => Text('${s.data ?? 0} followers')),
        FutureBuilder<Map<String, dynamic>>(future: repo.isDemo(p.uid)
          ? Future.value(DemoDataService.instance.reputation(p.uid)) : DatabaseService().reputation(p.uid),
          builder: (_, s) {
            if (s.hasError) return const Text('Reputation could not be loaded.');
            if (!s.hasData) return const LinearProgressIndicator();
            final data = s.data!;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${data['score'] ?? 0} reputation • ${data['posts'] ?? 0} posts • ${data['comments'] ?? 0} comments'),
              Wrap(spacing: 6, runSpacing: 6, children: List<String>.from(data['badges'] ?? const [])
                .map((badge) => Chip(avatar: const Icon(Icons.emoji_events_outlined, size: 16), label: Text(badge))).toList()),
            ]);
          }),
        TextButton.icon(onPressed: () => context.push('/community?authorId=${Uri.encodeComponent(p.uid)}'), icon: const Icon(Icons.article_outlined), label: Text(owner ? 'My posts' : 'View posts')),
        if (owner) TextButton.icon(onPressed: () => context.push('/bookmarks'), icon: const Icon(Icons.bookmark_outline), label: const Text('Saved items')),
      ]),
      _reviews(p, owner),
      if (owner) _card('Account', [
        TextButton.icon(onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings_outlined), label: const Text('Privacy & settings')),
        if (repo.isDemo(p.uid)) ...[
          const Text('Demo changes stay in this test session.'),
          TextButton(onPressed: () => context.push('/temporary-profiles'), child: const Text('Switch test profile')),
          TextButton(onPressed: () { ActiveProfileController.instance.clear(); context.go('/profile'); }, child: const Text('Exit test profile')),
        ],
      ]),
      if (!owner && repo.isDemo(p.uid)) OutlinedButton(onPressed: () {
        ActiveProfileController.instance.activate(ActiveProfileController.instance.profileById(p.uid)); context.push('/profile');
      }, child: const Text('Activate This Profile')),
    ]);
  }
}
