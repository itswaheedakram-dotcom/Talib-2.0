import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/models/post.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String name) => _db.collection(name);

  Stream<List<Post>> postsStream({bool popular = false}) => _db
      .collection('posts')
      .orderBy(popular ? 'likesCount' : 'createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Post.fromDoc).toList());

  Future<String> createPost({required String text, required String authorId, required String authorName}) async {
    final ref = await _db.collection('posts').add({
      'text': text.trim(), 'authorId': authorId, 'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(), 'likesCount': 0,
      'likedBy': <String>[], 'commentsCount': 0,
    });
    return ref.id;
  }

  Future<void> deletePost(String postId) => _db.collection('posts').doc(postId).delete();

  Future<void> toggleLike(Post post, String uid) async {
    final ref = _db.collection('posts').doc(post.id);
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};
      final likedBy = List<String>.from(data['likedBy'] ?? const []);
      if (likedBy.contains(uid)) {
        likedBy.remove(uid);
      } else {
        likedBy.add(uid);
      }
      tx.update(ref, {'likedBy': likedBy, 'likesCount': likedBy.length});
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(String postId) => _db
      .collection('posts').doc(postId).collection('comments')
      .orderBy('createdAt', descending: false).snapshots();

  Future<void> addComment({required String postId, required String text, required String authorId, required String authorName}) async {
    final postRef = _db.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc();
    await _db.runTransaction((tx) async {
      tx.set(commentRef, {
        'text': text.trim(), 'authorId': authorId, 'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(postRef, {'commentsCount': FieldValue.increment(1)});
    });
  }

  Future<void> toggleBookmark(String postId, String uid, bool save) async {
    final ref = _db.collection('users').doc(uid).collection('bookmarks').doc(postId);
    if (save) {
      await ref.set({'postId': postId, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  Stream<Set<String>> bookmarkIdsStream(String uid) => _db
      .collection('users').doc(uid).collection('bookmarks').snapshots()
      .map((s) => s.docs.map((d) => d.id).toSet());
}
