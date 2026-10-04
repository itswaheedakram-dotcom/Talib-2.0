import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';

class NotificationsScreen extends StatelessWidget{
  const NotificationsScreen({super.key});
  @override Widget build(BuildContext context){
    if(!FirebaseService.initialized||FirebaseAuth.instance.currentUser==null)return Scaffold(appBar:AppBar(title:const Text('Notifications')),body:const Center(child:Text('Sign in to view notifications.')));
    final uid=FirebaseAuth.instance.currentUser!.uid;final db=DatabaseService();
    return Scaffold(appBar:AppBar(title:const Text('Notifications')),body:StreamBuilder(stream:db.notificationsStream(uid),builder:(context,AsyncSnapshot snap){
      if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      if(snap.hasError)return const Center(child:Text('Could not load notifications.'));
      final docs=snap.data?.docs??[];if(docs.isEmpty)return const Center(child:Text('No notifications yet.'));
      return ListView.separated(padding:const EdgeInsets.all(12),itemCount:docs.length,separatorBuilder:(_,__)=>const SizedBox(height:6),itemBuilder:(_,i){
        final d=docs[i];final x=d.data() as Map<String,dynamic>;final read=x['read']==true;final postId=(x['postId']??'').toString();
        return Card(color:read?null:const Color(0xFFEAF8F2),child:ListTile(leading:CircleAvatar(backgroundColor:const Color(0xFFEAF8F2),child:Icon(x['type']=='comment'?Icons.comment_outlined:Icons.favorite_border,color:const Color(0xFF00A66A))),title:Text((x['text']??'Activity on your post').toString(),style:TextStyle(fontWeight:read?FontWeight.normal:FontWeight.w700)),subtitle:Text(read?'Read':'New notification'),onTap:()async{await db.markNotificationRead(uid,d.id);if(postId.isNotEmpty&&context.mounted)context.push('/community/post/'+postId);}));
      });
    }));
  }
}