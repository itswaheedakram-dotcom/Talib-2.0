import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/services/database_service.dart';
import '../../models/post.dart';

class CommunityPreferences extends ChangeNotifier {
  final String uid;
  final bool demo;
  final Map<String, String> hidden = {}, muted = {}, blocked = {};
  final Set<String> saved = {}, following = {}, topics = {}, institutes = {};
  final List<StreamSubscription> _subscriptions = [];
  static final Map<String, Map<String, String>> _demoHidden = {},
      _demoMuted = {},
      _demoBlocked = {};
  bool _disposed = false;
  String? error;
  bool followingReady = false;
  CommunityPreferences({required this.uid, required this.demo});
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void start() {
    if (uid.isEmpty) {
      followingReady = true;
      return;
    }
    final db = DatabaseService();
    _subscriptions.add(
      db.bookmarkIdsStream(uid).listen((v) {
        saved
          ..clear()
          ..addAll(v);
        _emit();
      }, onError: _failed),
    );
    _subscriptions.add(
      db.followingIdsStream(uid).listen((v) {
        followingReady = true;
        following
          ..clear()
          ..addAll(v);
        _emit();
      }, onError: _failed),
    );
    _subscriptions.add(
      db.timelineTopicsStream(uid).listen((v) {
        topics
          ..clear()
          ..addAll(v);
        _emit();
      }, onError: _failed),
    );
    _subscriptions.add(
      db.timelineInstitutesStream(uid).listen((v) {
        institutes
          ..clear()
          ..addAll(v);
        _emit();
      }, onError: _failed),
    );
    if (demo) {
      hidden.addAll(_demoHidden[uid] ?? {});
      muted.addAll(_demoMuted[uid] ?? {});
      blocked.addAll(_demoBlocked[uid] ?? {});
      _emit();
      return;
    }
    for (final entry in {
      'hiddenPosts': hidden,
      'mutedAuthors': muted,
      'blockedUsers': blocked,
    }.entries) {
      _subscriptions.add(
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection(entry.key)
            .snapshots()
            .listen((s) {
              entry.value
                ..clear()
                ..addEntries(
                  s.docs.map(
                    (d) => MapEntry(
                      d.id,
                      (d.data()['title'] ??
                              d.data()['name'] ??
                              'Community member')
                          .toString(),
                    ),
                  ),
                );
              _emit();
            }, onError: _failed),
      );
    }
  }

  void _failed(Object error) {
    this.error = 'Feed preferences could not be loaded. Retry to reconnect.';
    _emit();
  }

  bool allows(Post p) =>
      !hidden.containsKey(p.id) &&
      !muted.containsKey(p.authorId) &&
      !blocked.containsKey(p.authorId);
  Future<void> hide(Post post, {String reason = 'hide'}) async {
    if (demo) {
      (_demoHidden[uid] ??= {})[post.id] = post.text;
      hidden[post.id] = post.text;
      _emit();
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('hiddenPosts')
        .doc(post.id)
        .set({
          'postId': post.id,
          'title': post.text.length > 140
              ? post.text.substring(0, 140)
              : post.text,
          'reason': reason,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> mute(Post post) async {
    if (demo) {
      (_demoMuted[uid] ??= {})[post.authorId] = post.authorName;
      muted[post.authorId] = post.authorName;
      _emit();
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mutedAuthors')
        .doc(post.authorId)
        .set({
          'authorId': post.authorId,
          'name': post.authorName,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> block(Post post) async {
    if (demo) {
      DemoDataService.instance.setCommunityBlock(uid, post.authorId, true);
      (_demoBlocked[uid] ??= {})[post.authorId] = post.authorName;
      blocked[post.authorId] = post.authorName;
      DemoDataService.instance.toggleFollow(uid, post.authorId, false);
      DemoDataService.instance.toggleFollow(post.authorId, uid, false);
      _emit();
      return;
    }
    await DatabaseService().blockUser(uid, post.authorId);
  }

  Future<void> restore(String collection, String id) async {
    if (demo) {
      if (collection == 'hiddenPosts') {
        hidden.remove(id);
        _demoHidden[uid]?.remove(id);
      }
      if (collection == 'mutedAuthors') {
        muted.remove(id);
        _demoMuted[uid]?.remove(id);
      }
      if (collection == 'blockedUsers') {
        DemoDataService.instance.setCommunityBlock(uid, id, false);
        blocked.remove(id);
        _demoBlocked[uid]?.remove(id);
      }
      _emit();
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(collection)
        .doc(id)
        .delete();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
