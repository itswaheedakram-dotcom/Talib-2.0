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
  final List<String> facilities;
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
    this.facilities = const [],
    this.description = '',
    this.phone = '',
    this.imageUrl = '',
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
      facilities: List<String>.from((data['facilities'] ?? const []).map((e) => e.toString())),
      description: (data['description'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
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
    'facilities': facilities,
    'description': description,
    'phone': phone,
    'imageUrl': imageUrl,
    'address': address,
  };
}
