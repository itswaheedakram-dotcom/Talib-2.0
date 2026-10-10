import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/user_profile_repository.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../widgets/profile_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: ActiveProfileController.instance, builder: (_, __) {
    final uid = UserProfileRepository.instance.currentUid;
    if (uid != null) return ProfileView(key: ValueKey(uid), uid: uid);
    return Scaffold(appBar: AppBar(title: const Text('Profile')), body: Center(child: FilledButton(
      onPressed: () => context.push('/signin'), child: const Text('Sign in to view your profile'))));
  });
}
