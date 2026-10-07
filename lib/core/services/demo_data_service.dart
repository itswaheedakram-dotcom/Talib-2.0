import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/models/post.dart';

class DemoComment {
  final String id, authorId, authorName, text;
  final DateTime createdAt;
  const DemoComment({required this.id,required this.authorId,required this.authorName,required this.text,required this.createdAt});
}

class DemoDataService extends ChangeNotifier {
  DemoDataService._();
  static final instance=DemoDataService._().._seedData();

  final _changes=StreamController<void>.broadcast();
  Stream<void> get changes=>_changes.stream;

  final Map<String,Post> _posts={};
  final Map<String,List<DemoComment>> _comments={};
  final Map<String,Set<String>> _following={};
  final Map<String,List<Map<String,dynamic>>> _notifications={};
  final Map<String,Set<String>> _bookmarks={};
  final Map<String,List<Map<String,dynamic>>> _messages={};
  final List<Map<String,dynamic>> _resources=[];
  final Map<String,List<Map<String,dynamic>>> _reviews={};
  final Set<String> _instituteBookmarks={};
  final Set<String> _instituteClaims={};
  final List<Map<String,dynamic>> _groups=[];
  final Map<String,Set<String>> _groupMembers={};
  final Map<String,Map<String,dynamic>> _settings={};
  int _seq=0;

  Map<String,dynamic> settings(String uid)=>_settings.putIfAbsent(uid,()=>{'notificationsEnabled':true,'privateProfile':false,'appearanceMode':'system'});
  void setSetting(String uid,String field,dynamic value){settings(uid)[field]=value;_emit();}

  void _seedData(){
    final now=DateTime.now();
    final names={'demo-user-1':'Ayesha Khan','demo-user-2':'Ali Raza','demo-user-3':'Hira Ahmed','demo-user-4':'Usman Malik'};
    for(final id in names.keys){
      _following[id]={...names.keys.where((x)=>x!=id)};
      _notifications[id]=[];
      _reviews[id]=[];
    }
    _posts['demo-post-1']=Post(id:'demo-post-1',text:'Welcome to Talib Community! Ask questions, share guidance and help other students.',authorId:'demo-user-1',authorName:'Ayesha Khan',createdAt:now.subtract(const Duration(minutes:15)),category:'General',likesCount:2,likedBy:['demo-user-2','demo-user-3'],commentsCount:1);
    _posts['demo-post-2']=Post(id:'demo-post-2',text:'Which institute is best for your next education program? Share your experience.',authorId:'demo-user-2',authorName:'Ali Raza',createdAt:now.subtract(const Duration(hours:2)),category:'Institute Reviews',likesCount:1,likedBy:['demo-user-1'],commentsCount:1);
    _comments['demo-post-1']=[DemoComment(id:'c1',authorId:'demo-user-2',authorName:'Ali Raza',text:'This is helpful. Thanks!',createdAt:now.subtract(const Duration(minutes:8)))];
    _comments['demo-post-2']=[DemoComment(id:'c2',authorId:'demo-user-1',authorName:'Ayesha Khan',text:'I would compare programs and admission requirements.',createdAt:now.subtract(const Duration(hours:1)) )];

    _groups.add({'id':'demo-group-1','name':'Computer Science Students','description':'Discuss CS subjects, assignments and guidance.','memberCount':4});
    _groups.add({'id':'demo-group-2','name':'Admission Help 2026','description':'Share admission updates and institute guidance.','memberCount':4});
    _groupMembers['demo-group-1']={'demo-user-1','demo-user-2','demo-user-3','demo-user-4'};
    _groupMembers['demo-group-2']={'demo-user-1','demo-user-2','demo-user-3','demo-user-4'};

    for(final id in names.keys){
      _resources.add({'id':'resource-$id','title':'Study guidance','url':'https://example.com','description':'Temporary test resource shared by $id','authorId':id,'createdAt':now});
    }
  }

  void _emit(){notifyListeners();_changes.add(null);}
  bool isDemo(String uid)=>uid.startsWith('demo-user-');

  List<Post> posts({String category='All',String query=''}){final q=query.toLowerCase();return _posts.values.where((p)=>(category=='All'||p.category==category)&&(q.isEmpty||p.text.toLowerCase().contains(q)||p.authorName.toLowerCase().contains(q))).toList()..sort((a,b)=>b.createdAt.compareTo(a.createdAt));}
  String createPost({required String text,required String authorId,required String authorName,String category='General',bool isQuestion=false,List<String> pollOptions=const [],String? instituteId}){final id='demo-post-${++_seq}';_posts[id]=Post(id:id,text:text.trim(),authorId:authorId,authorName:authorName,createdAt:DateTime.now(),category:category,isQuestion:isQuestion,pollOptions:pollOptions,instituteId:instituteId);_comments[id]=[];_emit();return id;}
  Post? post(String id)=>_posts[id];

  void toggleLike(String postId,String uid){final p=_posts[postId];if(p==null)return;final liked=[...p.likedBy];if(liked.contains(uid)){liked.remove(uid);}else{liked.add(uid);if(p.authorId!=uid)_addNotification(p.authorId,{'type':'like','text':'liked your post','postId':postId,'fromId':uid,'createdAt':DateTime.now(),'read':false});}_posts[postId]=Post(id:p.id,text:p.text,authorId:p.authorId,authorName:p.authorName,createdAt:p.createdAt,category:p.category,likesCount:liked.length,likedBy:liked,commentsCount:p.commentsCount,isQuestion:p.isQuestion,bestAnswerId:p.bestAnswerId,instituteId:p.instituteId,pollOptions:p.pollOptions,pollVotes:p.pollVotes);_emit();}
  List<DemoComment> comments(String postId)=>List.unmodifiable(_comments[postId]??const []);
  void addComment({required String postId,required String uid,required String name,required String text}){final p=_posts[postId];if(p==null)return;(_comments[postId]??=[]).add(DemoComment(id:'demo-comment-${++_seq}',authorId:uid,authorName:name,text:text,createdAt:DateTime.now()));_posts[postId]=Post(id:p.id,text:p.text,authorId:p.authorId,authorName:p.authorName,createdAt:p.createdAt,category:p.category,likesCount:p.likesCount,likedBy:p.likedBy,commentsCount:(_comments[postId]??[]).length,isQuestion:p.isQuestion,bestAnswerId:p.bestAnswerId,instituteId:p.instituteId,pollOptions:p.pollOptions,pollVotes:p.pollVotes);if(p.authorId!=uid)_addNotification(p.authorId,{'type':'comment','text':'commented on your post','postId':postId,'fromId':uid,'createdAt':DateTime.now(),'read':false});_emit();}

  bool isFollowing(String uid,String target)=>_following[uid]?.contains(target)==true;
  bool isMutual(String a,String b)=>a!=b&&isFollowing(a,b)&&isFollowing(b,a);
  void toggleFollow(String uid,String target,bool follow){(_following[uid]??={});if(follow){_following[uid]!.add(target);_addNotification(target,{'type':'follow','text':'started following you','fromId':uid,'createdAt':DateTime.now(),'read':false});}else{_following[uid]!.remove(target);}_emit();}
  int followerCount(String uid)=>_following.values.where((s)=>s.contains(uid)).length;

  List<Map<String,dynamic>> notifications(String uid)=>List.unmodifiable(_notifications[uid]??const []);
  void _addNotification(String uid,Map<String,dynamic> n){(_notifications[uid]??=[]).insert(0,{'id':'demo-notification-${++_seq}',...n});}
  void markNotificationRead(String uid,String id){for(final n in _notifications[uid]??[]){if(n['id']==id)n['read']=true;}_emit();}

  bool bookmarked(String uid,String postId)=>_bookmarks[uid]?.contains(postId)==true;
  List<Post> bookmarks(String uid)=>(_bookmarks[uid]??const <String>{}).map((id)=>_posts[id]).whereType<Post>().toList();
  void toggleBookmark(String uid,String postId,bool save){(_bookmarks[uid]??={});if(save){_bookmarks[uid]!.add(postId);}else{_bookmarks[uid]!.remove(postId);}_emit();}

  String _conversation(String a,String b){final x=[a,b]..sort();return '${x[0]}|${x[1]}';}
  String _name(String id)=>{'demo-user-1':'Ayesha Khan','demo-user-2':'Ali Raza','demo-user-3':'Hira Ahmed','demo-user-4':'Usman Malik'}[id]??'Student';
  List<Map<String,dynamic>> conversations(String uid){final result=<Map<String,dynamic>>[];for(final e in _messages.entries){final parts=e.key.split('|');if(parts.contains(uid)){final other=parts.firstWhere((x)=>x!=uid,orElse:()=>uid);final list=e.value;final last=list.isEmpty?null:list.last;result.add({'id':e.key,'otherUid':other,'otherName':_name(other),'lastMessage':last?['text']??'','updatedAt':last?['createdAt']??DateTime.now()});}}return result..sort((a,b)=>(b['updatedAt'] as DateTime).compareTo(a['updatedAt'] as DateTime));}
  List<Map<String,dynamic>> messages(String a,String b)=>List.unmodifiable(_messages[_conversation(a,b)]??const []);
  void sendMessage(String from,String to,String text){if(!isMutual(from,to))return;final key=_conversation(from,to);(_messages[key]??=[]).add({'id':'demo-message-${++_seq}','senderId':from,'receiverId':to,'text':text,'createdAt':DateTime.now(),'read':false});_addNotification(to,{'type':'message','text':'sent you a message','fromId':from,'createdAt':DateTime.now(),'read':false});_emit();}

  List<Map<String,dynamic>> groups()=>List.unmodifiable(_groups);
  bool isGroupMember(String uid,String groupId)=>_groupMembers[groupId]?.contains(uid)==true;
  List<String> groupMemberIds(String groupId)=>List.unmodifiable(_groupMembers[groupId]??const <String>[]);
  void createGroup(String uid,String name,String description){final id='demo-group-${++_seq}';_groups.insert(0,{'id':id,'name':name,'description':description,'memberCount':1,'ownerId':uid});_groupMembers[id]={uid};_emit();}
  void joinGroup(String uid,String id){final g=_groups.cast<Map<String,dynamic>>().firstWhere((x)=>x['id']==id,orElse:()=>{});if(g.isEmpty)return;final members=_groupMembers.putIfAbsent(id,()=>{});if(members.add(uid)){g['memberCount']=members.length;_emit();}}
  
  List<Map<String,dynamic>> resources(String uid)=>List.unmodifiable(_resources);
  void addResource(String uid,String title,String url,String description){_resources.insert(0,{'id':'demo-resource-${++_seq}','title':title,'url':url,'description':description,'authorId':uid,'createdAt':DateTime.now()});_emit();}

  List<Map<String,dynamic>> reviews(String uid)=>List.unmodifiable(_reviews[uid]??const []);
  void addReview(String target,String reviewer,String reviewerName,int rating,String text){(_reviews[target]??=[]).insert(0,{'id':reviewer,'reviewerId':reviewer,'reviewerName':reviewerName,'rating':rating,'text':text,'createdAt':DateTime.now()});_emit();}

  bool instituteBookmarked(String uid,String id)=>_instituteBookmarks.contains('$uid|$id');
  void toggleInstituteBookmark(String uid,String id,bool save){final k='$uid|$id';if(save){_instituteBookmarks.add(k);}else{_instituteBookmarks.remove(k);}_emit();}
  bool claimed(String uid,String id)=>_instituteClaims.contains('$uid|$id');
  void claimInstitute(String uid,String id){_instituteClaims.add('$uid|$id');_emit();}
}
