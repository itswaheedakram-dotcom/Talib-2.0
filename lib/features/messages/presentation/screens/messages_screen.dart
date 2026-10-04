import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget{
  const MessagesScreen({super.key});
  @override Widget build(BuildContext context){
    final user=FirebaseAuth.instance.currentUser;
    if(user==null)return const Scaffold(body:Center(child:Text('Please sign in to use messages.')));
    final ref=FirebaseFirestore.instance.collection('users').doc(user.uid).collection('conversations');
    return Scaffold(appBar:AppBar(title:const Text('Messages')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:ref.orderBy('updatedAt',descending:true).snapshots(),builder:(context,s){
      if(s.hasError)return const Center(child:Text('Unable to load messages.'));
      if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      final docs=s.data?.docs??[];
      if(docs.isEmpty)return const Center(child:Text('No conversations yet.'));
      return ListView.builder(itemCount:docs.length,itemBuilder:(context,i){final d=docs[i].data();return ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text((d['name']??'Student').toString()),subtitle:Text((d['lastMessage']??'').toString()),onTap:()=>_chat(context,docs[i].id,(d['name']??'Student').toString(),user.uid));});
    }));
  }
  static Future<void> _chat(BuildContext context,String id,String name,String uid)async{
    final c=TextEditingController();
    await showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>Padding(padding:EdgeInsets.only(bottom:MediaQuery.of(context).viewInsets.bottom),child:Column(mainAxisSize:MainAxisSize.min,children:[ListTile(title:Text(name),leading:const CircleAvatar(child:Icon(Icons.person))),TextField(controller:c,decoration:InputDecoration(labelText:'Message',suffixIcon:IconButton(icon:const Icon(Icons.send),onPressed:()async{if(c.text.trim().isEmpty)return;await FirebaseFirestore.instance.collection('users').doc(uid).collection('conversations').doc(id).set({'name':name,'lastMessage':c.text.trim(),'updatedAt':FieldValue.serverTimestamp()});c.clear();}))),const SizedBox(height:20)])));
  }
}