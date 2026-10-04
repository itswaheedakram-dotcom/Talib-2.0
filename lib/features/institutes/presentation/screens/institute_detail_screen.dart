import 'package:flutter/material.dart';
class InstituteDetailScreen extends StatelessWidget {
  final String id;
  const InstituteDetailScreen({super.key,required this.id});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Institute Detail')),
    body: Padding(padding: const EdgeInsets.all(20),child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      Card(child: Padding(padding: const EdgeInsets.all(22),child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
        const CircleAvatar(radius: 34,child: Icon(Icons.school)),
        const SizedBox(height: 16),
        Text('Institute ' + id.replaceAll('-', ' '),style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Programs, admission information, location and other useful details will appear here.'),
      ]))),
      const SizedBox(height: 14),
      const ListTile(leading: Icon(Icons.location_on_outlined),title: Text('Location'),subtitle: Text('Pakistan')),
      const ListTile(leading: Icon(Icons.menu_book_outlined),title: Text('Programs'),subtitle: Text('Programs will be loaded from Firebase')),
    ])),
  );
}
