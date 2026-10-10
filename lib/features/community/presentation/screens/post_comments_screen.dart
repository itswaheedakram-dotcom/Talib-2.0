import '../../../../core/widgets/user_identity.dart';
import '../../../../core/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/demo_data_service.dart';
import '../../../../app/theme.dart';
import '../../../models/post.dart';

class PostCommentsScreen extends StatefulWidget {
  final String id;
  const PostCommentsScreen({super.key, required this.id});
  @override State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  DatabaseService? _db;
  final _comment = TextEditingController();
  bool _demoLiked = false, _saved = false;
  bool get isDemo => ActiveProfileController.instance.isDemoActive;

  @override
  void dispose() { _comment.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ready = FirebaseService.initialized;
    if (ready && _db == null) _db = DatabaseService();
    final user = ready ? FirebaseAuth.instance.currentUser : null;

    if (isDemo) {
      final post = DemoDataService.instance.post(widget.id);
      if (post == null) return const Scaffold(body: Center(child: Text('Post not found.')));
      return Scaffold(appBar: AppBar(title: const Text('Post')), body: _content(post, user));
    }
    if (!ready) return const Scaffold(body: Center(child: Text('Firebase is not initialized.')));

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('posts').doc(widget.id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('Post not found.'));
          return _content(Post.fromDoc(snapshot.data!), user);
        },
      ),
    );
  }

  Widget _content(Post post, User? user) {
    final identity = ActiveProfileController.instance;
    final uid = identity.resolveUid(user?.uid ?? '');
    final currentPost = isDemo ? (DemoDataService.instance.post(widget.id) ?? post) : post;
    final liked = currentPost.likedByUser(uid) || _demoLiked;
    final likes = currentPost.likesCount;
    final canInteract = user != null || isDemo;

    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(14), children: [
        InkWell(
          onTap: () => context.push('/profile/${post.authorId}'),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.softGreen,
              child: Text(post.authorName.isEmpty ? '?' : post.authorName[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              UserIdentity(uid: post.authorId, name: post.authorName),
              const Text('View profile', style: TextStyle(color: AppColors.homeMutedText, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 14),
        if (post.isQuestion) const Text('QUESTION', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 6),
        Text(post.text, style: const TextStyle(fontSize: 16, height: 1.45)),
        if(post.attachments.isNotEmpty) ...[
          const SizedBox(height:10),
          ...post.attachments.map((a){
            final type=a['type']??'file'; final url=a['url']??''; final name=a[ProfileFields.name]??'Attachment';
            if(type=='photo'&&url.isNotEmpty) return ClipRRect(
              borderRadius:BorderRadius.circular(12),
              child:Image.network(url,height:240,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>_attachmentTile(name,Icons.broken_image_outlined)),
            );
            return _attachmentTile(name,type=='link'?Icons.link:Icons.insert_drive_file_outlined);
          }),
        ],
        const SizedBox(height: 10),
        Wrap(spacing: 4, children: [
          IconButton(
            onPressed: canInteract ? () async {
              if (isDemo) {
                DemoDataService.instance.toggleLike(widget.id, uid);
                setState(() => _demoLiked = false);
              } else { await _db!.toggleLike(post, uid); }
            } : null,
            icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: Colors.red),
          ),
          Text('${likes} likes', style: const TextStyle(height: 3)),
          IconButton(
            onPressed: canInteract ? () async {
              final next = !_saved;
              setState(() => _saved = next);
              if (isDemo) {
                DemoDataService.instance.toggleBookmark(uid, post.id, next);
              } else {
                await _db!.toggleBookmark(post.id, uid, next);
              }
            } : null,
            icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border, color: AppColors.primaryGreen),
          ),
          Text(_saved ? 'Saved' : 'Save', style: const TextStyle(height: 3)),
          if (!isDemo && user != null && user.uid == post.authorId)
            IconButton(tooltip: 'Edit', onPressed: () => context.push('/community/create', extra: post), icon: const Icon(Icons.edit_outlined)),
          if (!isDemo && user != null && user.uid != post.authorId)
            IconButton(tooltip: 'Report', onPressed: () => _report(post, user), icon: const Icon(Icons.flag_outlined)),
        ]),
        const Divider(height: 26),
        Row(children: [
          const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(isDemo ? DemoDataService.instance.comments(widget.id).length.toString() : post.commentsCount.toString()),
        ]),
        const SizedBox(height: 8),
        if (isDemo) _demoComments() else _firebaseComments(post, user),
      ])),
      SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _comment,
            enabled: canInteract,
            onSubmitted: (_) => _addComment(user),
            decoration: InputDecoration(
              hintText: user == null ? 'Sign in to comment' : 'Write a comment...',
              filled: true,
              fillColor: AppColors.softGreen,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          )),
          IconButton(onPressed: canInteract ? () => _addComment(user) : null, icon: const Icon(Icons.send, color: AppColors.primaryGreen)),
        ]),
      )),
    ]);
  }

  Stream<List<Map<String, dynamic>>> _demoCommentsStream() async* {
    List<Map<String, dynamic>> current() => DemoDataService.instance.comments(widget.id)
        .map((x) => {
              'id': x.id,
              ProfileFields.authorId: x.authorId,
              ProfileFields.authorName: x.authorName,
              'text': x.text,
              'createdAt': x.createdAt,
            })
        .toList();

    // Emit the existing comments immediately when the screen opens.
    yield current();

    // Then keep the list live as demo data changes.
    yield* DemoDataService.instance.changes.map((_) => current());
  }

  Widget _demoComments() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _demoCommentsStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data ?? const <Map<String, dynamic>>[];
        if (docs.isEmpty) return const Text('No comments yet.');
        return Column(children: docs.map((x) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(backgroundColor: AppColors.softGreen, child: Icon(Icons.person, color: AppColors.primaryGreen)),
          title: Row(children:[
            Expanded(child:UserIdentity(uid: (x[ProfileFields.authorId] ?? '').toString(), name: (x[ProfileFields.authorName] ?? 'Student').toString())),
            if(widget.id.isNotEmpty && DemoDataService.instance.post(widget.id)?.bestAnswerId==x['id'])
              const Text('BEST ANSWER',style:TextStyle(color:AppColors.primaryGreen,fontSize:10,fontWeight:FontWeight.bold)),
          ]),
          subtitle: Text((x['text'] ?? '').toString()),
          trailing: (DemoDataService.instance.post(widget.id)?.isQuestion==true && DemoDataService.instance.post(widget.id)?.authorId==ActiveProfileController.instance.effectiveUid)
            ? IconButton(
                tooltip:'Mark as best answer',
                onPressed:()=>DemoDataService.instance.setBestAnswer(postId:widget.id,commentId:x['id'].toString(),uid:ActiveProfileController.instance.effectiveUid!),
                icon:Icon(
                  DemoDataService.instance.post(widget.id)?.bestAnswerId==x['id']?Icons.check_circle:Icons.check_circle_outline,
                  color:AppColors.primaryGreen,
                ),
              )
            : null,
        )).toList());
      },
    );
  }

  Widget _firebaseComments(Post post, User? user) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db!.commentsStream(widget.id),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (docs.isEmpty) return const Text('No comments yet.');
        return Column(children: docs.map((doc) {
          final data = doc.data();
          final commentId = doc.id;
          final accepted = commentId == post.bestAnswerId;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: AppColors.softGreen, child: Icon(Icons.person, color: AppColors.primaryGreen)),
            title: Row(children: [
              Expanded(child: UserIdentity(uid: (data[ProfileFields.authorId] ?? '').toString(), name: (data[ProfileFields.authorName] ?? 'Student').toString())),
              if (accepted) const Text('BEST ANSWER', style: TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
            subtitle: Text((data['text'] ?? '').toString()),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (user?.uid == post.authorId) IconButton(
                tooltip: accepted ? 'Best answer' : 'Mark as best answer',
                onPressed: () => _db!.setBestAnswer(postId: post.id, commentId: commentId, uid: user!.uid),
                icon: Icon(accepted ? Icons.check_circle : Icons.check_circle_outline, color: AppColors.primaryGreen),
              ),
              if (user?.uid == data[ProfileFields.authorId]) PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value != 'delete') return;
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete comment?'),
                      content: const Text('This comment will be permanently deleted.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok == true) await _db!.deleteComment(postId: post.id, commentId: commentId, uid: user!.uid);
                },
                itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
              ),
            ]),
          );
        }).toList());
      },
    );
  }

  Widget _attachmentTile(String name,IconData icon){
    return Padding(
      padding:const EdgeInsets.only(bottom:8),
      child:Container(
        padding:const EdgeInsets.all(12),
        decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(10)),
        child:Row(children:[
          Icon(icon,color:AppColors.primaryGreen),const SizedBox(width:10),
          Expanded(child:Text(name,overflow:TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Future<void> _addComment(User? user) async {
    final text = _comment.text.trim();
    final identity = ActiveProfileController.instance;
    if (text.isEmpty) return;
    if (isDemo) {
      final uid = identity.effectiveUid;
      if (uid == null) return;
      final name = identity.effectiveName ?? 'Student';
      DemoDataService.instance.addComment(postId: widget.id, text: text, uid: uid, name: name);
      _comment.clear();
      return;
    }
    if (user == null || _db == null) return;
    try {
      await _db!.addComment(
        postId: widget.id,
        text: text,
        authorId: user.uid,
        authorName: user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : (user.email ?? 'Student'),
      );
      _comment.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not add comment.')));
    }
  }

  Future<void> _report(Post post, User user) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Report post'),
        children: ['Spam', 'Harassment', 'Fake information', 'Inappropriate', 'Scam', 'Other']
            .map((reason) => SimpleDialogOption(onPressed: () => Navigator.pop(context, reason), child: Text(reason)))
            .toList(),
      ),
    );
    if (reason != null) await _db!.report(reporterId: user.uid, targetId: post.id, targetType: 'post', reason: reason);
  }
}
