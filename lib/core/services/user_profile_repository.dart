import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import 'active_profile_controller.dart';
import 'demo_data_service.dart';
import 'firebase_service.dart';
import '../../features/institutes/data/student_affiliation_repository.dart';

/// One profile source for editing, display and analytics; demo and live share the schema.
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

  Future<void> save(UserProfile profile) async {
    if (profile.uid != currentUid) throw StateError('You can edit only your own profile.');
    if (profile.name.trim().isEmpty || profile.name.length > 80) throw ArgumentError('Enter a name of 1–80 characters.');
    if (profile.bio.length > 300) throw ArgumentError('Keep your bio within 300 characters.');
    if (isDemo(profile.uid)) {
      _demo[profile.uid] = {...?_demo[profile.uid], ...profile.editableFields};
      ActiveProfileController.instance.updateProfile(name: profile.name, city: profile.city);
      notifyListeners(); return;
    }
    // Only personal fields are editable here. University/course use the affiliation transaction.
    final user = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    batch.set(db.collection('users').doc(profile.uid).collection('private').doc('account'), {'email': user.email ?? ''}, SetOptions(merge: true));
    batch.set(db.collection('users').doc(profile.uid), {
      ...profile.editableFields, ProfileFields.uid: profile.uid, 'email': FieldValue.delete(),
      ProfileFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    await user.updateDisplayName(profile.name);
  }

  Future<String?> pickPhoto(String uid) async {
    if (uid != currentUid) throw StateError('You can edit only your own photo.');
    final photo = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800, maxHeight: 800);
    if (photo == null) return null;
    final bytes = await photo.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) throw ArgumentError('Choose a photo smaller than 5 MB.');
    if (isDemo(uid)) return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final ref = FirebaseStorage.instance.ref('profiles/$uid/${DateTime.now().microsecondsSinceEpoch}.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return 'storage:${ref.fullPath}';
  }
}
