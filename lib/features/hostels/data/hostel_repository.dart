import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hostel.dart';
import 'hostel_seed_data.dart';
import 'hostel_review.dart';

class HostelRepository {
  HostelRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _collection => _db.collection('hostels');

  Stream<List<Hostel>> watchHostels() => _collection.snapshots().map((s) => s.docs.map(Hostel.fromDoc).where((h) => h.status == 'approved').toList()..sort((a,b) => a.name.compareTo(b.name)));
  Stream<List<Hostel>> watchOwnerHostels(String ownerId) => _collection.where('ownerId', isEqualTo: ownerId).snapshots().map((s) => s.docs.map(Hostel.fromDoc).toList()..sort((a,b) => a.name.compareTo(b.name)));

  Stream<List<HostelReview>> watchReviews(String hostelId) => _collection.doc(hostelId).collection('reviews').orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(HostelReview.fromDoc).toList());

  Future<HostelReview?> getMyReview(String hostelId, String userId) async {
    final doc = await _collection.doc(hostelId).collection('reviews').doc(userId).get();
    return doc.exists ? HostelReview.fromDoc(doc) : null;
  }

  Future<void> submitReview({required String hostelId, required String userId, required String userName, required double rating, required String comment}) async {
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
