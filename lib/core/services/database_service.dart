import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/models/post.dart';

class DatabaseService {
  final FirebaseFirestore _db=FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> collection(String name)=>_db.collection(name);
  Stream<List<Post>> postsStream({bool popular=false,String category='All',String query=''})=>_db.collection('posts').orderBy(popular?'likesCount':'createdAt',descending:true).snapshots().map((s)=>s.docs.map(Post.fromDoc).where((p)=>(category=='All'||p.category==category)&&(query.isEmpty||p.text.toLowerCase().contains(query.toLowerCase())||p.authorName.toLowerCase().contains(query.toLowerCase()))).toList());
  Future<String> createPost({required String text,required String authorId,required String authorName,String category='General',bool isQuestion=false})async{
    final ref=await _db.collection('posts').add({'text':text.trim(),'authorId':authorId,'authorName':authorName,'category':category,'isQuestion':isQuestion,'createdAt':FieldValue.serverTimestamp(),'likesCount':0,'likedBy':<String>[],'commentsCount':0});
    return ref.id;
  }
  Future<void> updatePost({required String postId,required String text,String? category,bool? isQuestion})=>_db.collection('posts').doc(postId).update({'text':text.trim(),if(category!=null)'category':category,if(isQuestion!=null)'isQuestion':isQuestion});
  Future<void> deletePost(String postId)=>_db.collection('posts').doc(postId).delete();
  Future<void> toggleLike(Post post,String uid)async{
    final ref=_db.collection('posts').doc(post.id);
    await _db.runTransaction((tx)async{final snap=await tx.get(ref);if(!snap.exists)return;final d=snap.data()??{};final ids=List<String>.from(d['likedBy']??const[]);final add=!ids.contains(uid);if(add)ids.add(uid);else ids.remove(uid);tx.update(ref,{'likedBy':ids,'likesCount':ids.length});if(add&&post.authorId!=uid){final n=_db.collection('users').doc(post.authorId).collection('notifications').doc();tx.set(n,{'type':'like','text':'liked your post','postId':post.id,'fromId':uid,'createdAt':FieldValue.serverTimestamp(),'read':false});}});
  }
  Stream<QuerySnapshot<Map<String,dynamic>>> commentsStream(String postId)=>_db.collection('posts').doc(postId).collection('comments').orderBy('createdAt',descending:false).snapshots();
  Future<void> addComment({required String postId,required String text,required String authorId,required String authorName})async{
    final postRef=_db.collection('posts').doc(postId);final commentRef=postRef.collection('comments').doc();
    await _db.runTransaction((tx)async{final snap=await tx.get(postRef);tx.set(commentRef,{'text':text.trim(),'authorId':authorId,'authorName':authorName,'createdAt':FieldValue.serverTimestamp()});tx.update(postRef,{'commentsCount':FieldValue.increment(1)});final owner=(snap.data()?['authorId']??'').toString();if(owner.isNotEmpty&&owner!=authorId){final n=_db.collection('users').doc(owner).collection('notifications').doc();tx.set(n,{'type':'comment','text':'commented on your post','postId':postId,'fromId':authorId,'createdAt':FieldValue.serverTimestamp(),'read':false});}});
  }
  Future<void> setBestAnswer({required String postId,required String commentId,required String uid})async{final p=await _db.collection('posts').doc(postId).get();if(p.data()?['authorId']==uid)await p.reference.update({'bestAnswerId':commentId});}
  Future<void> toggleBookmark(String postId,String uid,bool save)async{final ref=_db.collection('users').doc(uid).collection('bookmarks').doc(postId);if(save)await ref.set({'postId':postId,'createdAt':FieldValue.serverTimestamp()});else await ref.delete();}
  Stream<Set<String>> bookmarkIdsStream(String uid)=>_db.collection('users').doc(uid).collection('bookmarks').snapshots().map((s)=>s.docs.map((d)=>d.id).toSet());
  Stream<List<Post>> bookmarkedPostsStream(String uid)=>_db.collection('users').doc(uid).collection('bookmarks').orderBy('createdAt',descending:true).snapshots().asyncMap((s)async{final posts=<Post>[];for(final b in s.docs){final d=await _db.collection('posts').doc(b.id).get();if(d.exists)posts.add(Post.fromDoc(d));}return posts;});
  Future<void> report({required String reporterId,required String targetId,required String targetType,required String reason})=>_db.collection('reports').add({'reporterId':reporterId,'targetId':targetId,'targetType':targetType,'reason':reason,'createdAt':FieldValue.serverTimestamp(),'status':'open'});
  Future<void> blockUser(String uid,String blockedId)=>_db.collection('users').doc(uid).collection('blockedUsers').doc(blockedId).set({'blockedId':blockedId,'createdAt':FieldValue.serverTimestamp()});
  Future<void> unblockUser(String uid,String blockedId)=>_db.collection('users').doc(uid).collection('blockedUsers').doc(blockedId).delete();
  Stream<Set<String>> blockedUserIdsStream(String uid)=>_db.collection('users').doc(uid).collection('blockedUsers').snapshots().map((s)=>s.docs.map((d)=>d.id).toSet());
  Stream<QuerySnapshot<Map<String,dynamic>>> notificationsStream(String uid)=>_db.collection('users').doc(uid).collection('notifications').orderBy('createdAt',descending:true).limit(50).snapshots();
  Future<void> markNotificationRead(String uid,String id)=>_db.collection('users').doc(uid).collection('notifications').doc(id).update({'read':true});
}