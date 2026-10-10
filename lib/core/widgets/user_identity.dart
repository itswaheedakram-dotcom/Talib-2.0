import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/user_profile_repository.dart';
import '../services/firebase_service.dart';
import '../services/active_profile_controller.dart';

/// Every visible actor uses their actual immutable UID, never a display name as an id.
class UserIdentity extends StatelessWidget {
  final String uid, name;
  final Color? color;
  final bool resolveName;
  const UserIdentity({super.key, required this.uid, required this.name, this.color, this.resolveName = true});
  @override Widget build(BuildContext context) {
    Widget content(String display, [String photoUrl = '']) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      ProfileAvatar(name: display, photoUrl: photoUrl, radius: 18),
      const SizedBox(width: 8),
      Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(display.isEmpty ? 'Student' : display, softWrap: true,
        style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      if (uid.isNotEmpty) UserIdLabel(uid: uid, color: color),
    ])),
    ]);
    if (!resolveName || uid.isEmpty || (!FirebaseService.initialized && !temporaryProfiles.any((p) => p.id == uid))) return content(name);
    return StreamBuilder(stream: UserProfileRepository.instance.watch(uid),
      builder: (context, snapshot) => content(snapshot.data?.name ?? name, snapshot.data?.photoUrl ?? ''));
  }
}

class UserIdLabel extends StatelessWidget {
  final String uid;
  final Color? color;
  const UserIdLabel({super.key, required this.uid, this.color});
  @override Widget build(BuildContext context) => Semantics(label: 'User ID $uid. Tap to copy.',
    button: true, child: InkWell(onTap: () async {
      await Clipboard.setData(ClipboardData(text: uid));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User ID copied')));
    }, child: Padding(padding: const EdgeInsets.only(top: 3, bottom: 3),
      child: Text('UID: $uid', softWrap: true, style: TextStyle(fontSize: 12,
        color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(.75))))));
}

class ProfileAvatar extends StatelessWidget {
  final String name, photoUrl;
  final double radius;
  const ProfileAvatar({super.key, required this.name, this.photoUrl = '', this.radius = 36});
  @override Widget build(BuildContext context) {
    if (photoUrl.startsWith('storage:')) {
      return FutureBuilder<Uint8List?>(future: FirebaseStorage.instance.ref(photoUrl.substring(8)).getData(5 * 1024 * 1024),
        builder: (_, s) => CircleAvatar(radius: radius, foregroundImage: s.data == null ? null : MemoryImage(s.data!),
          child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: TextStyle(fontSize: radius * .7))));
    }
    ImageProvider? image;
    if (photoUrl.startsWith('data:image/')) {
      try { image = MemoryImage(base64Decode(photoUrl.split(',').last)); } catch (_) {}
    } else if (photoUrl.startsWith('https://')) { image = NetworkImage(photoUrl); }
    return CircleAvatar(radius: radius, backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundImage: image, onForegroundImageError: image == null ? null : (_, __) {},
      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: TextStyle(fontSize: radius * .7)));
  }
}
