import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/app/theme.dart';
import 'package:talib_2/core/services/active_profile_controller.dart';
import 'package:talib_2/core/services/demo_data_service.dart';
import 'package:talib_2/core/services/firebase_service.dart';
import 'package:talib_2/features/institutes/data/institute_repository.dart';
import 'package:talib_2/features/institutes/data/student_affiliation_repository.dart';
import 'package:talib_2/features/profile/presentation/widgets/student_affiliation_card.dart';

void main() {
  final affiliations = StudentAffiliationRepository.instance;
  tearDown(() {
    affiliations.resetDemoForTest();
    ActiveProfileController.instance.clear();
    FirebaseService.initialized = false;
  });

  testWidgets('selected university shows before approval; approval adds badge and verified count only', (tester) async {
    await InstituteRepository.instance.load();
    final university = InstituteRepository.instance.byId('university-2')!;
    ActiveProfileController.instance.activate(temporaryProfiles[0]);
    await affiliations.select(university, 'BS Computer Science (Demo)');

    var profile = await affiliations.profile('demo-user-1');
    expect(profile['studentInstituteName'], university.name);
    expect(profile['studentVerificationStatus'], 'pending');
    expect(await affiliations.verifiedStudentCount(university.id), 0);
    expect(DemoDataService.instance.notifications('demo-user-6').any((n) => n['type'] == 'student_affiliation'), isTrue);

    await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: Scaffold(body: StudentAffiliationCard(uid: 'demo-user-1'))));
    await tester.pumpAndSettle();
    expect(find.text(university.name), findsOneWidget);
    expect(find.text('Verification request sent. Waiting for the university.'), findsOneWidget);
    expect(find.text('University verified'), findsNothing);

    ActiveProfileController.instance.activate(temporaryProfiles[5]);
    final managerRequests = await affiliations.requests(university).first;
    expect(managerRequests.single['studentId'], 'demo-user-1');
    await affiliations.review(university, 'demo-user-1', 'approved');
    expect(await affiliations.verifiedStudentCount(university.id), 1);
    profile = await affiliations.profile('demo-user-1');
    expect(profile['studentVerificationStatus'], 'approved');
    await tester.pumpAndSettle();
    expect(find.text('University verified'), findsOneWidget);
    expect(DemoDataService.instance.notifications('demo-user-1').any((n) => n['type'] == 'student_affiliation_result'), isTrue);
    expect(FirebaseService.initialized, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('demo representative can decline a request without increasing verified count', () async {
    await InstituteRepository.instance.load();
    final university = InstituteRepository.instance.byId('university-31')!;
    ActiveProfileController.instance.activate(temporaryProfiles[1]);
    await affiliations.select(university, 'Agriculture program (Demo)');
    ActiveProfileController.instance.activate(temporaryProfiles[5]);
    await affiliations.review(university, 'demo-user-2', 'rejected');
    expect((await affiliations.profile('demo-user-2'))['studentVerificationStatus'], 'rejected');
    expect(await affiliations.verifiedStudentCount(university.id), 0);
  });
}
