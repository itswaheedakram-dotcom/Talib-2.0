import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../models/post.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/demo_data_service.dart';
import '../../timeline_topics.dart';
import '../../../institutes/data/institute_repository.dart';

class CommunityScreen extends StatefulWidget{
  final String? instituteId;final String? instituteName;
  const CommunityScreen({super.key,this.instituteId,this.instituteName});
  @override State<CommunityScreen> createState()=>_CommunityScreenState();
}
class _CommunityScreenState extends State<CommunityScreen>{
  final _db=DatabaseService();final _search=TextEditingController();
  bool popular=false;String query='';String category='All';
  int timelineTab=0;
  String? _selectedInstituteId;
  Set<String> _topics=TimelineTopics.defaults.toSet();
  final cats=const ['All','General','Admission Help','Career','Scholarships','Study Help','Institute Reviews','Jobs/Internships','Announcements'];
  @override void initState(){super.initState();InstituteRepository.instance.load();}
  @override void dispose(){_search.dispose();super.dispose();}
  String _errorText(Object error){final raw=error.toString().trim();if(raw.isEmpty)return 'Unknown error.';return raw.replaceFirst(RegExp(r'^Exception:\s*'),'');}
  void _showError(Object error){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_errorText(error)),duration:const Duration(seconds:5)));}
  void _login()=>_showError(StateError('Please sign in to create, like or save posts.'));
  
  Widget _topicTab(String name){
    final selected=timelineTab>=2&&_selectedInstituteId==null&&category==name;
    return InkWell(
      onTap:()=>setState((){timelineTab=2;_selectedInstituteId=null;category=name;}),
      child:Padding(
        padding:const EdgeInsets.symmetric(horizontal:12,vertical:12),
        child:Text(name,style:TextStyle(fontWeight:FontWeight.w800,color:selected?AppColors.primaryGreen:AppColors.homeMutedText)),
      ),
    );
  }

  Widget _instituteTab(Institute institute){
    final selected=_selectedInstituteId==institute.id;
    return InkWell(
      onTap:()=>setState((){timelineTab=3;_selectedInstituteId=institute.id;category='All';}),
      child:Padding(
        padding:const EdgeInsets.symmetric(horizontal:12,vertical:12),
        child:Text(institute.name,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w800,color:selected?AppColors.primaryGreen:AppColors.homeMutedText)),
      ),
    );
  }

  @override Widget build(BuildContext context){
    final ready=FirebaseService.initialized;
    final user=ready?FirebaseAuth.instance.currentUser:null;
    final identity=ActiveProfileController.instance;
    final demo=identity.isDemoActive;
    final canInteract=user!=null||demo;
    final uid=identity.resolveUid(user?.uid??'');

    return Scaffold(
      appBar:AppBar(title:Text(widget.instituteName==null?'Community':'${widget.instituteName} Community'),actions:[
        IconButton(tooltip:'Notifications',icon:const Icon(Icons.notifications_none),onPressed:()=>context.push('/notifications')),
        PopupMenuButton<bool>(onSelected:(v)=>setState(()=>popular=v),itemBuilder:(_)=>const[
          PopupMenuItem(value:false,child:Text('Latest')),PopupMenuItem(value:true,child:Text('Popular')),
        ]),
      ]),
      floatingActionButton:FloatingActionButton.extended(
        onPressed:!canInteract?_login:()=>context.push('/community/create?instituteId=${Uri.encodeComponent(widget.instituteId??'')}&instituteName=${Uri.encodeComponent(widget.instituteName??'')}'),
        icon:const Icon(Icons.add),label:const Text('Post'),
      ),
      body:Column(children:[
        Container(margin:const EdgeInsets.fromLTRB(12,10,12,6),padding:const EdgeInsets.all(13),
          decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(12)),
          child:const Row(children:[
            Icon(Icons.groups_rounded,color:AppColors.darkGreen,size:28),SizedBox(width:10),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Need Guidance?',style:TextStyle(color:AppColors.darkGreen,fontWeight:FontWeight.w700)),
              Text('Ask students and professionals for guidance.',style:TextStyle(fontSize:12,color:AppColors.homeMutedText)),
            ])),
          ])),
        AnimatedBuilder(
          animation:InstituteRepository.instance,
          builder:(context,_){
            return SizedBox(
              height:48,
              child:StreamBuilder<Set<String>>(
                stream:(uid.isEmpty&&!demo)?const Stream<Set<String>>.empty():_db.timelineTopicsStream(uid),
                builder:(context,pref){
                  final topics=pref.data??_topics;
                  _topics=topics;
                  final tabs=<Widget>[
                    _timelineTab('For You',0),
                    _timelineTab('Following',1),
                    ...topics.map(_topicTab),
                    ...InstituteRepository.instance.items.map(_instituteTab),
                    InkWell(
                      onTap:()=>context.push('/community/add-to-timeline').then((_)=>(mounted?setState((){}):null)),
                      child:const Padding(
                        padding:EdgeInsets.symmetric(horizontal:12,vertical:12),
                        child:Text('+ Add',style:TextStyle(fontWeight:FontWeight.w800,color:AppColors.primaryGreen)),
                      ),
                    ),
                  ];
                  return ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:4),children:tabs);
                },
              ),
            );
          },
        ),
        Padding(padding:const EdgeInsets.fromLTRB(12,0,12,6),child:TextField(
          controller:_search,onChanged:(v)=>setState(()=>query=v.trim()),
          decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Search posts and students',
            filled:true,fillColor:AppColors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:BorderSide.none)),
        )),
        Expanded(child:timelineTab==0
          ?_postFeed(user,demo,ready,_topics,null,null)
          :timelineTab==1
            ?StreamBuilder<Set<String>>(stream:(uid.isEmpty&&!demo)?const Stream<Set<String>>.empty():_db.followingIdsStream(uid),
                builder:(context,follow)=>_postFeed(user,demo,ready,_topics,follow.data??const <String>{},null))
            :_postFeed(user,demo,ready,{category},null,_selectedInstituteId)),
      ]),
    );
  }

  Widget _timelineTab(String label,int index)=>InkWell(
    onTap:()=>setState((){timelineTab=index;category='All';}),
    child:Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Center(
      child:Text(label,style:TextStyle(fontWeight:FontWeight.w800,color:timelineTab==index?AppColors.primaryGreen:AppColors.homeMutedText)))),
  );

  Widget _postFeed(User? user,bool demo,bool ready,Set<String> topics,Set<String>? following,String? instituteFilterId){
    final stream=demo?_demoPostsStream():ready?_db.postsStream(popular:popular,category:instituteFilterId!=null?'All':category,query:query):const Stream<List<Post>>.empty();
    return StreamBuilder<List<Post>>(stream:stream,builder:(context,s){
      if(s.hasError)return _errorState(s.error!);
      if(!demo&&!ready)return _errorState(StateError(FirebaseService.initializationErrorMessage.isEmpty?'Firebase is not initialized.':FirebaseService.initializationErrorMessage));
      if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      var posts=s.data??const <Post>[];
      if(instituteFilterId!=null){
        posts=posts.where((p)=>p.instituteId==instituteFilterId).toList();
      }else if(timelineTab==0){
        posts=posts.where((p)=>topics.contains(p.category)||p.category=='General').toList();
      }else{
        posts=posts.where((p)=>following?.contains(p.authorId)==true).toList();
      }
      if(widget.instituteId!=null)posts=posts.where((p)=>p.instituteId==widget.instituteId).toList();
      return _postList(posts,user);
    });
  }

  Widget _errorState(Object error)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Text(_errorText(error),textAlign:TextAlign.center),const SizedBox(height:12),
    OutlinedButton(onPressed:()=>setState((){}),child:const Text('Retry')),
  ])));
  
  Stream<List<Post>> _demoPostsStream()async*{
    List<Post> current()=>DemoDataService.instance.posts(category:category,query:query)
      .where((p)=>widget.instituteId==null||p.instituteId==widget.instituteId).toList();
    yield current();yield*DemoDataService.instance.changes.map((_)=>current());
  }
  
  Widget _postList(List<Post> posts,User? user){
    if(posts.isEmpty)return const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('No community posts found.')));
    final identity=ActiveProfileController.instance;final uid=identity.resolveUid(user?.uid??'');final canInteract=user!=null||identity.isDemoActive;
    return ListView.separated(padding:const EdgeInsets.fromLTRB(12,6,12,90),itemCount:posts.length,
      separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){
        final p=posts[i];final owner=uid==p.authorId;
        return _PostCard(post:p,user:user,onOpen:()=>context.push('/community/post/${p.id}'),
          onAuthor:()=>context.push('/profile/${p.authorId}'),onLike:!canInteract?null:()=>_toggleLike(p,uid),
          onBookmark:!canInteract?null:()=>_toggleBookmark(p,uid),onDelete:owner?()=>_delete(p):null,
          onEdit:owner?()=>context.push('/community/create',extra:p):null,onReport:!canInteract?null:()=>_report(p,user,uid),
          onPoll:!canInteract||p.pollOptions.isEmpty?null:(option)=>_votePoll(p,uid,option));
      });
  }
  Future<void> _toggleLike(Post p,String uid)async{try{await _db.toggleLike(p,uid);}catch(error){_showError(error);}}
  Future<void> _toggleBookmark(Post p,String uid)async{try{await _db.toggleBookmark(p.id,uid,true);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Saved to bookmarks')));}catch(error){_showError(error);}}
  Future<void> _votePoll(Post p,String uid,int option)async{try{await _db.votePoll(postId:p.id,uid:uid,option:option);}catch(error){_showError(error);}}
  Future<void> _delete(Post p)async{
    final yes=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Delete post?'),
      content:const Text('This post will be permanently deleted.'),actions:[
        TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Delete'))]));
    if(yes!=true)return;try{await _db.deletePost(p.id);}catch(error){_showError(error);}
  }
  Future<void> _report(Post p,User? user,String uid)async{
    final reason=await showDialog<String>(context:context,builder:(_)=>SimpleDialog(title:const Text('Report post'),
      children:['Spam','Harassment','Fake information','Inappropriate','Scam','Other'].map((x)=>SimpleDialogOption(onPressed:()=>Navigator.pop(context,x),child:Text(x))).toList()));
    if(reason==null)return;try{await _db.report(reporterId:user?.uid??uid,targetId:p.id,targetType:'post',reason:reason);}catch(error){_showError(error);}
  }
}

class _PostCard extends StatelessWidget{
  final Post post;final User? user;final VoidCallback onOpen,onAuthor;
  final VoidCallback? onLike,onBookmark,onDelete,onEdit,onReport;final Future<void> Function(int)? onPoll;
  const _PostCard({required this.post,required this.user,required this.onOpen,required this.onAuthor,this.onLike,this.onBookmark,this.onDelete,this.onEdit,this.onReport,this.onPoll});
  @override Widget build(BuildContext context){
    final liked=post.likedByUser(ActiveProfileController.instance.resolveUid(user?.uid??''));
    return Card(child:Padding(padding:const EdgeInsets.fromLTRB(13,12,9,8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        InkWell(onTap:onAuthor,child:CircleAvatar(backgroundColor:AppColors.softGreen,child:Text(post.authorName.isEmpty?'?':post.authorName[0].toUpperCase(),
          style:const TextStyle(color:AppColors.primaryGreen,fontWeight:FontWeight.bold)))),
        const SizedBox(width:10),Expanded(child:InkWell(onTap:onAuthor,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(post.authorName,style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.darkGreen)),
          Text(post.category,style:const TextStyle(fontSize:11,color:AppColors.homeMutedText)),
        ]))),
        PopupMenuButton<String>(onSelected:(v){if(v=='edit'&&onEdit!=null)onEdit!();if(v=='delete'&&onDelete!=null)onDelete!();if(v=='report'&&onReport!=null)onReport!();if(v=='save'&&onBookmark!=null)onBookmark!();},
          itemBuilder:(_)=>[if(onEdit!=null)const PopupMenuItem(value:'edit',child:Text('Edit')),if(onDelete!=null)const PopupMenuItem(value:'delete',child:Text('Delete')),
            if(onBookmark!=null)const PopupMenuItem(value:'save',child:Text('Save')),if(onReport!=null)const PopupMenuItem(value:'report',child:Text('Report'))]),
      ]),
      if(post.isQuestion)const Padding(padding:EdgeInsets.only(top:5),child:Text('QUESTION',style:TextStyle(fontSize:10,color:AppColors.primaryGreen,fontWeight:FontWeight.w800))),
      const SizedBox(height:8),InkWell(onTap:onOpen,child:Text(post.text,style:const TextStyle(fontSize:14,height:1.4))),const SizedBox(height:7),
      if(post.pollOptions.isNotEmpty)...[
        const Text('Poll',style:TextStyle(fontWeight:FontWeight.w700,color:AppColors.darkGreen)),const SizedBox(height:6),
        ...List.generate(post.pollOptions.length,(i){
          final total=post.pollVotes.values.fold<int>(0,(a,b)=>a+b);final votes=post.pollVotes[i.toString()]??0;final pct=total==0?0:votes/total;
          return Padding(padding:const EdgeInsets.only(bottom:6),child:InkWell(onTap:onPoll==null?null:()=>onPoll!(i),borderRadius:BorderRadius.circular(8),
            child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:9),decoration:BoxDecoration(border:Border.all(color:AppColors.guidanceBubble),borderRadius:BorderRadius.circular(8)),
              child:Row(children:[Expanded(child:Text(post.pollOptions[i])),Text('${(pct*100).round()}%  ($votes)',style:const TextStyle(fontSize:11,color:AppColors.homeMutedText))]))));
        }),const SizedBox(height:4),
      ],
      Row(children:[
        IconButton(onPressed:onLike,icon:Icon(liked?Icons.favorite:Icons.favorite_border,color:liked?Colors.red:AppColors.primaryGreen)),Text(post.likesCount.toString()),
        IconButton(onPressed:onOpen,icon:const Icon(Icons.comment_outlined,color:AppColors.primaryGreen)),Text(post.commentsCount.toString()),
        const Spacer(),TextButton(onPressed:onOpen,child:const Text('View')),
      ]),
    ])));
  }
}
