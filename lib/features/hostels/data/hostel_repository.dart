import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hostel.dart';
import 'hostel_seed_data.dart';

class HostelRepository {
  HostelRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('hostels');

  Stream<List<Hostel>> watchHostels() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Hostel.fromDoc).toList());
  }

  /// Adds the bundled examples only when the collection is empty.
  ///
  /// This is safe to call whenever the Hostels screen opens: existing hostel
  /// records are never overwritten and demo records are not duplicated.
  Future<void> seedDemoDataIfEmpty() async {
    final snapshot = await _collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final hostel in exampleHostels) {
      final ref = _collection.doc(hostel.id);
      batch.set(ref, {
        ...hostel.toMap(),
        'isDemo': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<String> addHostel(Hostel hostel) async {
    final ref = await _collection.add({
      ...hostel.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateHostel(Hostel hostel) {
    return _collection.doc(hostel.id).update({
      ...hostel.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteHostel(String hostelId) {
    return _collection.doc(hostelId).delete();
  }
}
