import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../data/hostel_repository.dart';
import '../../../models/hostel.dart';

class ListHostelScreen extends StatefulWidget {
  const ListHostelScreen({super.key});
  @override State<ListHostelScreen> createState() => _ListHostelScreenState();
}

class _ListHostelScreenState extends State<ListHostelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(), _city = TextEditingController(), _area = TextEditingController(), _address = TextEditingController();
  final _price = TextEditingController(), _security = TextEditingController(), _room = TextEditingController(), _availability = TextEditingController();
  final _meals = TextEditingController(), _phone = TextEditingController(), _website = TextEditingController(), _facilities = TextEditingController();
  final _description = TextEditingController(), _imageUrl = TextEditingController(), _imageUrls = TextEditingController();
  String _gender = 'Male', _type = 'Private';
  bool _ac = false, _saving = false;

  @override void dispose() { for (final c in [_name,_city,_area,_address,_price,_security,_room,_availability,_meals,_phone,_website,_facilities,_description,_imageUrl,_imageUrls]) { c.dispose(); } super.dispose(); }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { if (mounted) context.push('/signin'); return; }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final hostel = Hostel(id:'', name:_name.text.trim(), city:_city.text.trim(), area:_area.text.trim(), address:_address.text.trim(), price:_price.text.trim(), securityFee:_security.text.trim(), roomType:_room.text.trim(), availability:_availability.text.trim(), meals:_meals.text.trim(), phone:_phone.text.trim(), website:_website.text.trim(), facilities:_facilities.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toSet().toList(), description:_description.text.trim(), imageUrl:_imageUrl.text.trim(), imageUrls:_imageUrls.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toSet().toList(), gender:_gender, type:_type, ac:_ac, ownerId:user.uid, ownerName:user.displayName?.trim().isNotEmpty==true?user.displayName!.trim():'Hostel Owner', status:'pending');
      await HostelRepository().submitHostel(hostel);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Hostel submitted for admin approval.')));
      context.pop();
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Hostel could not be submitted. Please try again.'))); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AppColors.cream,
    appBar:AppBar(title:const Text('List Your Hostel')),
    body:Form(key:_formKey,child:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,30),children:[
      _intro(),const SizedBox(height:14),_section('Basic Information'),
      _field(_name,'Hostel Name',Icons.hotel_outlined,required:true),
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:_field(_city,'City',Icons.location_city_outlined,required:true)),const SizedBox(width:10),Expanded(child:_field(_area,'Area',Icons.place_outlined,required:true))]),
      _field(_address,'Complete Address',Icons.location_on_outlined,required:true),
      Row(children:[Expanded(child:_dropdown('For',_gender,['Male','Female','Both'],(v)=>setState(()=>_gender=v))),const SizedBox(width:10),Expanded(child:_dropdown('Type',_type,['Private','University'],(v)=>setState(()=>_type=v)))]),
      const SizedBox(height:4),_section('Rooms & Pricing'),_field(_price,'Monthly Rent',Icons.payments_outlined,required:true),_field(_security,'Security Fee',Icons.account_balance_wallet_outlined),_field(_room,'Room Type (e.g. 2-Seater)',Icons.bed_outlined,required:true),_field(_availability,'Availability (e.g. 6 beds)',Icons.event_available_outlined),_field(_meals,'Meals / Mess Details',Icons.restaurant_outlined),
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Air Conditioning (AC)'),value:_ac,onChanged:(v)=>setState(()=>_ac=v),activeColor:AppColors.primaryGreen),
      const SizedBox(height:4),_section('Facilities & Contact'),_field(_facilities,'Facilities (comma separated)',Icons.apartment_outlined,maxLines:2),_field(_phone,'Phone / WhatsApp',Icons.phone_outlined,required:true,keyboard:TextInputType.phone),_field(_website,'Website (optional)',Icons.language_outlined,keyboard:TextInputType.url),_field(_imageUrl,'Main Photo URL (optional)',Icons.image_outlined,keyboard:TextInputType.url),_field(_imageUrls,'Additional Photo URLs (comma separated, optional)',Icons.photo_library_outlined,maxLines:2,keyboard:TextInputType.url),_field(_description,'About Your Hostel',Icons.description_outlined,maxLines:4),
      const SizedBox(height:8),Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(14)),child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.verified_user_outlined,color:AppColors.primaryGreen),SizedBox(width:9),Expanded(child:Text('Your listing will stay private until an admin reviews and approves it. You can manage your listing after submission.',style:TextStyle(color:AppColors.darkGreen,height:1.35)))])),
      const SizedBox(height:18),SizedBox(height:50,child:FilledButton.icon(onPressed:_saving?null:_submit,style:FilledButton.styleFrom(backgroundColor:AppColors.primaryGreen,foregroundColor:AppColors.white),icon:_saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:AppColors.white)):const Icon(Icons.send_outlined),label:Text(_saving?'Submitting...':'Submit for Approval')))
    ])));

  Widget _intro()=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.white,borderRadius:BorderRadius.circular(16)),child:const Row(children:[CircleAvatar(radius:25,backgroundColor:AppColors.softGreen,child:Icon(Icons.hotel_rounded,color:AppColors.primaryGreen,size:28)),SizedBox(width:12),Expanded(child:Text('Reach students looking for accommodation. Add accurate details so your hostel can be reviewed and listed.',style:TextStyle(color:AppColors.darkGreen,height:1.35)))]));
  Widget _section(String title)=>Padding(padding:const EdgeInsets.only(bottom:10,top:5),child:Text(title,style:const TextStyle(color:AppColors.darkGreen,fontSize:17,fontWeight:FontWeight.w700)));
  Widget _field(TextEditingController c,String label,IconData icon,{bool required=false,int maxLines=1,TextInputType? keyboard})=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextFormField(controller:c,maxLines:maxLines,keyboardType:keyboard,validator:required?(v)=>v==null||v.trim().isEmpty?'Required':null:null,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon))));
  Widget _dropdown(String label,String value,List<String> items,ValueChanged<String> onChanged)=>DropdownButtonFormField<String>(value:value,decoration:InputDecoration(labelText:label,prefixIcon:const Icon(Icons.tune_outlined)),items:items.map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v){if(v!=null)onChanged(v);});
}
