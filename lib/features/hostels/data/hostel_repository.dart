import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hostel.dart';

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
