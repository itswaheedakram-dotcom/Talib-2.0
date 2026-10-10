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
    await tester.ensureVisible(find.byType(InstituteDetailListings));
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
    expect(find.text('Eligibility: BS students'), findsNothing);
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
    final scholarship = find.ancestor(
      of: find.text('Merit Support'),
      matching: find.byType(InstituteOpportunityCard),
    );
    await tester.ensureVisible(
      find.descendant(of: scholarship, matching: find.text('More details')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: scholarship, matching: find.text('More details')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Eligibility: BS students'), findsOneWidget);
    expect(find.text('Not provided'), findsNothing);
    // Section shortcuts scroll the same page and keep every listing mounted.
    final admissionsTab = find.widgetWithText(ChoiceChip, 'Admissions');
    await tester.ensureVisible(admissionsTab);
    await tester.pumpAndSettle();
    await tester.tap(admissionsTab);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(admissionsTab).selected, isTrue);
    expect(find.byType(InstituteDetailScreen), findsOneWidget);
    final coursesTab = find.widgetWithText(ChoiceChip, 'Programs');
    await tester.ensureVisible(coursesTab);
    await tester.pumpAndSettle();
    await tester.tap(coursesTab);
    await tester.pumpAndSettle();
    final save = find.byTooltip('Save institute');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove bookmark'), findsOneWidget);
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

  testWidgets('large text and dark theme preserve overview and owner controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ActiveProfileController.instance.activate(temporaryProfiles[5]);
    final repository = InstituteRepository.instance;
    final institute = (await repository.add(
      Institute(
        id: 'accessible-ux-test',
        name: 'A Long Institute Name for Accessible Mobile Browsing',
        type: 'universities',
        city: 'Lahore',
        description: List.filled(
          12,
          'Students can explore this institute and its learning opportunities.',
        ).join(' '),
      ),
    ))!;
    await repository.setSubmissionStatus(institute.id, 'approved');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: InstituteDetailScreen(id: institute.id),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Edit institute'), findsOneWidget);
    expect(find.byTooltip('Manage Programs / Courses'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Website'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Call'), findsNothing);
    expect(find.text('Not provided'), findsNothing);
    final readMore = find.text('Read more');
    await tester.ensureVisible(readMore);
    await tester.pumpAndSettle();
    await tester.tap(readMore);
    await tester.pumpAndSettle();
    expect(find.text('Read less'), findsOneWidget);
    await tester.ensureVisible(find.text('Read less'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Read less'));
    await tester.pumpAndSettle();
    expect(find.text('Read more'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'category chips expand their own programs and collapse the previous group',
    (tester) async {
      ActiveProfileController.instance.activate(temporaryProfiles[0]);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: InstituteDetailListings(
                institute: Institute(
                  id: 'group-choice-test',
                  name: 'Grouped Institute',
                  type: 'universities',
                  city: 'Lahore',
                  programs: ['Education', 'Undergraduate', 'Graduate'],
                  programGroups: {
                    'Education': ['B.Ed'],
                    'Undergraduate': ['BS Computer Science', 'BS Education'],
                    'Graduate': ['MS Education'],
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('BS Computer Science'), findsNothing);
      final undergraduate = find.widgetWithText(ChoiceChip, 'Undergraduate');
      await tester.tap(undergraduate);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(undergraduate).selected, isTrue);
      expect(find.text('BS Computer Science'), findsOneWidget);
      expect(find.text('BS Education'), findsOneWidget);
      expect(find.text('MS Education'), findsNothing);
      final graduate = find.widgetWithText(ChoiceChip, 'Graduate');
      await tester.tap(graduate);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(undergraduate).selected, isFalse);
      expect(find.text('BS Computer Science'), findsNothing);
      expect(find.text('MS Education'), findsOneWidget);
      await tester.tap(graduate);
      await tester.pumpAndSettle();
      expect(find.text('MS Education'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Education'));
      await tester.pumpAndSettle();
      expect(find.text('B.Ed'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'program groups survive serialization without guessing legacy offerings',
    () {
      final grouped = Institute.fromMap('grouped', {
        'name': 'Grouped Institute',
        'city': 'Lahore',
        'programs': ['Undergraduate'],
        'programGroups': {
          'Undergraduate': ['BS Computer Science', 'BS Computer Science'],
          'Graduate': 'MS Education, MS English',
        },
      });
      expect(grouped.programCategories, ['Undergraduate', 'Graduate']);
      final restored = Institute.fromMap(grouped.id, grouped.toMap());
      expect(restored.programGroups['Undergraduate'], ['BS Computer Science']);
      expect(restored.programGroups['Graduate'], [
        'MS Education',
        'MS English',
      ]);
      final legacy = Institute.fromMap('legacy', {
        'programs': ['Undergraduate', 'Graduate'],
      });
      expect(legacy.programGroups, isEmpty);
    },
  );

  test(
    'group management uses the shared repository and enforces permissions',
    () async {
      final profiles = ActiveProfileController.instance;
      profiles.activate(temporaryProfiles[5]);
      final repository = InstituteRepository.instance;
      final institute = (await repository.add(
        const Institute(
          id: 'group-management-test',
          name: 'Managed Groups Institute',
          type: 'universities',
          city: 'Lahore',
          programs: ['Undergraduate'],
          programGroups: {
            'Undergraduate': ['BS Computer Science'],
          },
        ),
      ))!;
      await repository.setSubmissionStatus(institute.id, 'approved');
      expect(
        await repository.addProgramToGroup(
          institute.id,
          'undergraduate',
          'BS Education',
        ),
        isTrue,
      );
      expect(
        await repository.addProgramToGroup(
          institute.id,
          'Undergraduate',
          'bs education',
        ),
        isFalse,
      );
      expect(
        await repository.addProgramToGroup(
          institute.id,
          'Graduate',
          'MS Education',
        ),
        isTrue,
      );
      expect(
        await repository.removeProgramFromGroup(
          institute.id,
          'Undergraduate',
          'BS Computer Science',
        ),
        isTrue,
      );
      final saved = (await repository.loadById(institute.id))!;
      expect(saved.programGroups['Undergraduate'], ['BS Education']);
      expect(saved.programGroups['Graduate'], ['MS Education']);
      profiles.activate(temporaryProfiles[0]);
      expect(
        await repository.addProgramToGroup(
          institute.id,
          'Graduate',
          'Unauthorized program',
        ),
        isFalse,
      );
      expect(repository.byId(institute.id)!.programGroups, saved.programGroups);
    },
  );
}
