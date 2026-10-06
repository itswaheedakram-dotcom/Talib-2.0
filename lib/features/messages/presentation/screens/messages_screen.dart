import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_service.dart';

class MessagesScreen extends StatelessWidget{
  const MessagesScreen({super.key});

  String _otherId(Map<String,dynamic> d,String uid) {
    final p=List<String>.from(d['participants']??const []);
    return p.firstWhere((x)=>x!=uid,orElse:()=> '');
  }

  @override Widget build(BuildContext context){
    final user=FirebaseAuth.instance.currentUser;
    if(user==null)return const Center(child:Text('Please sign in to use messages.'));
    final ref=FirebaseFirestore.instance.collection('conversations').where('participants',arrayContains:user.uid).orderBy('updatedAt',descending:true);
    return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream:ref.snapshots(),
      builder:(context,s){
        if(s.hasError)return const Center(child:Text('Unable to load messages. If this is the first run, create the Firestore index requested by Firebase.'));
        if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
        final docs=s.data?.docs??[];
        if(docs.isEmpty)return const Center(child:Text('No conversations yet. Follow each other to start messaging.'));
        return ListView.separated(
          padding:const EdgeInsets.symmetric(vertical:8),
          itemCount:docs.length,
          separatorBuilder:(_,__)=>const Divider(height:1),
          itemBuilder:(context,i){
            final d=docs[i].data();
            final otherId=_otherId(d,user.uid);
            final names=Map<String,dynamic>.from(d['participantNames']??{});
            final name=(names[otherId]??'Student').toString();
            return ListTile(
              leading:const CircleAvatar(child:Icon(Icons.person_outline)),
              title:Text(name,style:const TextStyle(fontWeight:FontWeight.w600)),
              subtitle:Text((d['lastMessage']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis),
              trailing:const Icon(Icons.chevron_right),
              onTap:otherId.isEmpty?null:()=>context.push('/chat/${docs[i].id}?uid=$otherId&name=${Uri.encodeComponent(name)}'),
            );
          },
        );
      },
    );
  }
}