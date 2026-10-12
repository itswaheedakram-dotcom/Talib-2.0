import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/demo_data_service.dart';
import '../../models/post.dart';

/// Latest page stays live; older pages load on demand. New arrivals are buffered
/// until the reader accepts them, preserving scroll position during reading.
class CommunityFeedController extends ChangeNotifier {
  final bool demo;
  final String uid;
  final int pageSize;
  String sort;
  final Map<String, Post> _posts = {}, _pending = {};
  StreamSubscription? _subscription;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool loading = true, loadingMore = false, hasMore = false;
  String? error;
  bool _initial = false, _disposed = false;
  int _generation = 0, _demoLimit = 20;
  CommunityFeedController({
    required this.demo,
    required this.uid,
    this.sort = 'Latest',
    this.pageSize = 20,
  });
  List<Post> get posts => _posts.values.toList()..sort(_compare);
  int get pendingCount => _pending.length;
  int _compare(Post a, Post b) {
    if (sort == 'Popular') {
      final score = b.reactionsCount.compareTo(a.reactionsCount);
      if (score != 0) return score;
    }
    final date = b.createdAt.compareTo(a.createdAt);
    return date != 0 ? date : b.id.compareTo(a.id);
  }

  Query<Map<String, dynamic>> get _query => FirebaseFirestore.instance
      .collection('posts')
      .orderBy(
        sort == 'Popular' ? 'likesCount' : 'createdAt',
        descending: true,
      );
  void start() {
    final generation = ++_generation;
    _subscription?.cancel();
    loading = true;
    error = null;
    notifyListeners();
    if (demo) {
      _demoLimit = pageSize;
      void emit() {
        if (generation != _generation || _disposed) return;
        final all = DemoDataService.instance.posts()..sort(_compare);
        hasMore = all.length > _demoLimit;
        _posts.removeWhere(
          (id, p) => DemoDataService.instance.post(id) == null,
        );
        _pending.removeWhere(
          (id, p) => DemoDataService.instance.post(id) == null,
        );
        acceptLivePage(all.take(_demoLimit).toList());
      }

      emit();
      _subscription = DemoDataService.instance.changes.listen((_) => emit());
      return;
    }
    if (uid.isEmpty) {
      loading = false;
      error = 'Sign in to browse the community.';
      notifyListeners();
      return;
    }
    _subscription = _query
        .limit(pageSize)
        .snapshots()
        .listen(
          (snapshot) {
            if (generation != _generation || _disposed) return;
            if (!_initial) {
              _cursor = snapshot.docs.lastOrNull;
              hasMore = snapshot.docs.length == pageSize;
            }
            acceptLivePage(snapshot.docs.map(Post.fromDoc).toList());
            // A removal can mean deletion or leaving the live window; verify it rather
            // than discarding an older post which is still visible in the loaded feed.
            for (final change in snapshot.docChanges.where(
              (c) => c.type == DocumentChangeType.removed,
            )) {
              refreshPost(change.doc.id);
            }
          },
          onError: (Object e) {
            if (generation != _generation || _disposed) return;
            loading = false;
            error =
                'Community posts could not be loaded. Check your connection and retry.';
            notifyListeners();
          },
        );
  }

  void acceptLivePage(List<Post> page) {
    if (_disposed) return;
    for (final p in page) {
      if (!_initial || _posts.containsKey(p.id)) {
        _posts[p.id] = p;
      } else {
        _pending[p.id] = p;
      }
    }
    _initial = true;
    loading = false;
    error = null;
    notifyListeners();
  }

  void showNewPosts() {
    _posts.addAll(_pending);
    _pending.clear();
    notifyListeners();
  }

  Future<void> refresh() async {
    _generation++;
    await _subscription?.cancel();
    if (_disposed) return;
    loadingMore = false;
    _posts.clear();
    _pending.clear();
    _cursor = null;
    _initial = false;
    hasMore = false;
    start();
  }

  Future<void> changeSort(String value) async {
    if (value == sort) return;
    sort = value;
    await refresh();
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore || _disposed) return;
    final generation = _generation;
    loadingMore = true;
    error = null;
    notifyListeners();
    try {
      if (demo) {
        _demoLimit += pageSize;
        final all = DemoDataService.instance.posts()..sort(_compare);
        for (final p in all.take(_demoLimit)) {
          if (!_pending.containsKey(p.id)) _posts[p.id] = p;
        }
        hasMore = all.length > _demoLimit;
      } else {
        var query = _query.limit(pageSize);
        if (_cursor != null) query = query.startAfterDocument(_cursor!);
        final snapshot = await query.get();
        if (generation != _generation || _disposed) return;
        for (final doc in snapshot.docs) {
          final p = Post.fromDoc(doc);
          if (!_pending.containsKey(p.id)) _posts[p.id] = p;
        }
        if (snapshot.docs.isNotEmpty) _cursor = snapshot.docs.last;
        hasMore = snapshot.docs.length == pageSize;
      }
    } catch (_) {
      if (generation == _generation)
        error = 'More posts could not be loaded. Please retry.';
    } finally {
      if (generation == _generation && !_disposed) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshPost(String id) async {
    final generation = _generation;
    try {
      Post? post;
      if (demo) {
        post = DemoDataService.instance.post(id);
      } else {
        final doc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(id)
            .get();
        if (doc.exists) post = Post.fromDoc(doc);
      }
      if (_disposed || generation != _generation) return;
      if (post == null) {
        _posts.remove(id);
        _pending.remove(id);
      } else if (_posts.containsKey(id)) {
        _posts[id] = post;
      } else if (_pending.containsKey(id)) {
        _pending[id] = post;
      }
      notifyListeners();
    } catch (_) {
      /* Feed remains usable; the next refresh retries. */
    }
  }

  void remove(String id) {
    _posts.remove(id);
    _pending.remove(id);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }
}
