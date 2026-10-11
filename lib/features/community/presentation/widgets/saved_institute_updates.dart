import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';

class SavedInstituteUpdates extends StatelessWidget {
  final String uid;
  const SavedInstituteUpdates({super.key, required this.uid});
  String version(Map<String,dynamic> data) => jsonEncode(data,
      toEncodable: (value) => value is Timestamp
          ? value.millisecondsSinceEpoch : value.toString());
  @override Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
    stream: FirebaseFirestore.instance.collection('users').doc(uid)
        .collection('instituteBookmarks').snapshots(),
    builder: (context, saved) {
      if (saved.hasError) return const ListTile(title: Text('Could not load saved institute updates.'));
      if (!saved.hasData) return const LinearProgressIndicator();
      if (saved.data!.docs.isEmpty) return const SizedBox.shrink();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const ListTile(title: Text('Saved institute updates', style: TextStyle(fontWeight: FontWeight.w700))),
        ...saved.data!.docs.map((bookmark) {
          final institute = FirebaseFirestore.instance.collection('institutes').doc(bookmark.id);
          final seen = Map<String,dynamic>.from(bookmark.data()['seenOpportunityUpdates'] as Map? ?? {});
          return StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
            stream: institute.collection('opportunities').where('published', isEqualTo: true).snapshots(),
            builder: (context, updates) {
              if (updates.hasError) return const ListTile(title: Text('Could not load institute updates.'));
              if (!updates.hasData) return const LinearProgressIndicator();
              final docs = updates.data!.docs.toList()..sort((a,b) {
                int time(Map<String,dynamic> d) => ((d['updatedAt'] ?? d['createdAt']) as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                return time(b.data()).compareTo(time(a.data()));
              });
              if (docs.isEmpty) return const SizedBox.shrink();
              return FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(
                future: institute.get(),
                builder: (context, details) => Column(children: docs.map((doc) {
                  final data = doc.data();
                  final key = version(data);
                  final read = seen[doc.id] == key;
                  final name = details.data?.data()?['name']?.toString() ?? 'Saved institute';
                  final kind = data['kind'] == 'scholarship' ? 'Scholarship'
                      : data['kind'] == 'course' ? 'Course / program' : 'Admission';
                  return Card(color: read ? null : AppPalette.of(context).softSurface,
                    child: ListTile(
                      leading: Icon(Icons.account_balance_outlined, color: AppPalette.of(context).accent),
                      title: Text(data['title']?.toString() ?? kind,
                          style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.w700)),
                      subtitle: Text('$name • $kind • ${read ? "Read" : "New update"}'),
                      onTap: () async {
                        try {
                          await bookmark.reference.update({
                            'seenOpportunityUpdates.${doc.id}': key,
                          });
                        } catch (_) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not mark update as read.')));
                        }
                        if (context.mounted) context.push('/institute/${bookmark.id}/opportunities');
                      },
                    ));
                }).toList()),
              );
            },
          );
        }),
      ]);
    },
  );
}
