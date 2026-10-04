import 'package:flutter/material.dart';
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override State<CreatePostScreen> createState() => _CreatePostScreenState();
}
class _CreatePostScreenState extends State<CreatePostScreen> {
  final controller = TextEditingController();
  @override void dispose(){controller.dispose();super.dispose();}
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Post')),
    body: Padding(padding: const EdgeInsets.all(20),child: Column(children: [
      TextField(controller: controller,maxLines: 7,decoration: const InputDecoration(hintText: 'What do you want to share?')),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity,child: FilledButton(onPressed: () => Navigator.pop(context),child: const Text('Publish'))),
    ])),
  );
}
