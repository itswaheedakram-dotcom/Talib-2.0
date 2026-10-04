import 'package:flutter/material.dart';
class PostCommentsScreen extends StatelessWidget {
  final String id;
  const PostCommentsScreen({super.key,required this.id});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Post')),
    body: ListView(padding: const EdgeInsets.all(20),children: [
      Card(child: Padding(padding: const EdgeInsets.all(18),child: Text('Community post ' + id,style: Theme.of(context).textTheme.titleLarge))),
      const SizedBox(height: 18),
      const Text('Comments',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold)),
      const ListTile(leading: CircleAvatar(child: Icon(Icons.person)),title: Text('Student'),subtitle: Text('This is a sample comment.')),
    ]),
  );
}
