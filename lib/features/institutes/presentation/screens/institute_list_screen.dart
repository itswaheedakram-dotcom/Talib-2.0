import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class InstituteListScreen extends StatelessWidget {
  final String type;
  const InstituteListScreen({super.key,required this.type});
  @override
  Widget build(BuildContext context) {
    final title = type[0].toUpperCase() + type.substring(1);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(20), itemCount: 6,
        separatorBuilder: (_,__) => const SizedBox(height: 10),
        itemBuilder: (_,i) => Card(child: ListTile(
          leading: CircleAvatar(child: Text((i+1).toString())),
          title: Text(title + ' Institute ' + (i+1).toString()),
          subtitle: const Text('Institute details and programs'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/institute/' + type + '-' + i.toString()),
        )),
      ),
    );
  }
}
