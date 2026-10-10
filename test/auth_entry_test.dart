import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/core/services/auth_form_rules.dart';
import 'package:talib_2/core/services/firebase_service.dart';
import 'package:talib_2/features/auth/presentation/screens/auth_entry_screen.dart';

Finder field(String label) => find.byWidgetPredicate((widget) => widget is TextFormField && widget.decoration?.labelText == label);
void main() {
  setUp(() => FirebaseService.initialized = false);
  test('shared validation protects registration without rejecting existing sign-in passwords', () {
    expect(AuthFormRules.email('broken@'), isNotNull);
    expect(AuthFormRules.email('  user@example.com  '), isNull);
    expect(AuthFormRules.name('   '), isNotNull);
    expect(AuthFormRules.password('old123'), isNull);
    expect(AuthFormRules.password('old123', registering: true), isNotNull);
    expect(AuthFormRules.error('email-already-in-use'), contains('Sign in or reset'));
  });
  testWidgets('sign-up validates confirmation and does not expose fake social sign-in', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthEntryScreen(registering: true)));
    await tester.enterText(field('Full name'), 'Student');
    await tester.enterText(field('Email'), 'student@example.com');
    await tester.enterText(field('Password'), 'strong-password');
    await tester.ensureVisible(field('Confirm password'));
    await tester.enterText(field('Confirm password'), 'different-password');
    final submit = find.byType(FilledButton);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(find.byIcon(Icons.facebook), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reset validates email without Firebase and ignores empty password', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthEntryScreen(registering: false)));
    await tester.enterText(field('Email'), 'bad-email');
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsNothing);
    await tester.enterText(field('Email'), 'valid@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    expect(find.text('Account services are not available yet. You can continue browsing.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
