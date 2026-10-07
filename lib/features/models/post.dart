import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id,text,authorId,authorName,category;
  final DateTime createdAt;
  final int likesCount,commentsCount;
  final List<String> likedBy;
  final bool isQuestion;
  final String? bestAnswerId;
  final String? instituteId;
  final List<String> instituteIds;
  final List<String> tags;
  final List<String> pollOptions;
  final Map<String,int> pollVotes;
  final List<Map<String,String>> attachments;

  const Post({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.category='General',
    this.likesCount=0,
    this.likedBy=const [],
    this.commentsCount=0,
    this.isQuestion=false,
    this.bestAnswerId,
    this.instituteId,
    this.instituteIds=const [],
    this.tags=const [],
    this.pollOptions=const [],
    this.pollVotes=const {},
    this.attachments=const []
  });

  factory Post.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc){
    final d=doc.data()??{};
    final raw=d['createdAt'];
    int asInt(dynamic v)=>v is num?v.toInt():int.tryParse(v?.toString()??'0')??0;
    return Post(
      id:doc.id,
      text:(d['text']??'').toString(),
      authorId:(d['authorId']??'').toString(),
      authorName:(d['authorName']??'Student').toString(),
      createdAt:raw is Timestamp?raw.toDate():DateTime.now(),
      category:(d['category']??'General').toString(),
      likesCount:asInt(d['likesCount']),
      likedBy:List<String>.from(d['likedBy']??const []),
      commentsCount:asInt(d['commentsCount']),
      isQuestion:d['isQuestion']==true,
      bestAnswerId:d['bestAnswerId']?.toString(),
      instituteId:d['instituteId']?.toString(),
      instituteIds:(d['instituteIds'] is List) ? List<String>.from(d['instituteIds']) : ((d['instituteId']??'').toString().isEmpty ? const [] : [(d['instituteId']??'').toString()]),
      tags:(d['tags'] is List) ? List<String>.from(d['tags']) : [(d['category']??'General').toString()],
      pollOptions:List<String>.from(d['pollOptions']??const []),
      pollVotes:Map<String,int>.from((d['pollVotes']??const {}).map((k,v)=>MapEntry(k.toString(),asInt(v)))),
      attachments:(d['attachments'] is List)
          ? (d['attachments'] as List).map((x)=>Map<String,String>.from((x as Map).map((k,v)=>MapEntry(k.toString(),v.toString())))).toList()
          : const [],
    );
  }

  bool likedByUser(String? uid)=>uid!=null&&likedBy.contains(uid);

  Map<String,dynamic> toMap() => {
    'text':text,'authorId':authorId,'authorName':authorName,'category':category,
    'createdAt':Timestamp.fromDate(createdAt),'likesCount':likesCount,'likedBy':likedBy,
    'commentsCount':commentsCount,'isQuestion':isQuestion,'bestAnswerId':bestAnswerId,
    if(instituteId!=null)'instituteId':instituteId,'instituteIds':instituteIds,'tags':tags,'pollOptions':pollOptions,'pollVotes':pollVotes,
    'attachments':attachments,
  };
}