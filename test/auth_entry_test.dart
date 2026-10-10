import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/core/services/auth_form_rules.dart';
import 'package:talib_2/core/models/username_rules.dart';
import 'package:talib_2/core/services/firebase_service.dart';
import 'package:talib_2/features/auth/presentation/screens/auth_entry_screen.dart';

Finder field(String label) => find.byWidgetPredicate((widget) => widget is TextField && widget.decoration?.labelText == label);
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
  test('signup allocates name-based IDs and retries taken candidates', () async {
    final claimed = <String>{'waheed_akram'};
    Future<bool> claim(String id) async => claimed.add(id);
    await Future.wait([
      UsernameRules.assign(' Waheed Akram ', claim),
      UsernameRules.assign('Waheed Akram', claim),
    ]);
    expect(claimed, {'waheed_akram', 'waheed_akram1', 'waheed_akram2'});
    for (final name in ['علی', 'Al', '123 Student', 'A' * 80]) {
      expect(UsernameRules.valid(UsernameRules.candidate(name, 999)), isTrue);
    }
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
  testWidgets('reference-style signup fits narrow screens and large text', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.4)), child: child!),
      home: const AuthEntryScreen(registering: true)));
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.byTooltip('Add profile photo'), findsOneWidget);
    expect(find.text('Your User ID is created automatically from your name.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.pumpAndSettle();
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
