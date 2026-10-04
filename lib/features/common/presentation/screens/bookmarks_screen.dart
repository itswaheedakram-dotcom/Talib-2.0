import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_service.dart';
import '../../../models/post.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(appBar: AppBar(title: const Text('Bookmarks')), body: const _EmptyState(
        icon: Icons.bookmark_border, title: 'Sign in to view bookmarks',
        message: 'Save useful community posts and keep them here for later.',
      ));
    }
    final db = DatabaseService();
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: StreamBuilder<List<Post>>(
        stream: db.bookmarkedPostsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const _EmptyState(icon: Icons.error_outline, title: 'Could not load bookmarks', message: 'Please try again in a moment.');
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final posts = snapshot.data ?? const <Post>[];
          if (posts.isEmpty) return const _EmptyState(icon: Icons.bookmark_border, title: 'No bookmarks yet', message: 'Tap the bookmark icon on a community post to save it here.');
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final post = posts[index];
              return _BookmarkCard(post: post, onOpen: () => context.push('/community/post/' + post.id), onRemove: () => db.toggleBookmark(post.id, user.uid, false));
            },
          );
        },
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final Post post; final VoidCallback onOpen; final VoidCallback onRemove;
  const _BookmarkCard({required this.post, required this.onOpen, required this.onRemove});
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: onOpen, borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: const Color(0xFFE8F5E9), child: Text(
              post.authorName.isEmpty ? '?' : post.authorName[0].toUpperCase(),
              style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
            )),
            const SizedBox(width: 10),
            Expanded(child: Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w600))),
            IconButton(onPressed: onRemove, tooltip: 'Remove bookmark', icon: const Icon(Icons.bookmark)),
          ]),
          const SizedBox(height: 8),
          Text(post.text, maxLines: 4, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text(post.likesCount.toString() + ' likes  •  ' + post.commentsCount.toString() + ' comments', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String title; final String message;
  const _EmptyState({required this.icon, required this.title, required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 64, color: const Color(0xFF4CAF50)),
      const SizedBox(height: 14),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 18),
      Builder(builder: (context) => SizedBox(width: 150, child: FilledButton(onPressed: () => context.push('/signin'), child: const Text('Sign In')))),
    ]),
  ));
}