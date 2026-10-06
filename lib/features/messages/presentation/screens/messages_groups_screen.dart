import 'package:flutter/material.dart';
import 'messages_screen.dart';
import '../../../groups/presentation/screens/groups_screen.dart';

class MessagesGroupsScreen extends StatelessWidget {
  const MessagesGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages & Groups'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.chat_bubble_outline_rounded), text: 'Messages'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Groups'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MessagesScreen(),
            GroupsScreen(),
          ],
        ),
      ),
    );
  }
}
