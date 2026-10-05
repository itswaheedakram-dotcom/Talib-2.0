import 'package:cloud_firestore/cloud_firestore.dart';

class Hostel {
  final String id;
  final String name;
  final String city;
  final String area;
  final String type;
  final String gender;
  final String distance;
  final String price;
  final String securityFee;
  final String roomType;
  final String availability;
  final String meals;
  final bool ac;
  final List<String> facilities;
  final List<String> imageUrls;
  final String description;
  final String phone;
  final String imageUrl;
  final String address;

  const Hostel({
    required this.id,
    required this.name,
    required this.city,
    required this.area,
    this.type = 'Private',
    this.gender = 'Male',
    this.distance = '',
    this.price = '',
    this.securityFee = '',
    this.roomType = '',
    this.availability = '',
    this.meals = '',
    this.ac = false,
    this.facilities = const [],
    this.description = '',
    this.phone = '',
    this.imageUrl = '',
    this.imageUrls = const [],
    this.address = '',
  });

  factory Hostel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Hostel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      area: (data['area'] ?? '').toString(),
      type: (data['type'] ?? 'Private').toString(),
      gender: (data['gender'] ?? 'Male').toString(),
      distance: (data['distance'] ?? '').toString(),
      price: (data['price'] ?? '').toString(),
      securityFee: (data['securityFee'] ?? '').toString(),
      roomType: (data['roomType'] ?? '').toString(),
      availability: (data['availability'] ?? '').toString(),
      meals: (data['meals'] ?? '').toString(),
      ac: data['ac'] == true,
      facilities: List<String>.from((data['facilities'] ?? const []).map((e) => e.toString())),
      description: (data['description'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      imageUrls: data['imageUrls'] is List ? List<String>.from((data['imageUrls'] as List).map((e) => e.toString())) : const [],
      address: (data['address'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'city': city,
    'area': area,
    'type': type,
    'gender': gender,
    'distance': distance,
    'price': price,
    'securityFee': securityFee,
    'roomType': roomType,
    'availability': availability,
    'meals': meals,
    'ac': ac,
    'facilities': facilities,
    'description': description,
    'phone': phone,
    'imageUrl': imageUrl,
    'imageUrls': imageUrls,
    'address': address,
  };
}
