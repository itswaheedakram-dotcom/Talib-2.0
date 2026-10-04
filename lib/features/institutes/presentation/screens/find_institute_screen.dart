import 'package:flutter/material.dart';
class FindInstituteScreen extends StatelessWidget {
  const FindInstituteScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Find Institute')),
    body: Padding(padding: const EdgeInsets.all(20),child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
      Text('Find the right institute',style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Filter institutes by city, type, program and other criteria.'),
      const SizedBox(height: 20),
      const TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search),hintText: 'Search by institute or city')),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: () {},icon: const Icon(Icons.filter_list),label: const Text('Apply filters')),
    ])),
  );
}
