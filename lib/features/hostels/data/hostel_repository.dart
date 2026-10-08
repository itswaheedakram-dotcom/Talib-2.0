import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hostel.dart';
import 'hostel_seed_data.dart';
import 'hostel_review.dart';
import 'hostel_claim.dart';
import 'hostel_manager.dart';
import 'hostel_room.dart';
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



  static final List<Hostel> _demoHostels = List<Hostel>.from(exampleHostels);
  static final Map<String, HostelClaim> _demoClaims = {};

  static List<Hostel> get demoHostels => List<Hostel>.unmodifiable(_demoHostels);
  static final Map<String, List<HostelReview>> _demoReviews = {
    'example_student_residency_lahore': [
      const HostelReview(id: 'demo-review-1', userId: 'demo-student-1', userName: 'Demo Student', rating: 5, comment: 'Clean rooms and good study environment.'),
    ],
    'example_girls_campus_hostel': [
      const HostelReview(id: 'demo-review-2', userId: 'demo-student-2', userName: 'Demo Member', rating: 4, comment: 'Good location and useful facilities.'),
    ],
  };

  static final Map<String, StreamController<List<HostelReview>>> _demoReviewControllers = {};

  static Stream<List<HostelReview>> demoReviewStream(String hostelId) {
    final controller = _demoReviewControllers.putIfAbsent(
      hostelId,
      () => StreamController<List<HostelReview>>.broadcast(),
    );
    return Stream.multi((multi) {
      multi.add(List<HostelReview>.from(_demoReviews[hostelId] ?? const []));
      final subscription = controller.stream.listen(multi.add);
      multi.onCancel = subscription.cancel;
    });
  }

  static void _emitDemoReviews(String hostelId) {
    final controller = _demoReviewControllers[hostelId];
    if (controller != null && !controller.isClosed) {
      controller.add(List<HostelReview>.from(_demoReviews[hostelId] ?? const []));
    }
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
    final hostelIndex = _demoHostels.indexWhere((h) => h.id == hostelId);
    if (hostelIndex >= 0) {
      final total = reviews.fold<double>(0, (sum, item) => sum + item.rating);
      final current = _demoHostels[hostelIndex];
      _demoHostels[hostelIndex] = Hostel(
        id: current.id, name: current.name, city: current.city, area: current.area,
        type: current.type, gender: current.gender, distance: current.distance,
        price: current.price, securityFee: current.securityFee, roomType: current.roomType,
        availability: current.availability, meals: current.meals, ac: current.ac,
        facilities: current.facilities, imageUrls: current.imageUrls, description: current.description,
        phone: current.phone, website: current.website, imageUrl: current.imageUrl, address: current.address,
        ownerId: current.ownerId, ownerName: current.ownerName, status: current.status,
        isVerified: current.isVerified, isDemo: current.isDemo,
        rating: reviews.isEmpty ? 0 : total / reviews.length,
        reviewCount: reviews.length, ratingTotal: total, rooms: current.rooms, rules: current.rules,
      );
      _emitDemoReviews(hostelId);
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
      final existing = _demoClaims[id];
      if (existing != null && (existing.status == 'pending' || existing.status == 'approved')) {
        return id;
      }
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
    final ref = db.collection('hostelClaims').doc('${hostelId}_${userId}');
    final existing = await ref.get();
    if (existing.exists) {
      final existingStatus = (existing.data()?['status'] ?? 'pending').toString();
      if (existingStatus == 'pending' || existingStatus == 'approved') return ref.id;
    }
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
    if (hostel.isDemo || !FirebaseService.initialized) {
      final index = _demoHostels.indexWhere((item) => item.id == hostel.id);
      if (index >= 0) _demoHostels[index] = hostel;
      return;
    }
    await FirebaseFirestore.instance.collection('hostels').doc(hostel.id).update({
      ...hostel.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> canManageHostel(String hostelId, String userId) async {
    final hostel = await getHostel(hostelId);
    if (hostel == null || userId.trim().isEmpty) return false;
    if (hostel.ownerId == userId) return true;
    final manager = await getManager(hostelId, userId);
    return manager != null && manager.status == 'active';
  }

  Future<HostelManager?> managerAccess(String hostelId, String userId) =>
      getManager(hostelId, userId);
  static Future<String> submitHostelSafe(Hostel hostel, {required bool demo}) async {
    if (demo || !FirebaseService.initialized) {
      final id = 'demo_hostel_${DateTime.now().microsecondsSinceEpoch}';
      final copy = Hostel(
        id: id,
        name: hostel.name,
        city: hostel.city,
        area: hostel.area,
        type: hostel.type,
        gender: hostel.gender,
        distance: hostel.distance,
        price: hostel.price,
        securityFee: hostel.securityFee,
        roomType: hostel.roomType,
        availability: hostel.availability,
        meals: hostel.meals,
        ac: hostel.ac,
        facilities: hostel.facilities,
        imageUrls: hostel.imageUrls,
        description: hostel.description,
        phone: hostel.phone,
        website: hostel.website,
        imageUrl: hostel.imageUrl,
        address: hostel.address,
        ownerId: hostel.ownerId.isEmpty ? 'demo-user' : hostel.ownerId,
        ownerName: hostel.ownerName.isEmpty ? 'Demo Hostel Owner' : hostel.ownerName,
        status: 'approved',
        isVerified: false,
        isDemo: true,
        rating: 0,
        reviewCount: 0,
        ratingTotal: 0,
        rooms: hostel.rooms,
        rules: hostel.rules,
      );
      _demoHostels.add(copy);
      return id;
    }
    return HostelRepository().submitHostel(hostel);
  }

  static Future<void> deleteHostelSafe(Hostel hostel) async {
    if (hostel.isDemo || !FirebaseService.initialized) {
      _demoHostels.removeWhere((item) => item.id == hostel.id);
      return;
    }
    await FirebaseFirestore.instance.collection('hostels').doc(hostel.id).delete();
  }

  static final Map<String, List<HostelManager>> _demoManagers = {};

  Stream<List<HostelManager>> watchManagers(String hostelId) {
    final demoHostel = _demoHostels.any((item) => item.id == hostelId);
    if (demoHostel || !FirebaseService.initialized) {
      return Stream.value(
        List<HostelManager>.from(_demoManagers[hostelId] ?? const <HostelManager>[]),
      );
    }
    return _db.collection('hostels').doc(hostelId).collection('managers').snapshots().map(
      (s) => s.docs.map(HostelManager.fromDoc).where((m) => m.status == 'active').toList(),
    );
  }

  Future<HostelManager?> getManager(String hostelId, String userId) async {
    final demoHostel = _demoHostels.any((item) => item.id == hostelId);
    if (demoHostel || !FirebaseService.initialized) {
      for (final manager in _demoManagers[hostelId] ?? const <HostelManager>[]) {
        if (manager.userId == userId && manager.status == 'active') return manager;
      }
      return null;
    }
    final doc = await _db.collection('hostels').doc(hostelId).collection('managers').doc(userId).get();
    if (!doc.exists) return null;
    final manager = HostelManager.fromDoc(doc);
    return manager.status == 'active' ? manager : null;
  }

  Future<void> addManager({
    required String hostelId,
    required String userId,
    required String userName,
    required Map<String, bool> permissions,
  }) async {
    if (userId.trim().isEmpty) throw ArgumentError('Manager user ID is required');
    final manager = HostelManager(
      id: userId,
      hostelId: hostelId,
      userId: userId.trim(),
      userName: userName.trim().isEmpty ? 'Manager' : userName.trim(),
      status: 'active',
      permissions: Map<String, bool>.from(permissions),
      createdAt: DateTime.now(),
    );
    if (!FirebaseService.initialized) {
      final list = _demoManagers.putIfAbsent(hostelId, () => <HostelManager>[]);
      final index = list.indexWhere((item) => item.userId == manager.userId);
      if (index >= 0) {
        list[index] = manager;
      } else {
        list.add(manager);
      }
      return;
    }
    await _db.collection('hostels').doc(hostelId).collection('managers').doc(manager.userId).set({
      ...manager.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateManagerPermissions({
    required String hostelId,
    required String userId,
    required Map<String, bool> permissions,
  }) async {
    if (!FirebaseService.initialized) {
      final list = _demoManagers[hostelId] ?? <HostelManager>[];
      final index = list.indexWhere((item) => item.userId == userId);
      if (index >= 0) {
        final old = list[index];
        list[index] = HostelManager(
          id: old.id, hostelId: old.hostelId, userId: old.userId, userName: old.userName,
          status: old.status, permissions: Map<String, bool>.from(permissions), createdAt: old.createdAt,
        );
        _demoManagers[hostelId] = list;
      }
      return;
    }
    await _db.collection('hostels').doc(hostelId).collection('managers').doc(userId).update({
      'permissions': permissions,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeManager(String hostelId, String userId) async {
    if (!FirebaseService.initialized) {
      final list = _demoManagers[hostelId];
      list?.removeWhere((item) => item.userId == userId);
      return;
    }
    await _db.collection('hostels').doc(hostelId).collection('managers').doc(userId).update({
      'status': 'revoked',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<HostelClaim>> watchOwnerClaims(String userId) {
    if (!FirebaseService.initialized) {
      return Stream.value(
        _demoClaims.values.where((claim) => claim.userId == userId).toList(),
      );
    }
    return _db.collection('hostelClaims').where('userId', isEqualTo: userId).snapshots().map(
      (s) => s.docs.map(HostelClaim.fromDoc).toList(),
    );
  }

  Future<HostelClaim?> getMyClaim(String hostelId, String userId) async {
    final claimId = '${hostelId}_${userId}';
    if (!FirebaseService.initialized) {
      return _demoClaims['demo-claim-$hostelId-$userId'];
    }
    final doc = await _db.collection('hostelClaims').doc(claimId).get();
    return doc.exists ? HostelClaim.fromDoc(doc) : null;
  }

  /// Manager updates are section-based so owner-only fields stay protected.
  Future<void> updateHostelSectionSafe({
    required Hostel hostel,
    required String userId,
    required String permission,
    required Map<String, dynamic> changes,
  }) async {
    if (changes.isEmpty) return;
    if (userId.trim().isEmpty) throw StateError('User identity is required.');

    final allowedByPermission = <String, Set<String>>{
      HostelManagerPermissions.basicInfo: {'name', 'type', 'gender', 'description'},
      HostelManagerPermissions.location: {'city', 'area', 'distance', 'address'},
      HostelManagerPermissions.pricing: {'price', 'securityFee', 'roomType'},
      HostelManagerPermissions.rooms: {'rooms'},
      HostelManagerPermissions.photos: {'imageUrl', 'imageUrls'},
      HostelManagerPermissions.facilities: {'facilities', 'meals', 'ac'},
      HostelManagerPermissions.rules: {'rules'},
      HostelManagerPermissions.availability: {'availability'},
      HostelManagerPermissions.contact: {'phone', 'website'},
    };
    final allowedKeys = allowedByPermission[permission] ?? <String>{};
    if (allowedKeys.isEmpty || changes.keys.any((key) => !allowedKeys.contains(key))) {
      throw StateError('This section contains fields outside its permission.');
    }

    final isOwner = hostel.ownerId == userId;
    final isDemoHostel = _demoHostels.any((item) => item.id == hostel.id);
    if (!isOwner) {
      final manager = await getManager(hostel.id, userId);
      if (manager == null || !manager.can(permission)) {
        throw StateError('You do not have permission to edit this section.');
      }
    }

    if (isDemoHostel || !FirebaseService.initialized) {
      final index = _demoHostels.indexWhere((item) => item.id == hostel.id);
      if (index < 0) throw StateError('Hostel not found.');
      _demoHostels[index] = _applyDemoChanges(_demoHostels[index], changes);
      return;
    }
    await _collection.doc(hostel.id).update({
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Hostel _applyDemoChanges(Hostel hostel, Map<String, dynamic> changes) {
    return Hostel(
      id: hostel.id,
      name: (changes['name'] ?? hostel.name).toString(),
      city: (changes['city'] ?? hostel.city).toString(),
      area: (changes['area'] ?? hostel.area).toString(),
      type: (changes['type'] ?? hostel.type).toString(),
      gender: (changes['gender'] ?? hostel.gender).toString(),
      distance: (changes['distance'] ?? hostel.distance).toString(),
      price: (changes['price'] ?? hostel.price).toString(),
      securityFee: (changes['securityFee'] ?? hostel.securityFee).toString(),
      roomType: (changes['roomType'] ?? hostel.roomType).toString(),
      availability: (changes['availability'] ?? hostel.availability).toString(),
      meals: (changes['meals'] ?? hostel.meals).toString(),
      ac: changes['ac'] is bool ? changes['ac'] as bool : hostel.ac,
      facilities: changes['facilities'] is List
          ? List<String>.from((changes['facilities'] as List).map((e) => e.toString()))
          : hostel.facilities,
      imageUrls: changes['imageUrls'] is List
          ? List<String>.from((changes['imageUrls'] as List).map((e) => e.toString()))
          : hostel.imageUrls,
      description: (changes['description'] ?? hostel.description).toString(),
      phone: (changes['phone'] ?? hostel.phone).toString(),
      website: (changes['website'] ?? hostel.website).toString(),
      imageUrl: (changes['imageUrl'] ?? hostel.imageUrl).toString(),
      address: (changes['address'] ?? hostel.address).toString(),
      ownerId: hostel.ownerId,
      ownerName: hostel.ownerName,
      status: hostel.status,
      isVerified: hostel.isVerified,
      isDemo: hostel.isDemo,
      rating: hostel.rating,
      reviewCount: hostel.reviewCount,
      ratingTotal: hostel.ratingTotal,
      rooms: changes['rooms'] is List
          ? List<HostelRoom>.from(changes['rooms'] as List)
          : hostel.rooms,
      rules: changes['rules'] is List
          ? List<String>.from((changes['rules'] as List).map((e) => e.toString()))
          : hostel.rules,
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
    if (rating < 1 || rating > 5) throw ArgumentError('Rating must be between 1 and 5');
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
