import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';
import 'active_profile_controller.dart';

enum TalibAdminRole { none, managerAdmin, superAdmin, demoSuperAdmin }

class AdminAccessService extends ChangeNotifier {
  AdminAccessService._();
  static final AdminAccessService instance = AdminAccessService._();

  StreamSubscription<User?>? _authSubscription;
  TalibAdminRole _role = TalibAdminRole.none;
  Map<String, dynamic> _permissions = const {};
  bool _loading = false;
  String? _uid;

  TalibAdminRole get role => _role;
  bool get isSuperAdmin => _role == TalibAdminRole.superAdmin;
  bool get isDemoSuperAdmin => _role == TalibAdminRole.demoSuperAdmin;
  bool get isManagerAdmin => _role == TalibAdminRole.managerAdmin;
  bool get canOpenPanel => _role != TalibAdminRole.none;
  bool get isLoading => _loading;
  Map<String, dynamic> get permissions => Map.unmodifiable(_permissions);

  bool can(String permission) =>
      isSuperAdmin || (_role == TalibAdminRole.managerAdmin && _permissions[permission] == true);

  void start() {
    ActiveProfileController.instance.removeListener(_onActiveProfileChanged);
    ActiveProfileController.instance.addListener(_onActiveProfileChanged);
    if (ActiveProfileController.instance.active?.id == 'demo-user-6') {
      _setRole(TalibAdminRole.demoSuperAdmin, const {}, 'demo-user-6');
      _loading = false;
      notifyListeners();
      return;
    }
    if (!FirebaseService.initialized) {
      _setRole(TalibAdminRole.none, const {}, null);
      return;
    }
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      refresh(user: user);
    });
    refresh();
  }

  void _onActiveProfileChanged() => refresh();

  Future<void> refresh({User? user}) async {
    final activeProfile = ActiveProfileController.instance.active;
    if (activeProfile?.id == 'demo-user-6') {
      _setRole(TalibAdminRole.demoSuperAdmin, const {}, activeProfile!.id);
      _loading = false;
      notifyListeners();
      return;
    }
    if (!FirebaseService.initialized) {
      _setRole(TalibAdminRole.none, const {}, null);
      return;
    }
    final current = user ?? FirebaseAuth.instance.currentUser;
    if (current == null || current.isAnonymous) {
      _setRole(TalibAdminRole.none, const {}, current?.uid);
      return;
    }

    _loading = true;
    notifyListeners();
    try {
      final token = await current.getIdTokenResult();
      final claims = token.claims ?? const <String, dynamic>{};
      if (claims['admin'] == true) {
        _setRole(TalibAdminRole.superAdmin, const {}, current.uid);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('adminRoles')
          .doc(current.uid)
          .get();
      final data = snapshot.data();
      if (snapshot.exists && data?['status'] == 'active' && data?['role'] == 'manager_admin') {
        final raw = data?['permissions'];
        _setRole(
          TalibAdminRole.managerAdmin,
          raw is Map ? Map<String, dynamic>.from(raw) : const {},
          current.uid,
        );
      } else {
        _setRole(TalibAdminRole.none, const {}, current.uid);
      }
    } catch (_) {
      _setRole(TalibAdminRole.none, const {}, current.uid);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _setRole(TalibAdminRole role, Map<String, dynamic> permissions, String? uid) {
    _role = role;
    _permissions = permissions;
    _uid = uid;
    notifyListeners();
  }

  Future<void> assignManager({
    required String uid,
    required Map<String, bool> permissions,
  }) async {
    if (!isSuperAdmin) {
      throw StateError('Only the Super Admin can create Manager Admin access.');
    }
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) throw ArgumentError('Enter the manager user UID.');
    await FirebaseFirestore.instance.collection('adminRoles').doc(cleanUid).set({
      'uid': cleanUid,
      'role': 'manager_admin',
      'status': 'active',
      'permissions': permissions,
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setManagerStatus(String uid, String status) async {
    if (!isSuperAdmin) throw StateError('Only the Super Admin can change manager access.');
    if (!{'active', 'suspended', 'revoked'}.contains(status)) {
      throw ArgumentError('Invalid manager status.');
    }
    await FirebaseFirestore.instance.collection('adminRoles').doc(uid).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> managers() async {
    if (!isSuperAdmin) throw StateError('Only the Super Admin can view all managers.');
    final result = await FirebaseFirestore.instance
        .collection('adminRoles')
        .where('role', isEqualTo: 'manager_admin')
        .get();
    return result.docs;
  }

  @override
  void dispose() {
    ActiveProfileController.instance.removeListener(_onActiveProfileChanged);
    _authSubscription?.cancel();
    super.dispose();
  }
}
