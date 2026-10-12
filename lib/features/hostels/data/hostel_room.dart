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
  final String rentBasis;
  final String securityPolicy;
  final int roomCount;

  const HostelRoom({
    this.id = '',
    required this.type,
    this.rent = '',
    this.securityFee = '',
    this.totalBeds = 0,
    this.availableBeds = 0,
    this.ac = false,
    this.notes = '',
    this.rentBasis = '',
    this.securityPolicy = 'Not specified',
    this.roomCount = 1,
  });

  String get rentLabel => rentBasis.isEmpty ? rent : 'PKR $rent / month / ${rentBasis == 'Per room' ? 'room' : 'bed'}';
  String? get validationError {
    if(type.trim().isEmpty)return 'Choose a room type.';
    final amount=double.tryParse(rent.replaceAll(',', ''));
    if(amount==null||!amount.isFinite||amount<=0)return 'Monthly rent must be a positive number.';
    if(!const ['Per bed','Per room'].contains(rentBasis))return 'Choose whether rent is per bed or per room.';
    final deposit=double.tryParse(securityFee.replaceAll(',', ''));
    if(deposit==null||!deposit.isFinite||deposit<0)return 'Security fee must be zero or a positive number.';
    if(roomCount<1||totalBeds<1)return 'Room quantity and total beds must be at least one.';
    if(availableBeds<0||availableBeds>totalBeds)return 'Available beds must be between zero and total beds.';
    return null;
  }

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
      rentBasis: (data['rentBasis'] ?? '').toString(),
      securityPolicy: (data['securityPolicy'] ?? 'Not specified').toString(),
      roomCount: (data['roomCount'] as num?)?.toInt() ?? 1,
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
    'rentBasis': rentBasis,
    'securityPolicy': securityPolicy,
    'roomCount': roomCount,
  };
}
