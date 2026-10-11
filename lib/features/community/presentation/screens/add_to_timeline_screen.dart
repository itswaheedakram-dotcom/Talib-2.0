import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../institutes/data/institute_repository.dart';
import '../../../models/institute.dart';
import '../../timeline_topics.dart';

class AddToTimelineScreen extends StatefulWidget {
  const AddToTimelineScreen({super.key});
  @override State<AddToTimelineScreen> createState()=>_AddToTimelineScreenState();
}

class _AddToTimelineScreenState extends State<AddToTimelineScreen> {
  final _db=DatabaseService();
  Set<String> _selectedTopics={};
  Set<String> _selectedInstitutes={};
  bool _loading=true,_saving=false;
  User? _user;
  String _type='All',_province='All',_city='All',_town='All';

  @override void initState(){super.initState();InstituteRepository.instance.load();_load();}

  Future<void> _load() async {
    final identity=ActiveProfileController.instance;
    try {
      _user=FirebaseService.initialized?FirebaseAuth.instance.currentUser:null;
      final uid=identity.resolveUid(_user?.uid??'');
      if(uid.isEmpty&&!identity.isDemoActive) {
        _selectedTopics={};
        _selectedInstitutes={};
      } else {
        final values=await Future.wait([
          _db.timelineTopicsStream(uid).first,
          _db.timelineInstitutesStream(uid).first,
        ]);
        _selectedTopics=Set<String>.from(values[0] as Set<String>);
        _selectedInstitutes=Set<String>.from(values[1] as Set<String>);
      }
    } catch(error) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString())));
    } finally {if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _save() async {
    if(_saving)return;
    final identity=ActiveProfileController.instance;
    final uid=identity.resolveUid(_user?.uid??'');
    if(uid.isEmpty&&!identity.isDemoActive){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Please sign in first.')));
      return;
    }
    setState(()=>_saving=true);
    try {
      await _db.setTimelineTopics(uid,_selectedTopics);
      await _db.setTimelineInstitutes(uid,_selectedInstitutes);
      if(mounted)context.pop(true);
    } catch(error) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString())));
    } finally {if(mounted)setState(()=>_saving=false);}
  }

  List<Institute> get _filteredInstitutes {
    return InstituteRepository.instance.items.where((i){
      final typeOk=_type=='All'||i.type==_type;
      final provinceOk=_province=='All'||i.province==_province;
      final cityOk=_city=='All'||i.city==_city;
      final townOk=_town=='All'||i.town==_town;
      return typeOk&&provinceOk&&cityOk&&townOk;
    }).toList();
  }

  List<String> get _provinces=>['All',...{for(final i in InstituteRepository.instance.items)if(i.province.trim().isNotEmpty)i.province}];
  List<String> get _cities=>['All',...{for(final i in InstituteRepository.instance.items)if((_province=='All'||i.province==_province)&&i.city.trim().isNotEmpty)i.city}];
  List<String> get _towns=>['All',...{for(final i in InstituteRepository.instance.items)if((_province=='All'||i.province==_province)&&(_city=='All'||i.city==_city)&&i.town.trim().isNotEmpty)i.town}];

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(
      title:Text('Add to Timeline'),
      actions:[TextButton(onPressed:_saving?null:_save,child:Text(_saving?'Saving…':'Done',style:TextStyle(color:AppColors.white,fontWeight:FontWeight.w800)))],
    ),
    body:_loading?Center(child:CircularProgressIndicator()):ListView(
      padding:EdgeInsets.fromLTRB(14,12,14,30),
      children:[
        Text('Choose what you want to see',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:AppPalette.of(context).ink)),
        SizedBox(height:6),
        Text('Selected topics and institutes will appear on your Community timeline. Unselected institutes stay hidden from the top bar.',style:TextStyle(color:AppPalette.of(context).muted)),
        SizedBox(height:18),
        ..._section('Education',['Admissions','Entry Tests','Exam Preparation','Study Help','Study Resources','Scholarships','Study Abroad','Degree & Programs']),
        ..._section('Career',['Career','Jobs','Internships','Freelancing','Skills & Courses']),
        ..._section('Institutes',['Institute Reviews','Institute Updates','Admission Deadlines','Fee & Financial Aid','Announcements']),
        ..._section('Student Life',['Hostels','Transport','Student Life','Events & Seminars','Travel','Food & Cafes']),
        ..._section('Fun & Entertainment',['Gaming','Esports','Sports','Cricket','Movies & Series','Music','Memes & Fun']),
        ..._section('Creative & Tech',['Photography','Art & Creativity','Tech & Gadgets']),
        ..._section('Community',['General Discussion','Questions & Answers']),
        SizedBox(height:18),
        Text('Institutes',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:AppPalette.of(context).ink)),
        SizedBox(height:5),
        Text('Institute tags are created automatically for every institute. Select only the institutes you want on your timeline.',style:TextStyle(color:AppPalette.of(context).muted)),
        SizedBox(height:12),
        AnimatedBuilder(
          animation:InstituteRepository.instance,
          builder:(context,_){
            final list=_filteredInstitutes;
            return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Wrap(spacing:8,runSpacing:8,children:['All','universities','colleges','schools'].map((type)=>ChoiceChip(
                label:Text(type=='All'?'All':type[0].toUpperCase()+type.substring(1)),
                selected:_type==type,
                selectedColor:AppColors.primaryGreen,
                labelStyle:TextStyle(color:_type==type?AppColors.white:AppPalette.of(context).ink,fontWeight:FontWeight.w700),
                onSelected:(_)=>setState((){_type=type;}),
              )).toList()),
              SizedBox(height:12),
              Row(children:[
                Expanded(child:_locationDrop('Province',_province,_provinces,(v)=>setState((){_province=v!;_city='All';_town='All';}))),
                SizedBox(width:8),
                Expanded(child:_locationDrop('City',_city,_cities,(v)=>setState((){_city=v!;_town='All';}))),
              ]),
              SizedBox(height:8),
              _locationDrop('Town',_town,_towns,(v)=>setState(()=>_town=v!)),
              SizedBox(height:12),
              if(list.isEmpty)
                Padding(padding:EdgeInsets.all(16),child:Text('No institutes match these filters.',style:TextStyle(color:AppPalette.of(context).muted)))
              else
                Wrap(spacing:8,runSpacing:8,children:list.map((institute){
                  final selected=_selectedInstitutes.contains(institute.id);
                  return FilterChip(
                    selected:selected,
                    onSelected:(v)=>setState(()=>v?_selectedInstitutes.add(institute.id):_selectedInstitutes.remove(institute.id)),
                    backgroundColor:AppPalette.of(context).softSurface,
                    selectedColor:AppColors.primaryGreen,
                    checkmarkColor:AppColors.white,
                    label:Text(institute.name,overflow:TextOverflow.ellipsis,style:TextStyle(color:selected?AppColors.white:AppPalette.of(context).ink,fontWeight:FontWeight.w700)),
                  );
                }).toList()),
            ]);
          },
        ),
      ],
    ),
  );

  Widget _locationDrop(String label,String value,List<String> items,ValueChanged<String?> onChanged)=>DropdownButtonFormField<String>(
    initialValue:items.contains(value)?value:'All',
    isExpanded:true,
    decoration:InputDecoration(labelText:label,prefixIcon:Icon(Icons.location_on_outlined)),
    items:items.map((e)=>DropdownMenuItem(value:e,child:Text(e,overflow:TextOverflow.ellipsis))).toList(),
    onChanged:items.length<=1?null:onChanged,
  );

  List<Widget> _section(String title,List<String> names)=>[
    Padding(padding:EdgeInsets.only(top:8,bottom:8),child:Text(title,style:TextStyle(fontWeight:FontWeight.w800,color:AppPalette.of(context).ink))),
    Wrap(spacing:8,runSpacing:8,children:names.map((name){
      final topic=TimelineTopics.byName(name)!;
      final selected=_selectedTopics.contains(name);
      return FilterChip(
        selected:selected,
        onSelected:(v)=>setState(()=>v?_selectedTopics.add(name):_selectedTopics.remove(name)),
        backgroundColor:AppPalette.of(context).softSurface,
        selectedColor:AppColors.primaryGreen,
        checkmarkColor:AppColors.white,
        label:Text(topic.emoji+'  '+topic.name,style:TextStyle(color:selected?AppColors.white:AppPalette.of(context).ink,fontWeight:FontWeight.w600)),
      );
    }).toList()),
  ];
}
