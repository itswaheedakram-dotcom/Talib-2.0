import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String text;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int likesCount;
  final List<String> likedBy;
  final int commentsCount;

  const Post({required this.id, required this.text, required this.authorId, required this.authorName, required this.createdAt, this.likesCount = 0, this.likedBy = const [], this.commentsCount = 0});

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawDate = data['createdAt'];
    return Post(
      id: doc.id,
      text: (data['text'] ?? '').toString(),
      authorId: (data['authorId'] ?? '').toString(),
      authorName: (data['authorName'] ?? 'Student').toString(),
      createdAt: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      likesCount: (data['likesCount'] ?? 0) as int,
      likedBy: List<String>.from(data['likedBy'] ?? const []),
      commentsCount: (data['commentsCount'] ?? 0) as int,
    );
  }

  bool likedByUser(String? uid) => uid != null && likedBy.contains(uid);
}
