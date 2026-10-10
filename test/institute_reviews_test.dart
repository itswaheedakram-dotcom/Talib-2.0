import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/app/theme.dart';
import 'package:talib_2/core/services/active_profile_controller.dart';
import 'package:talib_2/core/services/firebase_service.dart';
import 'package:talib_2/features/models/institute.dart';
import 'package:talib_2/features/models/institute_review.dart';
import 'package:talib_2/features/institutes/data/institute_repository.dart';
import 'package:talib_2/features/institutes/data/institute_review_repository.dart';
import 'package:talib_2/features/institutes/presentation/widgets/institute_reviews_section.dart';

void main() {
  tearDown(() { ActiveProfileController.instance.clear(); FirebaseService.initialized = false; });
  test('ratings deduplicate people, validate bounds and soften small samples', () {
    InstituteReview review(String uid, int score) => InstituteReview(instituteId: 'i', userId: uid, authorName: 'User', rating: score, text: '', updatedAt: DateTime(2026));
    final result = InstituteRatingSummary.fromReviews([review('a', 5), review('a', 4), review('b', 3), review('c', 5)]);
    expect(result.count, 3); expect(result.total, 12); expect(result.average, 4);
    expect(result.distribution, {4: 1, 3: 1, 5: 1}); expect(result.eligibleForRank, isTrue);
    expect(result.rankingScore, 27 / 8);
    expect(InstituteRatingSummary.fromReviews([review('a', 5)]).eligibleForRank, isFalse);
    expect(InstituteReview.read({...review('a', 5).toMap(), 'rating': 6}), isNull);
    expect(InstituteReview.read({...review('a', 5).toMap(), 'published': false}), isNull);
    expect(InstituteReview.read(review('a', 5).toMap())!.rating, 5);
  });
  Future<Institute> fixture(String name) async {
    ActiveProfileController.instance.activate(temporaryProfiles[5]);
    final institutes = InstituteRepository.instance;
    final i = (await institutes.add(Institute(id: '', name: name, type: 'universities', city: 'Lahore')))!;
    await institutes.setSubmissionStatus(i.id, 'approved');
    return institutes.byId(i.id)!;
  }
  testWidgets('three demo profiles rank seeded universities and edits update the displayed rank', (tester) async {
    ActiveProfileController.instance.activate(temporaryProfiles[0]);
    final institutes = InstituteRepository.instance;
    await institutes.load();
    final first = institutes.byId('university-2')!;
    final second = institutes.byId('university-31')!;
    final repo = InstituteReviewRepository.instance;
    final originals = repo.forInstitute(second.id).toList();
    addTearDown(() async {
      for (var n = 0; n < 3; n++) {
        ActiveProfileController.instance.activate(temporaryProfiles[n]);
        final review = originals.singleWhere((r) => r.userId == temporaryProfiles[n].id);
        await repo.save(second.id, review.rating, review.text);
      }
    });
    expect(repo.summary(first.id).average, closeTo(4.33, .01));
    expect(repo.rank(first), 1);
    expect(repo.rank(second), 2);
    for (var n = 0; n < 3; n++) {
      ActiveProfileController.instance.activate(temporaryProfiles[n]);
      await repo.save(second.id, 5, 'Demo profile ${n + 1}: testing community ranking.');
    }
    expect(repo.summary(second.id).count, 3);
    expect(repo.summary(second.id).average, 5);
    expect(repo.rank(second), 1);
    expect(repo.rank(first), 2);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: Scaffold(body: SingleChildScrollView(child: InstituteReviewsSection(institute: second)))));
    await tester.pumpAndSettle();
    expect(find.text('5.0 / 5'), findsOneWidget);
    expect(find.text('3 ratings'), findsOneWidget);
    expect(find.text('Community rank #1 of 2'), findsOneWidget);
    // Editing the same three accounts changes the rank without adding votes.
    for (var n = 0; n < 3; n++) {
      ActiveProfileController.instance.activate(temporaryProfiles[n]);
      await repo.save(second.id, [5, 4, 4][n], 'Demo review updated.');
    }
    await tester.pumpAndSettle();
    expect(repo.summary(second.id).count, 3);
    expect(repo.rank(first), 1);
    expect(repo.rank(second), 1);
    expect(find.text('Community rank #1 of 2'), findsOneWidget);
    ActiveProfileController.instance.activate(temporaryProfiles[2]);
    await repo.save(second.id, 3, 'Demo review updated again.');
    await tester.pumpAndSettle();
    expect(repo.rank(second), 2);
    expect(find.text('Community rank #2 of 2'), findsOneWidget);
    expect(FirebaseService.initialized, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('demo users have one editable rating each; ranks require three and deletion updates totals', () async {
    final i = await fixture('Review repository test');
    final repo = InstituteReviewRepository.instance;
    for (var n = 0; n < 3; n++) {
      ActiveProfileController.instance.activate(temporaryProfiles[n]);
      await repo.save(i.id, 4, 'Experience $n');
    }
    expect(repo.summary(i.id).count, 3); expect(repo.rank(i), isNotNull);
    await repo.save(i.id, 5, 'Updated experience');
    expect(repo.summary(i.id).count, 3); expect(repo.summary(i.id).total, 13);
    await repo.delete(i.id);
    expect(repo.summary(i.id).count, 2); expect(repo.rank(i), isNull);
    expect(repo.forInstitute(i.id).any((r) => r.userId == temporaryProfiles[0].id), isTrue);
    expect(() => repo.save(i.id, 0, ''), throwsArgumentError);
    ActiveProfileController.instance.clear();
    expect(() => repo.save(i.id, 5, ''), throwsStateError);
    expect(FirebaseService.initialized, isFalse);
  });
  testWidgets('public section lets a user rate, edit and delete on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 900); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final i = await fixture('Public review UI');
    ActiveProfileController.instance.activate(temporaryProfiles[0]);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: Scaffold(body: SingleChildScrollView(child: InstituteReviewsSection(institute: i)))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Rate this institute'));
    await tester.tap(find.text('Rate this institute')); await tester.pumpAndSettle();
    await tester.tap(find.text('Publish review')); await tester.pumpAndSettle();
    expect(find.text('Choose a star rating first.'), findsOneWidget);
    await tester.tap(find.byTooltip('4 stars'));
    await tester.enterText(find.byKey(const ValueKey('institute-review-text')), 'Helpful staff and good labs.');
    await tester.tap(find.text('Publish review')); await tester.pumpAndSettle();
    expect(find.text('Helpful staff and good labs.'), findsOneWidget);
    expect(find.text('1 rating'), findsOneWidget);
    await tester.ensureVisible(find.text('Edit your review'));
    await tester.tap(find.text('Edit your review')); await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('5 stars'));
    await tester.tap(find.text('Publish review')); await tester.pumpAndSettle();
    expect(InstituteReviewRepository.instance.summary(i.id).average, 5);
    expect(InstituteReviewRepository.instance.summary(i.id).count, 1);
    await tester.ensureVisible(find.text('Edit your review'));
    await tester.tap(find.text('Edit your review')); await tester.pumpAndSettle();
    await tester.tap(find.text('Delete your review')); await tester.pumpAndSettle();
    expect(InstituteReviewRepository.instance.summary(i.id).count, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('signed-out public users see summaries without a review composer', (tester) async {
    final i = await fixture('Anonymous reviews'); ActiveProfileController.instance.clear();
    await tester.pumpWidget(MaterialApp(theme: buildDarkTheme(), home: Scaffold(body: SingleChildScrollView(child: InstituteReviewsSection(institute: i)))));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to share your rating and review.'), findsOneWidget);
    expect(find.text('Rate this institute'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
