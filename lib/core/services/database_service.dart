import 'package:cloud_firestore/cloud_firestore.dart';
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String,dynamic>> collection(String name) => _db.collection(name);
}
