import 'package:flutter/material.dart';
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bookmarks')),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min,children: [
      Icon(Icons.bookmark_border,size: 70,color: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 12),
      const Text('Your saved items will appear here.'),
    ])),
  );
}
