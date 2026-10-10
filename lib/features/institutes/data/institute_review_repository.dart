import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/active_profile_controller.dart';
import '../../models/institute.dart';
import '../../models/institute_review.dart';
import 'institute_access.dart';
import 'institute_repository.dart';

class InstituteReviewRepository extends ChangeNotifier {
  InstituteReviewRepository._() {
    for (final id in ['university-2', 'university-31']) {
      _demo[id] = [for (var i = 0; i < 3; i++) InstituteReview(
        instituteId: id, userId: temporaryProfiles[i].id, authorName: '${temporaryProfiles[i].name} (Demo)',
        rating: id == 'university-2' ? [5, 4, 4][i] : [4, 4, 3][i],
        text: ['Demo review: helpful teaching staff.', 'Demo review: good learning environment.', 'Demo review: facilities could improve.'][i],
        updatedAt: DateTime.now().subtract(Duration(days: i + 1)))];
    }
  }
  static final instance = InstituteReviewRepository._();
  final Map<String, List<InstituteReview>> _demo = {};
  final Map<String, List<InstituteReview>> _real = {};
  bool _realRankingsLoaded = false;
  Map<String, List<InstituteReview>> get _source => InstituteAccess.isDemo ? _demo : _real;
  bool get rankingsAvailable => InstituteAccess.isDemo || _realRankingsLoaded;
  List<InstituteReview> forInstitute(String id) => List.unmodifiable(_source[id] ?? const []);
  InstituteRatingSummary summary(String id) => InstituteRatingSummary.fromReviews(forInstitute(id));

  List<Institute> ranked(String type) {
    final items = InstituteRepository.instance.items.where((i) => i.type == type && summary(i.id).eligibleForRank).toList();
    items.sort((a, b) {
      final result = summary(b.id).rankingScore.compareTo(summary(a.id).rankingScore);
      return result != 0 ? result : a.name.compareTo(b.name);
    });
    return items;
  }
  int? rank(Institute institute) {
    if (!rankingsAvailable || !summary(institute.id).eligibleForRank) return null;
    final items = ranked(institute.type);
    final index = items.indexWhere((i) => i.id == institute.id);
    if (index < 0) return null;
    var first = index;
    while (first > 0 && summary(items[first - 1].id).rankingScore == summary(institute.id).rankingScore) { first--; }
    return first + 1;
  }

  Future<void> load(String id) async {
    if (InstituteAccess.isDemo) return;
    final actor = InstituteAccess.uid;
    final docs = await FirebaseFirestore.instance.collection('institutes').doc(id)
        .collection('instituteReviews').where('published', isEqualTo: true).get();
    if (InstituteAccess.isDemo || actor != InstituteAccess.uid) return;
    _real[id] = [for (final doc in docs.docs)
      if (InstituteReview.read(doc.data()) case final review?)
        if (review.instituteId == id && review.userId == doc.id) review];
    notifyListeners();
  }

  Future<void> loadRankings() async {
    if (InstituteAccess.isDemo) return;
    final actor = InstituteAccess.uid;
    _realRankingsLoaded = false;
    await InstituteRepository.instance.load();
    if (InstituteRepository.instance.error != null) throw StateError('Could not load institute rankings.');
    final docs = await FirebaseFirestore.instance.collectionGroup('instituteReviews')
        .where('published', isEqualTo: true).get();
    if (InstituteAccess.isDemo || actor != InstituteAccess.uid) return;
    final grouped = <String, List<InstituteReview>>{};
    for (final doc in docs.docs) {
      final review = InstituteReview.read(doc.data());
      if (review == null || review.userId != doc.id || review.instituteId != doc.reference.parent.parent?.id
          || doc.reference.parent.parent?.parent.path != 'institutes') continue;
      (grouped[review.instituteId] ??= []).add(review);
    }
    _real..clear()..addAll(grouped);
    _realRankingsLoaded = true;
    notifyListeners();
  }

  Future<void> save(String id, int rating, String text) async {
    final demo = InstituteAccess.isDemo;
    final uid = InstituteAccess.uid;
    if (uid == null || uid.isEmpty) throw StateError('Sign in to rate this institute.');
    if (rating < 1 || rating > 5) throw ArgumentError('Choose between 1 and 5 stars.');
    if (text.trim().length > 1000) throw ArgumentError('Keep the review within 1,000 characters.');
    final institute = await InstituteRepository.instance.loadById(id);
    if (demo != InstituteAccess.isDemo || uid != InstituteAccess.uid) throw StateError('Your profile changed. Please retry.');
    if (institute == null || !{'approved', 'verified'}.contains(institute.status.toLowerCase())) throw StateError('This institute is not available for public reviews.');
    final name = demo ? ActiveProfileController.instance.effectiveName : FirebaseAuth.instance.currentUser?.displayName;
    final displayName = (name?.trim().isNotEmpty ?? false) ? '${name!.trim()}${demo ? ' (Demo)' : ''}' : 'Community member';
    final review = InstituteReview(instituteId: id, userId: uid,
      authorName: displayName.length > 100 ? displayName.substring(0, 100) : displayName,
      rating: rating, text: text.trim(), updatedAt: DateTime.now());
    if (!demo) await FirebaseFirestore.instance.collection('institutes').doc(id)
        .collection('instituteReviews').doc(uid).set({...review.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
    if (demo != InstituteAccess.isDemo || uid != InstituteAccess.uid) return;
    final items = _source.putIfAbsent(id, () => []);
    items.removeWhere((r) => r.userId == uid);
    items.insert(0, review);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final demo = InstituteAccess.isDemo;
    final uid = InstituteAccess.uid;
    if (uid == null || uid.isEmpty) throw StateError('Sign in to delete your review.');
    if (!demo) await FirebaseFirestore.instance.collection('institutes').doc(id)
        .collection('instituteReviews').doc(uid).delete();
    if (demo != InstituteAccess.isDemo || uid != InstituteAccess.uid) return;
    _source[id]?.removeWhere((r) => r.userId == uid);
    notifyListeners();
  }
}
