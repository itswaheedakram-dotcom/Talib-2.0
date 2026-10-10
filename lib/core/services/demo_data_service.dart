import '../models/user_profile.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../features/models/post.dart';
import '../../features/community/timeline_topics.dart';

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
  final Map<String,int> _pollVoters={};
  final Map<String,List<DemoComment>> _comments={};
  final Map<String,Set<String>> _following={};
  final Map<String,List<Map<String,dynamic>>> _notifications={};
  final Map<String,Set<String>> _bookmarks={};
  final Map<String,List<Map<String,dynamic>>> _messages={};
  final List<Map<String,dynamic>> _resources=[];
  final Map<String,List<Map<String,dynamic>>> _reviews={};
  final Set<String> _instituteBookmarks={};
  final Set<String> _instituteClaims={};
  final Map<String, Map<String, dynamic>> _instituteClaimRecords = {};
  final List<Map<String,dynamic>> _groups=[];
  final Map<String,Set<String>> _groupMembers={};
  final Map<String,Map<String,dynamic>> _settings={};
  int _seq=0;

  Map<String,dynamic> settings(String uid)=>_settings.putIfAbsent(uid,()=>{'notificationsEnabled':true,ProfileFields.privateProfile:false,'appearanceMode':'system'});
  void setSetting(String uid,String field,dynamic value){settings(uid)[field]=value;_emit();}

  void _seedData(){
    final now=DateTime.now();
    final names={'demo-user-1':'Ayesha Khan','demo-user-2':'Ali Raza','demo-user-3':'Hira Ahmed','demo-user-4':'Usman Malik','demo-user-5':'Ahtasham Malik','demo-user-6':'Waheed Akram'};
    for(final id in names.keys){
      _following[id]={...names.keys.where((x)=>x!=id)};
      _notifications[id]=[];
      _reviews[id]=[];
    }

    // Seed visible demo ratings/reviews so the public profile has real
    // review content before a test user submits their own review.
    _reviews['demo-user-1']=[
      {'id':'demo-user-2',ProfileFields.reviewerId:'demo-user-2','reviewerName':'Ali Raza','rating':5,'text':'Helpful and supportive in the community.','createdAt':now.subtract(const Duration(days:2))},
      {'id':'demo-user-3',ProfileFields.reviewerId:'demo-user-3','reviewerName':'Hira Ahmed','rating':4,'text':'Good guidance and useful information.','createdAt':now.subtract(const Duration(days:1))},
    ];
    _reviews['demo-user-2']=[
      {'id':'demo-user-1',ProfileFields.reviewerId:'demo-user-1','reviewerName':'Ayesha Khan','rating':5,'text':'Very helpful for admission and study guidance.','createdAt':now.subtract(const Duration(days:3))},
      {'id':'demo-user-4',ProfileFields.reviewerId:'demo-user-4','reviewerName':'Usman Malik','rating':4,'text':'Good community member and responsive.','createdAt':now.subtract(const Duration(days:1))},
    ];
    _reviews['demo-user-3']=[
      {'id':'demo-user-1',ProfileFields.reviewerId:'demo-user-1','reviewerName':'Ayesha Khan','rating':5,'text':'Shares useful education guidance.','createdAt':now.subtract(const Duration(days:2))},
      {'id':'demo-user-2',ProfileFields.reviewerId:'demo-user-2','reviewerName':'Ali Raza','rating':5,'text':'Helpful and informative.','createdAt':now.subtract(const Duration(days:1))},
    ];
    _reviews['demo-user-4']=[
      {'id':'demo-user-1',ProfileFields.reviewerId:'demo-user-1','reviewerName':'Ayesha Khan','rating':4,'text':'Helpful in the community.','createdAt':now.subtract(const Duration(days:2))},
      {'id':'demo-user-3',ProfileFields.reviewerId:'demo-user-3','reviewerName':'Hira Ahmed','rating':5,'text':'Good guidance and discussion.','createdAt':now.subtract(const Duration(days:1))},
    ];
    _posts['demo-post-1']=Post(id:'demo-post-1',text:'Welcome to Talib Community! Ask questions, share guidance and help other students.',authorId:'demo-user-1',authorName:'Ayesha Khan',createdAt:now.subtract(const Duration(minutes:15)),category:'General',likesCount:2,likedBy:['demo-user-2','demo-user-3'],commentsCount:1);
    _posts['demo-post-2']=Post(id:'demo-post-2',text:'Which institute is best for your next education program? Share your experience.',authorId:'demo-user-2',authorName:'Ali Raza',createdAt:now.subtract(const Duration(hours:2)),category:'Institute Reviews',likesCount:1,likedBy:['demo-user-1'],commentsCount:1);
    _comments['demo-post-1']=[DemoComment(id:'c1',authorId:'demo-user-2',authorName:'Ali Raza',text:'This is helpful. Thanks!',createdAt:now.subtract(const Duration(minutes:8)))];
    _comments['demo-post-2']=[DemoComment(id:'c2',authorId:'demo-user-1',authorName:'Ayesha Khan',text:'I would compare programs and admission requirements.',createdAt:now.subtract(const Duration(hours:1)) )];

    _groups.add({'id':'demo-group-1',ProfileFields.name:'Computer Science Students','description':'Discuss CS subjects, assignments and guidance.','memberCount':4});
    _groups.add({'id':'demo-group-2',ProfileFields.name:'Admission Help 2026','description':'Share admission updates and institute guidance.','memberCount':4});
    _groupMembers['demo-group-1']={'demo-user-1','demo-user-2','demo-user-3','demo-user-4'};
    _groupMembers['demo-group-2']={'demo-user-1','demo-user-2','demo-user-3','demo-user-4'};

    for(final id in names.keys){
      _resources.add({'id':'resource-$id','title':'Study guidance','url':'https://example.com','description':'Temporary test resource shared by $id',ProfileFields.authorId:id,'createdAt':now});
    }
  }

  void _emit(){notifyListeners();_changes.add(null);}
  bool isDemo(String uid)=>uid.startsWith('demo-user-');

  List<Post> posts({String category='All',String query=''}){final q=query.toLowerCase();return _posts.values.where((p)=>(category=='All'||p.category==category)&&(q.isEmpty||p.text.toLowerCase().contains(q)||p.authorName.toLowerCase().contains(q))).toList()..sort((a,b)=>b.createdAt.compareTo(a.createdAt));}
  String createPost({required String text,required String authorId,required String authorName,String category='General',bool isQuestion=false,List<String> pollOptions=const [],String? instituteId,List<Map<String,String>> attachments=const [],List<String> tags=const [],List<String> instituteIds=const []}){final id='demo-post-${++_seq}';_posts[id]=Post(id:id,text:text.trim(),authorId:authorId,authorName:authorName,createdAt:DateTime.now(),category:category,isQuestion:isQuestion,pollOptions:pollOptions,instituteId:instituteId,instituteIds:instituteIds,attachments:attachments,tags:tags);_comments[id]=[];_emit();return id;}
  Post? post(String id)=>_posts[id];

  void updatePost({required String postId,required String text,String? category,bool? isQuestion,List<String>? pollOptions,String? instituteId,List<Map<String,String>>? attachments,List<String>? tags,List<String>? instituteIds}) {
    final p=_posts[postId];
    if(p==null) throw StateError('Post not found: $postId');
    _posts[postId]=Post(
      id:p.id,text:text.trim(),authorId:p.authorId,authorName:p.authorName,
      createdAt:p.createdAt,category:category??p.category,likesCount:p.likesCount,
      likedBy:p.likedBy,commentsCount:p.commentsCount,isQuestion:isQuestion??p.isQuestion,
      bestAnswerId:p.bestAnswerId,instituteId:instituteId??p.instituteId,instituteIds:instituteIds??p.instituteIds,
      pollOptions:pollOptions??p.pollOptions,pollVotes:p.pollVotes,attachments:attachments??p.attachments,tags:tags??p.tags,
    );
    _emit();
  }

  void deletePost(String postId) {
    if(!_posts.containsKey(postId)) throw StateError('Post not found: $postId');
    _posts.remove(postId);
    _comments.remove(postId);
    _emit();
  }

  void setBestAnswer({required String postId,required String commentId,required String uid}) {
    final p=_posts[postId];
    if(p==null || p.authorId!=uid || !p.isQuestion) return;
    _posts[postId]=Post(id:p.id,text:p.text,authorId:p.authorId,authorName:p.authorName,createdAt:p.createdAt,category:p.category,likesCount:p.likesCount,likedBy:p.likedBy,commentsCount:p.commentsCount,isQuestion:p.isQuestion,bestAnswerId:commentId,instituteId:p.instituteId,instituteIds:p.instituteIds,tags:p.tags,pollOptions:p.pollOptions,pollVotes:p.pollVotes,attachments:p.attachments);
    _emit();
  }

  void votePoll({required String postId,required String uid,required int option}) {
    final p=_posts[postId];
    if(p==null) throw StateError('Post not found: $postId');
    if(option<0||option>=p.pollOptions.length) throw ArgumentError('Invalid poll option.');
    final votes=Map<String,int>.from(p.pollVotes);
    final voterKey='$postId|$uid';
    // Demo voter state is kept separately so one user can change their vote.
    final previous=_pollVoters[voterKey];
    if(previous!=null) {
      final oldKey=previous.toString();
      final oldCount=(votes[oldKey]??0)-1; votes[oldKey]=oldCount<0?0:oldCount;
    }
    _pollVoters[voterKey]=option;
    final key=option.toString();
    votes[key]=(votes[key]??0)+1;
    _posts[postId]=Post(
      id:p.id,text:p.text,authorId:p.authorId,authorName:p.authorName,createdAt:p.createdAt,
      category:p.category,likesCount:p.likesCount,likedBy:p.likedBy,commentsCount:p.commentsCount,
      isQuestion:p.isQuestion,bestAnswerId:p.bestAnswerId,instituteId:p.instituteId,instituteIds:p.instituteIds,tags:p.tags,
      pollOptions:p.pollOptions,pollVotes:votes,attachments:p.attachments,
    );
    _emit();
  }

  void toggleLike(String postId,String uid){final p=_posts[postId];if(p==null)return;final liked=[...p.likedBy];if(liked.contains(uid)){liked.remove(uid);}else{liked.add(uid);if(p.authorId!=uid)_addNotification(p.authorId,{'type':'like','text':'liked your post','postId':postId,ProfileFields.fromId:uid,'createdAt':DateTime.now(),'read':false});}_posts[postId]=Post(id:p.id,text:p.text,authorId:p.authorId,authorName:p.authorName,createdAt:p.createdAt,category:p.category,likesCount:liked.length,likedBy:liked,commentsCount:p.commentsCount,isQuestion:p.isQuestion,bestAnswerId:p.bestAnswerId,instituteId:p.instituteId,instituteIds:p.instituteIds,tags:p.tags,pollOptions:p.pollOptions,pollVotes:p.pollVotes,attachments:p.attachments);_emit();}
  List<DemoComment> comments(String postId)=>List.unmodifiable(_comments[postId]??const []);
  void addComment({required String postId,required String uid,required String name,required String text}){final p=_posts[postId];if(p==null)return;(_comments[postId]??=[]).add(DemoComment(id:'demo-comment-${++_seq}',authorId:uid,authorName:name,text:text,createdAt:DateTime.now()));_posts[postId]=Post(id:p.id,text:p.text,authorId:p.authorId,authorName:p.authorName,createdAt:p.createdAt,category:p.category,likesCount:p.likesCount,likedBy:p.likedBy,commentsCount:(_comments[postId]??[]).length,isQuestion:p.isQuestion,bestAnswerId:p.bestAnswerId,instituteId:p.instituteId,tags:p.tags,pollOptions:p.pollOptions,pollVotes:p.pollVotes,attachments:p.attachments);if(p.authorId!=uid)_addNotification(p.authorId,{'type':'comment','text':'commented on your post','postId':postId,ProfileFields.fromId:uid,'createdAt':DateTime.now(),'read':false});_emit();}

  final Map<String,Set<String>> _timelineTopics={};
  final Map<String,Set<String>> _timelineInstitutes={};

  Set<String> timelineTopics(String uid)=>Set.unmodifiable(_timelineTopics[uid]??TimelineTopics.defaults.toSet());
  void setTimelineTopics(String uid,Set<String> topics){_timelineTopics[uid]=topics.toSet();_emit();}
  Set<String> timelineInstitutes(String uid)=>Set.unmodifiable(_timelineInstitutes[uid]??const <String>{});
  void setTimelineInstitutes(String uid,Set<String> ids){_timelineInstitutes[uid]=ids.toSet();_emit();}
  Set<String> followingIds(String uid)=>Set.unmodifiable(_following[uid]??const <String>{});

  bool isFollowing(String uid,String target)=>_following[uid]?.contains(target)==true;
  bool isMutual(String a,String b)=>a!=b&&isFollowing(a,b)&&isFollowing(b,a);
  void toggleFollow(String uid,String target,bool follow){(_following[uid]??={});if(follow){_following[uid]!.add(target);_addNotification(target,{'type':'follow','text':'started following you',ProfileFields.fromId:uid,'createdAt':DateTime.now(),'read':false});}else{_following[uid]!.remove(target);}_emit();}
  int followerCount(String uid)=>_following.values.where((s)=>s.contains(uid)).length;

  List<Map<String,dynamic>> notifications(String uid)=>List.unmodifiable(_notifications[uid]??const []);
  void _addNotification(String uid,Map<String,dynamic> n){(_notifications[uid]??=[]).insert(0,{'id':'demo-notification-${++_seq}',...n});}
  void markNotificationRead(String uid,String id){for(final n in _notifications[uid]??[]){if(n['id']==id)n['read']=true;}_emit();}

  bool bookmarked(String uid,String postId)=>_bookmarks[uid]?.contains(postId)==true;
  List<Post> bookmarks(String uid)=>(_bookmarks[uid]??const <String>{}).map((id)=>_posts[id]).whereType<Post>().toList();
  void toggleBookmark(String uid,String postId,bool save){(_bookmarks[uid]??={});if(save){_bookmarks[uid]!.add(postId);}else{_bookmarks[uid]!.remove(postId);}_emit();}

  String _conversation(String a,String b){final x=[a,b]..sort();return '${x[0]}|${x[1]}';}
  String conversationId(String a,String b)=>_conversation(a,b);
  String _name(String id)=>{'demo-user-1':'Ayesha Khan','demo-user-2':'Ali Raza','demo-user-3':'Hira Ahmed','demo-user-4':'Usman Malik','demo-user-5':'Ahtasham Malik','demo-user-6':'Waheed Akram'}[id]??'Student';
  List<Map<String,dynamic>> conversations(String uid){final result=<Map<String,dynamic>>[];for(final e in _messages.entries){final parts=e.key.split('|');if(parts.contains(uid)){final other=parts.firstWhere((x)=>x!=uid,orElse:()=>uid);final list=e.value;final last=list.isEmpty?null:list.last;result.add({'id':e.key,'otherUid':other,'otherName':_name(other),'lastMessage':last?['text']??'','updatedAt':last?['createdAt']??DateTime.now()});}}return result..sort((a,b)=>(b['updatedAt'] as DateTime).compareTo(a['updatedAt'] as DateTime));}
  List<Map<String,dynamic>> messages(String a,String b)=>List.unmodifiable(_messages[_conversation(a,b)]??const []);
  void sendMessage(String from,String to,String text){if(!isMutual(from,to))return;final key=_conversation(from,to);(_messages[key]??=[]).add({'id':'demo-message-${++_seq}',ProfileFields.senderId:from,'receiverId':to,'text':text,'createdAt':DateTime.now(),'read':false});_addNotification(to,{'type':'message','text':'sent you a message',ProfileFields.fromId:from,'createdAt':DateTime.now(),'read':false});_emit();}

  List<Map<String,dynamic>> groups()=>List.unmodifiable(_groups);
  bool isGroupMember(String uid,String groupId)=>_groupMembers[groupId]?.contains(uid)==true;
  List<String> groupMemberIds(String groupId)=>List.unmodifiable(_groupMembers[groupId]??const <String>[]);
  void createGroup(String uid,String name,String description){final id='demo-group-${++_seq}';_groups.insert(0,{'id':id,ProfileFields.name:name,'description':description,'memberCount':1,'ownerId':uid});_groupMembers[id]={uid};_emit();}
  void joinGroup(String uid,String id){final g=_groups.cast<Map<String,dynamic>>().firstWhere((x)=>x['id']==id,orElse:()=>{});if(g.isEmpty)return;final members=_groupMembers.putIfAbsent(id,()=>{});if(members.add(uid)){g['memberCount']=members.length;_emit();}}
  
  List<Map<String,dynamic>> resources(String uid)=>List.unmodifiable(_resources);
  void addResource(String uid,String title,String url,String description){_resources.insert(0,{'id':'demo-resource-${++_seq}','title':title,'url':url,'description':description,ProfileFields.authorId:uid,'createdAt':DateTime.now()});_emit();}

  Map<String,dynamic> reputation(String uid) {
    final authoredPosts = _posts.values.where((p) => p.authorId == uid).toList();
    final authoredComments = _comments.values
        .expand((items) => items)
        .where((comment) => comment.authorId == uid)
        .length;
    var likes = 0;
    var commentCount = 0;
    var bestAnswers = 0;
    for (final post in authoredPosts) {
      likes += post.likesCount;
      commentCount += post.commentsCount;
      if ((post.bestAnswerId ?? '').isNotEmpty) bestAnswers++;
    }
    final followers = followerCount(uid);
    final userReviews = _reviews[uid] ?? const <Map<String, dynamic>>[];
    var ratingSum = 0;
    var validRatings = 0;
    for (final review in userReviews) {
      final rating = (review['rating'] as num?)?.toInt() ?? 0;
      if (rating >= 1 && rating <= 5) {
        ratingSum += rating;
        validRatings++;
      }
    }
    final average = validRatings == 0 ? 0.0 : ratingSum / validRatings;
    final score = authoredPosts.length * 5 + authoredComments * 3 +
        likes * 2 + commentCount + bestAnswers * 10 + followers +
        (average * 2).round();
    final badges = <String>[];
    if (authoredPosts.isNotEmpty) badges.add('First Post');
    if (authoredComments >= 5) badges.add('Helpful Voice');
    if (likes >= 10) badges.add('Popular Contributor');
    if (bestAnswers > 0) badges.add('Answer Expert');
    if (followers >= 10) badges.add('Community Builder');
    if (average >= 4.5 && validRatings >= 5) badges.add('Trusted Member');
    return {
      'score': score,
      'posts': authoredPosts.length,
      'comments': authoredComments,
      'likes': likes,
      'bestAnswers': bestAnswers,
      'followers': followers,
      'rating': average,
      'reviews': validRatings,
      'badges': badges,
    };
  }

  List<Map<String,dynamic>> reviews(String uid)=>List.unmodifiable(_reviews[uid]??const []);
  void addReview(String target,String reviewer,String reviewerName,int rating,String text){final reviews=_reviews[target]??= <Map<String,dynamic>>[];final index=reviews.indexWhere((r)=>r[ProfileFields.reviewerId]==reviewer);final item={'id':reviewer,ProfileFields.reviewerId:reviewer,'reviewerName':reviewerName,'rating':rating,'text':text,'createdAt':DateTime.now()};if(index>=0){reviews[index]=item;}else{reviews.insert(0,item);}_emit();}

  bool instituteBookmarked(String uid,String id)=>_instituteBookmarks.contains('$uid|$id');
  Set<String> instituteBookmarkIds(String uid)=>Set.unmodifiable(_instituteBookmarks.where((key)=>key.startsWith('$uid|')).map((key)=>key.substring(uid.length+1)));
  void toggleInstituteBookmark(String uid,String id,bool save){final k='$uid|$id';if(save){_instituteBookmarks.add(k);}else{_instituteBookmarks.remove(k);}_emit();}
  List<String> usersWhoBookmarkedInstitute(String instituteId) => _instituteBookmarks
      .where((key) => key.endsWith('|$instituteId'))
      .map((key) => key.substring(0, key.indexOf('|')))
      .toSet()
      .toList();
  void addNotification(String uid, Map<String, dynamic> notification) {
    _addNotification(uid, notification);
    _emit();
  }
  bool claimed(String uid,String id)=>_instituteClaims.contains('$uid|$id');

  void claimInstitute(
    String uid,
    String id, {
    String instituteName = '',
    String designation = '',
    String method = '',
    String details = '',
  }) {
    final key = '$uid|$id';
    final existing = _instituteClaimRecords[key];
    if (existing != null && const {'pending', 'approved'}.contains(existing['status'])) return;
    _instituteClaims.add(key);
    _instituteClaimRecords[key] = {
      'id': key,
      'instituteId': id,
      'instituteName': instituteName,
      'representativeId': uid,
      'representativeName': _demoName(uid),
      'designation': designation,
      'verificationMethod': method,
      'verificationDetails': details,
      'status': 'pending',
      'createdAt': DateTime.now(),
    };
    _emit();
  }

  List<Map<String, dynamic>> pendingInstituteClaims() => List.unmodifiable(
    _instituteClaimRecords.values
        .where((claim) => claim['status'] == 'pending')
        .toList()
      ..sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime)),
  );

  void reviewInstituteClaim(String claimId, String status) {
    if (!const {'approved', 'rejected'}.contains(status)) return;
    final claim = _instituteClaimRecords[claimId];
    if (claim == null || claim['status'] != 'pending') return;
    claim['status'] = status;
    claim['reviewedAt'] = DateTime.now();
    _emit();
  }

  List<Map<String, dynamic>> instituteClaimsFor(String uid) => _instituteClaimRecords.values
      .where((claim) => claim['representativeId'] == uid)
      .map((claim) => Map<String, dynamic>.unmodifiable(claim)).toList();

  String _demoName(String uid) => switch (uid) {
    'demo-user-1' => 'Ayesha Khan',
    'demo-user-2' => 'Ali Raza',
    'demo-user-3' => 'Hira Ahmed',
    'demo-user-4' => 'Usman Malik',
    'demo-user-5' => 'Ahtasham Malik',
    'demo-user-6' => 'Waheed Akram',
    _ => 'Demo Representative',
  };
}
