import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupsScreen extends StatelessWidget{
  const GroupsScreen({super.key});
  @override Widget build(BuildContext context){
    final user=FirebaseAuth.instance.currentUser;
    final ref=FirebaseFirestore.instance.collection('studyGroups');
    return Scaffold(appBar:AppBar(title:const Text('Study Groups')),floatingActionButton:user==null?null:FloatingActionButton.extended(onPressed:()=>_create(context,user.uid,ref),icon:const Icon(Icons.add),label:const Text('Create Group')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:ref.orderBy('createdAt',descending:true).limit(50).snapshots(),builder:(context,s){
      if(s.hasError)return const Center(child:Text('Unable to load study groups.'));
      if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      final docs=s.data?.docs??[];
      if(docs.isEmpty)return const Center(child:Text('No study groups yet. Create the first one.'));
      return ListView.builder(padding:const EdgeInsets.all(12),itemCount:docs.length,itemBuilder:(context,i){final d=docs[i].data();return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.groups_outlined)),title:Text((d['name']??'Study Group').toString(),style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text((d['description']??'').toString()),trailing:Text((d['memberCount']??1).toString()+' members'),onTap:()=>_join(context,docs[i].id,user?.uid)));});
    }));
  }
  static Future<void> _create(BuildContext context,String uid,CollectionReference<Map<String,dynamic>> ref)async{
    final name=TextEditingController(),desc=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Create Study Group'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Group name')),TextField(controller:desc,decoration:const InputDecoration(labelText:'Description'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Create'))]));
    if(ok==true&&name.text.trim().isNotEmpty)await ref.add({'name':name.text.trim(),'description':desc.text.trim(),'ownerId':uid,'memberCount':1,'createdAt':FieldValue.serverTimestamp()});
  }
  static Future<void> _join(BuildContext context,String groupId,String? uid)async{
    if(uid==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please sign in to join a group.')));return;}
    await FirebaseFirestore.instance.collection('studyGroups').doc(groupId).update({'memberCount':FieldValue.increment(1)});
    if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Joined study group.')));
  }
}