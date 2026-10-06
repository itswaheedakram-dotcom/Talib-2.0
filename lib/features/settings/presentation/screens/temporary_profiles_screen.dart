import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';

class TemporaryProfilesScreen extends StatelessWidget {
  const TemporaryProfilesScreen({super.key});

  static const profiles = <Map<String, String>>[
    {'id':'demo-user-1','name':'Ayesha Khan','city':'Lahore, Punjab','level':'BS Computer Science','institute':'University of the Punjab','program':'Computer Science'},
    {'id':'demo-user-2','name':'Ali Raza','city':'Multan, Punjab','level':'BS Software Engineering','institute':'BZU Multan','program':'Software Engineering'},
    {'id':'demo-user-3','name':'Hira Ahmed','city':'Islamabad','level':'MS Education','institute':'NUST Islamabad','program':'Education'},
    {'id':'demo-user-4','name':'Usman Malik','city':'Faisalabad, Punjab','level':'BS Business Administration','institute':'University of Agriculture Faisalabad','program':'Business Administration'},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Temporary Profiles')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.science_outlined, color: AppColors.primaryGreen),
          const SizedBox(width: 10),
          Expanded(child: Text('Temporary verified profiles for testing. These demo profiles are app-side only and can be removed when real profiles are added.', style: TextStyle(color: AppColors.mutedText))),
        ]))),
        const SizedBox(height: 10),
        ...profiles.map((p) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(backgroundColor: AppColors.softGreen, child: Text(p['name']![0], style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700))),
            title: Row(children: [Expanded(child: Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.w700))), const Icon(Icons.verified, size: 19, color: AppColors.primaryGreen)]),
            subtitle: Text('${p['level']}\n${p['city']}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/profile/${p['id']}'),
          ),
        )),
      ],
    ),
  );
}