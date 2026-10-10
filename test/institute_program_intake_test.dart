import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/app/theme.dart';
import 'package:talib_2/core/services/active_profile_controller.dart';
import 'package:talib_2/core/services/firebase_service.dart';
import 'package:talib_2/features/models/institute.dart';
import 'package:talib_2/features/models/institute_opportunity.dart';
import 'package:talib_2/features/models/institute_program_requirements.dart';
import 'package:talib_2/features/institutes/data/institute_repository.dart';
import 'package:talib_2/features/institutes/data/institute_opportunity_repository.dart';
import 'package:talib_2/features/institutes/presentation/widgets/institute_program_editor.dart';
import 'package:talib_2/features/institutes/presentation/widgets/institute_detail_listings.dart';

void main() {
  final cs = InstituteProgramRequirements.key(
    'Undergraduate',
    'BS Computer Science',
  );
  final education = InstituteProgramRequirements.key(
    'Undergraduate',
    'BS Education',
  );
  tearDown(() {
    ActiveProfileController.instance.clear();
    FirebaseService.initialized = false;
  });

  test(
    'intakes inherit live common values; sparse exceptions and clear/reset survive serialization',
    () {
      InstituteOpportunity intake(String score) => InstituteOpportunity(
        id: 'intake',
        instituteId: 'i',
        kind: 'admission',
        title: 'Fall',
        programKeys: [cs, education],
        deadline: '2027-01-20',
        requirements: {'scoreScale': 'Percentage', 'minScore': score},
        programOverrides: {
          cs: {'minScore': '60', 'deadline': '2027-02-01', 'documents': ''},
        },
      );
      final saved = InstituteOpportunity.fromMap(
        'intake',
        intake('50').toMap(),
      );
      expect(
        saved.forProgram(cs, {
          'documents': 'Certificate',
        }).requirements['documents'],
        '',
      );
      expect(saved.forProgram(cs).deadline, '2027-02-01');
      expect(saved.forProgram(education).deadline, '2027-01-20');
      expect(intake('55').forProgram(education).requirements['minScore'], '55');
      expect(intake('55').forProgram(cs).requirements['minScore'], '60');
      final reset = InstituteOpportunity.fromMap('intake', {
        ...saved.toMap(),
        'programOverrides': {},
      });
      expect(reset.forProgram(cs).requirements['minScore'], '50');
      expect(
        reset.forProgram(cs, {'subjects': 'Math'}).requirements['subjects'],
        'Math',
      );
      final legacy = InstituteOpportunity.fromMap('old', {
        'title': 'Legacy',
        'eligibility': 'Existing requirements',
      });
      expect(legacy.eligibility, 'Existing requirements');
      expect(legacy.programKeys, isEmpty);
      expect(
        InstituteProgramRequirements.name(
          InstituteProgramRequirements.key(
            'MS / MPhil',
            'Education / Research',
          ),
        ),
        'Education / Research',
      );
    },
  );

  test(
    'date status is inclusive and respects explicit closure and per-program deadline',
    () {
      final intake = InstituteOpportunity(
        id: 'i',
        instituteId: 'x',
        kind: 'admission',
        title: 'Fall',
        status: 'Upcoming',
        openingDate: '2026-10-10',
        deadline: '2026-10-30',
        programKeys: [cs],
        programOverrides: {
          cs: {'deadline': '2026-10-20'},
        },
      );
      expect(intake.statusAt(DateTime(2026, 10, 9)), 'Upcoming');
      expect(intake.statusAt(DateTime(2026, 10, 10)), 'Open');
      expect(intake.statusAt(DateTime(2026, 10, 30, 23, 59)), 'Open');
      expect(intake.statusAt(DateTime(2026, 10, 31)), 'Closed');
      expect(intake.forProgram(cs).statusAt(DateTime(2026, 10, 21)), 'Closed');
      final closed = InstituteOpportunity.fromMap('i', {
        ...intake.toMap(),
        'status': 'Closed',
      });
      expect(closed.statusAt(DateTime(2026, 10, 15)), 'Closed');
    },
  );

  test(
    'percentage and both CGPA scales validate without inventing universal criteria',
    () {
      expect(
        InstituteProgramRequirements.validate({
          'scoreScale': 'Percentage',
          'minScore': '100',
        }),
        isNull,
      );
      expect(
        InstituteProgramRequirements.validate({
          'scoreScale': 'Percentage',
          'minScore': '101',
        }),
        isNotNull,
      );
      expect(
        InstituteProgramRequirements.validate({
          'scoreScale': 'CGPA / 4',
          'minScore': '4.1',
        }),
        isNotNull,
      );
      expect(
        InstituteProgramRequirements.validate({
          'scoreScale': 'CGPA / 5',
          'minScore': '4.1',
        }),
        isNull,
      );
      expect(
        InstituteProgramRequirements.validate({'minScore': '2.5'}),
        isNotNull,
      );
      expect(InstituteProgramRequirements.validate({}), isNull);
    },
  );

  Future<Institute> fixture(String name) async {
    ActiveProfileController.instance.activate(temporaryProfiles[5]);
    final repository = InstituteRepository.instance;
    final institute = (await repository.add(
      Institute(
        id: '',
        name: name,
        type: 'universities',
        city: 'Lahore',
        programs: const ['Undergraduate'],
        programGroups: const {
          'Undergraduate': ['BS Computer Science', 'BS Education'],
        },
      ),
    ))!;
    await repository.setSubmissionStatus(institute.id, 'approved');
    return repository.byId(institute.id)!;
  }

  test(
    'repository rejects unauthorized changes, missing links and duplicate program details',
    () async {
      final institute = await fixture('Linked repository test');
      final repository = InstituteOpportunityRepository.instance;
      final program = InstituteOpportunity(
        id: '',
        instituteId: institute.id,
        kind: 'course',
        title: 'BS Computer Science',
        programKeys: [cs],
        requirements: const {'scoreScale': 'Percentage', 'minScore': '50'},
      );
      final saved = await repository.add(program);
      expect(saved, isNotNull);
      expect(await repository.add(program), isNull);
      expect(repository.baselineFor(institute.id, cs)['minScore'], '50');
      expect(
        await repository.add(
          InstituteOpportunity(
            id: '',
            instituteId: institute.id,
            kind: 'admission',
            title: 'Bad link',
            programKeys: ['missing'],
          ),
        ),
        isNull,
      );
      expect(
        await repository.add(
          InstituteOpportunity(
            id: '',
            instituteId: institute.id,
            kind: 'admission',
            title: 'Bad criteria',
            programKeys: [cs],
            requirements: const {'scoreScale': 'CGPA / 4', 'minScore': '5'},
          ),
        ),
        isNull,
      );
      ActiveProfileController.instance.activate(temporaryProfiles[0]);
      expect(await repository.update(saved!), isFalse);
      expect(await repository.delete(saved), isFalse);
      expect(FirebaseService.initialized, isFalse);
    },
  );

  testWidgets(
    'bulk intake selection saves one shared record on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final institute = await fixture('Bulk form test');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showInstituteProgramEditor(context, institute, 'admission'),
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      final missingSelection = find.text(
        'Choose at least one program to continue.',
      );
      expect(missingSelection, findsOneWidget);
      expect(tester.getRect(missingSelection).top, lessThan(900));
      expect(
        InstituteOpportunityRepository.instance.forInstitute(institute.id),
        isEmpty,
      );
      await tester.ensureVisible(
        find.text('Select / clear all Undergraduate programs'),
      );
      await tester.tap(find.text('Select / clear all Undergraduate programs'));
      await tester.pumpAndSettle();
      expect(find.text('2 programs selected'), findsOneWidget);
      final title = find.descendant(of: find.byKey(const ValueKey('editor-field-title')), matching: find.byType(TextFormField));
      await tester.ensureVisible(title);
      await tester.enterText(title, 'Shared Fall Intake');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      final scale = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(scale);
      await tester.tap(scale);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Percentage').last);
      await tester.pumpAndSettle();
      final commonScore = find.descendant(of: find.byKey(const ValueKey('editor-field-minScore')), matching: find.byType(TextFormField));
      await tester.ensureVisible(commonScore);
      await tester.enterText(commonScore, '50');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      final different = find.text('Different details for a program');
      await tester.ensureVisible(different);
      await tester.tap(different);
      await tester.pumpAndSettle();
      final exception = find.text('BS Computer Science').last;
      await tester.ensureVisible(exception);
      await tester.tap(exception);
      await tester.pumpAndSettle();
      final customizeScore = find.widgetWithText(
        SwitchListTile,
        'Minimum marks / CGPA',
      );
      await tester.ensureVisible(customizeScore);
      await tester.tap(customizeScore);
      await tester.pumpAndSettle();
      final specificScore = find.descendant(of: find.byKey(const ValueKey('editor-field-minScore')), matching: find.byType(TextFormField));
      await tester.ensureVisible(specificScore);
      await tester.enterText(specificScore, '60');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Check before saving'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final saved = InstituteOpportunityRepository.instance
          .forInstitute(institute.id)
          .single;
      expect(saved.title, 'Shared Fall Intake');
      expect(saved.programKeys.toSet(), {cs, education});
      expect(saved.requirements['minScore'], '50');
      expect(saved.forProgram(cs).requirements['minScore'], '60');
      expect(saved.forProgram(education).requirements['minScore'], '50');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('program wizard separates labels, keeps navigation above keyboard and preserves edits', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final institute = await fixture('Accessible program editor test');
    final repository = InstituteOpportunityRepository.instance;
    final existing = (await repository.add(InstituteOpportunity(
      id: '', instituteId: institute.id, kind: 'course', title: 'BS Computer Science',
      programKeys: [cs], programDetails: const {'duration': '4 years', 'campus': 'Main campus'},
      requirements: const {'qualification': 'Intermediate or equivalent qualification in the required subjects',
        'scoreScale': 'Percentage', 'minScore': '50', 'documents': 'CNIC and certificates', 'research': 'Existing research notes'},
    )))!;
    await tester.pumpWidget(MaterialApp(theme: buildDarkTheme(),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)), child: child!),
      home: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => showInstituteProgramEditor(context, institute, 'course', existing: existing, programKey: cs),
        child: const Text('Edit program'))))));
    await tester.tap(find.text('Edit program'));
    await tester.pumpAndSettle();
    expect(find.text('Graduate'), findsNothing);
    expect(find.text('Step 1 of 4 · Program basics'), findsOneWidget);
    final durationField = find.descendant(of: find.byKey(const ValueKey('editor-field-duration')), matching: find.byType(TextFormField));
    await tester.ensureVisible(durationField);
    await tester.enterText(durationField, '4 years / 8 semesters');
    final durationLabel = find.text('Duration / semesters');
    expect(tester.getRect(durationLabel).bottom + 7, lessThanOrEqualTo(tester.getRect(durationField).top));
    expect(tester.widget<TextFormField>(durationField).decoration?.labelText, isNull);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.widgetWithText(FilledButton, 'Next')).bottom, lessThanOrEqualTo(500));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    final scoreField = find.descendant(of: find.byKey(const ValueKey('editor-field-minScore')), matching: find.byType(TextFormField));
    await tester.ensureVisible(scoreField);
    await tester.enterText(scoreField, '101');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 4 · Who can apply?'), findsOneWidget);
    expect(find.textContaining('Minimum score must be between'), findsOneWidget);
    await tester.enterText(scoreField, '55');
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('4 years / 8 semesters'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('55'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('CNIC and certificates'), findsNothing);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = repository.forInstitute(institute.id).single;
    expect(saved.programDetails['duration'], '4 years / 8 semesters');
    expect(saved.requirements['minScore'], '55');
    expect(saved.requirements['documents'], 'CNIC and certificates');
    expect(saved.requirements['research'], 'Existing research notes');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'program expansion and admissions show linked criteria and customized deadline',
    (tester) async {
      final institute = await fixture('Linked UI test');
      final repository = InstituteOpportunityRepository.instance;
      expect(
        await repository.add(
          InstituteOpportunity(
            id: '',
            instituteId: institute.id,
            kind: 'course',
            title: 'CS program information',
            programKeys: [cs],
            programDetails: const {'duration': '4 years'},
            requirements: const {'scoreScale': 'Percentage', 'minScore': '50'},
          ),
        ),
        isNotNull,
      );
      final far = DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String()
          .split('T')
          .first;
      expect(
        await repository.add(
          InstituteOpportunity(
            id: '',
            instituteId: institute.id,
            kind: 'admission',
            title: 'Linked Fall Intake',
            status: 'Open',
            deadline: far,
            programKeys: [cs, education],
            programOverrides: {
              cs: {'subjects': 'Mathematics', 'minScore': '60'},
            },
          ),
        ),
        isNotNull,
      );
      ActiveProfileController.instance.activate(temporaryProfiles[0]);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: InstituteDetailListings(institute: institute),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Undergraduate'));
      await tester.pumpAndSettle();
      final program = find
          .widgetWithText(ExpansionTile, 'BS Computer Science')
          .first;
      await tester.ensureVisible(program);
      await tester.tap(find.text('BS Computer Science').first);
      await tester.pumpAndSettle();
      expect(find.text('CS program information'), findsOneWidget);
      expect(find.text('Linked Fall Intake'), findsNWidgets(2));
      final more = find.text('More details').first;
      await tester.ensureVisible(more);
      await tester.tap(more);
      await tester.pumpAndSettle();
      expect(find.text('Duration / semesters: 4 years'), findsOneWidget);
      final intakeMore = find.text('More details').at(1);
      await tester.ensureVisible(intakeMore);
      await tester.tap(intakeMore);
      await tester.pumpAndSettle();
      expect(find.text('Minimum marks / CGPA: 60'), findsOneWidget);
      expect(
        find.text('Required subjects / relevant disciplines: Mathematics'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
