import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  @override Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const green = Color(0xFF00A66A);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
        title: const Text('Comments'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('posts').doc(widget.id).snapshots(),
        builder: (context, postSnapshot) {
          if (postSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!postSnapshot.hasData || !postSnapshot.data!.exists) return const Center(child: Text('Post not found.'));
          final post = Post.fromDoc(postSnapshot.data!);
          return Column(children: [
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
              children: [
                Row(children: [
                  const CircleAvatar(radius: 21, backgroundColor: Color(0xFFEAF8F2), child: Icon(Icons.person, color: green)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Text('Student / Community member', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ])),
                  IconButton(onPressed: user == null ? null : () => _db.toggleLike(post, user.uid), icon: Icon(post.likedByUser(user?.uid) ? Icons.thumb_up : Icons.thumb_up_outlined, color: green)),
                ]),
                const SizedBox(height: 10),
                Text(post.text, style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 14),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 8),
                const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db.commentsStream(widget.id),
                  builder: (context, comments) {
                    if (comments.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final docs = comments.data?.docs ?? [];
                    if (docs.isEmpty) return const Padding(padding: EdgeInsets.only(top: 15), child: Text('No comments yet.'));
                    return Column(children: docs.map((doc) {
                      final data = doc.data();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(radius: 18, backgroundColor: Color(0xFFEAF8F2), child: Icon(Icons.person, size: 19, color: green)),
                        title: Text((data['authorName'] ?? 'Student').toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Padding(padding: const EdgeInsets.only(top: 3), child: Text((data['text'] ?? '').toString())),
                      );
                    }).toList());
                  },
                ),
              ],
            )),
            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: _comment,
                  enabled: user != null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _addComment(user),
                  decoration: InputDecoration(
                    hintText: user == null ? 'Sign in to comment' : 'Write a comment...',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                )),
                const SizedBox(width: 6),
                IconButton(onPressed: user == null ? null : () => _addComment(user), icon: const Icon(Icons.send, color: green)),
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
