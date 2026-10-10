import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/core/models/user_profile.dart';
import 'package:talib_2/core/services/user_profile_repository.dart';
import 'package:talib_2/core/services/active_profile_controller.dart';
import 'package:talib_2/core/services/firebase_service.dart';
import 'package:talib_2/core/services/database_service.dart';
import 'package:talib_2/core/services/demo_data_service.dart';
import 'package:talib_2/core/widgets/user_identity.dart';
import 'package:talib_2/features/institutes/data/institute_repository.dart';
import 'package:talib_2/features/institutes/data/student_affiliation_repository.dart';
import 'package:talib_2/features/profile/presentation/widgets/profile_view.dart';
import 'package:talib_2/app/theme.dart';

void main() {
  tearDown(() { ActiveProfileController.instance.clear(); FirebaseService.initialized = false; });
  test('other student activity retains its own UID in a demo session', () async {
    ActiveProfileController.instance.activate(temporaryProfiles[0]);
    final demo = DemoDataService.instance;
    final database = DatabaseService();
    final previous = demo.isFollowing('demo-user-2', 'demo-user-3');
    demo.toggleFollow('demo-user-2', 'demo-user-3', true);
    try {
      expect(await database.followingStream('demo-user-2', 'demo-user-3').first, isTrue);
      expect(await database.followerCountStream('demo-user-3').first, demo.followerCount('demo-user-3'));
      expect(await database.reputation('demo-user-3'), demo.reputation('demo-user-3'));
    } finally {
      demo.toggleFollow('demo-user-2', 'demo-user-3', previous);
    }
  });
  test('immutable UID and canonical course override old profile values', () {
    final profile = UserProfile.fromMap('real-uid', {
      'uid': 'forged-uid', 'name': 'Student',
      'studentInstituteId': 'university-1', 'studentProgram': 'BS Computing',
      'program': 'Wrong legacy course', 'skills': ['Unity', 'Unity'],
    });
    expect(profile.uid, 'real-uid');
    expect(profile.course, 'BS Computing');
    expect(profile.skills, ['Unity']);
    expect(profile.editableFields.containsKey(ProfileFields.course), isFalse);
    expect(profile.editableFields.containsKey(ProfileFields.uid), isFalse);
  });
  test('saving another student profile is rejected', () async {
    ActiveProfileController.instance.activate(temporaryProfiles[0]);
    await expectLater(UserProfileRepository.instance.save(const UserProfile(uid: 'demo-user-2', name: 'Spoof')),
      throwsStateError);
  });
  test('unchanged approved affiliation retains badge and count', () async {
    final repo = StudentAffiliationRepository.instance;
    repo.resetDemoForTest(seed: true);
    ActiveProfileController.instance.activate(temporaryProfiles[0]);
    await repo.select(InstituteRepository.instance.byId('university-1')!, 'BS Computer Science (Demo)');
    expect((await repo.profile('demo-user-1'))[ProfileFields.affiliationStatus], 'approved');
    expect(await repo.verifiedStudentCount('university-1'), 2);
  });
  testWidgets('UID remains below the actor name at large text sizes', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MediaQuery(data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.6)),
      child: const Scaffold(body: SizedBox(width: 280, child: UserIdentity(uid: 'immutable-long-user-id-123456789', name: 'A student with a long display name', resolveName: false))))));
    expect(find.text('UID: immutable-long-user-id-123456789'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('central profile screen displays UID and edit entry without duplicate course', (tester) async {
    ActiveProfileController.instance.activate(temporaryProfiles[0]);
    StudentAffiliationRepository.instance.resetDemoForTest(seed: true);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: const ProfileView(uid: 'demo-user-1')));
    await tester.pumpAndSettle();
    expect(find.text('UID: demo-user-1'), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('BS Computer Science (Demo)'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
