import 'dart:async';
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
import '../widgets/community_post_card.dart';
import '../widgets/community_shimmer.dart';

class PostCommentsScreen extends StatefulWidget {
  final String id;
  const PostCommentsScreen({super.key, required this.id});
  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  DatabaseService? _db = DatabaseService();
  final _comment = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<User?>? _auth;
  bool _sending = false;
  String _scope = '';
  bool get isDemo => ActiveProfileController.instance.isDemo;
  String get _uid => isDemo
      ? (ActiveProfileController.instance.effectiveUid ?? '')
      : (FirebaseService.initialized
            ? FirebaseAuth.instance.currentUser?.uid ?? ''
            : '');
  String get _currentScope => '${isDemo ? 'demo' : 'real'}:$_uid';
  @override
  void initState() {
    super.initState();
    _scope = _currentScope;
    ActiveProfileController.instance.addListener(_identityChanged);
    if (FirebaseService.initialized)
      _auth = FirebaseAuth.instance.authStateChanges().listen(
        (_) => _identityChanged(),
      );
  }

  void _identityChanged() {
    if (_scope != _currentScope) {
      _scope = _currentScope;
      _comment.clear();
      _sending = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    _scroll.dispose();
    _auth?.cancel();
    ActiveProfileController.instance.removeListener(_identityChanged);
    super.dispose();
  }

  void _feedback(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.initialized
        ? FirebaseAuth.instance.currentUser
        : null;
    if (isDemo)
      return ListenableBuilder(
        listenable: DemoDataService.instance,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Post')),
          body: DemoDataService.instance.post(widget.id) == null
              ? const Center(child: Text('This post is no longer available.'))
              : _content(DemoDataService.instance.post(widget.id)!, user),
        ),
      );
    if (!FirebaseService.initialized || user == null)
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: const Center(child: Text('Sign in to view this post.')),
      );
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('This post could not be loaded.'),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData)
            return const CommunityShimmer();
          if (snapshot.data?.exists != true)
            return const Center(
              child: Text('This post is no longer available.'),
            );
          return _content(Post.fromDoc(snapshot.data!), user);
        },
      ),
    );
  }

  Widget _content(Post post, User? user) {
    final uid = _uid, canInteract = uid.isNotEmpty;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            children: [
              StreamBuilder<Set<String>>(
                key: ValueKey(_scope),
                stream: canInteract
                    ? _db!.bookmarkIdsStream(uid)
                    : const Stream<Set<String>>.empty(),
                builder: (context, saved) => CommunityPostCard(
                  post: post,
                  uid: uid,
                  full: true,
                  saved: saved.data?.contains(post.id) == true,
                  onAuthor: () => context.push('/profile/${post.authorId}'),
                  onOpen: () => _scroll.animateTo(
                    _scroll.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                  ),
                  onReact: canInteract
                      ? (reaction) => _db!.setReaction(post.id, uid, reaction)
                      : null,
                  onSave: canInteract
                      ? () async {
                          try {
                            await _db!.toggleBookmark(
                              post.id,
                              uid,
                              saved.data?.contains(post.id) != true,
                            );
                          } catch (_) {
                            _feedback('Could not update saved posts.');
                          }
                        }
                      : null,
                  onPoll: canInteract
                      ? (index) async {
                          try {
                            await _db!.votePoll(
                              postId: post.id,
                              uid: uid,
                              option: index,
                            );
                          } catch (_) {
                            _feedback(
                              'Your vote could not be saved. The poll may have closed.',
                            );
                          }
                        }
                      : null,
                  menu: {
                    if (uid == post.authorId)
                      'Edit': () =>
                          context.push('/community/create', extra: post),
                    if (user != null && uid != post.authorId)
                      'Report': () => _report(post, user),
                  },
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Comments (${post.commentsCount})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              if (isDemo) _demoComments() else _firebaseComments(post, user),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _comment,
                    enabled: canInteract && !_sending,
                    maxLength: 5000,
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => _addComment(user),
                    decoration: InputDecoration(
                      hintText: canInteract
                          ? 'Write a comment…'
                          : 'Sign in to comment',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Send comment',
                  onPressed: canInteract && !_sending
                      ? () => _addComment(user)
                      : null,
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Stream<List<Map<String, dynamic>>> _demoCommentsStream() async* {
    List<Map<String, dynamic>> current() => DemoDataService.instance
        .comments(widget.id)
        .map(
          (x) => {
            'id': x.id,
            ProfileFields.authorId: x.authorId,
            ProfileFields.authorName: x.authorName,
            'text': x.text,
            'createdAt': x.createdAt,
          },
        )
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
        if (snapshot.hasError)
          return const Text(
            'Comments could not be loaded. Please reopen the post to retry.',
          );
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData)
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          );
        if (docs.isEmpty) return Text('No comments yet.');
        return Column(
          children: docs
              .map(
                (x) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Expanded(
                        child: UserIdentity(
                          showUsername: false,
                          uid: (x[ProfileFields.authorId] ?? '').toString(),
                          name: (x[ProfileFields.authorName] ?? 'Student')
                              .toString(),
                        ),
                      ),
                      if (widget.id.isNotEmpty &&
                          DemoDataService.instance
                                  .post(widget.id)
                                  ?.bestAnswerId ==
                              x['id'])
                        Text(
                          'BEST ANSWER',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text((x['text'] ?? '').toString()),
                  trailing:
                      (DemoDataService.instance.post(widget.id)?.isQuestion ==
                              true &&
                          DemoDataService.instance.post(widget.id)?.authorId ==
                              ActiveProfileController.instance.effectiveUid)
                      ? IconButton(
                          tooltip: 'Mark as best answer',
                          onPressed: () =>
                              DemoDataService.instance.setBestAnswer(
                                postId: widget.id,
                                commentId: x['id'].toString(),
                                uid: ActiveProfileController
                                    .instance
                                    .effectiveUid!,
                              ),
                          icon: Icon(
                            DemoDataService.instance
                                        .post(widget.id)
                                        ?.bestAnswerId ==
                                    x['id']
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: AppColors.primaryGreen,
                          ),
                        )
                      : null,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _firebaseComments(Post post, User? user) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db!.commentsStream(widget.id),
      builder: (context, snapshot) {
        final docs =
            snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (snapshot.hasError)
          return const Text(
            'Comments could not be loaded. Please reopen the post to retry.',
          );
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData)
          return const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          );
        if (docs.isEmpty) return Text('No comments yet.');
        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final commentId = doc.id;
            final accepted = commentId == post.bestAnswerId;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Expanded(
                    child: UserIdentity(
                      showUsername: false,
                      uid: (data[ProfileFields.authorId] ?? '').toString(),
                      name: (data[ProfileFields.authorName] ?? 'Student')
                          .toString(),
                    ),
                  ),
                  if (accepted)
                    Text(
                      'BEST ANSWER',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              subtitle: Text((data['text'] ?? '').toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post.isQuestion && user?.uid == post.authorId)
                    IconButton(
                      tooltip: accepted ? 'Best answer' : 'Mark as best answer',
                      onPressed: () => _db!.setBestAnswer(
                        postId: post.id,
                        commentId: commentId,
                        uid: user!.uid,
                      ),
                      icon: Icon(
                        accepted
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  if (user?.uid == data[ProfileFields.authorId])
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value != 'delete') return;
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('Delete comment?'),
                            content: Text(
                              'This comment will be permanently deleted.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true)
                          await _db!.deleteComment(
                            postId: post.id,
                            commentId: commentId,
                            uid: user!.uid,
                          );
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _attachmentTile(String name, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppPalette.of(context).softSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGreen),
            SizedBox(width: 10),
            Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Future<void> _addComment(User? user) async {
    if (_sending) return;
    final text = _comment.text.trim(), uid = _uid, scope = _scope;
    if (text.isEmpty || uid.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _db!.addComment(
        postId: widget.id,
        text: text,
        authorId: uid,
        authorName:
            ActiveProfileController.instance.effectiveName ??
            user?.displayName ??
            'Student',
      );
      if (mounted && scope == _scope) _comment.clear();
    } catch (_) {
      if (mounted && scope == _scope)
        _feedback(
          'Comment could not be sent. Your text is still here—please retry.',
        );
    } finally {
      if (mounted && scope == _scope) setState(() => _sending = false);
    }
  }

  Future<void> _report(Post post, User user) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('Report post'),
        children:
            [
                  'Spam',
                  'Harassment',
                  'Fake information',
                  'Inappropriate',
                  'Scam',
                  'Other',
                ]
                .map(
                  (reason) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, reason),
                    child: Text(reason),
                  ),
                )
                .toList(),
      ),
    );
    if (reason != null) {
      try {
        await _db!.report(
          reporterId: _uid,
          targetId: post.id,
          targetType: 'post',
          reason: reason,
        );
        _feedback('Report submitted for review');
      } catch (_) {
        _feedback('Report could not be sent. Please retry.');
      }
    }
  }
}
