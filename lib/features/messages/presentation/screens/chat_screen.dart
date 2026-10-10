import '../../../../core/widgets/user_identity.dart';
import '../../../../core/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/demo_data_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../app/theme.dart';

class ChatScreen extends StatefulWidget{final String conversationId,otherUid,otherName;const ChatScreen({super.key,required this.conversationId,required this.otherUid,required this.otherName});@override State<ChatScreen> createState()=>_ChatScreenState();}
class _ChatScreenState extends State<ChatScreen>{
 final controller=TextEditingController(); bool sending=false;
 String _time(dynamic v){final d=v is Timestamp?v.toDate():v is DateTime?v:null;if(d==null)return '';return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';}
 List<String> _demoParticipants()=>widget.conversationId.split('|').where((x)=>x.isNotEmpty).toList();
String? _demoOtherUid(String currentUid){final p=_demoParticipants();if(p.length==2&&p.contains(currentUid))return p.firstWhere((x)=>x!=currentUid);if(widget.otherUid!=currentUid)return widget.otherUid;return null;}
String _demoOtherName(String uid){const names={'demo-user-1':'Ayesha Khan','demo-user-2':'Ali Raza','demo-user-3':'Hira Ahmed','demo-user-4':'Usman Malik'};return names[uid]??widget.otherName;}

Future<void> _send()async{
  final identity=ActiveProfileController.instance;
  final text=controller.text.trim();
  if(text.isEmpty||sending)return;
  if(identity.isDemo){
    final id=identity.effectiveUid;
    if(id==null)return;
    setState(()=>sending=true);
    try{
      final to=_demoOtherUid(id);if(to==null||to==id)return;DemoDataService.instance.sendMessage(id,to,text);
      controller.clear();
    }finally{if(mounted)setState(()=>sending=false);}
    return;
  }
  final real=FirebaseAuth.instance.currentUser;
  if(real==null)return;
  setState(()=>sending=true);
  try{
    final id=identity.resolveUid(real.uid);
    if(!await DatabaseService().isMutualFollow(id,widget.otherUid)){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('You can message only when both users follow each other.')));
      return;
    }
    final db=FirebaseFirestore.instance;
    final conversation=db.collection('conversations').doc(widget.conversationId);
    if(!(await conversation.get()).exists){
      final name=real.displayName?.trim().isNotEmpty==true?real.displayName!.trim():'Student';
      if(await DatabaseService().createConversation(uid:id,otherUid:widget.otherUid,otherName:widget.otherName,uidName:name)==null)return;
    }
    final now=FieldValue.serverTimestamp();
    final batch=db.batch();
    final message=conversation.collection('messages').doc();
    batch.set(message,{ProfileFields.senderId:id,'receiverId':widget.otherUid,'text':text,'createdAt':now,'read':false});
    batch.update(conversation,{'lastMessage':text,'lastMessageAt':now,'updatedAt':now,'unreadCounts.$id':0,'unreadCounts.${widget.otherUid}':FieldValue.increment(1)});
    await batch.commit();
    controller.clear();
  }finally{if(mounted)setState(()=>sending=false);}
}
 @override Widget build(BuildContext context){final identity=ActiveProfileController.instance;if(identity.isDemo){return AnimatedBuilder(animation:identity,builder:(context,_){final currentUid=identity.effectiveUid;if(currentUid==null)return const Scaffold(body:Center(child:Text('Activate a demo profile first.')));final otherUid=_demoOtherUid(currentUid);if(otherUid==null||otherUid==currentUid)return const Scaffold(body:Center(child:Text('This conversation does not match the active profile.')));return _demo(context,currentUid,otherUid,_demoOtherName(otherUid));});}final real=FirebaseAuth.instance.currentUser;if(real==null)return const Scaffold(body:Center(child:Text('Please sign in.')));final stream=FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).collection('messages').orderBy('createdAt');return _shell(context,stream.snapshots(),real.uid,widget.otherName);}
 Widget _demo(BuildContext context,String uid,String otherUid,String otherName){
  return _shell(
    context,
    Stream<List<Map<String,dynamic>>>.multi((controller){
      controller.add(DemoDataService.instance.messages(uid,otherUid));
      final sub=DemoDataService.instance.changes.listen((_)=>controller.add(DemoDataService.instance.messages(uid,otherUid)));
      controller.onCancel=sub.cancel;
    }),
    uid,
    otherName,
  );
}
 Widget _shell(BuildContext context,Stream stream,String uid,String otherName)=>Scaffold(appBar:AppBar(toolbarHeight:88,title:UserIdentity(uid: ActiveProfileController.instance.isDemo ? (_demoOtherUid(uid) ?? widget.otherUid) : widget.otherUid, name: otherName, color: AppColors.white)),body:Column(children:[Expanded(child:StreamBuilder(stream:stream,builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());final raw=s.data;final docs=raw is List?raw:raw is QuerySnapshot?raw.docs.map((x)=>x.data()).toList():const [];if(docs.isEmpty)return const Center(child:Text('No messages yet. Say hello!'));return ListView.builder(padding:const EdgeInsets.all(12),itemCount:docs.length,itemBuilder:(context,i){final d=docs[i] as Map<String,dynamic>;final mine=d[ProfileFields.senderId]==uid;return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.78),margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),decoration:BoxDecoration(color:mine?AppColors.primaryGreen:AppColors.softGreen,borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:mine?CrossAxisAlignment.end:CrossAxisAlignment.start,children:[UserIdentity(uid:(d[ProfileFields.senderId]??'').toString(),name:mine ? 'You' : otherName,color:mine?AppColors.white:AppColors.darkGreen),const SizedBox(height:4),Text((d['text']??'').toString(),style:TextStyle(color:mine?AppColors.white:AppColors.darkGreen)),Text(_time(d['createdAt']),style:TextStyle(fontSize:10,color:mine?AppColors.white.withOpacity(.75):AppColors.mutedText))])));});})),SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(10,6,10,10),child:Row(children:[Expanded(child:TextField(controller:controller,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:const InputDecoration(hintText:'Write a message...',border:OutlineInputBorder()))),const SizedBox(width:8),IconButton(onPressed:sending?null:_send,icon:const Icon(Icons.send))])))]));
 @override void dispose(){controller.dispose();super.dispose();}
}