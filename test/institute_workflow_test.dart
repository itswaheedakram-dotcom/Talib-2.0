import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/core/services/active_profile_controller.dart';
import 'package:talib_2/core/services/firebase_service.dart';
import 'package:talib_2/features/institutes/data/institute_access.dart';
import 'package:talib_2/features/institutes/data/institute_claim_repository.dart';
import 'package:talib_2/features/institutes/data/institute_opportunity_repository.dart';
import 'package:talib_2/features/institutes/data/institute_repository.dart';
import 'package:talib_2/features/institutes/data/institute_score.dart';
import 'package:talib_2/features/models/institute.dart';
import 'package:talib_2/features/models/institute_opportunity.dart';

void main() {
  tearDown(() {
    ActiveProfileController.instance.clear();
    FirebaseService.initialized = false;
  });

  test(
    'demo claim approval enables only the assigned owner and never requires Firebase',
    () async {
      // No Firebase app is initialized: any accidental real access fails this test.
      final profiles = ActiveProfileController.instance;
      final repo = InstituteRepository.instance;
      final claims = InstituteClaimRepository.instance;
      profiles.activate(temporaryProfiles[0]);
      final listing = (await repo.add(
        const Institute(
          id: 'workflow-institute',
          name: 'Workflow Institute',
          type: 'schools',
          city: 'Lahore',
        ),
      ))!;
      expect(listing.status, 'pending');
      expect(repo.items.any((item) => item.id == listing.id), isFalse);
      expect(await repo.setSubmissionStatus(listing.id, 'approved'), isFalse);

      profiles.activate(temporaryProfiles[5]);
      expect(await repo.setSubmissionStatus(listing.id, 'approved'), isTrue);
      profiles.activate(temporaryProfiles[0]);
      var institute = repo.byId(listing.id)!;
      expect(InstituteAccess.canManage(institute), isFalse);
      expect(
        await repo.update(
          Institute.fromMap(institute.id, {
            ...institute.toMap(),
            'name': 'Unauthorized',
          }),
        ),
        isFalse,
      );
      await claims.submit(
        institute,
        designation: 'Principal',
        method: 'Official email',
        details: 'principal@example.test',
      );
      final claim = (await claims.watch().first).single;
      expect(claim['verificationDetails'], 'principal@example.test');
      await expectLater(
        claims.review(claim['id'], 'approved'),
        throwsStateError,
      );

      profiles.activate(temporaryProfiles[5]);
      await claims.review(claim['id'], 'approved');
      profiles.activate(temporaryProfiles[0]);
      institute = repo.byId(listing.id)!;
      expect(InstituteAccess.canManage(institute), isTrue);
      expect((await claims.get(claim['id']))?['status'], 'approved');
      expect(
        await repo.update(
          Institute.fromMap(institute.id, {
            ...institute.toMap(),
            'name': 'Owner edit',
          }),
        ),
        isTrue,
      );
      expect((await repo.loadById(institute.id))?.name, 'Owner edit');
      expect(
        await repo.update(
          Institute.fromMap(institute.id, {
            ...institute.toMap(),
            'ownerId': 'another-owner',
          }),
        ),
        isFalse,
      );

      profiles.activate(temporaryProfiles[1]);
      expect(InstituteAccess.canManage(repo.byId(listing.id)!), isFalse);
      expect(
        await InstituteOpportunityRepository.instance.add(
          InstituteOpportunity(
            id: '',
            instituteId: listing.id,
            kind: 'admission',
            title: 'Unauthorized admission',
          ),
        ),
        isNull,
      );
      expect(await claims.get(claim['id']), isNull);
    },
  );

  test(
    'score scales survive serialization and eligibility never mixes units',
    () {
      final institute = Institute.fromMap('i', const {
        'name': 'I',
        'city': 'Lahore',
        'minScore': 3.2,
        'scoreScale': 'cgpa4',
      });
      expect(Institute.fromMap('i', institute.toMap()).scoreScale, 'cgpa4');
      expect(
        Institute.fromMap('legacy', const {'minScore': 3.2}).scoreScale,
        'unspecified',
      );
      expect(
        InstituteScore.eligible(
          score: 72,
          scale: 'percentage',
          minimum: 3.2,
          minimumScale: 'cgpa4',
        ),
        isFalse,
      );
      expect(
        InstituteScore.eligible(
          score: 3.5,
          scale: 'cgpa4',
          minimum: 3.2,
          minimumScale: 'cgpa4',
        ),
        isTrue,
      );
      expect(
        InstituteScore.eligible(
          score: 3.5,
          scale: 'cgpa4',
          minimum: 3.2,
          minimumScale: 'cgpa5',
        ),
        isFalse,
      );
      expect(
        InstituteScore.eligible(
          score: 72,
          scale: 'percentage',
          minimum: 50,
          minimumScale: 'unspecified',
        ),
        isFalse,
      );
      expect(InstituteScore.validate('101', 'percentage'), isNotNull);
      expect(InstituteScore.validate('4.1', 'cgpa4'), isNotNull);
      expect(InstituteScore.validate('NaN', 'percentage'), isNotNull);
    },
  );

  test('real browsing does not expose built-in sample institutes', () {
    FirebaseService.initialized = true;
    ActiveProfileController.instance.clear();
    expect(InstituteRepository.instance.items, isEmpty);
  });
}
