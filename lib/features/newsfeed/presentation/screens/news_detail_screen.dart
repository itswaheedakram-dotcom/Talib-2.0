import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/news_item.dart';
import '../../../../core/services/database_service.dart';

class NewsDetailScreen extends StatelessWidget {
  final String id;
  const NewsDetailScreen({super.key,required this.id});
  @override Widget build(BuildContext context)=>FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(future:DatabaseService().newsItem(id),builder:(context,snapshot){
    if(snapshot.connectionState==ConnectionState.waiting)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    if(snapshot.hasError||!snapshot.hasData||!snapshot.data!.exists)return const Scaffold(body:Center(child:Text('News item not found.')));
    final n=NewsItem.fromDoc(snapshot.data!);
    return Scaffold(appBar:AppBar(title:const Text('News')),body:ListView(padding:const EdgeInsets.all(18),children:[if(n.imageUrl.isNotEmpty)ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.network(n.imageUrl,height:210,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())),const SizedBox(height:14),Text(n.title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:8),Text(n.category+' • '+n.author),const SizedBox(height:18),Text(n.text,style:Theme.of(context).textTheme.bodyLarge?.copyWith(height:1.55))]));
  });
}
