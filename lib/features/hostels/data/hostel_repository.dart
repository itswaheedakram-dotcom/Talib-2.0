import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hostel.dart';
import 'hostel_seed_data.dart';
import 'hostel_review.dart';
import 'hostel_claim.dart';
import '../../../core/services/firebase_service.dart';

class HostelRepository {
  HostelRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection => _db.collection('hostels');

  Stream<List<Hostel>> watchHostels() => _collection.snapshots().map(
    (s) => _sortRecommended(
      s.docs.map(Hostel.fromDoc).where((h) => h.status == 'approved').toList(),
    ),
  );

  /// Central discovery filtering used by Hostel screens.
  List<Hostel> discover(
    Iterable<Hostel> source, {
    String query = '',
    String city = 'All',
    String gender = 'All',
    String type = 'All',
    String roomType = 'All',
    bool acOnly = false,
    String sort = 'Recommended',
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final result = source.where((hostel) {
      if (hostel.status.toLowerCase() != 'approved') return false;
      if (city != 'All' && hostel.city != city) return false;
      if (gender != 'All' && hostel.gender != gender) return false;
      if (type != 'All' && hostel.type != type) return false;
      if (roomType != 'All' &&
          hostel.roomType != roomType &&
          !hostel.rooms.any((room) => room.type == roomType)) {
        return false;
      }
      if (acOnly && !hostel.ac && !hostel.rooms.any((room) => room.ac)) {
        return false;
      }
      if (normalizedQuery.isEmpty) return true;
      final haystack = <String>[
        hostel.name,
        hostel.city,
        hostel.area,
        hostel.type,
        hostel.gender,
        hostel.price,
        hostel.roomType,
        hostel.availability,
        hostel.meals,
        hostel.description,
        hostel.address,
        hostel.website,
        ...hostel.facilities,
        ...hostel.rules,
        ...hostel.rooms.map((room) => room.type),
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();

    switch (sort) {
      case 'Price Low':
        result.sort((a, b) => _numericValue(a.price).compareTo(_numericValue(b.price)));
        break;
      case 'Price High':
        result.sort((a, b) => _numericValue(b.price).compareTo(_numericValue(a.price)));
        break;
      case 'Nearest':
        result.sort((a, b) => _numericValue(a.distance).compareTo(_numericValue(b.distance)));
        break;
      case 'Top Rated':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        result.sort((a, b) {
          final verified = (b.isVerified ? 1 : 0).compareTo(a.isVerified ? 1 : 0);
          if (verified != 0) return verified;
          final rating = b.rating.compareTo(a.rating);
          if (rating != 0) return rating;
          return a.name.compareTo(b.name);
        });
    }
    return result;
  }

  List<Hostel> _sortRecommended(List<Hostel> hostels) {
    hostels.sort((a, b) {
      final verified = (b.isVerified ? 1 : 0).compareTo(a.isVerified ? 1 : 0);
      if (verified != 0) return verified;
      final rating = b.rating.compareTo(a.rating);
      if (rating != 0) return rating;
      return a.name.compareTo(b.name);
    });
    return hostels;
  }

  double _numericValue(String value) {
    final match = RegExp(r'[-+]?\d+(?:\.\d+)?').firstMatch(value.replaceAll(',', ''));
    return match == null ? double.infinity : double.tryParse(match.group(0)!) ?? double.infinity;
  }
  Stream<List<Hostel>> watchOwnerHostels(String ownerId) => _collection.where('ownerId', isEqualTo: ownerId).snapshots().map((s) => s.docs.map(Hostel.fromDoc).toList()..sort((a,b) => a.name.compareTo(b.name)));

  Future<Hostel?> getHostel(String hostelId) async {
    if (hostelId.trim().isEmpty) return null;
    final doc = await _collection.doc(hostelId).get();
    if (!doc.exists) return null;
    return Hostel.fromDoc(doc);
  }



  static final Map<String, HostelClaim> _demoClaims = {};
  static final Map<String, List<HostelReview>> _demoReviews = {
    'example_student_residency_lahore': [
      const HostelReview(id: 'demo-review-1', userId: 'demo-student-1', userName: 'Demo Student', rating: 5, comment: 'Clean rooms and good study environment.'),
    ],
    'example_girls_campus_hostel': [
      const HostelReview(id: 'demo-review-2', userId: 'demo-student-2', userName: 'Demo Member', rating: 4, comment: 'Good location and useful facilities.'),
    ],
  };

  static Stream<List<HostelReview>> demoReviewStream(String hostelId) {
    return Stream.value(List<HostelReview>.from(_demoReviews[hostelId] ?? const []));
  }

  static Future<HostelReview?> demoMyReview(String hostelId, String userId) async {
    for (final review in _demoReviews[hostelId] ?? const <HostelReview>[]) {
      if (review.userId == userId) return review;
    }
    return null;
  }

  static Future<void> submitDemoReview({
    required String hostelId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    final reviews = _demoReviews.putIfAbsent(hostelId, () => <HostelReview>[]);
    final index = reviews.indexWhere((r) => r.userId == userId);
    final review = HostelReview(
      id: index >= 0 ? reviews[index].id : 'demo-$userId',
      userId: userId,
      userName: userName.isEmpty ? 'Demo Member' : userName,
      rating: rating,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );
    if (index >= 0) {
      reviews[index] = review;
    } else {
      reviews.insert(0, review);
    }
  }

  static Future<String> submitClaim({
    required String hostelId,
    required String hostelName,
    required String userId,
    required String userName,
    required String contact,
    required String note,
    required bool demo,
  }) async {
    if (demo || !FirebaseService.initialized) {
      final id = 'demo-claim-$hostelId-$userId';
      _demoClaims[id] = HostelClaim(
        id: id,
        hostelId: hostelId,
        hostelName: hostelName,
        userId: userId,
        userName: userName,
        contact: contact,
        note: note,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      return id;
    }
    final db = FirebaseFirestore.instance;
    final ref = db.collection('hostelClaims').doc();
    await ref.set({
      'hostelId': hostelId,
      'hostelName': hostelName,
      'userId': userId,
      'userName': userName,
      'contact': contact,
      'note': note,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> updateHostelSafe(Hostel hostel) async {
    if (hostel.isDemo || !FirebaseService.initialized) return;
    await FirebaseFirestore.instance.collection('hostels').doc(hostel.id).update({
      ...hostel.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<HostelClaim>> watchOwnerClaims(String userId) {
    return _db.collection('hostelClaims').where('userId', isEqualTo: userId).snapshots().map(
      (s) => s.docs.map(HostelClaim.fromDoc).toList(),
    );
  }

  Stream<List<HostelClaim>> watchAllClaims() {
    return _db.collection('hostelClaims').orderBy('createdAt', descending: true).snapshots().map(
      (s) => s.docs.map(HostelClaim.fromDoc).toList(),
    );
  }

  Future<void> approveClaim(HostelClaim claim) async {
    final batch = _db.batch();
    batch.update(_db.collection('hostelClaims').doc(claim.id), {
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_collection.doc(claim.hostelId), {
      'ownerId': claim.userId,
      'ownerName': claim.userName,
      'isDemo': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> rejectClaim(String claimId) async {
    await _db.collection('hostelClaims').doc(claimId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<HostelReview>> watchReviews(String hostelId) => _collection.doc(hostelId).collection('reviews').orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(HostelReview.fromDoc).toList());

  Future<HostelReview?> getMyReview(String hostelId, String userId) async {
    final doc = await _collection.doc(hostelId).collection('reviews').doc(userId).get();
    return doc.exists ? HostelReview.fromDoc(doc) : null;
  }

  Future<void> submitReview({required String hostelId, required String userId, required String userName, required double rating, required String comment}) async {
    if (!FirebaseService.initialized) {
      await submitDemoReview(hostelId: hostelId, userId: userId, userName: userName, rating: rating, comment: comment);
      return;
    }
    final ref = _collection.doc(hostelId).collection('reviews').doc(userId);
    await _db.runTransaction((tx) async {
      final old = await tx.get(ref);
      final hostelRef = _collection.doc(hostelId);
      final hostel = await tx.get(hostelRef);
      final currentCount = (hostel.data()?['reviewCount'] as num?)?.toInt() ?? 0;
      final currentTotal = (hostel.data()?['ratingTotal'] as num?)?.toDouble() ?? 0;
      final oldRating = old.exists ? ((old.data()?['rating'] as num?)?.toDouble() ?? 0) : 0;
      final count = old.exists ? currentCount : currentCount + 1;
      final total = currentTotal - oldRating + rating;
      tx.set(ref, {'userId': userId, 'userName': userName.isEmpty ? 'Member' : userName, 'rating': rating, 'comment': comment.trim(), 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
      tx.update(hostelRef, {'reviewCount': count, 'ratingTotal': total, 'rating': count == 0 ? 0 : total / count, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  Future<void> seedDemoDataIfEmpty() async {
    final snapshot = await _collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final hostel in exampleHostels) {
      final ref = _collection.doc(hostel.id);
      batch.set(ref, {...hostel.toMap(), 'status':'approved','isVerified':true,'isDemo':true,'reviewCount':0,'ratingTotal':0.0,'rating':0.0,'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()});
    }
    await batch.commit();
  }

  Future<String> submitHostel(Hostel hostel) async { final ref=_collection.doc(); await ref.set({...hostel.toMap(),'ownerId':hostel.ownerId,'ownerName':hostel.ownerName,'status':'pending','isVerified':false,'isDemo':false,'reviewCount':0,'ratingTotal':0.0,'rating':0.0,'createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp()}); return ref.id; }
  Future<void> updateHostel(Hostel hostel) => _collection.doc(hostel.id).update({...hostel.toMap(),'updatedAt':FieldValue.serverTimestamp()});
  Future<void> deleteHostel(String hostelId) => _collection.doc(hostelId).delete();
}
