import 'dart:async';

class AppUser {
  final String uid;
  final String email;
  String? displayName;
  AppUser({required this.uid, required this.email, this.displayName});
}

class AuthService {
  static AppUser? _currentUser;
  static final StreamController<AppUser?> _controller = StreamController<AppUser?>.broadcast();
  Stream<AppUser?> get authStateChanges => _controller.stream;
  AppUser? get currentUser => _currentUser;

  Future<AppUser> signIn(String email, String password) async {
    final value = email.trim();
    if (value.isEmpty || password.isEmpty) throw Exception('Enter your email and password.');
    final user = AppUser(uid: 'local-${value.toLowerCase()}', email: value, displayName: value.split('@').first);
    _currentUser = user; _controller.add(user); return user;
  }

  Future<AppUser> register(String email, String password, {required String name, String role = 'student'}) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.length < 6) throw Exception('Enter valid account details.');
    final user = AppUser(uid: 'local-${email.trim().toLowerCase()}', email: email.trim(), displayName: name.trim());
    _currentUser = user; _controller.add(user); return user;
  }

  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) throw Exception('Enter your email first.');
  }

  Future<AppUser> signInAnonymously() async {
    final user = AppUser(uid: 'guest-local', email: '', displayName: 'Guest');
    _currentUser = user; _controller.add(user); return user;
  }

  Future<void> signOut() async { _currentUser = null; _controller.add(null); }
}
