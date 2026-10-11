import '../../../../core/widgets/user_identity.dart';
import '../../../../core/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/demo_data_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../groups/presentation/screens/groups_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int retry = 0;
  final db = DatabaseService();

  String _time(dynamic value) {
    final date = value is Timestamp ? value.toDate() : value is DateTime ? value : null;
    if (date == null) return '';
    return date.hour.toString().padLeft(2, '0') + ':' + date.minute.toString().padLeft(2, '0');
  }

  void _openChat(String id, String uid, String name) {
    context.push('/chat/' + Uri.encodeComponent(id) + '?uid=' +
        Uri.encodeComponent(uid) + '&name=' + Uri.encodeComponent(name));
  }

  Future<void> _startChat(String uid) async {
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .8,
        child: Column(children: [
          const Padding(padding: EdgeInsets.all(20), child: Column(children: [
            Text('Start a chat', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('You can message people when you both follow each other.',
                textAlign: TextAlign.center),
          ])),
          Expanded(child: StreamBuilder<Set<String>>(
            stream: db.followingIdsStream(uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) return _state(Icons.error_outline,
                  'Contacts unavailable', 'Close this panel and try again.');
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final ids = snapshot.data!.where((id) => id != uid).toList()..sort();
              if (ids.isEmpty) return _state(Icons.people_outline,
                  'Follow people to connect',
                  'Find students in Community and follow them. They need to follow you back.',
                  action: () { Navigator.pop(sheetContext); this.context.push('/community'); },
                  label: 'Find people');
              return ListView(children: [
                for (final id in ids) StreamBuilder<bool>(
                  stream: db.mutualFollowStream(uid, id),
                  builder: (context, mutual) {
                    if (mutual.hasError) return const ListTile(title: Text('Unable to check a contact'));
                    if (!mutual.hasData) return const ListTile(title: LinearProgressIndicator());
                    return _contact(sheetContext, uid, id, mutual.data!);
                  },
                ),
                TextButton(onPressed: () {
                  Navigator.pop(sheetContext); this.context.push('/community');
                }, child: const Text('Find more people')),
              ]);
            },
          )),
        ]),
      ),
    );
  }

  Widget _contact(BuildContext sheetContext, String uid, String other, bool eligible) {
    final identity = ActiveProfileController.instance;
    if (identity.isDemo) {
      return _contactTile(sheetContext, uid, other, identity.profileById(other).name, eligible);
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(other).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const ListTile(title: Text('Profile unavailable'));
        if (!snapshot.hasData) return const ListTile(title: LinearProgressIndicator());
        final name = (snapshot.data!.data()?[ProfileFields.name] ?? 'Student').toString();
        return _contactTile(sheetContext, uid, other, name, eligible);
      },
    );
  }

  Widget _contactTile(BuildContext sheetContext, String uid, String other,
      String name, bool eligible) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: UserIdentity(uid: other, name: name),
      subtitle: Text(eligible ? 'You follow each other' : 'Waiting for them to follow you back'),
      trailing: eligible ? const Icon(Icons.chat_bubble_outline) : const Icon(Icons.hourglass_empty),
      onTap: () {
        Navigator.pop(sheetContext);
        if (!eligible) {
          context.push('/profile/' + Uri.encodeComponent(other));
          return;
        }
        final ids = [uid, other]..sort();
        _openChat(ActiveProfileController.instance.isDemo ? ids.join('|') :
            db.conversationId(uid, other), other, name);
      },
    );
  }

  Widget _state(IconData icon, String title, String detail,
      {VoidCallback? action, String label = 'Start chat'}) {
    return Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(detail, textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(.7))),
        if (action != null) ...[
          const SizedBox(height: 24),
          FilledButton(onPressed: action, child: Text(label)),
        ],
      ]),
    ));
  }

  Widget _list(List<Map<String, dynamic>> items, String uid) {
    if (items.isEmpty) return _state(Icons.chat_bubble_outline, 'No chats yet',
        'Start a conversation with someone who follows you back.',
        action: () => _startChat(uid));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final other = item['otherUid'].toString();
        final name = item['otherName'].toString();
        final last = (item['lastMessage'] ?? '').toString();
        return ListTile(
          leading: CircleAvatar(child: Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase())),
          title: UserIdentity(uid: other, name: name),
          subtitle: Text(last.isEmpty ? 'Say hello' : last, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(_time(item['updatedAt']), style: const TextStyle(fontSize: 12)),
          onTap: () => _openChat(item['id'].toString(), other, name),
        );
      },
    );
  }

  Widget _chats(String uid, bool demo) {
    if (demo) return StreamBuilder<void>(
      stream: DemoDataService.instance.changes,
      builder: (_, __) => _list(DemoDataService.instance.conversations(uid), uid),
    );
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey(uid + '-' + retry.toString()),
      stream: FirebaseFirestore.instance.collection('conversations')
          .where('participants', arrayContains: uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _state(Icons.error_outline, 'Messages unavailable',
            'Check your connection and try again.',
            action: () => setState(() => retry++), label: 'Retry');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final at = a.data()['updatedAt'], bt = b.data()['updatedAt'];
          return at is Timestamp && bt is Timestamp ? bt.compareTo(at) : 0;
        });
        final items = <Map<String, dynamic>>[];
        for (final doc in docs) {
          final data = doc.data();
          final participants = List<String>.from(data['participants'] ?? const []);
          final other = participants.firstWhere((id) => id != uid, orElse: () => '');
          if (other.isEmpty) continue;
          final names = Map<String, dynamic>.from(data['participantNames'] ?? {});
          items.add({...data, 'id': doc.id, 'otherUid': other,
            'otherName': names[other] ?? 'Student'});
        }
        return _list(items, uid);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActiveProfileController.instance,
      builder: (context, _) {
        final identity = ActiveProfileController.instance;
        final uid = identity.isDemo ? identity.effectiveUid : FirebaseAuth.instance.currentUser?.uid;
        final theme = Theme.of(context);
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('Messages'),
              systemOverlayStyle: SystemUiOverlayStyle.light,
              bottom: const TabBar(
                labelColor: Colors.white, unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [Tab(text: 'Chats', icon: Icon(Icons.chat_bubble_outline)),
                  Tab(text: 'Study Groups', icon: Icon(Icons.groups_outlined))],
              ),
            ),
            body: uid == null
                ? _state(Icons.lock_outline, 'Sign in to connect',
                    'Sign in to start chats and join study groups.',
                    action: () => context.push('/signin'), label: 'Sign in')
                : TabBarView(children: [
                    Scaffold(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      body: Column(children: [
                        if (identity.isDemo) Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('Test profile: ' + (identity.effectiveName ?? 'Student')),
                        ),
                        Expanded(child: _chats(uid, identity.isDemo)),
                      ]),
                      floatingActionButton: FloatingActionButton.extended(
                        onPressed: () => _startChat(uid),
                        icon: const Icon(Icons.edit_outlined), label: const Text('Start chat'),
                      ),
                    ),
                    const GroupsScreen(embedded: true),
                  ]),
          ),
        );
      },
    );
  }
}
