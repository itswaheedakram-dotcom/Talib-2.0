/// Shared validation and user-facing auth errors for both account forms.
abstract final class AuthFormRules {
  static String? email(String? input) {
    final value = (input ?? '').trim();
    if (value.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) return 'Enter a valid email address.';
    return null;
  }
  static String? name(String? input) {
    final value = (input ?? '').trim();
    return value.isEmpty || value.length > 80 ? 'Enter your name (1–80 characters).' : null;
  }
  static String? password(String? input, {bool registering = false}) {
    if (input == null || input.isEmpty) return 'Enter your password.';
    if (registering && input.length < 8) return 'Use at least 8 characters.';
    return null;
  }
  static String error(String code) => switch (code) {
    'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Incorrect email or password.',
    'invalid-email' => 'Enter a valid email address.',
    'email-already-in-use' => 'This email already has an account. Sign in or reset your password.',
    'weak-password' => 'Choose a stronger password with at least 8 characters.',
    'user-disabled' => 'This account is disabled. Please contact support.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'Check your internet connection and try again.',
    'operation-not-allowed' => 'This sign-in method is unavailable. Please try later.',
    _ => 'Could not complete this action. Please try again.',
  };
}
