import 'package:cloud_firestore/cloud_firestore.dart';

class HostelClaim {
  final String id;
  final String hostelId;
  final String hostelName;
  final String userId;
  final String userName;
  final String contact;
  final String note;
  final String status;
  final DateTime? createdAt;

  const HostelClaim({
    required this.id,
    required this.hostelId,
    required this.hostelName,
    required this.userId,
    required this.userName,
    required this.contact,
    required this.note,
    required this.status,
    this.createdAt,
  });

  factory HostelClaim.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final raw = data['createdAt'];
    return HostelClaim(
      id: doc.id,
      hostelId: (data['hostelId'] ?? '').toString(),
      hostelName: (data['hostelName'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? 'Member').toString(),
      contact: (data['contact'] ?? '').toString(),
      note: (data['note'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      createdAt: raw is Timestamp ? raw.toDate() : null,
    );
  }
}