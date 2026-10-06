import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/database_service.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(appBar: AppBar(title: const Text('Blocked users')), body: const Center(child: Text('Please sign in to manage blocked users.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).collection('blockedUsers').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, blockedSnapshot) {
          if (blockedSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (blockedSnapshot.hasError) return const Center(child: Text('Could not load blocked users.'));
          final docs = blockedSnapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          if (docs.isEmpty) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.block_outlined, size: 52, color: AppColors.primaryGreen),
                const SizedBox(height: 12),
                const Text('No blocked users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Users you block will appear here.', textAlign: TextAlign.center),
              ]),
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final blockedId = docs[index].id;
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('users').doc(blockedId).get(),
                builder: (context, userSnapshot) {
                  final data = userSnapshot.data?.data() ?? {};
                  final nameRaw = (data['name'] ?? data['username'] ?? 'User').toString().trim();
                  final name = nameRaw.isEmpty ? 'User' : nameRaw;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.softGreen,
                        child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Blocked'),
                      trailing: TextButton(
                        onPressed: () async {
                          await DatabaseService().unblockUser(uid, blockedId);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User unblocked.')));
                        },
                        child: const Text('Unblock'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
