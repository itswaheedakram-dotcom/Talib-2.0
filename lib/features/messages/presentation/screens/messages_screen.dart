import '../../../../core/widgets/user_identity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/demo_data_service.dart';
import '../../../../core/services/active_profile_controller.dart';

class MessagesScreen extends StatelessWidget{
  const MessagesScreen({super.key});
  String _time(dynamic v){if(v is Timestamp){final d=v.toDate();return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';}if(v is DateTime)return '${v.hour.toString().padLeft(2,'0')}:${v.minute.toString().padLeft(2,'0')}';return '';}
  @override Widget build(BuildContext context){
    final identity=ActiveProfileController.instance;
    if(identity.isDemo){
      final uid=identity.effectiveUid;
      if(uid == null){
        return const Center(
          child: Text('Open a demo profile and tap "Activate This Profile" to use messages.'),
        );
      }
      return StreamBuilder<void>(
        stream: DemoDataService.instance.changes,
        builder: (context, s) => _demoList(
          context,
          DemoDataService.instance.conversations(uid),
        ),
      );
    }
    final real=FirebaseAuth.instance.currentUser;
    if(real==null)return const Center(child:Text('Please sign in to use messages.'));
    final ref=FirebaseFirestore.instance.collection('conversations').where('participants',arrayContains:real.uid);
    return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:ref.snapshots(),builder:(context,s){if(s.hasError)return const Center(child:Text('Unable to load messages.'));if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());final List<QueryDocumentSnapshot<Map<String,dynamic>>> docs = List<QueryDocumentSnapshot<Map<String,dynamic>>>.from(s.data?.docs ?? const <QueryDocumentSnapshot<Map<String,dynamic>>>[]);docs.sort((a,b){final at=a.data()['updatedAt'],bt=b.data()['updatedAt'];if(at is Timestamp&&bt is Timestamp)return bt.compareTo(at);return 0;});return _firebaseList(context,docs,real.uid);});
  }
  Widget _demoList(BuildContext context,List<Map<String,dynamic>> items)=>Column(children:[Padding(padding:const EdgeInsets.fromLTRB(16,6,16,2),child:Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>context.push('/groups'),icon:const Icon(Icons.groups_outlined),label:const Text('Study Groups')))),Padding(padding:const EdgeInsets.fromLTRB(16,10,16,6),child:Align(alignment:Alignment.centerLeft,child:Text('Test profile: ${ActiveProfileController.instance.effectiveName}',style:const TextStyle(fontWeight:FontWeight.w700)))),Expanded(child:items.isEmpty?const Center(child:Text('No conversations yet.')):ListView.separated(itemCount:items.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(context,i){final x=items[i];return ListTile(leading:const CircleAvatar(child:Icon(Icons.person_outline)),title:UserIdentity(uid:(x['otherUid']??'').toString(),name:x['otherName'].toString()),subtitle:Text(x['lastMessage'].toString(),maxLines:1,overflow:TextOverflow.ellipsis),trailing:Text(_time(x['updatedAt']),style:const TextStyle(fontSize:11)),onTap:()=>context.push('/chat/${x['id']}?uid=${x['otherUid']}&name=${Uri.encodeComponent(x['otherName'].toString())}'));}))]);
  Widget _firebaseList(BuildContext context,List<QueryDocumentSnapshot<Map<String,dynamic>>> docs,String uid)=>Column(children:[Padding(padding:const EdgeInsets.fromLTRB(16,6,16,2),child:Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>context.push('/groups'),icon:const Icon(Icons.groups_outlined),label:const Text('Study Groups')))),Expanded(child:docs.isEmpty?const Center(child:Text('No conversations yet. Follow each other to start messaging.')):ListView.separated(itemCount:docs.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(context,i){final d=docs[i].data();final p=List<String>.from(d['participants']??const[]);final other=p.firstWhere((x)=>x!=uid,orElse:()=> '');final names=Map<String,dynamic>.from(d['participantNames']??{});final name=(names[other]??'Student').toString();return ListTile(leading:const CircleAvatar(child:Icon(Icons.person_outline)),title:UserIdentity(uid:other,name:name),subtitle:Text((d['lastMessage']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis),onTap:other.isEmpty?null:()=>context.push('/chat/${docs[i].id}?uid=$other&name=${Uri.encodeComponent(name)}'));}))]);
}