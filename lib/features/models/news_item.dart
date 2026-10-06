import 'package:cloud_firestore/cloud_firestore.dart';

class NewsItem {
  final String id,title,text,author,category,imageUrl;
  final DateTime? createdAt;
  const NewsItem({required this.id,required this.title,required this.text,required this.author,required this.category,required this.imageUrl,required this.createdAt});
  factory NewsItem.fromDoc(DocumentSnapshot<Map<String,dynamic>> doc){
    final d=doc.data()??{}; final ts=d['createdAt'];
    return NewsItem(id:doc.id,title:(d['title']??'Untitled').toString(),text:(d['text']??d['description']??'').toString(),author:(d['authorName']??d['author']??'Talib').toString(),category:(d['category']??'General').toString(),imageUrl:(d['imageUrl']??'').toString(),createdAt:ts is Timestamp?ts.toDate():null);
  }
}
