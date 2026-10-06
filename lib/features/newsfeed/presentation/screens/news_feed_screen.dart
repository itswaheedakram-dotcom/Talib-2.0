import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/news_item.dart';
import '../../../../core/services/database_service.dart';

class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('News Feed'),actions:[IconButton(onPressed:()=>context.push('/notifications'),icon:const Icon(Icons.notifications_none_rounded))]),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:DatabaseService().newsStream(),builder:(context,snapshot){
    if(snapshot.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
    if(snapshot.hasError)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('Unable to load news. Check your connection and Firestore configuration.',textAlign:TextAlign.center)));
    final items=snapshot.data?.docs.map(NewsItem.fromDoc).toList()??[];
    if(items.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.newspaper_outlined,size:58),SizedBox(height:12),Text('No news available yet',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),SizedBox(height:6),Text('New education, admissions and career updates will appear here.',textAlign:TextAlign.center)])));
    return ListView.builder(padding:const EdgeInsets.fromLTRB(14,12,14,28),itemCount:items.length,itemBuilder:(context,index){final n=items[index];return Card(margin:const EdgeInsets.only(bottom:12),child:InkWell(borderRadius:BorderRadius.circular(12),onTap:()=>context.push('/news/'+n.id),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(n.imageUrl.isNotEmpty)ClipRRect(borderRadius:BorderRadius.circular(10),child:Image.network(n.imageUrl,height:170,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())),if(n.imageUrl.isNotEmpty)const SizedBox(height:10),Row(children:[Expanded(child:Text(n.title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700))),const Icon(Icons.chevron_right)]),const SizedBox(height:8),Text(n.text,maxLines:4,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:13,height:1.4)),const SizedBox(height:10),Row(children:[Text(n.author,style:const TextStyle(fontWeight:FontWeight.w600)),const Spacer(),const Text('Read more →',style:TextStyle(fontWeight:FontWeight.w600))])]))));});
  }));
}
