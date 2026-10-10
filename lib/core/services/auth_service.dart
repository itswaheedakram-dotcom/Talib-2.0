import '../models/user_profile.dart';
import '../models/username_rules.dart';
import 'active_profile_controller.dart';
import 'auth_form_rules.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSetupIncomplete implements Exception {
  const AccountSetupIncomplete();
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    try { await _ensureProfile(result.user!); }
    catch (_) { await _auth.signOut(); throw const AccountSetupIncomplete(); }
    ActiveProfileController.instance.clear();
    return result;
  }

  Future<void> _ensureProfile(User user, {String? name, String role = 'student'}) async {
    final ref = _db.collection('users').doc(user.uid);
    await UsernameRules.assign(name ?? user.displayName ?? 'Student', (candidate) async {
      return _db.runTransaction<bool>((transaction) async {
        final existing = await transaction.get(ref);
        final previous = (existing.data()?[ProfileFields.username] ?? '').toString();
        final needsUsername = previous.isEmpty;
        final claimRef = _db.collection('usernames').doc(candidate);
        if (needsUsername) {
          final claim = await transaction.get(claimRef);
          if (claim.exists && claim.data()?[ProfileFields.uid] != user.uid) return false;
        }
        final values = <String, dynamic>{
          ProfileFields.uid: user.uid, 'email': FieldValue.delete(),
          if (!existing.exists) ...{
            ProfileFields.name: name ?? user.displayName ?? 'Student',
            ProfileFields.role: role, 'createdAt': FieldValue.serverTimestamp(),
          },
          ProfileFields.updatedAt: FieldValue.serverTimestamp(),
        };
        if (needsUsername) {
          values[ProfileFields.username] = candidate;
          transaction.set(claimRef, {ProfileFields.uid: user.uid});
        }
        transaction.set(ref, values, SetOptions(merge: true));
        transaction.set(ref.collection('private').doc('account'), {'email': user.email ?? ''}, SetOptions(merge: true));
        return true;
      });
    });
  }

  Future<UserCredential> register(
    String email,
    String password, {
    required String name,
    String role = 'student',
  }) async {
    if (AuthFormRules.name(name) != null || AuthFormRules.email(email) != null || AuthFormRules.password(password, registering: true) != null) {
      throw ArgumentError('Invalid registration details.');
    }
    if (!['student', 'institute'].contains(role)) throw ArgumentError('Invalid account type.');
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Account could not be created.',
      );
    }

    try {
      await user.updateDisplayName(name.trim());
      await _ensureProfile(user, name: name.trim(), role: role);
    } catch (_) {
      await _auth.signOut();
      throw const AccountSetupIncomplete();
    }
    ActiveProfileController.instance.clear();
    return result;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in account found.',
      );
    }
    final email = user.email;
    if (email == null || email.trim().isEmpty) {
      throw FirebaseAuthException(
        code: 'password-not-supported',
        message: 'Password change is not available for this account.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    ActiveProfileController.instance.clear();
  }
}
