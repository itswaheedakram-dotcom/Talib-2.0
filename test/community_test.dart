import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/services/active_profile_controller.dart';
import '../lib/core/services/database_service.dart';
import '../lib/core/services/demo_data_service.dart';
import '../lib/features/models/post.dart';
import '../lib/features/community/domain/post_templates.dart';
import '../lib/features/community/data/community_feed_controller.dart';
import '../lib/features/community/data/community_preferences.dart';
import '../lib/features/community/presentation/widgets/community_shimmer.dart';
import '../lib/features/community/presentation/widgets/community_post_card.dart';
import '../lib/features/community/presentation/screens/create_post_screen.dart';
import '../lib/features/community/presentation/screens/community_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ActiveProfileController.instance.activate(temporaryProfiles.first);
  });
  tearDown(() => ActiveProfileController.instance.clear());
  test(
    'legacy likes remain while users change or remove their own reaction',
    () async {
      final demos = DemoDataService.instance,
          id = demos.createPost(
            text: 'Reaction fixture',
            authorId: 'demo-user-2',
            authorName: 'Ali',
          );
      demos.toggleLike(id, 'demo-user-3');
      await DatabaseService().setReaction(id, 'demo-user-1', 'helpful');
      var p = demos.post(id)!;
      expect(p.reactionBy('demo-user-3'), 'like');
      expect(p.reactionBy('demo-user-1'), 'helpful');
      expect(p.reactionsCount, 2);
      await DatabaseService().setReaction(id, 'demo-user-1', 'insightful');
      p = demos.post(id)!;
      expect(p.reactionsCount, 2);
      expect(p.reactionCounts['helpful'], 0);
      expect(p.reactionCounts['insightful'], 1);
      await DatabaseService().setReaction(id, 'demo-user-1', null);
      expect(demos.post(id)!.reactors, {'demo-user-3': 'like'});
      expect(
        () => demos.setReaction(id, 'demo-user-1', 'fake'),
        throwsArgumentError,
      );
      demos.deletePost(id);
    },
  );
  test(
    'structured post details and reactions survive comments, votes and edits',
    () async {
      final demos = DemoDataService.instance,
          id = demos.createPost(
            text: 'Which subject?',
            authorId: 'demo-user-1',
            authorName: 'Ayesha',
            postType: 'poll',
            educationalData: {'duration': '3 days'},
            pollOptions: ['Physics', 'Mathematics'],
            pollClosesAt: DateTime.now().add(const Duration(days: 3)),
          );
      demos.setReaction(id, 'demo-user-2', 'celebrate');
      demos.addComment(
        postId: id,
        uid: 'demo-user-3',
        name: 'Hira',
        text: 'Mathematics',
      );
      demos.votePoll(postId: id, uid: 'demo-user-2', option: 0);
      demos.votePoll(postId: id, uid: 'demo-user-2', option: 1);
      demos.updatePost(postId: id, text: 'Which subject do you prefer?');
      final p = demos.post(id)!;
      expect(p.educationalData['duration'], '3 days');
      expect(p.reactionBy('demo-user-2'), 'celebrate');
      expect(p.pollVotes['0'], 0);
      expect(p.pollVotes['1'], 1);
      expect(p.pollVoters['demo-user-2'], 1);
      expect(p.updatedAt, isNotNull);
      expect(
        () => demos.updatePost(
          postId: id,
          text: 'Changed',
          pollOptions: ['A', 'B'],
        ),
        throwsStateError,
      );
      demos.deletePost(id);
    },
  );
  test('closed poll cannot receive another vote', () {
    final d = DemoDataService.instance,
        id = d.createPost(
          text: 'Closed poll',
          authorId: 'demo-user-1',
          authorName: 'Ayesha',
          pollOptions: ['A', 'B'],
          pollClosesAt: DateTime.now().subtract(const Duration(days: 1)),
        );
    expect(
      () => d.votePoll(postId: id, uid: 'demo-user-2', option: 0),
      throwsStateError,
    );
    d.deletePost(id);
  });
  test('new arrivals are buffered while existing reactions update live', () {
    final controller = CommunityFeedController(demo: true, uid: 'demo-user-1');
    final old = Post(
      id: 'old',
      text: 'Read me',
      authorId: 'a',
      authorName: 'A',
      createdAt: DateTime(2026, 1, 1),
    );
    controller.acceptLivePage([old]);
    controller.acceptLivePage([
      old.copyWith(reactions: {'b': 'helpful'}, likedBy: ['b'], likesCount: 1),
      Post(
        id: 'new',
        text: 'New arrival',
        authorId: 'a',
        authorName: 'A',
        createdAt: DateTime(2026, 1, 2),
      ),
    ]);
    expect(controller.posts.map((p) => p.id), ['old']);
    expect(controller.posts.single.reactionsCount, 1);
    expect(controller.pendingCount, 1);
    controller.showNewPosts();
    expect(controller.posts.map((p) => p.id), ['new', 'old']);
    controller.dispose();
  });
  test(
    'feed preferences isolate accounts and blocking removes mutual follow',
    () async {
      final d = DemoDataService.instance;
      d.toggleFollow('demo-user-1', 'demo-user-2', true);
      d.toggleFollow('demo-user-2', 'demo-user-1', true);
      final a = CommunityPreferences(uid: 'demo-user-1', demo: true)..start(),
          b = CommunityPreferences(uid: 'demo-user-3', demo: true)..start();
      final post = d.post('demo-post-2')!;
      await a.hide(post);
      await a.mute(post);
      expect(a.allows(post), isFalse);
      expect(b.allows(post), isTrue);
      await a.restore('hiddenPosts', post.id);
      await a.restore('mutedAuthors', post.authorId);
      await a.block(post);
      expect(d.isMutual('demo-user-1', 'demo-user-2'), isFalse);
      expect(d.communityBlocked('demo-user-1', 'demo-user-2'), isTrue);
      await a.restore('blockedUsers', post.authorId);
      expect(d.communityBlocked('demo-user-1', 'demo-user-2'), isFalse);
      a.dispose();
      b.dispose();
    },
  );
  test(
    'templates require useful content, safe links and concrete study arrangements',
    () {
      expect(PostTemplates.all.length, 10);
      expect(
        PostTemplates.validate(
          type: 'question',
          values: {'subject': 'Physics'},
          body: '',
        ),
        isNotNull,
      );
      expect(
        PostTemplates.validate(
          type: 'admission',
          values: {
            'program': 'BS',
            'deadline': '2026-11-01',
            'eligibility': 'Intermediate',
            'sourceUrl': 'https://university.edu',
          },
          body: '',
          institutes: 1,
        ),
        isNull,
      );
      expect(
        PostTemplates.validate(
          type: 'admission',
          values: {
            'program': 'BS',
            'deadline': '2026-11-01',
            'eligibility': 'Intermediate',
            'sourceUrl': 'javascript:alert(1)',
          },
          body: '',
          institutes: 1,
        ),
        isNotNull,
      );
      expect(
        PostTemplates.validate(
          type: 'study_group',
          values: {
            'subject': 'Physics',
            'mode': 'In person',
            'schedule': 'Monday',
            'time': '5 PM',
          },
          body: '',
        ),
        isNotNull,
      );
      expect(
        PostTemplates.validate(
          type: 'poll',
          values: {'duration': '3 days'},
          body: 'Choose',
          options: ['Same', 'same'],
        ),
        isNotNull,
      );
    },
  );
  testWidgets('shimmer is animated loading UI and disposes its ticker', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CommunityShimmer())),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'long press opens educational reactions with readable labels on narrow dark layout',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? chosen;
      final post = Post(
        id: 'fixture',
        text: 'A short helpful post.',
        authorId: 'demo-user-2',
        authorName: 'Ali Raza',
        createdAt: DateTime.now(),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: CommunityPostCard(
              post: post,
              uid: 'demo-user-1',
              onReact: (value) async {
                chosen = value;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Comment'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
      await tester.longPress(find.text('Like'));
      await tester.pumpAndSettle();
      expect(find.text('💡 Insightful'), findsOneWidget);
      await tester.tap(find.text('🙌 Helpful'));
      await tester.pumpAndSettle();
      expect(chosen, 'helpful');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'create post chooses a guided question and preview does not publish',
    (tester) async {
      tester.view.physicalSize = const Size(360, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: CreatePostScreen()));
      await tester.pumpAndSettle();
      expect(find.text('What would you like to share?'), findsOneWidget);
      await tester.tap(find.text('Ask a question'));
      await tester.pumpAndSettle();
      final subject = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Subject *',
      );
      await tester.enterText(subject, 'Physics');
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Your question *',
        ),
        'How does gravity affect acceleration?',
      );
      await tester.pump(const Duration(milliseconds: 600));
      final before = DemoDataService.instance.posts().length;
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(find.text('Public community preview'), findsOneWidget);
      expect(find.text('How does gravity affect acceleration?'), findsWidgets);
      expect(DemoDataService.instance.posts().length, before);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Back to editing'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 10));
    },
  );
  testWidgets('draft restores only to the same account and post', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'talib.community.draft.demo:demo-user-1.new',
      '{"type":"general","body":"My saved educational post","fields":{},"tags":[],"institutes":[],"options":[],"attachments":[]}',
    );
    await tester.pumpWidget(const MaterialApp(home: CreatePostScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Restore your draft?'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(find.text('My saved educational post'), findsOneWidget);
    ActiveProfileController.instance.activate(temporaryProfiles[1]);
    await tester.pumpAndSettle();
    expect(find.text('My saved educational post'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
  testWidgets(
    'feed separates following/topics and hides raw initialization errors',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));
      await tester.pumpAndSettle();
      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('View'), findsNothing);
      expect(find.text('All topics'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      ActiveProfileController.instance.clear();
      await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Sign in to browse the community.'), findsOneWidget);
      expect(find.textContaining('Firebase'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
