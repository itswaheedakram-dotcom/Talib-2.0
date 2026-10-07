import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../models/post.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';

class CommunityScreen extends StatefulWidget {
  final String? instituteId;
  final String? instituteName;
  const CommunityScreen({super.key,this.instituteId,this.instituteName});
  @override State<CommunityScreen> createState()=>_CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const categories=[
    'All','General','Admission Help','Career','Scholarships','Study Help',
    'Institute Reviews','Jobs/Internships','Announcements'
  ];
  final _db=DatabaseService();
  final _search=TextEditingController();
  bool popular=false;
  String query='';
  String category='All';

  @override void dispose(){_search.dispose();super.dispose();}

  void _error(Object e){
    final msg=e.toString().replaceFirst('Exception: ','').trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor:AppColors.darkGreen,
        content:Text(msg.isEmpty?'Action failed.':msg,style:const TextStyle(color:AppColors.white))),
    );
  }

  @override Widget build(BuildContext context){
    final ready=FirebaseService.initialized;
    final user=ready?FirebaseAuth.instance.currentUser:null;
    final uid=user?.uid??'demo-current-user';

    return Scaffold(
      appBar:AppBar(
        title:Text(widget.instituteName==null?'Community':'${widget.instituteName} Community'),
        actions:[
          IconButton(tooltip:'Notifications',icon:const Icon(Icons.notifications_none),
            onPressed:()=>context.push('/notifications')),
          PopupMenuButton<bool>(
            onSelected:(v)=>setState(()=>popular=v),
            itemBuilder:(_)=>const[
              PopupMenuItem(value:false,child:Text('Latest')),
              PopupMenuItem(value:true,child:Text('Popular')),
            ],
          ),
        ],
      ),
      floatingActionButton:FloatingActionButton.extended(
        onPressed:ready&&user==null
            ? ()=>_error('Please sign in to create a post.')
            : ()=>context.push(
                '/community/create?instituteId=${widget.instituteId??''}'
                '&instituteName=${Uri.encodeComponent(widget.instituteName??'')}'),
        icon:const Icon(Icons.add),label:const Text('Post'),
      ),
      body:Column(children:[
        Container(
          margin:const EdgeInsets.fromLTRB(12,10,12,6),
          padding:const EdgeInsets.all(13),
          decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(12)),
          child:const Row(children:[
            Icon(Icons.groups_rounded,color:AppColors.darkGreen,size:28),
            SizedBox(width:10),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Need Guidance?',style:TextStyle(color:AppColors.darkGreen,fontWeight:FontWeight.w700)),
              Text('Ask students and professionals for guidance.',style:TextStyle(fontSize:12,color:AppColors.mutedText)),
            ])),
          ]),
        ),
        Padding(
          padding:const EdgeInsets.fromLTRB(12,4,12,6),
          child:TextField(controller:_search,onChanged:(v)=>setState(()=>query=v.trim()),
            decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search posts and students')),
        ),
        SizedBox(
          height:42,
          child:ListView.separated(
            scrollDirection:Axis.horizontal,
            padding:const EdgeInsets.symmetric(horizontal:12),
            itemCount:categories.length,
            itemBuilder:(_,i)=>ChoiceChip(
              label:Text(categories[i]),selected:category==categories[i],
              onSelected:(_)=>setState(()=>category=categories[i]),
            ),
            separatorBuilder:(_,__)=>const SizedBox(width:6),
          ),
        ),
        Expanded(
          child:StreamBuilder<Set<String>>(
            stream:_db.blockedUserIdsStream(uid),
            builder:(context,b){
              final blocked=b.data??const <String>{};
              return StreamBuilder<List<Post>>(
                stream:_db.postsStream(popular:popular,category:category,query:query),
                builder:(context,s){
                  if(s.hasError)return _errorView(s.error!);
                  if(s.connectionState==ConnectionState.waiting)
                    return const Center(child:CircularProgressIndicator());
                  final posts=(s.data??[])
                    .where((p)=>!blocked.contains(p.authorId))
                    .where((p)=>widget.instituteId==null||p.instituteId==widget.instituteId)
                    .toList();
                  return _postList(posts,user,uid);
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _errorView(Object e)=>Center(child:Padding(
    padding:const EdgeInsets.all(24),
    child:Column(mainAxisSize:MainAxisSize.min,children:[
      const Icon(Icons.error_outline,color:AppColors.darkGreen,size:40),
      const SizedBox(height:10),
      Text(e.toString(),textAlign:TextAlign.center,style:const TextStyle(color:AppColors.darkGreen)),
      const SizedBox(height:12),
      FilledButton(onPressed:()=>setState((){}),child:const Text('Retry')),
    ]),
  ));

  Widget _postList(List<Post> posts,User? user,String uid){
    if(posts.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('No community posts found.')));
    return ListView.separated(
      padding:const EdgeInsets.fromLTRB(12,6,12,90),
      itemCount:posts.length,
      separatorBuilder:(_,__)=>const SizedBox(height:8),
      itemBuilder:(_,i){
        final p=posts[i];
        return _PostCard(
          post:p,uid:uid,
          onOpen:()=>context.push('/community/post/${p.id}'),
          onAuthor:()=>context.push('/profile/${p.authorId}'),
          onLike:()=>_like(p,uid),
          onDelete:p.authorId==uid?()=>_delete(p):null,
          onEdit:p.authorId==uid?()=>context.push('/community/create',extra:p):null,
          onReport:user==null?null:()=>_report(p,user),
          onPoll:p.pollOptions.isEmpty?null:(option)=>_vote(p,uid,option),
        );
      },
    );
  }

  Future<void> _like(Post p,String uid)async{try{await _db.toggleLike(p,uid);}catch(e){_error(e);}}
  Future<void> _vote(Post p,String uid,int option)async{try{await _db.votePoll(postId:p.id,uid:uid,option:option);}catch(e){_error(e);}}

  Future<void> _delete(Post p)async{
    final yes=await showDialog<bool>(
      context:context,
      builder:(_)=>AlertDialog(
        title:const Text('Delete post?'),
        content:const Text('This post will be permanently deleted.'),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
          FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Delete')),
        ],
      ),
    );
    if(yes!=true)return;
    try{await _db.deletePost(p.id);}catch(e){_error(e);}
  }

  Future<void> _report(Post p,User u)async{
    final reason=await showDialog<String>(
      context:context,
      builder:(_)=>SimpleDialog(
        title:const Text('Report post'),
        children:['Spam','Harassment','Fake information','Inappropriate','Scam','Other']
          .map((x)=>SimpleDialogOption(onPressed:()=>Navigator.pop(context,x),child:Text(x))).toList(),
      ),
    );
    if(reason==null)return;
    try{await _db.report(reporterId:u.uid,targetId:p.id,targetType:'post',reason:reason);}catch(e){_error(e);}
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final String uid;
  final VoidCallback onOpen,onAuthor,onLike;
  final VoidCallback? onDelete,onEdit,onReport;
  final Future<void> Function(int)? onPoll;
  const _PostCard({required this.post,required this.uid,required this.onOpen,required this.onAuthor,required this.onLike,this.onDelete,this.onEdit,this.onReport,this.onPoll});

  @override Widget build(BuildContext context){
    final liked=post.likedByUser(uid);
    return Card(
      child:Padding(
        padding:const EdgeInsets.fromLTRB(13,12,9,8),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            InkWell(
              onTap:onAuthor,
              child:CircleAvatar(
                backgroundColor:AppColors.softGreen,
                child:Text(post.authorName.isEmpty?'?':post.authorName[0].toUpperCase(),
                  style:const TextStyle(color:AppColors.primaryGreen,fontWeight:FontWeight.bold)),
              ),
            ),
            const SizedBox(width:10),
            Expanded(child:InkWell(onTap:onAuthor,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(post.authorName,style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.darkGreen)),
              Text(post.category,style:const TextStyle(fontSize:11,color:AppColors.mutedText)),
            ]))),
            PopupMenuButton<String>(
              onSelected:(v){if(v=='edit'&&onEdit!=null)onEdit!();if(v=='delete'&&onDelete!=null)onDelete!();if(v=='report'&&onReport!=null)onReport!();},
              itemBuilder:(_)=>[
                if(onEdit!=null)const PopupMenuItem(value:'edit',child:Text('Edit')),
                if(onDelete!=null)const PopupMenuItem(value:'delete',child:Text('Delete')),
                if(onReport!=null)const PopupMenuItem(value:'report',child:Text('Report')),
              ],
            ),
          ]),
          if(post.isQuestion)const Padding(
            padding:EdgeInsets.only(top:5),
            child:Text('QUESTION',style:TextStyle(fontSize:10,color:AppColors.primaryGreen,fontWeight:FontWeight.w800)),
          ),
          const SizedBox(height:8),
          InkWell(onTap:onOpen,child:Text(post.text,style:const TextStyle(fontSize:14,height:1.4,color:AppColors.darkGreen))),
          if(post.pollOptions.isNotEmpty)...[
            const SizedBox(height:8),
            const Text('Poll',style:TextStyle(fontWeight:FontWeight.w700,color:AppColors.darkGreen)),
            const SizedBox(height:6),
            ...List.generate(post.pollOptions.length,(i){
              final total=post.pollVotes.values.fold<int>(0,(a,b)=>a+b);
              final votes=post.pollVotes[i.toString()]??0;
              final pct=total==0?0.0:votes/total;
              return Padding(
                padding:const EdgeInsets.only(bottom:6),
                child:InkWell(
                  onTap:onPoll==null?null:()=>onPoll!(i),
                  borderRadius:BorderRadius.circular(8),
                  child:Container(
                    padding:const EdgeInsets.symmetric(horizontal:10,vertical:9),
                    decoration:BoxDecoration(border:Border.all(color:AppColors.divider),borderRadius:BorderRadius.circular(8)),
                    child:Row(children:[
                      Expanded(child:Text(post.pollOptions[i])),
                      Text('${(pct*100).round()}%  ($votes)',style:const TextStyle(fontSize:11,color:AppColors.mutedText)),
                    ]),
                  ),
                ),
              );
            }),
          ],
          Row(children:[
            IconButton(onPressed:onLike,icon:Icon(liked?Icons.favorite:Icons.favorite_border,color:liked?AppColors.actionAccent:AppColors.primaryGreen)),
            Text(post.likesCount.toString()),
            IconButton(onPressed:onOpen,icon:const Icon(Icons.comment_outlined,color:AppColors.primaryGreen)),
            Text(post.commentsCount.toString()),
            const Spacer(),
            TextButton(onPressed:onOpen,child:const Text('View')),
          ]),
        ]),
      ),
    );
  }
}
