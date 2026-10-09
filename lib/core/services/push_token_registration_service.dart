import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'active_profile_controller.dart';
import 'admin_access_service.dart';
import 'firebase_service.dart';

class PushTokenRegistrationService {
  PushTokenRegistrationService._();
  static final instance = PushTokenRegistrationService._();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    ActiveProfileController.instance.addListener(_sync);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) => _sync());
    _sync();
  }

  Future<void> _sync() async {
    if (!FirebaseService.initialized || ActiveProfileController.instance.isDemo) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      await AdminAccessService.instance.refresh(user:user);
      final settings = await FirebaseMessaging.instance.requestPermission(alert:true,badge:true,sound:true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _save(user.uid, token);
      _tokenSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if (!ActiveProfileController.instance.isDemo && FirebaseAuth.instance.currentUser?.uid == user.uid) {
          _save(user.uid, token);
        }
      });
    } catch (_) {
      // Push registration is optional; report submission and in-app ticket history still work.
    }
  }

  Future<void> _save(String uid, String token) async {
    final access = AdminAccessService.instance;
    final adminRecipient = access.isSuperAdmin || access.can('manage_reports');
    await FirebaseFirestore.instance.collection('pushTokens').doc(uid).set({
      'uid':uid,
      'tokens':FieldValue.arrayUnion([token]),
      'adminRecipient':adminRecipient,
      'updatedAt':FieldValue.serverTimestamp(),
    }, SetOptions(merge:true));
  }
}
