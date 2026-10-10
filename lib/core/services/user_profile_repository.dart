import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_photo_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../models/username_rules.dart';
import 'active_profile_controller.dart';
import 'demo_data_service.dart';
import 'firebase_service.dart';
import '../../features/institutes/data/student_affiliation_repository.dart';

/// One profile source for editing, display and analytics; demo and live share the schema.
class UsernameTaken implements Exception {
  final String username;
  const UsernameTaken(this.username);
}

class UserProfileRepository extends ChangeNotifier {
  UserProfileRepository._() {
    ActiveProfileController.instance.addListener(notifyListeners);
    StudentAffiliationRepository.instance.addListener(notifyListeners);
    DemoDataService.instance.changes.listen((_) => notifyListeners());
  }
  static final instance = UserProfileRepository._();
  final Map<String, Map<String, dynamic>> _demo = {};
  bool isDemo(String uid) => uid.startsWith('demo-user-');
  String? get currentUid => ActiveProfileController.instance.effectiveUid ??
      (FirebaseService.initialized ? FirebaseAuth.instance.currentUser?.uid : null);

  UserProfile demoProfile(String uid) {
    final identity = ActiveProfileController.instance.profileById(uid);
    return UserProfile.fromMap(uid, {
      ProfileFields.username: identity.name.split(' ').first.toLowerCase(),
      ProfileFields.name: identity.name, ProfileFields.city: identity.city,
      ProfileFields.educationLevel: identity.level,
      ProfileFields.role: uid == 'demo-user-6' ? 'community' : 'student',
      ProfileFields.course: identity.program, ProfileFields.instituteName: identity.institute,
      ...?_demo[uid], ...StudentAffiliationRepository.instance.demoProfileData(uid), ...DemoDataService.instance.settings(uid),
    });
  }

  Stream<UserProfile> watch(String uid) {
    if (isDemo(uid)) {
      return Stream.multi((controller) {
        void emit() => controller.add(demoProfile(uid));
        emit(); addListener(emit);
        controller.onCancel = () => removeListener(emit);
      });
    }
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) throw StateError('This profile is not available.');
      return UserProfile.fromMap(uid, doc.data() ?? {});
    });
  }

  static String normalizeUsername(String value) => UsernameRules.normalize(value);
  static bool validUsername(String value) => UsernameRules.valid(value);
  Future<bool> usernameAvailable(String value) async {
    final username = normalizeUsername(value);
    if (!validUsername(username)) return false;
    final uid = currentUid;
    if (uid == null) throw StateError('Sign in first.');
    if (isDemo(uid)) {
      return !temporaryProfiles.any((p) => p.id != uid && demoProfile(p.id).username == username);
    }
    final claim = await FirebaseFirestore.instance.collection('usernames').doc(username).get();
    return !claim.exists || claim.data()?[ProfileFields.uid] == uid;
  }
  Future<List<String>> usernameSuggestions(String value) async {
    var base = normalizeUsername(value).replaceAll(RegExp('[^a-z0-9_]'), '');
    if (base.isEmpty || !RegExp('^[a-z]').hasMatch(base)) base = 'student$base';
    if (base.length > 18) base = base.substring(0, 18);
    final candidates = [for (final suffix in ['_1', '_2', '_pk', '01', '24', '99']) '$base$suffix'];
    final result = <String>[];
    for (final candidate in candidates) {
      if (await usernameAvailable(candidate)) result.add(candidate);
      if (result.length == 3) break;
    }
    return result;
  }

  Future<void> save(UserProfile profile) async {
    if (profile.uid != currentUid) throw StateError('You can edit only your own profile.');
    if (profile.name.trim().isEmpty || profile.name.length > 80) throw ArgumentError('Enter a name of 1–80 characters.');
    final username = normalizeUsername(profile.username);
    if (!validUsername(username)) throw ArgumentError('Use 3–24 lowercase letters, numbers or underscores; start with a letter.');
    if (profile.bio.length > 300) throw ArgumentError('Keep your bio within 300 characters.');
    if (isDemo(profile.uid)) {
      if (temporaryProfiles.any((p) => p.id != profile.uid && demoProfile(p.id).username == username)) throw UsernameTaken(username);
      _demo[profile.uid] = {...?_demo[profile.uid], ...profile.editableFields, ProfileFields.username: username};
      ActiveProfileController.instance.updateProfile(name: profile.name, city: profile.city, level: ActiveProfileController.instance.profileById(profile.uid).level);
      notifyListeners(); return;
    }
    // Only personal fields are editable here. University/course use the affiliation transaction.
    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;
    final profileRef = db.collection('users').doc(profile.uid);
    final claimRef = db.collection('usernames').doc(username);
    await db.runTransaction((transaction) async {
      final existing = await transaction.get(profileRef);
      final claim = await transaction.get(claimRef);
      if (claim.exists && claim.data()?[ProfileFields.uid] != profile.uid) throw UsernameTaken(username);
      final previous = (existing.data()?[ProfileFields.username] ?? '').toString();
      if (previous.isNotEmpty && previous != username) {
        transaction.delete(db.collection('usernames').doc(previous));
      }
      transaction.set(claimRef, {ProfileFields.uid: profile.uid});
      transaction.set(profileRef.collection('private').doc('account'), {'email': user.email ?? ''}, SetOptions(merge: true));
      transaction.set(profileRef, {
        ...profile.editableFields, ProfileFields.username: username,
        ProfileFields.uid: profile.uid, 'email': FieldValue.delete(),
        ProfileFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    await user.updateDisplayName(profile.name);
  }

  Future<String?> pickPhoto(String uid) async {
    if (uid != currentUid) throw StateError('You can edit only your own photo.');
    final photo = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800, maxHeight: 800);
    if (photo == null) return null;
    final bytes = await photo.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) throw ArgumentError('Choose a photo smaller than 5 MB.');
    if (isDemo(uid)) return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    return ProfilePhotoStorage.upload(uid, bytes);
  }
}
