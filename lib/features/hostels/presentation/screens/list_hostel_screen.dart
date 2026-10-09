import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../data/hostel_registry.dart';
import '../../data/hostel_repository.dart';
import '../../data/hostel_room.dart';
import '../../../models/hostel.dart';

class ListHostelScreen extends StatefulWidget {
  const ListHostelScreen({super.key});
  @override State<ListHostelScreen> createState() => _ListHostelScreenState();
}

class _ListHostelScreenState extends State<ListHostelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(), _city = TextEditingController(), _area = TextEditingController(), _address = TextEditingController();
  final _phone = TextEditingController(), _website = TextEditingController(), _description = TextEditingController();
  final _imageUrl = TextEditingController(), _imageUrls = TextEditingController(), _ruleInput = TextEditingController();
  String _gender = HostelRegistry.genders.first, _type = HostelRegistry.types.first, _meals = HostelRegistry.mealOptions.first;
  bool _saving = false;
  bool _uploadingImage = false;
  final List<String> _facilities = [], _rules = [];
  final List<_RoomDraft> _rooms = [];

  @override void dispose() {
    for (final c in [_name,_city,_area,_address,_phone,_website,_description,_imageUrl,_imageUrls,_ruleInput]) { c.dispose(); }
    for (final room in _rooms) { room.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    // FirebaseAuth.instance throws when Firebase has not been initialized.
    // Read auth only when Firebase is ready so demo submissions still work.
    final activeProfile = ActiveProfileController.instance.active;
    User? user;
    if (FirebaseService.initialized) {
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (_) {
        user = null;
      }
    }
    final demoMode = activeProfile != null || !FirebaseService.initialized;
    if (user == null && activeProfile == null && !demoMode) {
      if (mounted) context.push('/signin');
      return;
    }
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete the required fields: hostel name, city, area, address and phone.')),
        );
      }
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final rooms = _rooms.map((r) => r.toModel()).where((r) => r.type.trim().isNotEmpty).toList();
      final mainRoom = rooms.isNotEmpty ? rooms.first : null;
      final hostel = Hostel(
        id:'', name:_name.text.trim(), city:_city.text.trim(), area:_area.text.trim(), address:_address.text.trim(),
        type:_type, gender:_gender, price:mainRoom?.rent ?? '', securityFee:mainRoom?.securityFee ?? '',
        roomType:mainRoom?.type ?? '', availability:mainRoom == null ? '' : '\${mainRoom.availableBeds} beds available',
        meals:_meals, ac:rooms.any((r) => r.ac), facilities:List<String>.from(_facilities), rooms:rooms,
        rules:List<String>.from(_rules), phone:_phone.text.trim(), website:_website.text.trim(),
        imageUrl:_imageUrl.text.trim(), imageUrls:_imageUrls.text.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toSet().toList(),
        description:_description.text.trim(), ownerId:activeProfile?.id ?? user?.uid ?? 'demo-user',
        ownerName:activeProfile?.name ?? (user?.displayName?.trim().isNotEmpty==true ? user!.displayName!.trim() : 'Hostel Owner'), status:'pending',
      );
      await HostelRepository.submitHostelSafe(hostel, demo: demoMode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(demoMode ? 'Hostel request submitted for admin approval (Demo).' : 'Hostel submitted for admin approval.')));
      context.pop();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Hostel request failed: $error')));
    } finally { if (mounted) setState(() => _saving = false); }
  }


  Future<void> _pickAndUploadImage() async {
    if (ActiveProfileController.instance.isDemoActive || !FirebaseService.initialized) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo mode uses image URLs. Enable Firebase to upload hostel photos.')));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { if (mounted) context.push('/signin'); return; }
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82);
      if (picked == null) return;
      setState(() => _uploadingImage = true);
      final bytes = await picked.readAsBytes();
      final extension = picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : 'jpg';
      final ref = FirebaseStorage.instance.ref('hostels/' + user.uid + '/' + DateTime.now().millisecondsSinceEpoch.toString() + '.' + extension);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/' + extension));
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      setState(() => _imageUrl.text = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Main hostel photo uploaded.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo upload failed. You can paste an image URL instead.')));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AppColors.cream,
    appBar:AppBar(title:const Text('List Your Hostel')),
    body:Form(key:_formKey,child:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,32),children:[
      _intro(), const SizedBox(height:18),
      _section('Basic Information','Tell students what kind of hostel you are listing.',Icons.hotel_outlined),
      _field(_name,'Hostel Name',Icons.hotel_rounded,required:true),
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(child:_dropdown('For',_gender,HostelRegistry.genders,(v)=>setState(()=>_gender=v),Icons.people_alt_outlined)),
        const SizedBox(width:10),
        Expanded(child:_dropdown('Type',_type,HostelRegistry.types,(v)=>setState(()=>_type=v),Icons.apartment_outlined)),
      ]),
      const SizedBox(height:6),
      _section('Location','Make the hostel easy to find for students.',Icons.location_on_outlined),
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(child:_field(_city,'City',Icons.location_city_outlined,required:true)),
        const SizedBox(width:10),
        Expanded(child:_field(_area,'Area / Town',Icons.place_outlined,required:true)),
      ]),
      _field(_address,'Complete Address',Icons.map_outlined,required:true,maxLines:2),
      const SizedBox(height:6),
      _section('Rooms & Pricing','Add every room configuration students can choose from.',Icons.bed_outlined),
      _rooms.isEmpty ? _emptyRooms() : Column(children:[for(var i=0;i<_rooms.length;i++) _roomCard(i,_rooms[i])]),
      const SizedBox(height:8),
      OutlinedButton.icon(onPressed:_addRoom,icon:const Icon(Icons.add_rounded),label:const Text('Add Room Type')),
      const SizedBox(height:18),
      _section('Meals','Choose the meal arrangement offered by the hostel.',Icons.restaurant_outlined),
      _dropdown('Meals / Mess',_meals,HostelRegistry.mealOptions,(v)=>setState(()=>_meals=v),Icons.restaurant_menu_outlined),
      const SizedBox(height:6),
      _section('Facilities','Select everything that is available to residents.',Icons.apartment_outlined),
      _facilityChips(),
      const SizedBox(height:18),
      _section('Hostel Rules','Add important rules students should know before joining.',Icons.rule_outlined),
      _ruleComposer(),
      if(_rules.isNotEmpty) ...[const SizedBox(height:8),..._rules.asMap().entries.map((e)=>_ruleTile(e.key,e.value))],
      const SizedBox(height:18),
      _section('Gallery','Use direct image URLs for the main photo and gallery.',Icons.photo_library_outlined),
      _field(_imageUrl,'Main Photo URL (optional)',Icons.image_outlined,keyboard:TextInputType.url,onChanged:(_)=>setState((){})),
      Align(alignment:Alignment.centerLeft,child:OutlinedButton.icon(onPressed:_uploadingImage?null:_pickAndUploadImage,icon:_uploadingImage?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:AppColors.primaryGreen)):const Icon(Icons.upload_outlined),label:Text(_uploadingImage?'Uploading...':'Upload Main Photo'))),
      _imagePreview(),
      _field(_imageUrls,'Additional Photo URLs (comma separated)',Icons.collections_outlined,maxLines:2,keyboard:TextInputType.url),
      const SizedBox(height:6),
      _section('About the Hostel','Give students a clear overview of what makes this hostel useful.',Icons.description_outlined),
      _field(_description,'Description',Icons.notes_outlined,maxLines:5),
      const SizedBox(height:6),
      _section('Contact','These details will appear at the end of the hostel profile.',Icons.contact_phone_outlined),
      _field(_phone,'Phone / WhatsApp',Icons.phone_outlined,required:true,keyboard:TextInputType.phone),
      _field(_website,'Website (optional)',Icons.language_outlined,keyboard:TextInputType.url),
      const SizedBox(height:8), _approvalNotice(), const SizedBox(height:18),
      SizedBox(height:52,child:FilledButton.icon(
        onPressed:_saving?null:_submit,
        style:FilledButton.styleFrom(backgroundColor:AppColors.primaryGreen,foregroundColor:AppColors.white),
        icon:_saving?const SizedBox(width:19,height:19,child:CircularProgressIndicator(strokeWidth:2,color:AppColors.white)):const Icon(Icons.send_outlined),
        label:Text(_saving?'Submitting...':'Submit for Approval'),
      )),
    ])));

  Widget _intro()=>Container(
    padding:const EdgeInsets.all(17),
    decoration:BoxDecoration(color:AppColors.white,borderRadius:BorderRadius.circular(18)),
    child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      CircleAvatar(radius:26,backgroundColor:AppColors.softGreen,child:Icon(Icons.hotel_rounded,color:AppColors.primaryGreen,size:29)),
      SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Reach students looking for accommodation',style:TextStyle(color:AppColors.darkGreen,fontSize:16,fontWeight:FontWeight.w700)),
        SizedBox(height:5),Text('Add complete and accurate information so students can compare your hostel with confidence.',style:TextStyle(color:AppColors.mutedText,height:1.35)),
      ])),
    ]),
  );

  Widget _section(String title,String subtitle,IconData icon)=>Padding(
    padding:const EdgeInsets.only(bottom:11),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Container(width:38,height:38,decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(11)),child:Icon(icon,color:AppColors.primaryGreen,size:21)),
      const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(color:AppColors.darkGreen,fontSize:17,fontWeight:FontWeight.w700)),
        const SizedBox(height:2),Text(subtitle,style:const TextStyle(color:AppColors.mutedText,fontSize:12.5,height:1.3)),
      ])),
    ]),
  );

  Widget _field(TextEditingController c,String label,IconData icon,{bool required=false,int maxLines=1,TextInputType? keyboard,ValueChanged<String>? onChanged})=>Padding(
    padding:const EdgeInsets.only(bottom:12),
    child:TextFormField(controller:c,maxLines:maxLines,keyboardType:keyboard,onChanged:onChanged,
      validator:required?(v)=>v==null||v.trim().isEmpty?'Required':null:null,
      decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon))),
  );

  Widget _dropdown(String label,String value,List<String> items,ValueChanged<String> onChanged,IconData icon)=>Padding(
    padding:const EdgeInsets.only(bottom:12),
    child:DropdownButtonFormField<String>(
      value:value,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon)),
      items:items.map((e)=>DropdownMenuItem(value:e,child:Text(e,overflow:TextOverflow.ellipsis))).toList(),
      onChanged:(v){if(v!=null)onChanged(v);},
    ),
  );

  Widget _emptyRooms()=>Container(
    padding:const EdgeInsets.all(16),
    decoration:BoxDecoration(color:AppColors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:AppColors.softGreen)),
    child:const Row(children:[
      Icon(Icons.bed_outlined,color:AppColors.primaryGreen),SizedBox(width:10),
      Expanded(child:Text('No room types added yet. Add at least one room to show structured rent and bed availability.',style:TextStyle(color:AppColors.mutedText,height:1.35))),
    ]),
  );

  Widget _roomCard(int index,_RoomDraft room)=>Container(
    margin:const EdgeInsets.only(bottom:12),
    padding:const EdgeInsets.fromLTRB(14,14,14,6),
    decoration:BoxDecoration(color:AppColors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:AppColors.softGreen)),
    child:Column(children:[
      Row(children:[
        const Icon(Icons.bed_outlined,color:AppColors.primaryGreen),const SizedBox(width:8),
        Expanded(child:Text('Room \${index + 1}',style:const TextStyle(color:AppColors.darkGreen,fontWeight:FontWeight.w700))),
        IconButton(tooltip:'Remove room',onPressed:()=>_removeRoom(index),icon:const Icon(Icons.delete_outline)),
      ]),
      _dropdown('Room Type',room.type,HostelRegistry.roomTypes,(v)=>setState(()=>room.type=v),Icons.meeting_room_outlined),
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(child:_field(room.rent,'Monthly Rent',Icons.payments_outlined)),
        const SizedBox(width:10),Expanded(child:_field(room.security,'Security Fee',Icons.account_balance_wallet_outlined)),
      ]),
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Expanded(child:_field(room.totalBeds,'Total Beds',Icons.groups_outlined,keyboard:TextInputType.number)),
        const SizedBox(width:10),Expanded(child:_field(room.availableBeds,'Available Beds',Icons.event_available_outlined,keyboard:TextInputType.number)),
      ]),
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('AC available'),value:room.ac,onChanged:(v)=>setState(()=>room.ac=v),activeColor:AppColors.primaryGreen),
      _field(room.notes,'Room notes (optional)',Icons.notes_outlined,maxLines:2),
    ]),
  );

  Widget _facilityChips()=>Container(
    padding:const EdgeInsets.fromLTRB(12,12,12,4),
    decoration:BoxDecoration(color:AppColors.white,borderRadius:BorderRadius.circular(15)),
    child:Wrap(spacing:8,runSpacing:8,children:HostelRegistry.commonFacilities.map((f){
      final selected=_facilities.contains(f);
      return FilterChip(label:Text(f),selected:selected,onSelected:(v){setState((){if(v){_facilities.add(f);}else{_facilities.remove(f);}});},selectedColor:AppColors.softGreen,checkmarkColor:AppColors.primaryGreen);
    }).toList()),
  );

  Widget _ruleComposer()=>Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Expanded(child:TextField(controller:_ruleInput,textInputAction:TextInputAction.done,onSubmitted:(_)=>_addRule(),decoration:const InputDecoration(labelText:'Add a rule',prefixIcon:Icon(Icons.rule_outlined)))),
    const SizedBox(width:8),SizedBox(height:52,child:FilledButton(onPressed:_addRule,style:FilledButton.styleFrom(backgroundColor:AppColors.primaryGreen,foregroundColor:AppColors.white,padding:const EdgeInsets.symmetric(horizontal:16)),child:const Icon(Icons.add_rounded))),
  ]);

  Widget _ruleTile(int index,String rule)=>Container(
    margin:const EdgeInsets.only(bottom:7),
    decoration:BoxDecoration(color:AppColors.white,borderRadius:BorderRadius.circular(12)),
    child:ListTile(dense:true,leading:const Icon(Icons.check_circle_outline,color:AppColors.primaryGreen),title:Text(rule),trailing:IconButton(tooltip:'Remove rule',onPressed:()=>setState(()=>_rules.removeAt(index)),icon:const Icon(Icons.close_rounded))),
  );

  Widget _imagePreview(){
    final url=_imageUrl.text.trim();
    if(url.isEmpty)return const SizedBox.shrink();
    return Padding(
      padding:const EdgeInsets.only(bottom:12),
      child:ClipRRect(borderRadius:BorderRadius.circular(14),child:AspectRatio(aspectRatio:16/7,child:Image.network(
        url,fit:BoxFit.cover,
        errorBuilder:(_,__,___)=>Container(color:AppColors.softGreen,alignment:Alignment.center,child:const Text('Image preview unavailable',style:TextStyle(color:AppColors.mutedText))),
        loadingBuilder:(context,child,progress)=>progress==null?child:const Center(child:CircularProgressIndicator(color:AppColors.primaryGreen)),
      ))),
    );
  }

  Widget _approvalNotice()=>Container(
    padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(15)),
    child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Icon(Icons.verified_user_outlined,color:AppColors.primaryGreen),SizedBox(width:9),
      Expanded(child:Text('Your listing will stay private until an admin reviews and approves it. After approval, students can discover the hostel through search and filters.',style:TextStyle(color:AppColors.darkGreen,height:1.35))),
    ]),
  );

  void _addRoom()=>setState(()=>_rooms.add(_RoomDraft()));
  void _removeRoom(int index){final room=_rooms.removeAt(index);room.dispose();setState((){});}
  void _addRule(){
    final value=_ruleInput.text.trim();
    if(value.isEmpty)return;
    if(_rules.contains(value)){_ruleInput.clear();return;}
    setState((){_rules.add(value);_ruleInput.clear();});
  }
}

class _RoomDraft {
  String type=HostelRegistry.roomTypes.first;
  bool ac=false;
  final rent=TextEditingController(), security=TextEditingController(), totalBeds=TextEditingController(), availableBeds=TextEditingController(), notes=TextEditingController();

  HostelRoom toModel()=>HostelRoom(
    id:'',type:type,rent:rent.text.trim(),securityFee:security.text.trim(),
    totalBeds:int.tryParse(totalBeds.text.trim())??0,availableBeds:int.tryParse(availableBeds.text.trim())??0,
    ac:ac,notes:notes.text.trim(),
  );

  void dispose(){rent.dispose();security.dispose();totalBeds.dispose();availableBeds.dispose();notes.dispose();}
}
