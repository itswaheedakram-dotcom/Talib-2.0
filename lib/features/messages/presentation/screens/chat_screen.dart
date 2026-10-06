import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/database_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUid;
  final String otherName;
  const ChatScreen({super.key,required this.conversationId,required this.otherUid,required this.otherName});
  @override State<ChatScreen> createState()=>_ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller=TextEditingController();
  bool sending=false;

  Future<void> _send() async {
    final me=FirebaseAuth.instance.currentUser;
    final text=controller.text.trim();
    if(me==null||text.isEmpty||sending)return;
    setState(()=>sending=true);
    try {
      if(!await DatabaseService().isMutualFollow(me.uid,widget.otherUid)) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('You can message only when both users follow each other.')));
        return;
      }
      final db=FirebaseFirestore.instance;
      final conversation=db.collection('conversations').doc(widget.conversationId);
      final message=conversation.collection('messages').doc();
      final now=FieldValue.serverTimestamp();
      final batch=db.batch();
      batch.set(message,{
        'senderId':me.uid,'receiverId':widget.otherUid,'text':text,'createdAt':now,'read':false,
      });
      batch.set(conversation,{
        'participants':[me.uid,widget.otherUid],
        'participantNames':{me.uid:me.displayName?.trim().isNotEmpty==true?me.displayName!.trim():'Student',widget.otherUid:widget.otherName},
        'lastMessage':text,'lastMessageAt':now,'updatedAt':now,
      },SetOptions(merge:true));
      await batch.commit();
      controller.clear();
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Message could not be sent.')));
    } finally {
      if(mounted)setState(()=>sending=false);
    }
  }

  Future<void> _markRead(List<QueryDocumentSnapshot<Map<String,dynamic>>> docs,String uid) async {
    final batch=FirebaseFirestore.instance.batch();
    var changed=false;
    for(final d in docs) {
      final x=d.data();
      if(x['receiverId']==uid && x['read']!=true) { batch.update(d.reference,{'read':true}); changed=true; }
    }
    if(changed) await batch.commit();
  }

  @override Widget build(BuildContext context) {
    final me=FirebaseAuth.instance.currentUser;
    if(me==null)return const Scaffold(body:Center(child:Text('Please sign in to use messages.')));
    final messages=FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).collection('messages').orderBy('createdAt');
    return Scaffold(
      appBar:AppBar(title:Text(widget.otherName)),
      body:Column(children:[
        Expanded(child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
          stream:messages.snapshots(),
          builder:(context,s){
            if(s.hasError)return const Center(child:Text('Unable to load chat.'));
            if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
            final docs=s.data?.docs??[];
            WidgetsBinding.instance.addPostFrameCallback((_)=>_markRead(docs,me.uid));
            if(docs.isEmpty)return const Center(child:Text('No messages yet. Say hello!'));
            return ListView.builder(reverse:false,padding:const EdgeInsets.all(12),itemCount:docs.length,itemBuilder:(context,i){
              final d=docs[i].data(); final mine=d['senderId']==me.uid;
              return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(
                constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*0.78),
                margin:const EdgeInsets.only(bottom:8),
                padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
                decoration:BoxDecoration(color:mine?const Color(0xFF00A66A):const Color(0xFFEAF8F2),borderRadius:BorderRadius.circular(16)),
                child:Text((d['text']??'').toString(),style:TextStyle(color:mine?Colors.white:Colors.black87)),
              ));
            });
          },
        )),
        SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(10,6,10,10),child:Row(children:[
          Expanded(child:TextField(controller:controller,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:const InputDecoration(hintText:'Write a message...',border:OutlineInputBorder()))),
          const SizedBox(width:8),
          IconButton(onPressed:sending?null:_send,icon:const Icon(Icons.send)),
        ]))),
      ]),
    );
  }

  @override void dispose(){controller.dispose();super.dispose();}
}
