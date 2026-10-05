import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../data/hostel_repository.dart';
import '../../data/hostel_seed_data.dart';
import '../../../models/hostel.dart';

class HostelsScreen extends StatefulWidget {
  const HostelsScreen({super.key});
  @override State<HostelsScreen> createState() => _HostelsScreenState();
}

class _HostelsScreenState extends State<HostelsScreen> {
  final _searchController = TextEditingController();
  HostelRepository? _repository;
  StreamSubscription<List<Hostel>>? _hostelSubscription;
  List<Hostel> _hostels = List<Hostel>.from(exampleHostels);
  String _city = 'All', _gender = 'All', _type = 'All', _roomType = 'All', _sort = 'Recommended';
  bool _acOnly = false;

  @override void initState() { super.initState(); _connectToFirestore(); }
  Future<void> _connectToFirestore() async {
    try {
      final repository = HostelRepository(); _repository = repository;
      await repository.seedDemoDataIfEmpty();
      _hostelSubscription = repository.watchHostels().listen((hostels) {
        if (!mounted) return;
        setState(() => _hostels = hostels.isEmpty ? List<Hostel>.from(exampleHostels) : hostels);
      }, onError: (_) {});
    } catch (_) {}
  }
  @override void dispose() { _hostelSubscription?.cancel(); _searchController.dispose(); super.dispose(); }

  List<Hostel> _filter(List<Hostel> hostels) {
    final query = _searchController.text.trim().toLowerCase();
    final result = hostels.where((item) {
      final text = [item.name,item.city,item.area,item.type,item.gender,item.price,item.roomType,item.availability,item.meals,item.description,item.address,...item.facilities].join(' ').toLowerCase();
      return (query.isEmpty || text.contains(query)) && (_city == 'All' || item.city == _city) && (_gender == 'All' || item.gender == _gender) && (_type == 'All' || item.type == _type) && (_roomType == 'All' || item.roomType == _roomType) && (!_acOnly || item.ac);
    }).toList();
    if (_sort == 'Price: Low') result.sort((a,b)=>_price(a.price).compareTo(_price(b.price)));
    if (_sort == 'Nearest') result.sort((a,b)=>_distance(a.distance).compareTo(_distance(b.distance)));
    return result;
  }
  int _price(String value) => int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999999999;
  double _distance(String value) => double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 999999;
  List<String> _values(List<Hostel> hostels,String Function(Hostel) value) { final values=hostels.map(value).where((v)=>v.trim().isNotEmpty).toSet().toList()..sort(); return ['All',...values]; }
  bool get _hasActiveFilters => _city!='All'||_gender!='All'||_type!='All'||_roomType!='All'||_acOnly||_sort!='Recommended';
  void _clearFilters()=>setState((){_city='All';_gender='All';_type='All';_roomType='All';_acOnly=false;_sort='Recommended';});

  void _showFilters({required List<String> cities,required List<String> genders,required List<String> types,required List<String> rooms}) {
    var city=_city,gender=_gender,type=_type,roomType=_roomType,sort=_sort; var acOnly=_acOnly;
    showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,backgroundColor:AppColors.cream,builder:(sheetContext)=>StatefulBuilder(builder:(context,setSheetState)=>SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,4,20,20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Expanded(child:Text('Filters',style:TextStyle(color:AppColors.darkGreen,fontSize:22,fontWeight:FontWeight.w700))),if(city!='All'||gender!='All'||type!='All'||roomType!='All'||acOnly||sort!='Recommended')TextButton(onPressed:()=>setSheetState((){city='All';gender='All';type='All';roomType='All';acOnly=false;sort='Recommended';}),child:const Text('Clear'))]),
      const SizedBox(height:16),_filterSection('City',cities,city,(v)=>setSheetState(()=>city=v)),_filterSection('Gender',genders,gender,(v)=>setSheetState(()=>gender=v)),_filterSection('Type',types,type,(v)=>setSheetState(()=>type=v)),_filterSection('Room type',rooms,roomType,(v)=>setSheetState(()=>roomType=v)),
      const Text('Other',style:TextStyle(color:AppColors.darkGreen,fontSize:14,fontWeight:FontWeight.w700)),const SizedBox(height:8),FilterChip(label:const Text('AC only'),selected:acOnly,onSelected:(v)=>setSheetState(()=>acOnly=v)),const SizedBox(height:16),
      const Text('Sort by',style:TextStyle(color:AppColors.darkGreen,fontSize:14,fontWeight:FontWeight.w700)),const SizedBox(height:8),Wrap(spacing:7,runSpacing:7,children:['Recommended','Price: Low','Nearest'].map((v)=>ChoiceChip(label:Text(v),selected:sort==v,onSelected:(_)=>setSheetState(()=>sort=v))).toList()),const SizedBox(height:20),
      SizedBox(width:double.infinity,child:FilledButton(style:FilledButton.styleFrom(backgroundColor:AppColors.primaryGreen,foregroundColor:AppColors.white),onPressed:(){setState((){_city=city;_gender=gender;_type=type;_roomType=roomType;_acOnly=acOnly;_sort=sort;});Navigator.pop(sheetContext);},child:const Text('Apply filters')))
    ]))));
  }
  Widget _filterSection(String title,List<String> values,String selected,ValueChanged<String> onChanged)=>Padding(padding:const EdgeInsets.only(bottom:14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:AppColors.darkGreen,fontSize:14,fontWeight:FontWeight.w700)),const SizedBox(height:7),Wrap(spacing:7,runSpacing:7,children:values.map((v)=>ChoiceChip(label:Text(v),selected:selected==v,onSelected:(_)=>onChanged(v))).toList())]));

  Widget _smallTag(String value)=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(10)),child:Text(value,style:const TextStyle(color:AppColors.darkGreen,fontSize:10,fontWeight:FontWeight.w600)));
  Widget _state(IconData icon,String title,String message)=>Center(child:Padding(padding:const EdgeInsets.all(32),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:54,color:AppColors.primaryGreen),const SizedBox(height:12),Text(title,textAlign:TextAlign.center,style:const TextStyle(color:AppColors.darkGreen,fontSize:18,fontWeight:FontWeight.w700)),const SizedBox(height:6),Text(message,textAlign:TextAlign.center,style:const TextStyle(color:AppColors.mutedText))])));

  @override Widget build(BuildContext context) {
    final allHostels=_hostels; final cities=_values(allHostels,(h)=>h.city),genders=_values(allHostels,(h)=>h.gender),types=_values(allHostels,(h)=>h.type),rooms=_values(allHostels,(h)=>h.roomType); final filtered=_filter(allHostels);
    return Scaffold(backgroundColor:AppColors.cream,appBar:AppBar(title:const Text('Hostels'),actions:[IconButton(tooltip:'List your hostel',onPressed:()=>context.push('/hostels/list'),icon:const Icon(Icons.add_business_outlined,color:AppColors.white)),Center(child:Padding(padding:const EdgeInsets.only(right:16),child:Text('${filtered.length}',style:const TextStyle(color:AppColors.white,fontWeight:FontWeight.w700))))]),
      body:Column(children:[Padding(padding:const EdgeInsets.fromLTRB(16,10,16,6),child:SearchBar(controller:_searchController,onChanged:(_)=>setState((){}),hintText:'Search hostels, cities, areas...',leading:const Icon(Icons.search_rounded,color:AppColors.primaryGreen),trailing:[if(_searchController.text.isNotEmpty)IconButton(onPressed:(){_searchController.clear();setState((){});},icon:const Icon(Icons.clear_rounded)),IconButton(tooltip:'Filters',onPressed:()=>_showFilters(cities:cities,genders:genders,types:types,rooms:rooms),icon:Stack(clipBehavior:Clip.none,children:[const Icon(Icons.tune_rounded,color:AppColors.primaryGreen),if(_hasActiveFilters)Positioned(right:-2,top:-2,child:Container(width:7,height:7,decoration:const BoxDecoration(color:AppColors.primaryGreen,shape:BoxShape.circle)))])])),
        if(_hasActiveFilters)Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Align(alignment:Alignment.centerRight,child:TextButton(onPressed:_clearFilters,child:const Text('Clear filters')))),
        Expanded(child:filtered.isEmpty?_state(Icons.hotel_outlined,'No hostels found','Try changing your search or filters.'):ListView.builder(padding:const EdgeInsets.fromLTRB(16,8,16,28),itemCount:filtered.length,itemBuilder:(context,index){final hostel=filtered[index];return _hostelCard(hostel);})),
      ]));
  }

  Widget _hostelCard(Hostel hostel)=>Card(color:AppColors.white,margin:const EdgeInsets.only(bottom:12),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:const BorderSide(color:AppColors.divider)),child:InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>context.push('/hostel/${hostel.id}',extra:hostel),child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[Container(width:86,height:86,decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(12)),clipBehavior:Clip.antiAlias,child:hostel.imageUrl.isNotEmpty?Image.network(hostel.imageUrl,fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Icon(Icons.hotel_rounded,color:AppColors.primaryGreen,size:34)):const Icon(Icons.hotel_rounded,color:AppColors.primaryGreen,size:34)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(hostel.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:AppColors.darkGreen,fontSize:16,fontWeight:FontWeight.w700))),if(hostel.reviewCount>0)...[_rating(hostel.rating,hostel.reviewCount)]]),const SizedBox(height:5),Text([hostel.area,hostel.city].where((e)=>e.isNotEmpty).join(', '),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:AppColors.mutedText,fontSize:12)),const SizedBox(height:7),Wrap(spacing:6,runSpacing:4,children:[_smallTag(hostel.type),_smallTag(hostel.gender),if(hostel.roomType.isNotEmpty)_smallTag(hostel.roomType),if(hostel.ac)_smallTag('AC')]),if(hostel.price.isNotEmpty||hostel.availability.isNotEmpty)...[const SizedBox(height:6),Row(children:[if(hostel.price.isNotEmpty)Expanded(child:Text(hostel.price,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:AppColors.primaryGreen,fontSize:12,fontWeight:FontWeight.w700))),if(hostel.availability.isNotEmpty)Text(hostel.availability,style:const TextStyle(color:AppColors.mutedText,fontSize:10))])],if(hostel.facilities.isNotEmpty)...[const SizedBox(height:7),Text(hostel.facilities.join(' • '),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:AppColors.mutedText,fontSize:11))]])),const Icon(Icons.chevron_right_rounded,color:AppColors.mutedText)]))));
  Widget _rating(double rating,int count)=>Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.star_rounded,color:AppColors.primaryGreen,size:16),const SizedBox(width:2),Text(rating.toStringAsFixed(1),style:const TextStyle(color:AppColors.darkGreen,fontSize:11,fontWeight:FontWeight.w700)),Text(' ($count)',style:const TextStyle(color:AppColors.mutedText,fontSize:9))]);
}
