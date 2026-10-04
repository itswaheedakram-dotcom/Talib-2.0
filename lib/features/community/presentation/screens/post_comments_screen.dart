import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/database_service.dart';
import '../../../models/post.dart';

class PostCommentsScreen extends StatefulWidget {
  final String id;
  const PostCommentsScreen({super.key, required this.id});
  @override State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final _db = DatabaseService();
  final _comment = TextEditingController();

  @override void dispose() { _comment.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('posts').doc(widget.id).snapshots(),
        builder: (context, postSnapshot) {
          if (postSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!postSnapshot.hasData || !postSnapshot.data!.exists) return const Center(child: Text('Post not found.'));
          final post = Post.fromDoc(postSnapshot.data!);
          return Column(children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.all(12), children: [
                Card(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(post.text, style: const TextStyle(fontSize: 16)),
                    Row(children: [
                      IconButton(
                        onPressed: user == null ? null : () => _db.toggleLike(post, user.uid),
                        icon: Icon(post.likedByUser(user?.uid) ? Icons.favorite : Icons.favorite_border),
                      ),
                      Text(post.likesCount.toString()),
                    ]),
                  ]),
                )),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 14, 4, 8),
                  child: Text('Comments', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db.commentsStream(widget.id),
                  builder: (context, comments) {
                    if (comments.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final docs = comments.data?.docs ?? [];
                    if (docs.isEmpty) return const Text('No comments yet.');
                    return Column(children: docs.map((doc) {
                      final data = doc.data();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text((data['authorName'] ?? 'Student').toString()),
                        subtitle: Text((data['text'] ?? '').toString()),
                      );
                    }).toList());
                  },
                ),
              ]),
            ),
            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _comment, enabled: user != null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _addComment(user),
                  decoration: const InputDecoration(hintText: 'Write a comment...'),
                )),
                IconButton(onPressed: user == null ? null : () => _addComment(user), icon: const Icon(Icons.send)),
              ]),
            )),
          ]);
        },
      ),
    );
  }

  Future<void> _addComment(User? user) async {
    final text = _comment.text.trim();
    if (user == null || text.isEmpty) return;
    final name = user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : (user.email ?? 'Student');
    try {
      await _db.addComment(postId: widget.id, text: text, authorId: user.uid, authorName: name);
      _comment.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not add comment.')));
    }
  }
}
