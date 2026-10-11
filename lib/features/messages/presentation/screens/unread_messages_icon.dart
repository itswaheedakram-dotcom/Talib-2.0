import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/active_profile_controller.dart';

Stream<int> unreadMessageCount(String uid) => Stream<int>.multi((controller) {
  final subscriptions = <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
  final counts = <String, int>{};
  final conversations = FirebaseFirestore.instance.collection('conversations')
      .where('participants', arrayContains: uid).snapshots().listen((snapshot) {
    final ids = snapshot.docs.map((doc) => doc.id).toSet();
    for (final id in subscriptions.keys.toList()) {
      if (!ids.contains(id)) { subscriptions.remove(id)?.cancel(); counts.remove(id); }
    }
    for (final id in ids) {
      subscriptions.putIfAbsent(id, () => FirebaseFirestore.instance
          .collection('conversations').doc(id).collection('messages')
          .where('receiverId', isEqualTo: uid).where('read', isEqualTo: false)
          .snapshots().listen((messages) {
        counts[id] = messages.size;
        controller.add(counts.values.fold<int>(0, (a, b) => a + b));
      }, onError: (Object error) {
        counts.remove(id);
        controller.add(counts.values.fold<int>(0, (a, b) => a + b));
      }));
    }
    controller.add(counts.values.fold<int>(0, (a, b) => a + b));
  }, onError: controller.addError);
  controller.onCancel = () async {
    await conversations.cancel();
    for (final subscription in subscriptions.values) { await subscription.cancel(); }
  };
});

class UnreadMessagesIcon extends StatelessWidget {
  final bool selected;
  const UnreadMessagesIcon({super.key, this.selected = false});
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: ActiveProfileController.instance,
    builder: (context, _) {
      final icon = Icon(selected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded);
      if (ActiveProfileController.instance.isDemo) return icon;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return icon;
      return StreamBuilder<int>(stream: unreadMessageCount(uid), builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Badge(isLabelVisible: count > 0, label: Text(count > 99 ? '99+' : count.toString()), child: icon);
      });
    },
  );
}
