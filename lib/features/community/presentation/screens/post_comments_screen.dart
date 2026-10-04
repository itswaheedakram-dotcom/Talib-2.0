import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../models/post.dart';

class PostCommentsScreen extends StatefulWidget {
  final String id;
  const PostCommentsScreen({super.key, required this.id});
  @override State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  DatabaseService? _db;
  final _comment = TextEditingController();
  bool _demoLiked = false;
  final List<Map<String,String>> _demoComments = [
    {'name':'Student Guide','text':'This is helpful. Thanks for sharing!'},
    {'name':'Talib Team','text':'You can also use Find Institute for more guidance.'},
  ];
  bool get isDemo => widget.id.startsWith('demo-');
  @override void dispose(){_comment.dispose();super.dispose();}

  @override Widget build(BuildContext context){
    final ready=FirebaseService.initialized;
    if(ready&&_db==null)_db=DatabaseService();
    final user=ready?FirebaseAuth.instance.currentUser:null;
    if(isDemo||!ready)return _demoPage(context,user);
    return Scaffold(
      appBar:AppBar(title:const Text('Post'),leading:IconButton(icon:const Icon(Icons.arrow_back_ios_new,size:18),onPressed:()=>context.pop())),
      body:StreamBuilder<DocumentSnapshot<Map<String,dynamic>>>(
        stream:FirebaseFirestore.instance.collection('posts').doc(widget.id).snapshots(),
        builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError||!s.hasData||!s.data!.exists)return const Center(child:Text('Post not found.'));return _content(context,Post.fromDoc(s.data!),user);},
      ),
    );
  }

  Widget _demoPage(BuildContext context,User? user){
    final data={'demo-1':{'name':'Talib Community','text':'Welcome to Talib Community! Ask questions, share guidance and help other students.','likes':'12'},'demo-2':{'name':'Student Guide','text':'Which institute is best for your next education program? Share your experience and help fellow students.','likes':'8'},'demo-3':{'name':'Talib Team','text':'Need admission guidance? You can use Find Institute to compare institutes, programs and eligibility.','likes':'6'}}[widget.id]??{'name':'Student','text':'Community post','likes':'0'};
    final p=Post(id:widget.id,text:data['text']!,authorId:'demo-user-1',authorName:data['name']!,createdAt:DateTime.now(),likesCount:int.parse(data['likes']!));
    return Scaffold(appBar:AppBar(title:const Text('Post'),leading:IconButton(icon:const Icon(Icons.arrow_back_ios_new,size:18),onPressed:()=>context.pop())),body:_content(context,p,user));
  }

  Widget _content(BuildContext context,Post post,User? user){
    final likes=post.likesCount+(_demoLiked?1:0);
    return Column(children:[
      Expanded(child:ListView(padding:const EdgeInsets.all(14),children:[
        InkWell(onTap:()=>context.push('/profile/'+post.authorId),child:Row(children:[
          CircleAvatar(radius:22,backgroundColor:const Color(0xFFEAF8F2),child:Text(post.authorName.isEmpty?'?':post.authorName[0].toUpperCase(),style:const TextStyle(color:Color(0xFF00A66A),fontWeight:FontWeight.bold))),
          const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(post.authorName,style:const TextStyle(fontWeight:FontWeight.w700)),const Text('View profile',style:TextStyle(color:Colors.black54,fontSize:12))]))
        ])),
        const SizedBox(height:14),Text(post.text,style:const TextStyle(fontSize:16,height:1.45)),const SizedBox(height:12),
        Row(children:[
          IconButton(onPressed:isDemo?()=>setState(()=>_demoLiked=!_demoLiked):user==null?null:()=>_db!.toggleLike(post,user.uid),icon:Icon((_demoLiked||post.likedByUser(user?.uid))?Icons.favorite:Icons.favorite_border,color:Colors.red)),
          Text('${likes} likes'),const SizedBox(width:16),const Icon(Icons.comment_outlined,color:Color(0xFF00A66A)),const SizedBox(width:5),Text('${isDemo?_demoComments.length:post.commentsCount} comments')
        ]),
        const Divider(height:28),const Text('Comments',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),const SizedBox(height:8),
        if(isDemo) ..._demoComments.map((c)=>ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(backgroundColor:const Color(0xFFEAF8F2),child:Text(c['name']![0])),title:Text(c['name']!,style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text(c['text']!)))
        else StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:_db!.commentsStream(widget.id),builder:(context,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());final docs=s.data?.docs??[];if(docs.isEmpty)return const Text('No comments yet.');return Column(children:docs.map((d){final x=d.data();return ListTile(contentPadding:EdgeInsets.zero,leading:const CircleAvatar(backgroundColor:Color(0xFFEAF8F2),child:Icon(Icons.person,color:Color(0xFF00A66A))),title:Text((x['authorName']??'Student').toString(),style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text((x['text']??'').toString()));}).toList());})
      ])),
      SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(12,6,12,10),child:Row(children:[
        Expanded(child:TextField(controller:_comment,enabled:user!=null&&!isDemo,onSubmitted:(_)=>_addComment(user),decoration:InputDecoration(hintText:isDemo||user==null?'Sign in to comment':'Write a comment...',filled:true,fillColor:Colors.grey.shade100,border:OutlineInputBorder(borderRadius:BorderRadius.circular(24),borderSide:BorderSide.none)))),
        IconButton(onPressed:user==null||isDemo?null:()=>_addComment(user),icon:const Icon(Icons.send,color:Color(0xFF00A66A)))
      ])))
    ]);
  }

  Future<void> _addComment(User? user)async{final text=_comment.text.trim();if(user==null||text.isEmpty||_db==null)return;final name=user.displayName?.trim().isNotEmpty==true?user.displayName!.trim():(user.email??'Student');try{await _db!.addComment(postId:widget.id,text:text,authorId:user.uid,authorName:name);_comment.clear();}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not add comment.')));}}
}
