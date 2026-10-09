import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final demo = ActiveProfileController.instance.isDemo;
    final activeUid = ActiveProfileController.instance.effectiveUid ?? '';

    // Demo identity and its notifications must work without Firebase auth.
    if (demo) {
      return Scaffold(
        appBar: AppBar(title: Text('${ActiveProfileController.instance.effectiveName} • Notifications')),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: db.demoNotificationsStream(activeUid),
          builder: (context, snapshot) => _demoList(
            context, snapshot.data ?? const [], db, activeUid,
          ),
        ),
      );
    }

    final real = FirebaseAuth.instance.currentUser;
    if (!FirebaseService.initialized || real == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Sign in to view notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder(
        stream: db.notificationsStream(real.uid),
        builder: (context, AsyncSnapshot snapshot) {
          final docs = snapshot.data?.docs ?? [];
          return _firebaseList(context, docs, db, real.uid);
        },
      ),
    );
  }

  Widget _demoList(
    BuildContext context,
    List<Map<String, dynamic>> docs,
    DatabaseService db,
    String uid,
  ) {
    if (docs.isEmpty) return const Center(child: Text('No notifications yet.'));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = docs[index];
        return _notificationTile(
          context,
          item,
          onTap: () => _openNotification(
            context, item, db, uid, item['id']?.toString() ?? '',
          ),
        );
      },
    );
  }

  Widget _firebaseList(BuildContext context, List docs, DatabaseService db, String uid) {
    if (docs.isEmpty) return const Center(child: Text('No notifications yet.'));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final item = Map<String, dynamic>.from(doc.data() as Map);
        return _notificationTile(
          context,
          item,
          onTap: () => _openNotification(context, item, db, uid, doc.id),
        );
      },
    );
  }

  Widget _notificationTile(
    BuildContext context,
    Map<String, dynamic> item, {
    required VoidCallback onTap,
  }) {
    final read = item['read'] == true;
    return Card(
      color: read ? null : AppColors.softGreen,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.softGreen,
          child: Icon(Icons.notifications_none, color: AppColors.darkGreen),
        ),
        title: Text(
          item['text']?.toString() ?? 'Activity',
          style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.w700),
        ),
        subtitle: Text(read ? 'Read' : 'New notification'),
        onTap: onTap,
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    Map<String, dynamic> item,
    DatabaseService db,
    String uid,
    String id,
  ) async {
    if (id.isNotEmpty) {
      await db.markNotificationRead(uid, id);
    }
    if (!context.mounted) return;
    final postId = (item['postId'] ?? '').toString();
    final instituteId = (item['instituteId'] ?? '').toString();
    if (postId.isNotEmpty) {
      context.push('/community/post/$postId');
    } else if (instituteId.isNotEmpty) {
      context.push('/institute/$instituteId/opportunities');
    }
  }
}
