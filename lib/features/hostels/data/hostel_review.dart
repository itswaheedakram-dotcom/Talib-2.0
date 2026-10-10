import '../../../core/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostelReview {
  final String id;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  const HostelReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory HostelReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['createdAt'];
    return HostelReview(
      id: doc.id,
      userId: (data[ProfileFields.userId] ?? '').toString(),
      userName: (data['userName'] ?? 'Member').toString(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      comment: (data['comment'] ?? '').toString(),
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
