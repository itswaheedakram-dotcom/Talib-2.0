import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme.dart';
import '../../data/hostel_repository.dart';
import '../../data/hostel_review.dart';
import '../../../models/hostel.dart';

class HostelDetailScreen extends StatefulWidget {
  final Hostel hostel;
  const HostelDetailScreen({super.key, required this.hostel});
  @override State<HostelDetailScreen> createState() => _HostelDetailScreenState();
}

class _HostelDetailScreenState extends State<HostelDetailScreen> {
  final _repo = HostelRepository();
  int _page = 0;
  double _myRating = 0;
  final _comment = TextEditingController();
  bool _savingReview = false;
  HostelReview? _myReview;
  Hostel get hostel => widget.hostel;

  List<String> get _images {
    final images = <String>[...hostel.imageUrls];
    if (hostel.imageUrl.isNotEmpty && !images.contains(hostel.imageUrl)) images.insert(0, hostel.imageUrl);
    return images;
  }

  @override
  void initState() { super.initState(); _loadMyReview(); }
  @override
  void dispose() { _comment.dispose(); super.dispose(); }

  Future<void> _loadMyReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || hostel.id.isEmpty) return;
    final review = await _repo.getMyReview(hostel.id, user.uid);
    if (!mounted) return;
    setState(() { _myReview = review; _myRating = review?.rating ?? 0; _comment.text = review?.comment ?? ''; });
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to review this hostel.')));
      return;
    }
    if (_myRating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rating.')));
      return;
    }
    setState(() => _savingReview = true);
    try {
      await _repo.submitReview(hostelId: hostel.id, userId: user.uid, userName: user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : 'Member', rating: _myRating, comment: _comment.text.trim());
      await _loadMyReview();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your review has been saved.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review could not be saved. Please try again.')));
    } finally { if (mounted) setState(() => _savingReview = false); }
  }

  Future<void> _openWebsite() async {
    var value = hostel.website.trim(); if (value.isEmpty) return;
    if (!value.startsWith('http://') && !value.startsWith('https://')) value = 'https://$value';
    final uri = Uri.tryParse(value);
    if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  Future<void> _copyPhone() async { await Clipboard.setData(ClipboardData(text: hostel.phone)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number copied'))); }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Hostel Details')),
      body: ListView(padding: const EdgeInsets.only(bottom: 30), children: [
        Padding(padding: const EdgeInsets.fromLTRB(16,14,16,10), child: Row(children: [Expanded(child: Text(hostel.name, style: const TextStyle(color: AppColors.darkGreen,fontSize:24,fontWeight:FontWeight.w700))), _ratingSummary(hostel.rating, hostel.reviewCount)])),
        _gallery(images),
        Padding(padding: const EdgeInsets.fromLTRB(16,0,16,0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _title('Location'), _card([
            if (hostel.address.isNotEmpty) _row(Icons.location_on_outlined,'Address',hostel.address),
            if (hostel.area.isNotEmpty || hostel.city.isNotEmpty) _row(Icons.place_outlined,'Area',[hostel.area,hostel.city].where((e)=>e.isNotEmpty).join(', ')),
            if (hostel.distance.isNotEmpty) _row(Icons.near_me_outlined,'Distance',hostel.distance),
          ]),
          _title('Complete Details'), _card([
            _row(Icons.apartment_outlined,'Hostel Type',hostel.type), _row(Icons.people_outline,'For',hostel.gender),
            if (hostel.roomType.isNotEmpty) _row(Icons.bed_outlined,'Room Type',hostel.roomType),
            if (hostel.availability.isNotEmpty) _row(Icons.event_available_outlined,'Availability',hostel.availability),
            if (hostel.price.isNotEmpty) _row(Icons.payments_outlined,'Monthly Rent',hostel.price),
            if (hostel.securityFee.isNotEmpty) _row(Icons.account_balance_wallet_outlined,'Security Fee',hostel.securityFee),
            _row(Icons.ac_unit_outlined,'Air Conditioning',hostel.ac?'Available':'Not available'),
            if (hostel.meals.isNotEmpty) _row(Icons.restaurant_outlined,'Meals / Mess',hostel.meals),
          ]),
          if (hostel.facilities.isNotEmpty) ...[_title('Facilities'),_card([Wrap(spacing:8,runSpacing:8,children:hostel.facilities.map(_facility).toList())])],
          if (hostel.description.isNotEmpty) ...[_title('About Hostel'),_card([Text(hostel.description,style:const TextStyle(color:AppColors.mutedText,height:1.45,fontSize:14))])],
          if (hostel.ownerName.isNotEmpty && !hostel.isDemo) ...[_title('Listed By'),_card([_row(Icons.person_outline,'Owner',hostel.ownerName)])],
          _title('Reviews'), _reviewsCard(),
          if (hostel.phone.isNotEmpty || hostel.website.isNotEmpty) ...[_title('Contact'),_card([
            if (hostel.phone.isNotEmpty) _button(Icons.phone_outlined,hostel.phone,_copyPhone),
            if (hostel.phone.isNotEmpty && hostel.website.isNotEmpty) const SizedBox(height:8),
            if (hostel.website.isNotEmpty) _button(Icons.language_outlined,hostel.website,_openWebsite),
          ])],
        ])),
      ]),
    );
  }

  Widget _reviewsCard() => StreamBuilder<List<HostelReview>>(
    stream: hostel.id.isEmpty ? const Stream.empty() : _repo.watchReviews(hostel.id),
    builder: (context,snapshot) {
      final reviews=snapshot.data??const <HostelReview>[];
      return _card([
        Row(children:[_ratingSummary(hostel.rating,hostel.reviewCount),const Spacer(),if(FirebaseAuth.instance.currentUser!=null) TextButton(onPressed:_showReviewEditor,child:Text(_myReview==null?'Write review':'Edit review'))]),
        const SizedBox(height:12),
        if(reviews.isEmpty) const Text('No reviews yet. Be the first registered member to review this hostel.',style:TextStyle(color:AppColors.mutedText,height:1.4)),
        ...reviews.take(8).map((r)=>Padding(padding:const EdgeInsets.only(top:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(r.userName,style:const TextStyle(color:AppColors.darkGreen,fontWeight:FontWeight.w700))),_stars(r.rating)]),if(r.comment.isNotEmpty) Padding(padding:const EdgeInsets.only(top:5),child:Text(r.comment,style:const TextStyle(color:AppColors.mutedText,height:1.35)))]))),
      ]);
    },
  );

  Future<void> _showReviewEditor() async {
    final result=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,showDragHandle:true,backgroundColor:AppColors.cream,builder:(sheet)=>StatefulBuilder(builder:(context,setSheet)=>Padding(padding:EdgeInsets.fromLTRB(20,4,20,MediaQuery.of(context).viewInsets.bottom+20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Your Review',style:TextStyle(color:AppColors.darkGreen,fontSize:21,fontWeight:FontWeight.w700)),const SizedBox(height:12),Center(child:Wrap(children:List.generate(5,(i)=>IconButton(onPressed:()=>setSheet(()=>_myRating=i+1.0),icon:Icon(i<_myRating?Icons.star_rounded:Icons.star_border_rounded,color:AppColors.primaryGreen,size:32))))),TextField(controller:_comment,maxLines:4,decoration:const InputDecoration(labelText:'Review',hintText:'Share your experience')),const SizedBox(height:14),SizedBox(width:double.infinity,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:AppColors.primaryGreen,foregroundColor:AppColors.white),onPressed:_savingReview?null, onPressed: _savingReview ? null : () async { await _submitReview(); if(context.mounted) Navigator.pop(context,true); },child:Text(_savingReview?'Saving...':'Submit review')))]))); if(result==true&&mounted)setState((){});
  }

  Widget _ratingSummary(double rating,int count)=>Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.star_rounded,color:AppColors.primaryGreen,size:19),const SizedBox(width:3),Text(rating>0?rating.toStringAsFixed(1):'New',style:const TextStyle(color:AppColors.darkGreen,fontWeight:FontWeight.w700,fontSize:12)),if(count>0) Text(' ($count)',style:const TextStyle(color:AppColors.mutedText,fontSize:11))]);
  Widget _stars(double rating)=>Row(mainAxisSize:MainAxisSize.min,children:List.generate(5,(i)=>Icon(i<rating.round()?Icons.star_rounded:Icons.star_border_rounded,color:AppColors.primaryGreen,size:16)));
  Widget _gallery(List<String> images)=>Column(children:[Container(margin:const EdgeInsets.symmetric(horizontal:16),height:235,decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(18)),clipBehavior:Clip.antiAlias,child:images.isEmpty?const Center(child:Icon(Icons.hotel_rounded,color:AppColors.primaryGreen,size:72)):PageView.builder(itemCount:images.length,onPageChanged:(i)=>setState(()=>_page=i),itemBuilder:(_,i)=>Image.network(images[i],fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Center(child:Icon(Icons.broken_image_outlined,color:AppColors.primaryGreen,size:48))))),if(images.length>1)Padding(padding:const EdgeInsets.only(top:8),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(images.length,(i)=>Container(width:7,height:7,margin:const EdgeInsets.symmetric(horizontal:3),decoration:BoxDecoration(color:i==_page?AppColors.primaryGreen:AppColors.divider,shape:BoxShape.circle))))]);
  Widget _title(String t)=>Padding(padding:const EdgeInsets.fromLTRB(0,18,0,8),child:Text(t,style:const TextStyle(color:AppColors.darkGreen,fontSize:17,fontWeight:FontWeight.w700)));
  Widget _card(List<Widget> c)=>Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:AppColors.white,borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:c));
  Widget _row(IconData i,String l,String v)=>Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i,color:AppColors.primaryGreen,size:20),const SizedBox(width:11),Expanded(child:RichText(text:TextSpan(children:[TextSpan(text:'$l\n',style:const TextStyle(color:AppColors.mutedText,fontSize:11,fontWeight:FontWeight.w600)),TextSpan(text:v,style:const TextStyle(color:AppColors.darkGreen,fontSize:14,height:1.25))])))]));
  Widget _facility(String v)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(10)),child:Text(v,style:const TextStyle(color:AppColors.darkGreen,fontSize:12,fontWeight:FontWeight.w600)));
  Widget _button(IconData i,String label,VoidCallback onPressed)=>SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:onPressed,style:OutlinedButton.styleFrom(foregroundColor:AppColors.primaryGreen,side:const BorderSide(color:AppColors.divider),padding:const EdgeInsets.symmetric(vertical:13)),icon:Icon(i),label:Text(label,maxLines:1,overflow:TextOverflow.ellipsis)));
}
