import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/models/post.dart';
import '../../features/models/news_item.dart';
import 'firebase_service.dart';

class DatabaseService {
  static final List<Post> _demoPosts = [
    Post(id:'demo-1',text:'Welcome to Talib Community! Ask questions, share guidance and help other students.',authorId:'demo-user-1',authorName:'Talib Community',createdAt:DateTime.now().subtract(const Duration(minutes:15)),category:'General',likesCount:12,commentsCount:4),
    Post(id:'demo-2',text:'Which institute is best for your next education program? Share your experience and help fellow students.',authorId:'demo-user-2',authorName:'Student Guide',createdAt:DateTime.now().subtract(const Duration(hours:2)),category:'Institute Reviews',likesCount:8,commentsCount:3,isQuestion:true),
    Post(id:'demo-3',text:'Need admission guidance? You can use Find Institute to compare institutes, programs and eligibility.',authorId:'demo-user-3',authorName:'Talib Team',createdAt:DateTime.now().subtract(const Duration(hours:5)),category:'Admission Help',likesCount:6,commentsCount:2),
  ];
  static final Set<String> _bookmarks = {};
  static final Set<String> _blocked = {};
  static final StreamController<void> _postChanges = StreamController<void>.broadcast();
  CollectionReference<Map<String,dynamic>> get _postsRef => FirebaseFirestore.instance.collection('posts');
  bool get _real => FirebaseService.initialized;

  Stream<List<Post>> postsStream({bool popular=false,String category='All',String query=''}) {
    if (_real) {
      Query<Map<String,dynamic>> q=_postsRef.orderBy('createdAt',descending:true);
      if(category!='All') q=q.where('category',isEqualTo:category);
      return q.snapshots().map((s){ final list=s.docs.map(Post.fromDoc).toList(); if(popular) list.sort((a,b)=>b.likesCount.compareTo(a.likesCount)); return _filter(list,query); });
    }
    return _postChanges.stream.asyncMap((_) async => _filter(_demoPosts.toList(),query,category:category,popular:popular)).startWith(_filter(_demoPosts.toList(),query,category:category,popular:popular));
  }
  List<Post> _filter(List<Post> list,String query,{String category='All',bool popular=false}) {
    final result=List<Post>.from(list);
    if(category!='All') result.removeWhere((p)=>p.category!=category);
    final n=query.trim().toLowerCase();
    if(n.isNotEmpty) result.removeWhere((p)=>!p.text.toLowerCase().contains(n)&&!p.authorName.toLowerCase().contains(n));
    if(popular) result.sort((a,b)=>b.likesCount.compareTo(a.likesCount)); else result.sort((a,b)=>b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Future<String> createPost({required String text,required String authorId,required String authorName,String category='General',bool isQuestion=false,List<String> pollOptions=const [],String? instituteId}) async {
    final clean=text.trim(); if(clean.isEmpty) throw ArgumentError('Post text cannot be empty.');
    final votes={for(var i=0;i<pollOptions.length;i++) i.toString():0};
    if(_real){
      final ref=_postsRef.doc();
      final p=Post(id:ref.id,text:clean,authorId:authorId,authorName:authorName,createdAt:DateTime.now(),category:category,isQuestion:isQuestion,instituteId:instituteId,pollOptions:pollOptions,pollVotes:votes);
      await ref.set(p.toMap()); return ref.id;
    }
    final id='demo-'+DateTime.now().microsecondsSinceEpoch.toString();
    _demoPosts.insert(0,Post(id:id,text:clean,authorId:authorId,authorName:authorName,createdAt:DateTime.now(),category:category,isQuestion:isQuestion,instituteId:instituteId,pollOptions:pollOptions,pollVotes:votes));
    _postChanges.add(null); return id;
  }

  Future<void> updatePost({required String postId,required String text,String? category,bool? isQuestion,List<String>? pollOptions}) async {
    final clean=text.trim(); if(clean.isEmpty) throw ArgumentError('Post text cannot be empty.');
    if(_real){
      final ref=_postsRef.doc(postId); final snap=await ref.get(); if(!snap.exists) throw StateError('Post no longer exists.');
      final old=Post.fromDoc(snap); final options=pollOptions??old.pollOptions; final votes=pollOptions==null?old.pollVotes:{for(var i=0;i<options.length;i++) i.toString():(old.pollVotes[i.toString()]??0)};
      await ref.update({'text':clean,'category':category??old.category,'isQuestion':isQuestion??old.isQuestion,'pollOptions':options,'pollVotes':votes,'updatedAt':FieldValue.serverTimestamp()}); return;
    }
    final i=_demoPosts.indexWhere((p)=>p.id==postId); if(i<0) throw StateError('Post no longer exists.');
    final p=_demoPosts[i]; final options=pollOptions??p.pollOptions; final votes=pollOptions==null?p.pollVotes:{for(var j=0;j<options.length;j++) j.toString():(p.pollVotes[j.toString()]??0)};
    _demoPosts[i]=Post(id:p.id,text:clean,authorId:p.authorId,authorName:p.authorName,createdAt:p.createdAt,category:category??p.category,likesCount:p.likesCount,likedBy:p.likedBy,commentsCount:p.commentsCount,isQuestion:isQuestion??p.isQuestion,bestAnswerId:p.bestAnswerId,instituteId:p.instituteId,pollOptions:options,pollVotes:votes); _postChanges.add(null);
  }

  Future<void> deletePost(String postId) async {
    if(_real){ final ref=_postsRef.doc(postId); if(!(await ref.get()).exists) throw StateError('Post no longer exists.'); await ref.delete(); return; }
    final before=_demoPosts.length; _demoPosts.removeWhere((p)=>p.id==postId); if(before==_demoPosts.length) throw StateError('Post no longer exists.'); _postChanges.add(null);
  }

  Future<void> toggleLike(Post post,String uid) async {
    if(uid.trim().isEmpty) throw ArgumentError('User id is required.');
    if(_real){ final ref=_postsRef.doc(post.id); await FirebaseFirestore.instance.runTransaction((tx) async { final snap=await tx.get(ref); if(!snap.exists) throw StateError('Post no longer exists.'); final p=Post.fromDoc(snap); final liked=List<String>.from(p.likedBy); if(liked.contains(uid)) liked.remove(uid); else liked.add(uid); tx.update(ref,{'likedBy':liked,'likesCount':liked.length,'updatedAt':FieldValue.serverTimestamp()}); }); return; }
    final i=_demoPosts.indexWhere((p)=>p.id==post.id); if(i<0) throw StateError('Post no longer exists.'); final p=_demoPosts[i]; final liked=List<String>.from(p.likedBy); if(liked.contains(uid)) liked.remove(uid); else liked.add(uid);
    _demoPosts[i]=Post(id:p.id,text:p.text,authorId:p.authorId,authorName:p.authorName,createdAt:p.createdAt,category:p.category,likesCount:liked.length,likedBy:liked,commentsCount:p.commentsCount,isQuestion:p.isQuestion,bestAnswerId:p.bestAnswerId,instituteId:p.instituteId,pollOptions:p.pollOptions,pollVotes:p.pollVotes); _postChanges.add(null);
  }

  Stream<Set<String>> blockedUserIdsStream(String uid) async* { yield Set<String>.unmodifiable(_blocked); }
  Stream<Set<String>> bookmarkIdsStream(String uid) async* { yield Set<String>.unmodifiable(_bookmarks); }
  Future<void> toggleBookmark(String postId,String uid,bool save) async { if(save)_bookmarks.add(postId);else _bookmarks.remove(postId); }
  Stream<List<Post>> bookmarkedPostsStream(String uid) async* { yield _demoPosts.where((p)=>_bookmarks.contains(p.id)).toList(); }
  Future<void> report({required String reporterId,required String targetId,required String targetType,required String reason}) async { if(_real) await FirebaseFirestore.instance.collection('reports').add({'reporterId':reporterId,'targetId':targetId,'targetType':targetType,'reason':reason,'createdAt':FieldValue.serverTimestamp()}); }
  Future<void> blockUser(String uid,String blockedId) async => _blocked.add(blockedId);
  Future<void> unblockUser(String uid,String blockedId) async => _blocked.remove(blockedId);
  Future<void> addComment({required String postId,required String text,required String authorId,required String authorName}) async { if(!_real)return; await _postsRef.doc(postId).collection('comments').add({'text':text.trim(),'authorId':authorId,'authorName':authorName,'createdAt':FieldValue.serverTimestamp()}); await _postsRef.doc(postId).update({'commentsCount':FieldValue.increment(1)}); }
  Future<void> deleteComment({required String postId,required String commentId,required String uid}) async { if(!_real)return; await _postsRef.doc(postId).collection('comments').doc(commentId).delete(); await _postsRef.doc(postId).update({'commentsCount':FieldValue.increment(-1)}); }
  Future<void> setBestAnswer({required String postId,required String commentId,required String uid}) async { if(_real) await _postsRef.doc(postId).update({'bestAnswerId':commentId}); }
  Future<void> votePoll({required String postId,required String uid,required int option}) async {
    if(_real){ final ref=_postsRef.doc(postId); await FirebaseFirestore.instance.runTransaction((tx) async { final snap=await tx.get(ref); if(!snap.exists) throw StateError('Post no longer exists.'); final p=Post.fromDoc(snap); if(option<0||option>=p.pollOptions.length) throw ArgumentError('Invalid poll option.'); final votes=Map<String,int>.from(p.pollVotes); final previous=votes[uid]; if(previous!=null){ final k=previous.toString(); votes[k]=(votes[k]??1)-1; if(votes[k]!<=0) votes.remove(k); } votes[uid]=option; final counts=<String,int>{}; for(final v in votes.values){ final k=v.toString(); counts[k]=(counts[k]??0)+1; } tx.update(ref,{'pollVotes':counts}); }); return; }
    final i=_demoPosts.indexWhere((p)=>p.id==postId); if(i<0) throw StateError('Post no longer exists.'); final p=_demoPosts[i]; if(option<0||option>=p.pollOptions.length) throw ArgumentError('Invalid poll option.'); final votes=Map<String,int>.from(p.pollVotes); final previous=votes[uid]; if(previous!=null){final k=previous.toString(); votes[k]=(votes[k]??1)-1;if(votes[k]!<=0)votes.remove(k);} votes[uid]=option; final counts=<String,int>{}; for(final v in votes.values){final k=v.toString();counts[k]=(counts[k]??0)+1;} _demoPosts[i]=Post(id:p.id,text:p.text,authorId:p.authorId,authorName:p.authorName,createdAt:p.createdAt,category:p.category,likesCount:p.likesCount,likedBy:p.likedBy,commentsCount:p.commentsCount,isQuestion:p.isQuestion,bestAnswerId:p.bestAnswerId,instituteId:p.instituteId,pollOptions:p.pollOptions,pollVotes:counts); _postChanges.add(null);
  }
  Future<void> notifyMention({required String targetId,required String fromId,required String postId}) async {}
  Future<void> notifyMentions({required String text,required String fromId,required String postId}) async {}
  Future<Map<String,dynamic>> reputation(String uid) async => {'score':0,'posts':0,'comments':0,'likes':0,'bestAnswers':0,'followers':0,'rating':0.0,'reviews':0,'badges':<String>[]};
  Stream<List<Map<String,dynamic>>> notificationsStream(String uid) async* { yield const []; }
  Future<void> markNotificationRead(String uid,String id) async {}
  DocumentReference<Map<String,dynamic>> _followingRef(String uid,String targetId) => FirebaseFirestore.instance.collection('users').doc(uid).collection('following').doc(targetId);
  DocumentReference<Map<String,dynamic>> _followersRef(String uid,String followerId) => FirebaseFirestore.instance.collection('users').doc(uid).collection('followers').doc(followerId);

  String conversationId(String a,String b) {
    final ids=[a,b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<bool> isFollowing(String uid,String targetId) async {
    if (uid == targetId) return false;
    return (await _followingRef(uid,targetId).get()).exists;
  }

  Future<bool> isMutualFollow(String uid,String targetId) async {
    if (uid == targetId) return false;
    final results=await Future.wait([
      _followingRef(uid,targetId).get(),
      _followingRef(targetId,uid).get(),
    ]);
    return results[0].exists && results[1].exists;
  }

  Future<void> toggleFollow(String uid,String targetId,bool follow) async {
    if (uid == targetId) return;
    final batch=FirebaseFirestore.instance.batch();
    final following=_followingRef(uid,targetId);
    final followers=_followersRef(targetId,uid);
    if (follow) {
      batch.set(following,{'uid':uid,'targetId':targetId,'createdAt':FieldValue.serverTimestamp()});
      batch.set(followers,{'uid':uid,'createdAt':FieldValue.serverTimestamp()});
    } else {
      batch.delete(following);
      batch.delete(followers);
    }
    await batch.commit();
  }

  Stream<bool> followingStream(String uid,String targetId) {
    if (uid == targetId) return Stream<bool>.value(false);
    return _followingRef(uid,targetId).snapshots().map((s)=>s.exists);
  }

  Stream<bool> mutualFollowStream(String uid,String targetId) {
    if (uid == targetId) return Stream<bool>.value(false);
    return _followingRef(uid,targetId).snapshots().asyncMap((_) async => isMutualFollow(uid,targetId));
  }

  Stream<int> followerCountStream(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('followers').snapshots().map((s)=>s.size);
  }

  Future<String?> createConversation({required String uid,required String otherUid,required String otherName}) async {
    if (uid == otherUid || !await isMutualFollow(uid,otherUid)) return null;
    final id=conversationId(uid,otherUid);
    await FirebaseFirestore.instance.collection('conversations').doc(id).set({
      'id':id,
      'participants':[uid,otherUid],
      'participantNames':{uid:'You',otherUid:otherName},
      'lastMessage':'',
      'lastMessageAt':FieldValue.serverTimestamp(),
      'updatedAt':FieldValue.serverTimestamp(),
      'createdAt':FieldValue.serverTimestamp(),
    },SetOptions(merge:true));
    return id;
  }
  Future<void> saveApplication({required String collection,required String itemId,required String title,required String applicantId,required String applicantName}) async {}
  Future<void> saveInterest({required String seminarId,required String title,required String userId,required String userName}) async {}
  Stream<bool> applicationExists({required String collection,required String itemId,required String applicantId}) async* { yield false; }
  Stream<bool> interestExists({required String seminarId,required String userId}) async* { yield false; }

  Stream<QuerySnapshot<Map<String,dynamic>>> commentsStream(String postId) {
    return FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').snapshots();
  }

  Stream<QuerySnapshot<Map<String,dynamic>>> newsStream() {
    return FirebaseFirestore.instance.collection('news').orderBy('createdAt', descending:true).snapshots();
  }

  Future<DocumentSnapshot<Map<String,dynamic>>> newsItem(String id) {
    return FirebaseFirestore.instance.collection('news').doc(id).get();
  }
}

}

extension _NullableStreamStart<T> on Stream<T> { Stream<T> startWith(T value) async* { yield value; yield* this; } }
