import 'package:flutter/material.dart';
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Search')),
    body: Padding(padding: const EdgeInsets.all(20),child: Column(children: [
      const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search),hintText: 'Search institutes, courses, jobs...')),
      const SizedBox(height: 24),
      Icon(Icons.manage_search,size: 64,color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 12),
      const Text('Search results will appear here.'),
    ])),
  );
}
