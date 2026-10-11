import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/app/theme.dart';
import 'package:talib_2/core/models/education_record.dart';
import 'package:talib_2/core/services/active_profile_controller.dart';
import 'package:talib_2/features/institutes/data/education_repository.dart';
import 'package:talib_2/features/institutes/data/institute_repository.dart';
import 'package:talib_2/features/institutes/data/student_affiliation_repository.dart';
import 'package:talib_2/features/profile/presentation/widgets/education_history_card.dart';

void main() {
  final repository = EducationRepository.instance;
  setUp(() {
    repository.resetDemo();
    StudentAffiliationRepository.instance.resetDemoForTest();
    ActiveProfileController.instance.activate(temporaryProfiles[0]);
  });
  tearDown(() {
    repository.resetDemo();
    ActiveProfileController.instance.clear();
  });
  EducationRecord degree(
    String id, {
    String status = 'current',
    bool primary = false,
  }) => EducationRecord(
    id: id,
    userId: 'demo-user-1',
    instituteId: 'school-1',
    instituteName: 'The Educators',
    program: 'Matric',
    programId: EducationFields.programKey('school-1', 'Matric'),
    levelId: 'school',
    status: status,
    primary: primary,
  );

  test(
    'all institute categories support enrollment, manager approval and self-declared completion',
    () async {
      final school = InstituteRepository.instance.byId('school-1')!;
      await repository.save(degree('school-degree'), school);
      var records = await repository.watch('demo-user-1').first;
      expect(records.single.verification, 'pending');
      await expectLater(
        repository.review(school, records.single, 'approved'),
        throwsStateError,
      );
      ActiveProfileController.instance.activate(temporaryProfiles[5]);
      await repository.review(school, records.single, 'approved');
      records = await repository.watch('demo-user-1').first;
      expect(records.single.isVerifiedCurrent, isTrue);
      ActiveProfileController.instance.activate(temporaryProfiles[0]);
      await repository.save(
        degree('school-degree', status: 'completed'),
        school,
      );
      records = await repository.watch('demo-user-1').first;
      expect(records.single.isAlumni, isTrue);
      expect(records.single.isVerifiedCurrent, isFalse);
      expect(records.single.verification, 'not_requested');
    },
  );

  test(
    'multiple current records have one primary, and completion preserves history',
    () async {
      final school = InstituteRepository.instance.byId('school-1')!;
      await repository.save(degree('one', primary: true), school);
      await repository.save(degree('two', primary: true), school);
      var records = await repository.watch('demo-user-1').first;
      expect(records.length, 2);
      expect(records.where((r) => r.primary).single.id, 'two');
      await repository.save(degree('one', status: 'completed'), school);
      await repository.save(degree('two', status: 'completed'), school);
      records = await repository.watch('demo-user-1').first;
      expect(records.where((r) => r.primary), isEmpty);
      expect(records.where((r) => r.isAlumni).length, 2);
    },
  );

  testWidgets(
    'alumni count deduplicates degrees and badge supports dark mode',
    (tester) async {
      final school = InstituteRepository.instance.byId('school-1')!;
      await repository.save(degree('one', status: 'completed'), school);
      await repository.save(degree('two', status: 'completed'), school);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDarkTheme(),
          home: const Scaffold(
            body: Column(
              children: [
                StudentAffiliationCard(uid: 'demo-user-1'),
                VerifiedStudentCount(instituteId: 'school-1'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alumni'), findsNWidgets(2));
      expect(find.text('1 alumni'), findsOneWidget);
      expect(find.text('0 current verified students'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await repository.save(degree('current'), school);
      ActiveProfileController.instance.activate(temporaryProfiles[5]);
      final current = (await repository.watch('demo-user-1').first).firstWhere(
        (r) => r.id == 'current',
      );
      await repository.review(school, current, 'approved');
      await tester.pumpAndSettle();
      expect(find.text('1 current verified students'), findsOneWidget);
      expect(find.text('1 alumni'), findsOneWidget);
      expect(find.text('Current verified student'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'migration retains previous approval and retires legacy count',
    () async {
      StudentAffiliationRepository.instance.resetDemoForTest(seed: true);
      final institute = InstituteRepository.instance.byId('university-1')!;
      await repository.save(
        EducationRecord(
          id: 'legacy-demo-user-1',
          userId: 'demo-user-1',
          instituteId: institute.id,
          instituteName: institute.name,
          program: 'BS Computer Science (Demo)',
          levelId: 'bachelors',
        ),
        institute,
      );
      expect(
        (await repository.watch('demo-user-1').first).single.isVerifiedCurrent,
        isTrue,
      );
      expect(
        await StudentAffiliationRepository.instance.verifiedStudentCount(
          institute.id,
        ),
        1,
      );
      expect(
        (await StudentAffiliationRepository.instance.profile(
          'demo-user-1',
        ))['studentInstituteId'],
        isNull,
      );
    },
  );
  testWidgets('legacy migration editor opens with a valid education level', (
    tester,
  ) async {
    StudentAffiliationRepository.instance.resetDemoForTest(seed: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: StudentAffiliationCard(uid: 'demo-user-1', editable: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('Move existing institute into education history'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit education'), findsOneWidget);
    expect(find.text('Bachelor’s degree'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
