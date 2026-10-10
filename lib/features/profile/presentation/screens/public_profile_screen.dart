import 'package:flutter/material.dart';
import '../widgets/profile_view.dart';

class PublicProfileScreen extends StatelessWidget {
  final String id;
  const PublicProfileScreen({super.key, required this.id});
  @override Widget build(BuildContext context) => ProfileView(uid: id, publicView: true);
}
