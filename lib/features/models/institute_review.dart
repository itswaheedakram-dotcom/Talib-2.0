import '../../core/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InstituteReview {
  final String instituteId;
  final String userId;
  final String authorName;
  final int rating;
  final String text;
  final DateTime updatedAt;
  const InstituteReview({required this.instituteId, required this.userId,
    required this.authorName, required this.rating, required this.text, required this.updatedAt});

  Map<String, dynamic> toMap() => {
    'instituteId': instituteId, ProfileFields.userId: userId, ProfileFields.authorName: authorName,
    'rating': rating, 'text': text, 'updatedAt': updatedAt.toUtc().toIso8601String(), 'published': true,
  };
  static InstituteReview? read(Map<String, dynamic> map) {
    final rating = map['rating'];
    if (rating is! int || rating < 1 || rating > 5 || map['published'] != true) return null;
    final id = map['instituteId']?.toString() ?? '';
    final uid = map[ProfileFields.userId]?.toString() ?? '';
    if (id.isEmpty || uid.isEmpty) return null;
    return InstituteReview(instituteId: id, userId: uid,
      authorName: map[ProfileFields.authorName]?.toString() ?? 'Community member', rating: rating,
      text: map['text']?.toString() ?? '',
      updatedAt: map['updatedAt'] is Timestamp ? (map['updatedAt'] as Timestamp).toDate() : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime(1970));
  }
}

class InstituteRatingSummary {
  final int count;
  final int total;
  final Map<int, int> distribution;
  const InstituteRatingSummary({this.count = 0, this.total = 0, this.distribution = const {}});
  factory InstituteRatingSummary.fromReviews(Iterable<InstituteReview> reviews) {
    final unique = {for (final review in reviews) review.userId: review};
    final distribution = <int, int>{};
    var total = 0;
    for (final review in unique.values) {
      total += review.rating;
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }
    return InstituteRatingSummary(count: unique.length, total: total, distribution: distribution);
  }
  double get average => count == 0 ? 0 : total / count;
  bool get eligibleForRank => count >= 3;
  /// Five neutral (3-star) prior votes reduce the impact of tiny samples.
  double get rankingScore => (total + 15) / (count + 5);
}
