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
  final List<Map<String, dynamic>> rooms;
  final String description;
  final String phone;
  final String website;
  final String imageUrl;
  final String address;
  final String ownerId;
  final String ownerName;
  final String status;
  final bool isVerified;
  final bool isDemo;
  final double rating;
  final int reviewCount;
  final double ratingTotal;

  const Hostel({required this.id, required this.name, required this.city, required this.area, this.type='Private', this.gender='Male', this.distance='', this.price='', this.securityFee='', this.roomType='', this.availability='', this.meals='', this.ac=false, this.facilities=const [], this.imageUrls=const [], this.rooms=const [], this.description='', this.phone='', this.website='', this.imageUrl='', this.address='', this.ownerId='', this.ownerName='', this.status='approved', this.isVerified=false, this.isDemo=false, this.rating=0, this.reviewCount=0, this.ratingTotal=0});

  factory Hostel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data=doc.data()??{}; final rawImages=data['imageUrls'];
    return Hostel(id:doc.id,name:(data['name']??'').toString(),city:(data['city']??'').toString(),area:(data['area']??'').toString(),type:(data['type']??'Private').toString(),gender:(data['gender']??'Male').toString(),distance:(data['distance']??'').toString(),price:(data['price']??'').toString(),securityFee:(data['securityFee']??'').toString(),roomType:(data['roomType']??'').toString(),availability:(data['availability']??'').toString(),meals:(data['meals']??'').toString(),ac:data['ac']==true,facilities:List<String>.from((data['facilities']??const []).map((e)=>e.toString())),imageUrl:(data['imageUrl']??'').toString(),imageUrls:rawImages is List?List<String>.from(rawImages.map((e)=>e.toString())):const [],rooms:data['rooms'] is List?(data['rooms'] as List).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList():const [],description:(data['description']??'').toString(),phone:(data['phone']??'').toString(),website:(data['website']??'').toString(),address:(data['address']??'').toString(),ownerId:(data['ownerId']??'').toString(),ownerName:(data['ownerName']??'').toString(),status:(data['status']??'approved').toString(),isVerified:data['isVerified']==true,isDemo:data['isDemo']==true,rating:(data['rating'] as num?)?.toDouble()??0,reviewCount:(data['reviewCount'] as num?)?.toInt()??0,ratingTotal:(data['ratingTotal'] as num?)?.toDouble()??0);
  }

  Map<String,dynamic> toMap()=>{'name':name,'city':city,'area':area,'type':type,'gender':gender,'distance':distance,'price':price,'securityFee':securityFee,'roomType':roomType,'availability':availability,'meals':meals,'ac':ac,'facilities':facilities,'imageUrl':imageUrl,'imageUrls':imageUrls,'rooms':rooms,'description':description,'phone':phone,'website':website,'address':address,'ownerId':ownerId,'ownerName':ownerName,'status':status,'isVerified':isVerified,'isDemo':isDemo,'rating':rating,'reviewCount':reviewCount,'ratingTotal':ratingTotal};
}
