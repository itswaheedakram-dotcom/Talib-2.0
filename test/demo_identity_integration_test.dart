import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/core/services/active_profile_controller.dart';
import 'package:talib_2/core/services/demo_data_service.dart';

void main() {
  test('Ayesha -> Usman demo identity scenario stays isolated', () {
    final data = DemoDataService.instance;
    final identity = ActiveProfileController.instance;

    const ayesha = 'demo-user-1';
    const usman = 'demo-user-4';
    const groupId = 'demo-group-1';
    const instituteId = 'demo-institute-test';

    // 1) Activate Ayesha and verify the active identity bridge.
    identity.activate(temporaryProfiles.firstWhere((p) => p.id == ayesha));
    expect(identity.effectiveUid, ayesha);
    expect(identity.effectiveName, 'Ayesha Khan');

    // 2) Community: Ayesha creates a post. Usman interacts with it.
    final postId = data.createPost(
      text: 'Ayesha identity audit post',
      authorId: ayesha,
      authorName: 'Ayesha Khan',
    );
    expect(data.post(postId)?.authorId, ayesha);
    expect(data.post(postId)?.authorName, 'Ayesha Khan');

    data.toggleLike(postId, usman);
    data.addComment(
      postId: postId,
      uid: usman,
      name: 'Usman Malik',
      text: 'Usman audit comment',
    );
    expect(data.post(postId)?.likedBy, contains(usman));
    expect(data.comments(postId).last.authorId, usman);
    expect(
      data.notifications(ayesha).any((n) => n['type'] == 'like'),
      isTrue,
    );
    expect(
      data.notifications(ayesha).any((n) => n['type'] == 'comment'),
      isTrue,
    );

    // 3) Follow + messaging: make the pair non-following, then build mutual follow.
    data.toggleFollow(ayesha, usman, false);
    data.toggleFollow(usman, ayesha, false);
    expect(data.isMutual(ayesha, usman), isFalse);

    data.toggleFollow(ayesha, usman, true);
    data.toggleFollow(usman, ayesha, true);
    expect(data.isFollowing(ayesha, usman), isTrue);
    expect(data.isFollowing(usman, ayesha), isTrue);
    expect(data.isMutual(ayesha, usman), isTrue);

    data.sendMessage(ayesha, usman, 'Hello from Ayesha');
    expect(data.messages(ayesha, usman).last['senderId'], ayesha);
    expect(data.messages(ayesha, usman).last['receiverId'], usman);
    expect(data.notifications(usman).any((n) => n['type'] == 'message'), isTrue);

    // 4) Group membership is identity-specific.
    expect(data.isGroupMember(ayesha, groupId), isTrue);
    expect(data.isGroupMember(usman, groupId), isTrue);
    data.createGroup(ayesha, 'Ayesha Audit Group', 'Identity audit');
    final createdGroup = data.groups().firstWhere((g) => g['name'] == 'Ayesha Audit Group');
    expect(data.isGroupMember(ayesha, createdGroup['id']), isTrue);
    expect(data.isGroupMember(usman, createdGroup['id']), isFalse);
    data.joinGroup(usman, createdGroup['id'] as String);
    expect(data.isGroupMember(usman, createdGroup['id']), isTrue);

    // 5) Resources are shared, but author identity remains correct.
    data.addResource(ayesha, 'Ayesha Resource', 'https://example.com/a', 'Ayesha resource');
    data.addResource(usman, 'Usman Resource', 'https://example.com/u', 'Usman resource');
    final resources = data.resources(ayesha);
    expect(resources.any((r) => r['authorId'] == ayesha && r['title'] == 'Ayesha Resource'), isTrue);
    expect(resources.any((r) => r['authorId'] == usman && r['title'] == 'Usman Resource'), isTrue);
    expect(data.resources(usman).length, resources.length);

    // 6) Reviews are attached to the target, not the active reviewer.
    data.addReview(usman, ayesha, 'Ayesha Khan', 5, 'Great guidance.');
    expect(data.reviews(usman).single['reviewerId'], ayesha);
    expect(data.reviews(usman).single['reviewerName'], 'Ayesha Khan');
    expect(data.reviews(ayesha), isEmpty);

    // 7) Bookmarks and institute interactions are per identity.
    data.toggleBookmark(ayesha, postId, true);
    expect(data.bookmarked(ayesha, postId), isTrue);
    expect(data.bookmarked(usman, postId), isFalse);

    data.toggleInstituteBookmark(ayesha, instituteId, true);
    expect(data.instituteBookmarked(ayesha, instituteId), isTrue);
    expect(data.instituteBookmarked(usman, instituteId), isFalse);

    data.claimInstitute(ayesha, instituteId);
    expect(data.claimed(ayesha, instituteId), isTrue);
    expect(data.claimed(usman, instituteId), isFalse);

    // 8) Settings are isolated.
    data.setSetting(ayesha, 'privateProfile', true);
    data.setSetting(usman, 'privateProfile', false);
    expect(data.settings(ayesha)['privateProfile'], isTrue);
    expect(data.settings(usman)['privateProfile'], isFalse);

    // 9) Switch to Usman and verify Ayesha's state is still intact.
    identity.activate(temporaryProfiles.firstWhere((p) => p.id == usman));
    expect(identity.effectiveUid, usman);
    expect(identity.effectiveName, 'Usman Malik');
    expect(data.post(postId)?.authorId, ayesha);
    expect(data.bookmarked(usman, postId), isFalse);
    expect(data.bookmarked(ayesha, postId), isTrue);
    expect(data.reviews(usman).single['reviewerId'], ayesha);
    expect(data.settings(ayesha)['privateProfile'], isTrue);
    expect(data.settings(usman)['privateProfile'], isFalse);
    expect(data.isGroupMember(ayesha, createdGroup['id']), isTrue);
    expect(data.isGroupMember(usman, createdGroup['id']), isTrue);

    identity.clear();
  });
}
