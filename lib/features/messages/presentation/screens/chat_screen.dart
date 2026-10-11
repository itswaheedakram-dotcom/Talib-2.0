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
class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver{
 final controller=TextEditingController(); bool sending=false;
 Future<String?>? ready;
 @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);_prepare();}
 void _prepare(){if(ActiveProfileController.instance.isDemo)return;final user=FirebaseAuth.instance.currentUser;if(user!=null){ready=DatabaseService().createConversation(uid:user.uid,otherUid:widget.otherUid,otherName:widget.otherName,uidName:user.displayName);}}
 @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed&&mounted)setState((){});}
 final scroll=ScrollController();
 String? sendError;
 final Set<String> markingRead={};
 void _scrollDown(){WidgetsBinding.instance.addPostFrameCallback((_){if(mounted&&scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:200),curve:Curves.easeOut);});}
 Future<void> _markRead(QuerySnapshot snapshot,String uid) async {
   if(ActiveProfileController.instance.isDemo||WidgetsBinding.instance.lifecycleState!=AppLifecycleState.resumed||ModalRoute.of(context)?.isCurrent==false)return;
   final pending=snapshot.docs.where((doc){final data=doc.data() as Map<String,dynamic>;return data['receiverId']==uid&&data['read']!=true&&!markingRead.contains(doc.id);}).take(400).toList();
   if(pending.isEmpty)return;
   markingRead.addAll(pending.map((doc)=>doc.id));
   try {
     final batch=FirebaseFirestore.instance.batch();
     for(final doc in pending){batch.update(doc.reference,{'read':true});}
     await batch.commit();
   } catch (_) { /* A failed receipt is retried on the next snapshot. */ }
   finally { markingRead.removeAll(pending.map((doc)=>doc.id)); }
 }

 String _time(dynamic v){final d=v is Timestamp?v.toDate():v is DateTime?v:null;if(d==null)return '';return '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';}
 List<String> _demoParticipants()=>widget.conversationId.split('|').where((x)=>x.isNotEmpty).toList();
String? _demoOtherUid(String currentUid){final p=_demoParticipants();if(p.length==2&&p.contains(currentUid))return p.firstWhere((x)=>x!=currentUid);if(widget.otherUid!=currentUid)return widget.otherUid;return null;}
String _demoOtherName(String uid){const names={'demo-user-1':'Ayesha Khan','demo-user-2':'Ali Raza','demo-user-3':'Hira Ahmed','demo-user-4':'Usman Malik'};return names[uid]??widget.otherName;}

Future<void> _send()async{
  final identity=ActiveProfileController.instance;
  final text=controller.text.trim();
  if(text.isEmpty||sending)return;
  if(text.length>5000){setState(()=>sendError='Message is too long. Maximum 5000 characters.');return;}
  setState(()=>sendError=null);
  if(identity.isDemo){
    final id=identity.effectiveUid;
    if(id==null)return;
    setState(()=>sending=true);
    try{
      final to=_demoOtherUid(id);if(to==null||to==id)return;DemoDataService.instance.sendMessage(id,to,text);
      if(controller.text.trim()==text)controller.clear();
      _scrollDown();
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
    if(controller.text.trim()==text)controller.clear();
      _scrollDown();
  }catch(_){if(mounted)setState(()=>sendError='Message could not be sent. Your text is saved below.');}
  finally{if(mounted)setState(()=>sending=false);}
}
 @override Widget build(BuildContext context){final identity=ActiveProfileController.instance;if(identity.isDemo){return AnimatedBuilder(animation:identity,builder:(context,_){final currentUid=identity.effectiveUid;if(currentUid==null)return const Scaffold(body:Center(child:Text('Activate a demo profile first.')));final otherUid=_demoOtherUid(currentUid);if(otherUid==null||otherUid==currentUid)return const Scaffold(body:Center(child:Text('This conversation does not match the active profile.')));return _demo(context,currentUid,otherUid,_demoOtherName(otherUid));});}final real=FirebaseAuth.instance.currentUser;if(real==null)return const Scaffold(body:Center(child:Text('Please sign in.')));final stream=FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).collection('messages').orderBy('createdAt');return FutureBuilder<String?>(future:ready,builder:(context,prepared){if(prepared.connectionState==ConnectionState.waiting)return Scaffold(appBar:AppBar(title:Text(widget.otherName)),body:const Center(child:CircularProgressIndicator()));if(prepared.hasError||prepared.data==null)return Scaffold(appBar:AppBar(title:Text(widget.otherName)),body:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Chat unavailable. Both people must follow each other.'),TextButton(onPressed:()=>setState(_prepare),child:const Text('Retry'))])));return _shell(context,stream.snapshots(includeMetadataChanges:true),real.uid,widget.otherName);});}
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
 Widget _shell(BuildContext context, Stream stream, String uid, String otherName) {
   final colors=AppPalette.of(context);
   return Scaffold(
     appBar:AppBar(toolbarHeight:60,titleSpacing:0,title:UserIdentity(
       uid:ActiveProfileController.instance.isDemo?(_demoOtherUid(uid)??widget.otherUid):widget.otherUid,
       name:otherName,color:Colors.white,compact:true,showUsername:false)),
     body:Column(children:[
       Expanded(child:StreamBuilder(stream:stream,builder:(context,snapshot){
         if(snapshot.hasError)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
           const Text('Unable to load this conversation.'),
           TextButton(onPressed:()=>setState((){}),child:const Text('Retry'))]));
         if(snapshot.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
         final raw=snapshot.data;
         if(raw is QuerySnapshot)_markRead(raw,uid);
         final nearBottom=!scroll.hasClients||scroll.position.maxScrollExtent-scroll.offset<100;
         if(nearBottom)_scrollDown();
         final docs=raw is List?raw:raw is QuerySnapshot?raw.docs.map((x)=>x.data()).toList():const [];
         if(docs.isEmpty)return Center(child:Text('No messages yet. Say hello!',style:TextStyle(color:colors.muted)));
         return ListView.builder(controller:scroll,padding:const EdgeInsets.symmetric(horizontal:16,vertical:16),
           itemCount:docs.length,itemBuilder:(context,index){
             final message=docs[index] as Map<String,dynamic>;
             final mine=message[ProfileFields.senderId]==uid;
             final pending=raw is QuerySnapshot&&raw.docs[index].metadata.hasPendingWrites;
             final read=message['read']==true;
             final textColor=mine?Colors.white:colors.ink;
             return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(
               constraints:BoxConstraints(maxWidth:MediaQuery.sizeOf(context).width*.78),
               margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.fromLTRB(14,10,12,8),
               decoration:BoxDecoration(color:mine?AppColors.primaryGreen:colors.softSurface,
                 borderRadius:BorderRadius.only(topLeft:const Radius.circular(18),topRight:const Radius.circular(18),
                   bottomLeft:Radius.circular(mine?18:5),bottomRight:Radius.circular(mine?5:18))),
               child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.end,children:[
                 Text((message['text']??'').toString(),style:TextStyle(fontSize:16,height:1.35,color:textColor)),
                 const SizedBox(height:5),
                 Row(mainAxisSize:MainAxisSize.min,children:[
                   Text(_time(message['createdAt']),style:TextStyle(fontSize:11,color:mine?Colors.white70:colors.muted)),
                   if(mine&&!ActiveProfileController.instance.isDemo)...[
                     const SizedBox(width:5),
                     Semantics(label:pending?'Sending':read?'Read':'Sent',child:Icon(
                       pending?Icons.schedule:read?Icons.done_all:Icons.done,
                       size:16,color:read?Colors.white:Colors.white70)),
                   ],
                 ]),
               ]),
             ));
           });
       })),
       if(sendError!=null) Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[
         Expanded(child:Text(sendError!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
         TextButton(onPressed:sending?null:_send,child:const Text('Retry'))])),
       Container(decoration:BoxDecoration(color:colors.surface,border:Border(top:BorderSide(color:colors.border))),
         child:SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(12,10,12,10),child:Row(
           crossAxisAlignment:CrossAxisAlignment.end,children:[
             Expanded(child:TextField(controller:controller,minLines:1,maxLines:5,
               textCapitalization:TextCapitalization.sentences,
               textInputAction:TextInputAction.newline,
               decoration:InputDecoration(hintText:'Message',filled:true,fillColor:colors.softSurface,
                 contentPadding:const EdgeInsets.symmetric(horizontal:18,vertical:12),
                 border:OutlineInputBorder(borderRadius:BorderRadius.circular(24),borderSide:BorderSide.none),
                 enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(24),borderSide:BorderSide.none)))),
             const SizedBox(width:8),
             SizedBox(width:48,height:48,child:Material(color:AppColors.primaryGreen,shape:const CircleBorder(),
               child:IconButton(tooltip:'Send message',onPressed:sending?null:_send,
                 icon:sending?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):
                   const Icon(Icons.send_rounded,color:Colors.white,size:23)))),
           ])))),
     ]),
   );
 }
 @override void dispose(){WidgetsBinding.instance.removeObserver(this);controller.dispose();scroll.dispose();super.dispose();}
}