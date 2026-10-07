import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/post.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/demo_data_service.dart';

class CommunityScreen extends StatefulWidget{final String? instituteId;final String? instituteName;const CommunityScreen({super.key,this.instituteId,this.instituteName});@override State<CommunityScreen> createState()=>_CommunityScreenState();}
class _CommunityScreenState extends State<CommunityScreen>{
 static const green=Color(0xFF00A66A),dark=Color(0xFF00543D),light=Color(0xFFEAF8F2);DatabaseService? _db;final _search=TextEditingController();bool popular=false;String query='';String category='All';
 final cats=const ['All','General','Admission Help','Career','Scholarships','Study Help','Institute Reviews','Jobs/Internships','Announcements'];
 @override void dispose(){_search.dispose();super.dispose();}
 void login()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please sign in to create, like or save posts.')));
 @override Widget build(BuildContext context){
   final ready=FirebaseService.initialized;
   if(ready&&_db==null)_db=DatabaseService();
   final realUser=ready?FirebaseAuth.instance.currentUser:null;
   final identity=ActiveProfileController.instance;
   final user=realUser;
   final demoActive=identity.isDemoActive;
   final canInteract=user!=null||demoActive;
   
   return Scaffold(
     appBar:AppBar(title:Text(widget.instituteName==null?'Community':widget.instituteName!+' Community'),actions:[IconButton(tooltip:'Notifications',icon:const Icon(Icons.notifications_none),onPressed:()=>context.push('/notifications')),PopupMenuButton<bool>(onSelected:(v)=>setState(()=>popular=v),itemBuilder:(_)=>const[PopupMenuItem(value:false,child:Text('Latest')),PopupMenuItem(value:true,child:Text('Popular'))])]),
     floatingActionButton:FloatingActionButton.extended(backgroundColor:green,onPressed:!canInteract?login:()=>context.push('/community/create?instituteId='+(widget.instituteId??'')+'&instituteName='+Uri.encodeComponent(widget.instituteName??'')),icon:const Icon(Icons.add),label:const Text('Post')),
     body:Column(children:[
       Container(margin:const EdgeInsets.fromLTRB(12,10,12,6),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:light,borderRadius:BorderRadius.circular(12)),child:const Row(children:[Icon(Icons.groups_rounded,color:dark,size:28),SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Need Guidance?',style:TextStyle(color:dark,fontWeight:FontWeight.w700)),Text('Ask students and professionals for guidance.',style:TextStyle(fontSize:12,color:Colors.black54))]))])),
       Padding(padding:const EdgeInsets.fromLTRB(12,4,12,6),child:TextField(controller:_search,onChanged:(v)=>setState(()=>query=v.trim()),decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Search posts and students',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:BorderSide.none)))),
       SizedBox(height:42,child:ListView.separated(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),itemCount:cats.length,itemBuilder:(_,i)=>ChoiceChip(label:Text(cats[i]),selected:category==cats[i],onSelected:(_)=>setState(()=>category=cats[i])),separatorBuilder:(_,__)=>const SizedBox(width:6))),
       Expanded(child:demoActive
         ? StreamBuilder<List<Post>>(stream:_demoPostsStream(),builder:(context,s)=>_postList(s.data??const <Post>[],user))
         : ready
           ? StreamBuilder<Set<String>>(stream:user==null?const Stream<Set<String>>.empty():_db!.blockedUserIdsStream(user.uid),builder:(context,b){
               final blocked=b.data??const <String>{};
               return StreamBuilder<List<Post>>(stream:_db!.postsStream(popular:popular,category:category,query:query),builder:(context,s){
                 if(s.hasError)return _empty('Unable to load community posts.');
                 if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
                 return _postList((s.data??[]).where((p)=>!blocked.contains(p.authorId)).where((p)=>widget.instituteId==null||p.instituteId==widget.instituteId).toList(),user);
               });
             })
           : _empty('Firebase is not initialized.')
       )
     ])
   );
 } Stream<List<Post>> _demoPostsStream() async* { yield DemoDataService.instance.posts(category:category,query:query); yield* DemoDataService.instance.changes.map((_)=>DemoDataService.instance.posts(category:category,query:query)); }
 List<Post> _demoPosts()=>[Post(id:'demo-1',text:'Welcome to Talib Community! Ask questions, share guidance and help other students.',authorId:'demo-user-1',authorName:'Talib Community',createdAt:DateTime.now().subtract(const Duration(minutes:15)),category:'General',likesCount:12,commentsCount:4),Post(id:'demo-2',text:'Which institute is best for your next education program? Share your experience and help fellow students.',authorId:'demo-user-2',authorName:'Student Guide',createdAt:DateTime.now().subtract(const Duration(hours:2)),category:'Institute Reviews',likesCount:8,commentsCount:3,isQuestion:true),Post(id:'demo-3',text:'Need admission guidance? You can use Find Institute to compare institutes, programs and eligibility.',authorId:'demo-user-3',authorName:'Talib Team',createdAt:DateTime.now().subtract(const Duration(hours:5)),category:'Admission Help',likesCount:6,commentsCount:2)];
 Widget _empty(String x)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Text(x,textAlign:TextAlign.center)));
 Widget _postList(List<Post> posts,User? user){if(posts.isEmpty)return _empty('No community posts found.');final identity=ActiveProfileController.instance;final uid=identity.resolveUid(user?.uid??'');final canInteract=user!=null||identity.isDemoActive;return ListView.separated(padding:const EdgeInsets.fromLTRB(12,6,12,90),itemCount:posts.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){final p=posts[i];final owner=uid==p.authorId;return _PostCard(post:p,user:user,onOpen:()=>context.push('/community/post/'+p.id),onAuthor:()=>context.push('/profile/'+p.authorId),onLike:!canInteract?null:()=>_toggleLike(p,user?.uid??uid),onBookmark:!canInteract?null:()=>_toggleBookmark(p,user?.uid??uid),onDelete:owner?()=>_delete(p):null,onEdit:owner?()=>context.push('/community/create',extra:p):null,onReport:!canInteract?null:()=>_report(p,user!),onPoll:!canInteract||p.pollOptions.isEmpty?null:(i)=>_db!.votePoll(postId:p.id,uid:user?.uid??uid,option:i),);});}
 Future<void> _toggleLike(Post p,String uid)async{try{if(ActiveProfileController.instance.isDemoActive){DemoDataService.instance.toggleLike(p.id,uid);}else if(_db!=null){await _db!.toggleLike(p,uid);}}catch(_){}}
 Future<void> _toggleBookmark(Post p,String uid)async{try{if(ActiveProfileController.instance.isDemoActive){DemoDataService.instance.toggleBookmark(uid,p.id,true);}else if(_db!=null){await _db!.toggleBookmark(p.id,uid,true);}if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Saved to bookmarks')));}catch(_){}} 
 Future<void> _delete(Post p)async{final yes=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Delete post?'),content:const Text('This post will be permanently deleted.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Delete'))]));if(yes==true&&_db!=null)await _db!.deletePost(p.id);}
 Future<void> _report(Post p,User u)async{final reason=await showDialog<String>(context:context,builder:(_)=>SimpleDialog(title:const Text('Report post'),children:['Spam','Harassment','Fake information','Inappropriate','Scam','Other'].map((x)=>SimpleDialogOption(onPressed:()=>Navigator.pop(context,x),child:Text(x))).toList()));if(reason!=null)await _db!.report(reporterId:u.uid,targetId:p.id,targetType:'post',reason:reason);}
}
class _PostCard extends StatelessWidget{final Post post;final User? user;final VoidCallback onOpen,onAuthor;final VoidCallback? onLike,onBookmark,onDelete,onEdit,onReport;final Future<void> Function(int)? onPoll;const _PostCard({required this.post,required this.user,required this.onOpen,required this.onAuthor,this.onLike,this.onBookmark,this.onDelete,this.onEdit,this.onReport,this.onPoll});
 @override Widget build(BuildContext context){final liked=post.likedByUser(ActiveProfileController.instance.resolveUid(user?.uid??''));return Card(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),child:Padding(padding:const EdgeInsets.fromLTRB(13,12,9,8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Row(children:[InkWell(onTap:onAuthor,child:CircleAvatar(backgroundColor:const Color(0xFFEAF8F2),child:Text(post.authorName.isEmpty?'?':post.authorName[0].toUpperCase(),style:const TextStyle(color:Color(0xFF00A66A),fontWeight:FontWeight.bold)))),const SizedBox(width:10),Expanded(child:InkWell(onTap:onAuthor,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(post.authorName,style:const TextStyle(fontWeight:FontWeight.w700,color:Color(0xFF00543D))),Text(post.category,style:const TextStyle(fontSize:11,color:Colors.black45))]))),PopupMenuButton<String>(onSelected:(v){if(v=='edit'&&onEdit!=null)onEdit!();if(v=='delete'&&onDelete!=null)onDelete!();if(v=='report'&&onReport!=null)onReport!();if(v=='save'&&onBookmark!=null)onBookmark!();},itemBuilder:(_)=>[if(onEdit!=null)const PopupMenuItem(value:'edit',child:Text('Edit')),if(onDelete!=null)const PopupMenuItem(value:'delete',child:Text('Delete')),if(onBookmark!=null)const PopupMenuItem(value:'save',child:Text('Save')),if(onReport!=null)const PopupMenuItem(value:'report',child:Text('Report'))])]),
 if(post.isQuestion)const Padding(padding:EdgeInsets.only(top:5),child:Text('QUESTION',style:TextStyle(fontSize:10,color:Color(0xFF00A66A),fontWeight:FontWeight.w800))),const SizedBox(height:8),InkWell(onTap:onOpen,child:Text(post.text,style:const TextStyle(fontSize:14,height:1.4))),const SizedBox(height:7),
 if(post.pollOptions.isNotEmpty) ...[
   const Text('Poll',style:TextStyle(fontWeight:FontWeight.w700,color:Color(0xFF00543D))),
   const SizedBox(height:6),
   ...List.generate(post.pollOptions.length,(i){final total=post.pollVotes.values.fold<int>(0,(a,b)=>a+b);final votes=post.pollVotes[i.toString()]??0;final pct=total==0?0:votes/total;return Padding(padding:const EdgeInsets.only(bottom:6),child:InkWell(onTap:onPoll==null?null:()=>onPoll!(i),borderRadius:BorderRadius.circular(8),child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:9),decoration:BoxDecoration(border:Border.all(color:Color(0xFFB7DCCB)),borderRadius:BorderRadius.circular(8)),child:Row(children:[Expanded(child:Text(post.pollOptions[i])),Text((pct*100).round().toString()+'%  ('+votes.toString()+')',style:const TextStyle(fontSize:11,color:Colors.black54))]))));}),
   const SizedBox(height:4),
 ],
 Row(children:[IconButton(onPressed:onLike,icon:Icon(liked?Icons.favorite:Icons.favorite_border,color:liked?Colors.red:Color(0xFF00A66A))),Text(post.likesCount.toString()),IconButton(onPressed:onOpen,icon:const Icon(Icons.comment_outlined,color:Color(0xFF00A66A))),Text(post.commentsCount.toString()),const Spacer(),TextButton(onPressed:onOpen,child:const Text('View'))]) ])));}}
