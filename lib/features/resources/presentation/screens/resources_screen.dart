import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResourcesScreen extends StatelessWidget{
  const ResourcesScreen({super.key});
  @override Widget build(BuildContext context){
    final user=FirebaseAuth.instance.currentUser;
    final ref=FirebaseFirestore.instance.collection('resources');
    return Scaffold(appBar:AppBar(title:const Text('Study Resources')),floatingActionButton:user==null?null:FloatingActionButton.extended(onPressed:()=>_add(context,user.uid,ref),icon:const Icon(Icons.add_link),label:const Text('Share Resource')),body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:ref.orderBy('createdAt',descending:true).limit(50).snapshots(),builder:(context,s){
      if(s.hasError)return const Center(child:Text('Unable to load resources.'));
      if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      final docs=s.data?.docs??[];
      if(docs.isEmpty)return const Center(child:Text('No resources shared yet.'));
      return ListView.builder(padding:const EdgeInsets.all(12),itemCount:docs.length,itemBuilder:(context,i){final d=docs[i].data();return Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.menu_book_outlined)),title:Text((d['title']??'Resource').toString()),subtitle:Text((d['description']??'').toString()),onTap:()=>_showLink(context,(d['url']??'').toString())));});
    }));
  }
  static Future<void> _add(BuildContext context,String uid,CollectionReference<Map<String,dynamic>> ref)async{
    final title=TextEditingController(),url=TextEditingController(),desc=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Share Resource'),content:SingleChildScrollView(child:Column(children:[TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),TextField(controller:url,decoration:const InputDecoration(labelText:'URL')),TextField(controller:desc,decoration:const InputDecoration(labelText:'Description'))])),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Share'))]));
    if(ok==true&&title.text.trim().isNotEmpty&&url.text.trim().isNotEmpty)await ref.add({'title':title.text.trim(),'url':url.text.trim(),'description':desc.text.trim(),'authorId':uid,'createdAt':FieldValue.serverTimestamp()});
  }
  static void _showLink(BuildContext context,String url)=>showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Resource Link'),content:SelectableText(url),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Close'))]));
}