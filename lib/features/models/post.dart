import '../community/domain/community_reaction.dart';
import '../../core/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id, text, authorId, authorName, category;
  final DateTime createdAt;
  final DateTime? updatedAt, pollClosesAt;
  final String postType;
  final Map<String, String> educationalData, reactions;
  final Map<String, int> pollVoters;
  final int likesCount, commentsCount;
  final List<String> likedBy;
  final bool isQuestion;
  final String? bestAnswerId;
  final String? instituteId;
  final List<String> instituteIds;
  final List<String> tags;
  final List<String> pollOptions;
  final Map<String, int> pollVotes;
  final List<Map<String, String>> attachments;

  const Post({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.category = 'General',
    this.postType = 'general',
    this.educationalData = const {},
    this.reactions = const {},
    this.pollVoters = const {},
    this.updatedAt,
    this.pollClosesAt,
    this.likesCount = 0,
    this.likedBy = const [],
    this.commentsCount = 0,
    this.isQuestion = false,
    this.bestAnswerId,
    this.instituteId,
    this.instituteIds = const [],
    this.tags = const [],
    this.pollOptions = const [],
    this.pollVotes = const {},
    this.attachments = const [],
  });

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final raw = d['createdAt'];
    int asInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '0') ?? 0;
    return Post(
      id: doc.id,
      postType: (d['postType'] ?? 'general').toString(),
      educationalData: d['educationalData'] is Map
          ? Map<String, String>.from(
              (d['educationalData'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            )
          : const {},
      reactions: d['reactions'] is Map
          ? Map<String, String>.from(
              (d['reactions'] as Map).map(
                (k, v) => MapEntry(k.toString(), v.toString()),
              ),
            )
          : const {},
      pollVoters: d['pollVoters'] is Map
          ? Map<String, int>.from(
              (d['pollVoters'] as Map).map(
                (k, v) => MapEntry(k.toString(), asInt(v)),
              ),
            )
          : const {},
      updatedAt: d['updatedAt'] is Timestamp
          ? (d['updatedAt'] as Timestamp).toDate()
          : null,
      pollClosesAt: d['pollClosesAt'] is Timestamp
          ? (d['pollClosesAt'] as Timestamp).toDate()
          : null,
      text: (d['text'] ?? '').toString(),
      authorId: (d[ProfileFields.authorId] ?? '').toString(),
      authorName: (d[ProfileFields.authorName] ?? 'Student').toString(),
      createdAt: raw is Timestamp ? raw.toDate() : DateTime.now(),
      category: (d['category'] ?? 'General').toString(),
      likesCount: asInt(d['likesCount']),
      likedBy: (d['likedBy'] is List
          ? (d['likedBy'] as List).whereType<String>().toList()
          : const <String>[]),
      commentsCount: asInt(d['commentsCount']),
      isQuestion: d['isQuestion'] == true,
      bestAnswerId: d['bestAnswerId']?.toString(),
      instituteId: d['instituteId']?.toString(),
      instituteIds: (d['instituteIds'] is List)
          ? (d['instituteIds'] as List).whereType<String>().toList()
          : ((d['instituteId'] ?? '').toString().isEmpty
                ? const []
                : [(d['instituteId'] ?? '').toString()]),
      tags: (d['tags'] is List)
          ? (d['tags'] as List).whereType<String>().toList()
          : [(d['category'] ?? 'General').toString()],
      pollOptions: (d['pollOptions'] is List
          ? (d['pollOptions'] as List).whereType<String>().toList()
          : const <String>[]),
      pollVotes: Map<String, int>.from(
        (d['pollVotes'] ?? const {}).map(
          (k, v) => MapEntry(k.toString(), asInt(v)),
        ),
      ),
      attachments: (d['attachments'] is List)
          ? (d['attachments'] as List)
                .whereType<Map>()
                .map(
                  (x) => Map<String, String>.from(
                    (x as Map).map(
                      (k, v) => MapEntry(k.toString(), v.toString()),
                    ),
                  ),
                )
                .toList()
          : const [],
    );
  }

  Map<String, String> get reactors => {
    for (final uid in likedBy) uid: 'like',
    ...Map<String, String>.fromEntries(
      reactions.entries.where((e) => CommunityReaction.valid(e.value)),
    ),
  };
  String? reactionBy(String uid) => reactors[uid];
  Map<String, int> get reactionCounts => {
    for (final r in CommunityReaction.all)
      r.id: reactors.values.where((v) => v == r.id).length,
  };
  int get reactionsCount => reactors.length;
  bool likedByUser(String? uid) => uid != null && reactionBy(uid) == 'like';
  bool get pollClosed =>
      pollClosesAt != null && !DateTime.now().isBefore(pollClosesAt!);

  Post copyWith({
    String? text,
    String? category,
    String? postType,
    Map<String, String>? educationalData,
    Map<String, String>? reactions,
    List<String>? likedBy,
    int? likesCount,
    int? commentsCount,
    bool? isQuestion,
    String? bestAnswerId,
    String? instituteId,
    List<String>? instituteIds,
    List<String>? tags,
    List<String>? pollOptions,
    Map<String, int>? pollVotes,
    Map<String, int>? pollVoters,
    List<Map<String, String>>? attachments,
    DateTime? updatedAt,
    DateTime? pollClosesAt,
  }) => Post(
    id: id,
    text: text ?? this.text,
    authorId: authorId,
    authorName: authorName,
    createdAt: createdAt,
    category: category ?? this.category,
    postType: postType ?? this.postType,
    educationalData: educationalData ?? this.educationalData,
    reactions: reactions ?? this.reactions,
    likedBy: likedBy ?? this.likedBy,
    likesCount: likesCount ?? this.likesCount,
    commentsCount: commentsCount ?? this.commentsCount,
    isQuestion: isQuestion ?? this.isQuestion,
    bestAnswerId: bestAnswerId ?? this.bestAnswerId,
    instituteId: instituteId ?? this.instituteId,
    instituteIds: instituteIds ?? this.instituteIds,
    tags: tags ?? this.tags,
    pollOptions: pollOptions ?? this.pollOptions,
    pollVotes: pollVotes ?? this.pollVotes,
    pollVoters: pollVoters ?? this.pollVoters,
    attachments: attachments ?? this.attachments,
    updatedAt: updatedAt ?? this.updatedAt,
    pollClosesAt: pollClosesAt ?? this.pollClosesAt,
  );

  Map<String, dynamic> toMap() => {
    'postType': postType,
    'educationalData': educationalData,
    'reactions': reactions,
    'pollVoters': pollVoters,
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    if (pollClosesAt != null) 'pollClosesAt': Timestamp.fromDate(pollClosesAt!),
    'text': text,
    ProfileFields.authorId: authorId,
    ProfileFields.authorName: authorName,
    'category': category,
    'createdAt': Timestamp.fromDate(createdAt),
    'likesCount': likesCount,
    'likedBy': likedBy,
    'commentsCount': commentsCount,
    'isQuestion': isQuestion,
    'bestAnswerId': bestAnswerId,
    if (instituteId != null) 'instituteId': instituteId,
    'instituteIds': instituteIds,
    'tags': tags,
    'pollOptions': pollOptions,
    'pollVotes': pollVotes,
    'attachments': attachments,
  };
}
