import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Community')),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/community/create'),icon: const Icon(Icons.add),label: const Text('Post')),
    body: ListView.separated(
      padding: const EdgeInsets.all(20),itemCount: 5,
      separatorBuilder: (_,__) => const SizedBox(height: 12),
      itemBuilder: (_,i) => Card(child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(child: Text((i+1).toString())),
        title: Text('Welcome to Talib Community ' + (i+1).toString()),
        subtitle: const Text('Students can discuss education, institutes and opportunities here.'),
        onTap: () => context.push('/community/post/' + i.toString()),
      )),
    ),
  );
}
