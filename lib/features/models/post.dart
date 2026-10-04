import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id,text,authorId,authorName,category;
  final DateTime createdAt;
  final int likesCount,commentsCount;
  final List<String> likedBy;
  final bool isQuestion;
  final String? bestAnswerId;
  final String? instituteId;
  final List<String> pollOptions;
  final Map<String,int> pollVotes;
  const Post({required this.id,required this.text,required this.authorId,required this.authorName,required this.createdAt,this.category='General',this.likesCount=0,this.likedBy=const [],this.commentsCount=0,this.isQuestion=false,this.bestAnswerId});
  factory Post.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc){
    final d=doc.data()??{}; final raw=d['createdAt'];
    int asInt(dynamic v)=>v is num?v.toInt():int.tryParse(v?.toString()??'0')??0;
    return Post(id:doc.id,text:(d['text']??'').toString(),authorId:(d['authorId']??'').toString(),authorName:(d['authorName']??'Student').toString(),createdAt:raw is Timestamp?raw.toDate():DateTime.now(),category:(d['category']??'General').toString(),likesCount:asInt(d['likesCount']),likedBy:List<String>.from(d['likedBy']??const []),commentsCount:asInt(d['commentsCount']),isQuestion:d['isQuestion']==true,bestAnswerId:d['bestAnswerId']?.toString());
  }
  bool likedByUser(String? uid)=>uid!=null&&likedBy.contains(uid);
}