import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/models/post.dart';
import 'active_profile_controller.dart';
import 'demo_data_service.dart';
import '../../features/community/timeline_topics.dart';

class DatabaseService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String _uid(String uid)=>ActiveProfileController.instance.resolveUid(uid);
  bool _demo(String uid)=>DemoDataService.instance.isDemo(_uid(uid));
  Stream<T> _demoStream<T>(T initial,T Function() current) async* {yield initial;yield* DemoDataService.instance.changes.map((_)=>current());}
  CollectionReference<Map<String,dynamic>> collection(String name)=>_db.collection(name);
  Stream<List<Post>> postsStream({bool popular=false,String category='All',String query=''}){if(ActiveProfileController.instance.isDemo)return _demoStream(DemoDataService.instance.posts(category:category,query:query),()=>DemoDataService.instance.posts(category:category,query:query));return _db.collection('posts').orderBy(popular?'likesCount':'createdAt',descending:true).snapshots().map((s)=>s.docs.map(Post.fromDoc).where((p)=>(category=='All'||p.category==category)&&(query.isEmpty||p.text.toLowerCase().contains(query.toLowerCase())||p.authorName.toLowerCase().contains(query.toLowerCase()))).toList());}
  Future<String> createPost({required String text,required String authorId,required String authorName,String category='General',bool isQuestion=false,List<String> pollOptions=const [],String? instituteId})async{
    if(ActiveProfileController.instance.isDemo)return DemoDataService.instance.createPost(text:text,authorId:_uid(authorId),authorName:ActiveProfileController.instance.resolveName(authorName),category:category,isQuestion:isQuestion,pollOptions:pollOptions,instituteId:instituteId);
    final ref=await _db.collection('posts').add({'text':text.trim(),'authorId':authorId,'authorName':authorName,'category':category,'isQuestion':isQuestion,'createdAt':FieldValue.serverTimestamp(),'likesCount':0,'likedBy':<String>[],'commentsCount':0,'pollOptions':pollOptions,'pollVotes':<String,int>{},if(instituteId!=null)'instituteId':instituteId});
    return ref.id;
  }
  Future<void> updatePost({required String postId,required String text,String? category,bool? isQuestion,List<String>? pollOptions,String? instituteId}) async {
    if(ActiveProfileController.instance.isDemo) {
      DemoDataService.instance.updatePost(postId:postId,text:text,category:category,isQuestion:isQuestion,pollOptions:pollOptions,instituteId:instituteId);
      return;
    }
    await _db.collection('posts').doc(postId).update({
      'text':text.trim(),
      if(category!=null)'category':category,
      if(isQuestion!=null)'isQuestion':isQuestion,
      if(pollOptions!=null)'pollOptions':pollOptions,
      if(instituteId!=null)'instituteId':instituteId,
    });
  }
  Future<void> deletePost(String postId) async {
    if(ActiveProfileController.instance.isDemo) {
      DemoDataService.instance.deletePost(postId);
      return;
    }
    await _db.collection('posts').doc(postId).delete();
  }
  Future<void> toggleLike(Post post,String uid)async{uid=_uid(uid);if(_demo(uid)){DemoDataService.instance.toggleLike(post.id,uid);return;}
    final ref=_db.collection('posts').doc(post.id);
    await _db.runTransaction((tx)async{final snap=await tx.get(ref);if(!snap.exists)return;final d=snap.data()??{};final ids=List<String>.from(d['likedBy']??const[]);final add=!ids.contains(uid);if(add)ids.add(uid);else ids.remove(uid);tx.update(ref,{'likedBy':ids,'likesCount':ids.length});if(add&&post.authorId!=uid){final n=_db.collection('users').doc(post.authorId).collection('notifications').doc();tx.set(n,{'type':'like','text':'liked your post','postId':post.id,'fromId':uid,'createdAt':FieldValue.serverTimestamp(),'read':false});}});
  }
  Stream<QuerySnapshot<Map<String,dynamic>>> commentsStream(String postId)=>_db.collection('posts').doc(postId).collection('comments').orderBy('createdAt',descending:false).snapshots();
  Future<void> addComment({required String postId,required String text,required String authorId,required String authorName})async{authorId=_uid(authorId);if(_demo(authorId)){DemoDataService.instance.addComment(postId:postId,uid:authorId,name:ActiveProfileController.instance.resolveName(authorName),text:text.trim());return;}
    final postRef=_db.collection('posts').doc(postId);final commentRef=postRef.collection('comments').doc();
    await _db.runTransaction((tx)async{final snap=await tx.get(postRef);tx.set(commentRef,{'text':text.trim(),'authorId':authorId,'authorName':authorName,'createdAt':FieldValue.serverTimestamp()});tx.update(postRef,{'commentsCount':FieldValue.increment(1)});final owner=(snap.data()?['authorId']??'').toString();if(owner.isNotEmpty&&owner!=authorId){final n=_db.collection('users').doc(owner).collection('notifications').doc();tx.set(n,{'type':'comment','text':'commented on your post','postId':postId,'fromId':authorId,'createdAt':FieldValue.serverTimestamp(),'read':false});}});
  }
  Future<void> deleteComment({required String postId,required String commentId,required String uid})async{final postRef=_db.collection('posts').doc(postId);final commentRef=postRef.collection('comments').doc(commentId);await _db.runTransaction((tx)async{final post=await tx.get(postRef);final comment=await tx.get(commentRef);if(!comment.exists)return;if((comment.data()?['authorId']??'').toString()!=uid)return;tx.delete(commentRef);final current=((post.data()?['commentsCount']??0) as num).toInt();tx.update(postRef,{'commentsCount':current>0?current-1:0});});}
  Future<void> setBestAnswer({required String postId,required String commentId,required String uid})async{final p=await _db.collection('posts').doc(postId).get();if(p.data()?['authorId']!=uid)return;final comment=await p.reference.collection('comments').doc(commentId).get();final answerer=(comment.data()?['authorId']??'').toString();await p.reference.update({'bestAnswerId':commentId});if(answerer.isNotEmpty&&answerer!=uid){final n=_db.collection('users').doc(answerer).collection('notifications').doc();await n.set({'type':'best_answer','text':'your answer was marked as the best answer','postId':postId,'fromId':uid,'createdAt':FieldValue.serverTimestamp(),'read':false});}}
  Future<void> toggleBookmark(String postId,String uid,bool save)async{uid=_uid(uid);if(_demo(uid)){DemoDataService.instance.toggleBookmark(uid,postId,save);return;}final ref=_db.collection('users').doc(uid).collection('bookmarks').doc(postId);if(save)await ref.set({'postId':postId,'createdAt':FieldValue.serverTimestamp()});else await ref.delete();}
  Stream<Set<String>> bookmarkIdsStream(String uid){uid=_uid(uid);if(_demo(uid))return _demoStream(DemoDataService.instance.bookmarks(uid).map((p)=>p.id).toSet(),()=>DemoDataService.instance.bookmarks(uid).map((p)=>p.id).toSet());return _db.collection('users').doc(uid).collection('bookmarks').snapshots().map((s)=>s.docs.map((d)=>d.id).toSet());}
  Stream<List<Post>> bookmarkedPostsStream(String uid){uid=_uid(uid);if(_demo(uid))return _demoStream(DemoDataService.instance.bookmarks(uid),()=>DemoDataService.instance.bookmarks(uid));return _db.collection('users').doc(uid).collection('bookmarks').orderBy('createdAt',descending:true).snapshots().asyncMap((s)async{final posts=<Post>[];for(final b in s.docs){final d=await _db.collection('posts').doc(b.id).get();if(d.exists)posts.add(Post.fromDoc(d));}return posts;});}
  Future<void> report({required String reporterId,required String targetId,required String targetType,required String reason})=>_db.collection('reports').add({'reporterId':reporterId,'targetId':targetId,'targetType':targetType,'reason':reason,'createdAt':FieldValue.serverTimestamp(),'status':'open'});
  Future<void> blockUser(String uid,String blockedId) async {
    if(uid==blockedId)return;
    final batch=_db.batch();
    batch.set(_db.collection('users').doc(uid).collection('blockedUsers').doc(blockedId),{'blockedId':blockedId,'createdAt':FieldValue.serverTimestamp()});
    batch.delete(_db.collection('users').doc(uid).collection('following').doc(blockedId));
    batch.delete(_db.collection('users').doc(blockedId).collection('followers').doc(uid));
    batch.delete(_db.collection('users').doc(blockedId).collection('following').doc(uid));
    batch.delete(_db.collection('users').doc(uid).collection('followers').doc(blockedId));
    await batch.commit();
  }
  Future<void> unblockUser(String uid,String blockedId)=>_db.collection('users').doc(uid).collection('blockedUsers').doc(blockedId).delete();
  Stream<Set<String>> blockedUserIdsStream(String uid)=>_db.collection('users').doc(uid).collection('blockedUsers').snapshots().map((s)=>s.docs.map((d)=>d.id).toSet());
  Stream<QuerySnapshot<Map<String,dynamic>>> notificationsStream(String uid)=>_db.collection('users').doc(uid).collection('notifications').orderBy('createdAt',descending:true).limit(50).snapshots();
  Future<void> toggleFollow(String uid,String targetId,bool follow)async{uid=_uid(uid);targetId=_uid(targetId);if(_demo(uid)){DemoDataService.instance.toggleFollow(uid,targetId,follow);return;}final following=_db.collection('users').doc(uid).collection('following').doc(targetId);final follower=_db.collection('users').doc(targetId).collection('followers').doc(uid);final batch=_db.batch();if(follow){batch.set(following,{'userId':targetId,'createdAt':FieldValue.serverTimestamp()});batch.set(follower,{'userId':uid,'createdAt':FieldValue.serverTimestamp()});final n=_db.collection('users').doc(targetId).collection('notifications').doc();batch.set(n,{'type':'follow','text':'started following you','fromId':uid,'createdAt':FieldValue.serverTimestamp(),'read':false});}else{batch.delete(following);batch.delete(follower);}await batch.commit();}
  DocumentReference<Map<String,dynamic>> _followingRef(String uid,String targetId) => _db.collection('users').doc(uid).collection('following').doc(targetId);
  String conversationId(String a,String b) { final ids=[a,b]..sort(); return '${ids[0]}_${ids[1]}'; }
  Future<bool> isBlocked(String uid,String targetId) async {uid=_uid(uid);targetId=_uid(targetId);if(_demo(uid))return false;
    if(uid==targetId)return false;
    final r=await _db.collection('users').doc(uid).collection('blockedUsers').doc(targetId).get();
    return r.exists;
  }
  Future<bool> isEitherBlocked(String uid,String targetId) async {
    if(uid==targetId)return false;
    final r=await Future.wait([isBlocked(uid,targetId),isBlocked(targetId,uid)]);
    return r[0] || r[1];
  }
  Future<bool> isMutualFollow(String uid,String targetId) async {uid=_uid(uid);targetId=_uid(targetId);if(_demo(uid)||_demo(targetId))return DemoDataService.instance.isMutual(uid,targetId);
    if(uid==targetId)return false;
    if(await isEitherBlocked(uid,targetId))return false;
    final r=await Future.wait([
      _followingRef(uid,targetId).get(),
      _followingRef(targetId,uid).get(),
    ]);
    return r[0].exists&&r[1].exists;
  }
  Future<String?> createConversation({required String uid,required String otherUid,required String otherName, String? uidName}) async {
    if(uid==otherUid||!await isMutualFollow(uid,otherUid))return null;
    final id=conversationId(uid,otherUid);
    await _db.collection('conversations').doc(id).set({
      'id':id,'participants':[uid,otherUid],
      'participantNames':{uid:(uidName?.trim().isNotEmpty == true ? uidName!.trim() : 'Student'),otherUid:otherName},
      'lastMessage':'','lastMessageAt':FieldValue.serverTimestamp(),
      'updatedAt':FieldValue.serverTimestamp(),'createdAt':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));
    return id;
  }
  Stream<Set<String>> timelineTopicsStream(String uid){
    uid=_uid(uid);
    if(_demo(uid)) return _demoStream(DemoDataService.instance.timelineTopics(uid),()=>DemoDataService.instance.timelineTopics(uid));
    return _db.collection('users').doc(uid).snapshots().map((s){
      final data=s.data()??{};
      final raw=data['timelineTopics'];
      if(raw is List && raw.isNotEmpty) return raw.map((x)=>x.toString()).toSet();
      return TimelineTopics.defaults.toSet();
    });
  }

  Future<void> setTimelineTopics(String uid,Set<String> topics) async {
    uid=_uid(uid);
    if(_demo(uid)){DemoDataService.instance.setTimelineTopics(uid,topics);return;}
    await _db.collection('users').doc(uid).set({'timelineTopics':topics.toList()},SetOptions(merge:true));
  }

  Stream<bool> followingStream(String uid,String targetId){uid=_uid(uid);targetId=_uid(targetId);if(_demo(uid)||_demo(targetId))return _demoStream(DemoDataService.instance.isFollowing(uid,targetId),()=>DemoDataService.instance.isFollowing(uid,targetId));return _db.collection('users').doc(uid).collection('following').doc(targetId).snapshots().map((s)=>s.exists);}
  Stream<bool> mutualFollowStream(String uid,String targetId) {
    if (uid == targetId) return Stream<bool>.value(false);
    return followingStream(uid, targetId).asyncMap((following) async {
      if (!following) return false;
      final reverse = await _db.collection('users').doc(targetId).collection('following').doc(uid).get();
      return reverse.exists;
    });
  }
  Stream<int> followerCountStream(String uid){uid=_uid(uid);if(_demo(uid))return _demoStream(DemoDataService.instance.followerCount(uid),()=>DemoDataService.instance.followerCount(uid));return _db.collection('users').doc(uid).collection('followers').snapshots().map((s)=>s.size);}
  Future<void> notifyMention({required String targetId,required String fromId,required String postId})=>_db.collection('users').doc(targetId).collection('notifications').add({'type':'mention','text':'mentioned you in a community post','postId':postId,'fromId':fromId,'createdAt':FieldValue.serverTimestamp(),'read':false});
  Future<void> votePoll({required String postId,required String uid,required int option})async{uid=_uid(uid);if(ActiveProfileController.instance.isDemo){DemoDataService.instance.votePoll(postId:postId,uid:uid,option:option);return;}final ref=_db.collection('posts').doc(postId);await _db.runTransaction((tx)async{final s=await tx.get(ref);if(!s.exists)return;final d=s.data()??{};final voters=Map<String,dynamic>.from(d['pollVoters']??{});final old=voters[uid];final votes=Map<String,dynamic>.from(d['pollVotes']??{});if(old!=null){final k=old.toString();votes[k]=((votes[k]??0) as num).toInt()-1;}voters[uid]=option;final k=option.toString();votes[k]=((votes[k]??0) as num).toInt()+1;tx.update(ref,{'pollVoters':voters,'pollVotes':votes});});}
  Future<void> notifyMentions({required String text,required String fromId,required String postId})async{
    final matches=RegExp(r'@([A-Za-z0-9_.-]+)').allMatches(text);
    if(matches.isEmpty)return;
    final mentioned=matches.map((m)=>m.group(1)!.trim().toLowerCase()).toSet();
    if(mentioned.isEmpty)return;
    final users=await _db.collection('users').get();
    for(final doc in users.docs){
      if(doc.id==fromId)continue;
      final data=doc.data();
      final name=(data['username']??data['name']??'').toString().trim().toLowerCase();
      if(name.isEmpty||!mentioned.contains(name))continue;
      await notifyMention(targetId:doc.id,fromId:fromId,postId:postId);
    }
  }
  Future<Map<String,dynamic>> reputation(String uid)async{
    final posts=(await _db.collection('posts').where('authorId',isEqualTo:uid).get()).docs;
    var likes=0,comments=0,bestAnswers=0;
    for(final p in posts){
      final d=p.data();
      likes+=(d['likesCount'] as num?)?.toInt()??0;
      comments+=(d['commentsCount'] as num?)?.toInt()??0;
      if((d['bestAnswerId']??'').toString().isNotEmpty)bestAnswers++;
    }
    final followerCount=(await _db.collection('users').doc(uid).collection('followers').get()).size;
    final commentDocs=(await _db.collectionGroup('comments').where('authorId',isEqualTo:uid).get()).size;
    final reviews=(await _db.collection('users').doc(uid).collection('reviews').get()).docs;
    var ratingSum=0;
    for(final r in reviews)ratingSum+=(r.data()['rating'] as num?)?.toInt()??0;
    final avg=reviews.isEmpty?0.0:ratingSum/reviews.length;
    final score=posts.length*5+commentDocs*3+likes*2+comments+bestAnswers*10+followerCount+((avg*2).round());
    final badges=<String>[];
    if(posts.length>=1)badges.add('First Post');
    if(commentDocs>=5)badges.add('Helpful Voice');
    if(likes>=10)badges.add('Popular Contributor');
    if(bestAnswers>=1)badges.add('Answer Expert');
    if(followerCount>=10)badges.add('Community Builder');
    if(avg>=4.5&&reviews.length>=5)badges.add('Trusted Member');
    return {'score':score,'posts':posts.length,'comments':commentDocs,'likes':likes,'bestAnswers':bestAnswers,'followers':followerCount,'rating':avg,'reviews':reviews.length,'badges':badges};
  }
  Stream<List<Map<String,dynamic>>> demoCommentsStream(String postId)=>_demoStream(DemoDataService.instance.comments(postId).map((x)=>{'id':x.id,'authorId':x.authorId,'authorName':x.authorName,'text':x.text,'createdAt':x.createdAt}).toList(),()=>DemoDataService.instance.comments(postId).map((x)=>{'id':x.id,'authorId':x.authorId,'authorName':x.authorName,'text':x.text,'createdAt':x.createdAt}).toList());
  Stream<List<Map<String,dynamic>>> demoNotificationsStream(String uid)=>_demoStream(DemoDataService.instance.notifications(_uid(uid)),()=>DemoDataService.instance.notifications(_uid(uid)));
  Future<void> markNotificationRead(String uid,String id){uid=_uid(uid);if(_demo(uid)){DemoDataService.instance.markNotificationRead(uid,id);return Future.value();}return _db.collection('users').doc(uid).collection('notifications').doc(id).update({'read':true});}
  Stream<List<Map<String,dynamic>>> demoConversationsStream(String uid)=>_demoStream(DemoDataService.instance.conversations(_uid(uid)),()=>DemoDataService.instance.conversations(_uid(uid)));
  Stream<List<Map<String,dynamic>>> demoMessagesStream(String uid,String otherUid)=>_demoStream(DemoDataService.instance.messages(_uid(uid),_uid(otherUid)),()=>DemoDataService.instance.messages(_uid(uid),_uid(otherUid)));
  Future<void> sendDemoMessage(String uid,String otherUid,String text){uid=_uid(uid);otherUid=_uid(otherUid);DemoDataService.instance.sendMessage(uid,otherUid,text);return Future.value();}
  Stream<List<Map<String,dynamic>>> demoGroupsStream()=>_demoStream(DemoDataService.instance.groups(),()=>DemoDataService.instance.groups());
  Future<void> createDemoGroup(String uid,String name,String description){DemoDataService.instance.createGroup(_uid(uid),name,description);return Future.value();}
  Future<void> joinDemoGroup(String uid,String id){DemoDataService.instance.joinGroup(_uid(uid),id);return Future.value();}
  Stream<List<Map<String,dynamic>>> demoResourcesStream(String uid)=>_demoStream(DemoDataService.instance.resources(_uid(uid)),()=>DemoDataService.instance.resources(_uid(uid)));
  Future<void> addResourceDemo(String uid,String title,String url,String description){DemoDataService.instance.addResource(_uid(uid),title,url,description);return Future.value();}
  Stream<List<Map<String,dynamic>>> demoReviewsStream(String uid)=>_demoStream(DemoDataService.instance.reviews(uid),()=>DemoDataService.instance.reviews(uid));
  Future<void> addDemoReview(String target,String reviewer,String reviewerName,int rating,String text){DemoDataService.instance.addReview(target,reviewer,reviewerName,rating,text);return Future.value();}
  Stream<bool> demoInstituteBookmarkStream(String uid,String instituteId)=>_demoStream(DemoDataService.instance.instituteBookmarked(_uid(uid),instituteId),()=>DemoDataService.instance.instituteBookmarked(_uid(uid),instituteId));
  Future<void> toggleDemoInstituteBookmark(String uid,String instituteId,bool save){DemoDataService.instance.toggleInstituteBookmark(_uid(uid),instituteId,save);return Future.value();}
  Future<void> claimDemoInstitute(String uid,String instituteId){DemoDataService.instance.claimInstitute(_uid(uid),instituteId);return Future.value();}

}