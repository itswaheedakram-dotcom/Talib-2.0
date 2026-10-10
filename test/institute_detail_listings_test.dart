import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/app/theme.dart';
import 'package:talib_2/core/services/active_profile_controller.dart';
import 'package:talib_2/core/services/firebase_service.dart';
import 'package:talib_2/features/institutes/data/institute_opportunity_repository.dart';
import 'package:talib_2/features/institutes/data/institute_repository.dart';
import 'package:talib_2/features/institutes/presentation/screens/institute_detail_screen.dart';
import 'package:talib_2/features/institutes/presentation/widgets/institute_detail_listings.dart';
import 'package:talib_2/features/institutes/presentation/widgets/institute_opportunity_card.dart';
import 'package:talib_2/features/models/institute.dart';
import 'package:talib_2/features/models/institute_opportunity.dart';

void main() {
  tearDown(() {
    ActiveProfileController.instance.clear();
    FirebaseService.initialized = false;
  });

  testWidgets('detail page shows every offering inline on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // No Firebase app exists; production repositories must use the demo backend.
    final profiles = ActiveProfileController.instance;
    profiles.activate(temporaryProfiles[5]);
    final institutes = InstituteRepository.instance;
    final institute = (await institutes.add(
      const Institute(
        id: 'inline-listings-test',
        name: 'Inline Listings Institute',
        type: 'universities',
        city: 'Lahore',
        programs: ['Computer Science', 'Engineering'],
      ),
    ))!;
    expect(
      await institutes.setSubmissionStatus(institute.id, 'approved'),
      isTrue,
    );
    final offerings = InstituteOpportunityRepository.instance;
    for (final item in [
      InstituteOpportunity(
        id: '',
        instituteId: institute.id,
        kind: 'course',
        title: 'Software Engineering Professional Course',
        status: 'Open',
        feeDetails: 'PKR 20000',
        deliveryMode: 'On campus',
      ),
      InstituteOpportunity(
        id: '',
        instituteId: institute.id,
        kind: 'admission',
        title: 'Current Undergraduate Intake',
        status: 'Open',
        academicYear: '2026',
        deadline: '2026-12-01',
      ),
      InstituteOpportunity(
        id: '',
        instituteId: institute.id,
        kind: 'admission',
        title: 'Next Undergraduate Intake',
        status: 'Upcoming',
        academicYear: '2027',
        openingDate: '2027-01-01',
      ),
      InstituteOpportunity(
        id: '',
        instituteId: institute.id,
        kind: 'admission',
        title: 'Old Closed Intake',
        status: 'Closed',
      ),
      InstituteOpportunity(
        id: '',
        instituteId: institute.id,
        kind: 'scholarship',
        title: 'Merit Support',
        status: 'Open',
        eligibility: 'BS students',
        coverage: 'Full tuition',
        deadline: '2026-12-15',
      ),
    ]) {
      expect(await offerings.add(item), isNotNull);
    }
    profiles.activate(temporaryProfiles[0]);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: InstituteDetailScreen(id: institute.id),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(InstituteDetailListings), 350);
    await tester.pumpAndSettle();

    expect(find.text('Computer Science'), findsOneWidget);
    expect(find.text('Engineering'), findsOneWidget);
    expect(
      find.text('Software Engineering Professional Course'),
      findsOneWidget,
    );
    expect(find.text('Current Undergraduate Intake'), findsOneWidget);
    expect(find.text('Next Undergraduate Intake'), findsOneWidget);
    expect(find.text('Old Closed Intake'), findsNothing);
    expect(find.text('Merit Support'), findsOneWidget);
    expect(find.text('Fee: PKR 20000'), findsOneWidget);
    expect(find.text('Eligibility: BS students'), findsOneWidget);
    expect(find.text('Coverage: Full tuition'), findsOneWidget);
    expect(find.text('Scholarship deadline: 2026-12-15'), findsOneWidget);
    expect(find.byType(InstituteOpportunityCard), findsNWidgets(4));
    for (final title in [
      'Programs',
      'Programs / Courses',
      'Admissions',
      'Scholarships',
    ]) {
      expect(find.widgetWithText(OutlinedButton, title), findsNothing);
    }
    await tester.ensureVisible(find.text('Merit Support'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('empty institute shows honest empty sections without Firebase', (
    tester,
  ) async {
    ActiveProfileController.instance.activate(temporaryProfiles[0]);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: InstituteDetailListings(
              institute: Institute(
                id: 'empty-inline-institute',
                name: 'Empty Institute',
                type: 'universities',
                city: 'Lahore',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No programs or courses listed yet.'), findsOneWidget);
    expect(
      find.text('No open or upcoming admissions listed yet.'),
      findsOneWidget,
    );
    expect(find.text('No scholarships listed yet.'), findsOneWidget);
    expect(find.byType(InstituteOpportunityCard), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
