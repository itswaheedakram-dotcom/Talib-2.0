import '../../../core/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostelManagerPermissions {
  static const basicInfo = 'basicInfo';
  static const location = 'location';
  static const pricing = 'pricing';
  static const rooms = 'rooms';
  static const availability = 'availability';
  static const photos = 'photos';
  static const facilities = 'facilities';
  static const rules = 'rules';
  static const contact = 'contact';

  static const labels = <String, String>{
    basicInfo: 'Basic information',
    location: 'Location',
    pricing: 'Pricing',
    rooms: 'Rooms',
    availability: 'Availability',
    photos: 'Photos',
    facilities: 'Facilities & meals',
    rules: 'Rules',
    contact: 'Contact information',
  };
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
      userId: (data[ProfileFields.userId] ?? '').toString(),
      userName: (data['userName'] ?? 'Manager').toString(),
      status: (data['status'] ?? 'active').toString(),
      permissions: permissions,
      createdAt: raw is Timestamp ? raw.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'hostelId': hostelId,
    ProfileFields.userId: userId,
    'userName': userName,
    'status': status,
    'permissions': permissions,
  };
}
