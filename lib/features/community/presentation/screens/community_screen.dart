import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/post.dart';
import '../../../../core/services/database_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _db = DatabaseService();
  final _search = TextEditingController();
  bool _popular = false;
  String _query = '';

  @override void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          PopupMenuButton<bool>(
            onSelected: (v) => setState(() => _popular = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: false, child: Text('Latest')),
              PopupMenuItem(value: true, child: Text('Popular')),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: user == null ? () => _loginMessage() : () => context.push('/community/create'),
        icon: const Icon(Icons.add), label: const Text('Post'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search community posts'),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Post>>(
            stream: _db.postsStream(popular: _popular),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Unable to load community posts.'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final posts = (snapshot.data ?? []).where((p) =>
                _query.isEmpty || p.text.toLowerCase().contains(_query) || p.authorName.toLowerCase().contains(_query)).toList();
              if (posts.isEmpty) return const Center(child: Text('No community posts found.'));
              return StreamBuilder<Set<String>>(
                stream: user == null ? null : _db.bookmarkIdsStream(user.uid),
                builder: (context, bookmarks) {
                  final saved = bookmarks.data ?? <String>{};
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 90),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final post = posts[i];
                      return _PostCard(
                        post: post, saved: saved.contains(post.id), user: user,
                        onOpen: () => context.push('/community/post/' + post.id),
                        onLike: user == null ? null : () => _db.toggleLike(post, user.uid),
                        onBookmark: user == null ? null : () => _db.toggleBookmark(post.id, user.uid, !saved.contains(post.id)),
                        onDelete: user?.uid == post.authorId ? () => _confirmDelete(post) : null,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  void _loginMessage() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Please sign in to create, like or save posts.')),
  );

  Future<void> _confirmDelete(Post post) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This post will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) await _db.deletePost(post.id);
  }
}

class _PostCard extends StatelessWidget {
  final Post post; final User? user; final bool saved;
  final VoidCallback onOpen; final VoidCallback onAuthor; final VoidCallback? onLike; final VoidCallback? onBookmark; final VoidCallback? onDelete;
  const _PostCard({required this.post, required this.user, required this.saved, required this.onOpen, required this.onAuthor, this.onLike, this.onBookmark, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final liked = post.likedByUser(user?.uid);
    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(backgroundColor: const Color(0xFFE8F5E9), child: Text(post.authorName.isEmpty ? '?' : post.authorName[0].toUpperCase(), style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold))),
              const SizedBox(width: 10),
              Expanded(child: Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold))),
              if (onDelete != null) IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
            ]),
            const SizedBox(height: 10),
            Text(post.text, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Row(children: [
              IconButton(onPressed: onLike, icon: Icon(liked ? Icons.favorite : Icons.favorite_border)),
              Text(post.likesCount.toString()),
              IconButton(onPressed: onOpen, icon: const Icon(Icons.comment_outlined)),
              Text(post.commentsCount.toString()),
              const Spacer(),
              IconButton(onPressed: onBookmark, icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border)),
            ]),
          ]),
        ),
      ),
    );
  }
}
