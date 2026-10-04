import 'package:flutter/material.dart';
class EmptyFeatureScreen extends StatelessWidget {
  final String title;
  const EmptyFeatureScreen({super.key,required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min,children: [
      const Icon(Icons.construction_outlined,size: 64),
      const SizedBox(height: 12),
      Text(title + ' module is ready for implementation.'),
    ])),
  );
}
