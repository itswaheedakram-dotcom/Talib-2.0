import '../../../../core/widgets/user_identity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';

class TemporaryProfilesScreen extends StatelessWidget {
  const TemporaryProfilesScreen({super.key});

  static const profiles = temporaryProfiles;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Temporary Profiles')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.science_outlined, color: AppColors.primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Temporary verified profiles for testing. These demo profiles are app-side only and can be removed when real profiles are added.',
                    style: const TextStyle(color: AppColors.mutedText),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...profiles.map(
          (p) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: AppColors.softGreen,
                child: Text(
                  p.name.substring(0, 1),
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: UserIdentity(uid: p.id, name: p.name),
              subtitle: Text('${p.level}\n${p.city}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/profile/${p.id}'),
            ),
          ),
        ),
      ],
    ),
  );
}