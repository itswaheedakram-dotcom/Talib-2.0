import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../models/post.dart';

class PostCommentsScreen extends StatefulWidget{
 final String id; const PostCommentsScreen({super.key,required this.id});
 @override State<PostCommentsScreen> createState()=>_PostCommentsScreenState();
}
class _PostCommentsScreenState extends State<PostCommentsScreen>{
 DatabaseService? _db;final _comment=TextEditingController();bool _demoLiked=false,_saved=false;
 bool get isDemo=>widget.id.startsWith('demo-');
 @override void dispose(){_comment.dispose();super.dispose();}
 @override Widget build(BuildContext context){
  final ready=FirebaseService.initialized;if(ready&&_db==null)_db=DatabaseService();final user=ready?FirebaseAuth.instance.currentUser:null;
  if(isDemo||!ready)return _demo(user);
  return Scaffold(appBar:AppBar(title:const Text('Post')),body:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('posts').doc(widget.id).snapshots(),builder:(c,s){
   if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
   if(s.hasError||!s.hasData||!s.data!.exists)return const Center(child:Text('Post not found.'));
   return _content(Post.fromDoc(s.data!),user);
  }));
 }
 Widget _demo(User? user){final data={'demo-1':{'name':'Talib Community','text':'Welcome to Talib Community! Ask questions, share guidance and help other students.','likes':12,'author':'demo-user-1'},'demo-2':{'name':'Student Guide','text':'Which institute is best for your next education program? Share your experience and help fellow students.','likes':8,'author':'demo-user-2'},'demo-3':{'name':'Talib Team','text':'Need admission guidance? You can use Find Institute to compare institutes, programs and eligibility.','likes':6,'author':'demo-user-3'}}[widget.id]??{'name':'Student','text':'Community post','likes':0,'author':'demo-user-1'};final p=Post(id:widget.id,text:data['text']!.toString(),authorId:data['author']!.toString(),authorName:data['name']!.toString(),createdAt:DateTime.now(),likesCount:data['likes'] as int,commentsCount:2);return Scaffold(appBar:AppBar(title:const Text('Post')),body:_content(p,user));}
 Widget _content(Post post,User? user){final liked=post.likedByUser(user?.uid)||_demoLiked;final likes=post.likesCount+(_demoLiked?1:0);return Column(children:[
  Expanded(child:ListView(padding:const EdgeInsets.all(14),children:[
   InkWell(onTap:()=>context.push('/profile/'+post.authorId),child:Row(children:[CircleAvatar(radius:22,backgroundColor:const Color(0xFFEAF8F2),child:Text(post.authorName.isEmpty?'?':post.authorName[0].toUpperCase(),style:const TextStyle(color:Color(0xFF00A66A),fontWeight:FontWeight.bold))),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(post.authorName,style:const TextStyle(fontWeight:FontWeight.w700)),const Text('View profile',style:TextStyle(color:Colors.black54,fontSize:12))]))])),
   const SizedBox(height:14),if(post.isQuestion)const Text('QUESTION',style:TextStyle(color:Color(0xFF00A66A),fontWeight:FontWeight.w800,fontSize:11)),const SizedBox(height:6),Text(post.text,style:const TextStyle(fontSize:16,height:1.45)),
   const SizedBox(height:10),Wrap(spacing:4,children:[
    IconButton(onPressed:isDemo?()=>setState(()=>_demoLiked=!_demoLiked):user==null?null:()=>_db!.toggleLike(post,user.uid),icon:Icon(liked?Icons.favorite:Icons.favorite_border,color:Colors.red)),Text(likes.toString()+' likes',style:const TextStyle(height:3)),
    IconButton(onPressed:user==null?null:()async{setState(()=>_saved=!_saved);await _db!.toggleBookmark(post.id,user.uid,_saved);},icon:Icon(_saved?Icons.bookmark:Icons.bookmark_border,color:const Color(0xFF00A66A))),Text(_saved?'Saved':'Save',style:const TextStyle(height:3)),
    if(user!=null&&user.uid==post.authorId)IconButton(tooltip:'Edit',onPressed:()=>context.push('/community/create',extra:post),icon:const Icon(Icons.edit_outlined)),
    if(user!=null&&user.uid!=post.authorId)IconButton(tooltip:'Report',onPressed:()=>_report(post,user),icon:const Icon(Icons.flag_outlined)),
   ]),
   const Divider(height:26),Row(children:[const Text('Comments',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),const Spacer(),Text((isDemo?2:post.commentsCount).toString())]),const SizedBox(height:8),
   if(isDemo)...[const ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:Color(0xFFEAF8F2),child:Icon(Icons.person,color:Color(0xFF00A66A))),title:Text('Student Guide',style:TextStyle(fontWeight:FontWeight.w600)),subtitle:Text('This is helpful. Thanks for sharing!')),const ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:Color(0xFFEAF8F2),child:Icon(Icons.person,color:Color(0xFF00A66A))),title:Text('Talib Team',style:TextStyle(fontWeight:FontWeight.w600)),subtitle:Text('You can also use Find Institute for more guidance.'))]
   else StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_db!.commentsStream(widget.id),builder:(c,s){final docs=s.data?.docs??[];if(docs.isEmpty)return const Text('No comments yet.');return Column(children:docs.map((d){final x=d.data();final cid=d.id;final accepted=cid==post.bestAnswerId;return ListTile(contentPadding:EdgeInsets.zero,leading:const CircleAvatar(backgroundColor:Color(0xFFEAF8F2),child:Icon(Icons.person,color:Color(0xFF00A66A))),title:Row(children:[Expanded(child:Text((x['authorName']??'Student').toString(),style:const TextStyle(fontWeight:FontWeight.w600))),if(accepted)const Text('BEST ANSWER',style:TextStyle(color:Color(0xFF00A66A),fontSize:10,fontWeight:FontWeight.bold))]),subtitle:Text((x['text']??'').toString()),trailing:user?.uid==post.authorId?IconButton(onPressed:()=>_db!.setBestAnswer(postId:post.id,commentId:cid,uid:user!.uid),icon:Icon(accepted?Icons.check_circle:Icons.check_circle_outline,color:const Color(0xFF00A66A))):null);}).toList());})
  ])),
  SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(12,6,12,10),child:Row(children:[Expanded(child:TextField(controller:_comment,enabled:user!=null&&!isDemo,onSubmitted:(_)=>_addComment(user),decoration:InputDecoration(hintText:user==null||isDemo?'Sign in to comment':'Write a comment...',filled:true,fillColor:Colors.grey.shade100,border:OutlineInputBorder(borderRadius:BorderRadius.circular(24),borderSide:BorderSide.none)))),IconButton(onPressed:user==null||isDemo?null:()=>_addComment(user),icon:const Icon(Icons.send,color:Color(0xFF00A66A))) ])))
 ]);}
 Future<void> _addComment(User? user)async{final t=_comment.text.trim();if(user==null||t.isEmpty||_db==null)return;try{await _db!.addComment(postId:widget.id,text:t,authorId:user.uid,authorName:user.displayName?.trim().isNotEmpty==true?user.displayName!.trim():(user.email??'Student'));_comment.clear();}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not add comment.')));}}
 Future<void> _report(Post p,User u)async{final reason=await showDialog<String>(context:context,builder:(_)=>SimpleDialog(title:const Text('Report post'),children:['Spam','Harassment','Fake information','Inappropriate','Scam','Other'].map((x)=>SimpleDialogOption(onPressed:()=>Navigator.pop(context,x),child:Text(x))).toList()));if(reason!=null)await _db!.report(reporterId:u.uid,targetId:p.id,targetType:'post',reason:reason);}
}