import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/models/post.dart';
import '../../features/models/news_item.dart';

class DatabaseService {
  static final List<Post> _posts = [
    Post(id:'demo-1',text:'Welcome to Talib Community! Ask questions, share guidance and help other students.',authorId:'demo-user-1',authorName:'Talib Community',createdAt:DateTime.now().subtract(const Duration(minutes:15)),category:'General',likesCount:12,commentsCount:4),
    Post(id:'demo-2',text:'Which institute is best for your next education program? Share your experience and help fellow students.',authorId:'demo-user-2',authorName:'Student Guide',createdAt:DateTime.now().subtract(const Duration(hours:2)),category:'Institute Reviews',likesCount:8,commentsCount:3,isQuestion:true),
    Post(id:'demo-3',text:'Need admission guidance? You can use Find Institute to compare institutes, programs and eligibility.',authorId:'demo-user-3',authorName:'Talib Team',createdAt:DateTime.now().subtract(const Duration(hours:5)),category:'Admission Help',likesCount:6,commentsCount:2),
  ];
  static final Set<String> _bookmarks = {};
  static final Set<String> _blocked = {};
  Stream<List<Post>> postsStream({bool popular=false,String category='All',String query=''}) async* { yield _filtered(popular,category,query); }
  List<Post> _filtered(bool popular,String category,String query) {
    final list=List<Post>.from(_posts);
    if(popular) list.sort((a,b)=>b.likesCount.compareTo(a.likesCount)); else list.sort((a,b)=>b.createdAt.compareTo(a.createdAt));
    return list.where((p)=>(category=='All'||p.category==category)&&(query.isEmpty||p.text.toLowerCase().contains(query.toLowerCase())||p.authorName.toLowerCase().contains(query.toLowerCase()))).toList();
  }
  Future<String> createPost({required String text,required String authorId,required String authorName,String category='General',bool isQuestion=false,List<String> pollOptions=const [],String? instituteId}) async {
    final id='local-${DateTime.now().microsecondsSinceEpoch}';
    _posts.insert(0,Post(id:id,text:text.trim(),authorId:authorId,authorName:authorName,createdAt:DateTime.now(),category:category,isQuestion:isQuestion,pollOptions:pollOptions,likesCount:0,commentsCount:0,instituteId:instituteId)); return id;
  }
  Future<void> updatePost({required String postId,required String text,String? category,bool? isQuestion}) async {
    final i=_posts.indexWhere((p)=>p.id==postId); if(i<0)return; final p=_posts[i];
    _posts[i]=Post(id:p.id,text:text.trim(),authorId:p.authorId,authorName:p.authorName,createdAt:p.createdAt,category:category??p.category,likesCount:p.likesCount,commentsCount:p.commentsCount,isQuestion:isQuestion??p.isQuestion,pollOptions:p.pollOptions,instituteId:p.instituteId);
  }
  Future<void> deletePost(String postId) async => _posts.removeWhere((p)=>p.id==postId);
  Future<void> toggleLike(Post post,String uid) async {}
  Stream<Set<String>> blockedUserIdsStream(String uid) async* { yield _blocked; }
  Stream<Set<String>> bookmarkIdsStream(String uid) async* { yield _bookmarks; }
  Future<void> toggleBookmark(String postId,String uid,bool save) async { if(save)_bookmarks.add(postId);else _bookmarks.remove(postId); }
  Stream<List<Post>> bookmarkedPostsStream(String uid) async* { yield _posts.where((p)=>_bookmarks.contains(p.id)).toList(); }
  Future<void> report({required String reporterId,required String targetId,required String targetType,required String reason}) async {}
  Future<void> blockUser(String uid,String blockedId) async => _blocked.add(blockedId);
  Future<void> unblockUser(String uid,String blockedId) async => _blocked.remove(blockedId);
  Future<void> addComment({required String postId,required String text,required String authorId,required String authorName}) async {}
  Future<void> deleteComment({required String postId,required String commentId,required String uid}) async {}
  Future<void> setBestAnswer({required String postId,required String commentId,required String uid}) async {}
  Future<void> votePoll({required String postId,required String uid,required int option}) async {}
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
  Stream<bool> followingStream(String uid,String targetId) async* { yield false; }
  Stream<int> followerCountStream(String uid) async* { yield 0; }
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
