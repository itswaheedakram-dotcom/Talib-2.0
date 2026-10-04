import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id,text,authorId,authorName,category;
  final DateTime createdAt;
  final int likesCount,commentsCount;
  final List<String> likedBy;
  final bool isQuestion;
  final String? bestAnswerId;
  const Post({required this.id,required this.text,required this.authorId,required this.authorName,required this.createdAt,this.category='General',this.likesCount=0,this.likedBy=const [],this.commentsCount=0,this.isQuestion=false,this.bestAnswerId});
  factory Post.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc){
    final d=doc.data()??{}; final raw=d['createdAt'];
    return Post(id:doc.id,text:(d['text']??'').toString(),authorId:(d['authorId']??'').toString(),authorName:(d['authorName']??'Student').toString(),createdAt:raw is Timestamp?raw.toDate():DateTime.now(),category:(d['category']??'General').toString(),likesCount:(d['likesCount']??0) is num?(d['likesCount']??0 as num).toInt():0,likedBy:List<String>.from(d['likedBy']??const []),commentsCount:(d['commentsCount']??0) is num?(d['commentsCount']??0 as num).toInt():0,isQuestion:d['isQuestion']==true,bestAnswerId:d['bestAnswerId']?.toString());
  }
  bool likedByUser(String? uid)=>uid!=null&&likedBy.contains(uid);
}