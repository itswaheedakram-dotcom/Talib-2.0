import 'package:cloud_firestore/cloud_firestore.dart';

class HostelManagerPermissions {
  static const basicInfo = 'basicInfo';
  static const location = 'location';
  static const pricing = 'pricing';
  static const rooms = 'rooms';
  static const availability = 'availability';
  static const photos = 'photos';
  static const facilities = 'facilities';
  static const contact = 'contact';

  static const all = <String>[
    basicInfo, location, pricing, rooms, availability, photos, facilities, contact,
  ];

  static String label(String permission) {
    switch (permission) {
      case basicInfo: return 'Basic information';
      case location: return 'Location';
      case pricing: return 'Pricing';
      case rooms: return 'Rooms';
      case availability: return 'Availability';
      case photos: return 'Photos';
      case facilities: return 'Facilities & meals';
      case contact: return 'Contact & website';
      default: return permission;
    }
  }
}

class HostelManager {
  final String id;
  final String hostelId;
  final String userId;
  final String userName;
  final String status;
  final Map<String, bool> permissions;
  final DateTime? createdAt;

  const HostelManager({
    required this.id,
    required this.hostelId,
    required this.userId,
    required this.userName,
    required this.status,
    required this.permissions,
    this.createdAt,
  });

  bool can(String permission) => permissions[permission] == true;

  factory HostelManager.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawPermissions = data['permissions'];
    final permissions = <String, bool>{};
    if (rawPermissions is Map) {
      rawPermissions.forEach((key, value) {
        permissions[key.toString()] = value == true;
      });
    }
    final raw = data['createdAt'];
    return HostelManager(
      id: doc.id,
      hostelId: (data['hostelId'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? 'Manager').toString(),
      status: (data['status'] ?? 'active').toString(),
      permissions: permissions,
      createdAt: raw is Timestamp ? raw.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'hostelId': hostelId,
    'userId': userId,
    'userName': userName,
    'status': status,
    'permissions': permissions,
  };
}
