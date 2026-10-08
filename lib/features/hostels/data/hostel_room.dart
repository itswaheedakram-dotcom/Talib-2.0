import 'package:cloud_firestore/cloud_firestore.dart';

/// A room configuration inside a hostel.
///
/// Keeping rooms as structured records lets us later manage rent and bed
/// availability without parsing display strings such as "6 beds available".
class HostelRoom {
  final String id;
  final String type;
  final String rent;
  final String securityFee;
  final int totalBeds;
  final int availableBeds;
  final bool ac;
  final String notes;

  const HostelRoom({
    this.id = '',
    required this.type,
    this.rent = '',
    this.securityFee = '',
    this.totalBeds = 0,
    this.availableBeds = 0,
    this.ac = false,
    this.notes = '',
  });

  factory HostelRoom.fromMap(Map<String, dynamic> data) {
    return HostelRoom(
      id: (data['id'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      rent: (data['rent'] ?? '').toString(),
      securityFee: (data['securityFee'] ?? '').toString(),
      totalBeds: (data['totalBeds'] as num?)?.toInt() ?? 0,
      availableBeds: (data['availableBeds'] as num?)?.toInt() ?? 0,
      ac: data['ac'] == true,
      notes: (data['notes'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'rent': rent,
    'securityFee': securityFee,
    'totalBeds': totalBeds,
    'availableBeds': availableBeds,
    'ac': ac,
    'notes': notes,
  };
}
