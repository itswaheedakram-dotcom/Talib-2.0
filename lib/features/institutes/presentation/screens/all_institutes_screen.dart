import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class AllInstitutesScreen extends StatelessWidget {
  const AllInstitutesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('All Institutes')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      _tile(context,'Schools',Icons.school_outlined,'/institutes/schools'),
      _tile(context,'Colleges',Icons.account_balance_outlined,'/institutes/colleges'),
      _tile(context,'Universities',Icons.castle_outlined,'/institutes/universities'),
    ]),
  );
}
Widget _tile(BuildContext c,String title,IconData icon,String route) => Card(
  child: ListTile(leading: Icon(icon),title: Text(title),trailing: const Icon(Icons.chevron_right),onTap: () => c.push(route)),
);
