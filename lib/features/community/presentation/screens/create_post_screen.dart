import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  final _db = DatabaseService();
  bool _saving = false;

  @override void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _publish() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _controller.text.trim();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write something before publishing.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final name = user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : (user.email ?? 'Student');
      await _db.createPost(text: text, authorId: user.uid, authorName: name);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not publish the post.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override Widget build(BuildContext context) {
    const green = Color(0xFF00A66A);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
        title: const Text('Create post'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _publish,
            child: Text(_saving ? '...' : 'Post', style: const TextStyle(color: green, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(14, 10, 14, 10), children: [
          Row(children: [
            const CircleAvatar(radius: 21, backgroundColor: Color(0xFFEAF8F2), child: Icon(Icons.person, color: green)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Your profile', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('@student', style: TextStyle(color: Colors.black54, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 8,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'What do you want to share?', border: InputBorder.none),
          ),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 50, color: green)),
          ),
        ])),
        SafeArea(child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: Row(children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined, color: green)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.image_outlined, color: green)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.location_on_outlined, color: green)),
            const Spacer(),
            Text(_controller.text.length.toString() + '/1000', style: const TextStyle(color: Colors.black45)),
          ]),
        )),
      ]),
    );
  }
}
