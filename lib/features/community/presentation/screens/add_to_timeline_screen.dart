import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../timeline_topics.dart';

class AddToTimelineScreen extends StatefulWidget {
  const AddToTimelineScreen({super.key});
  @override State<AddToTimelineScreen> createState()=>_AddToTimelineScreenState();
}

class _AddToTimelineScreenState extends State<AddToTimelineScreen> {
  final _db=DatabaseService();
  Set<String> _selected={};
  bool _loading=true,_saving=false;
  User? _user;

  @override void initState(){super.initState();_load();}

  Future<void> _load() async {
    final identity=ActiveProfileController.instance;
    try {
      _user=FirebaseService.initialized?FirebaseAuth.instance.currentUser:null;
      final uid=identity.resolveUid(_user?.uid??'');
      if(uid.isEmpty && !identity.isDemoActive) {
        _selected=TimelineTopics.defaults.toSet();
      } else {
        _selected=await _db.timelineTopicsStream(uid).first;
      }
    } catch(error) {
      _selected=TimelineTopics.defaults.toSet();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString())));
    } finally {if(mounted)setState(()=>_loading=false);}
  }

  Future<void> _save() async {
    if(_saving)return;
    final identity=ActiveProfileController.instance;
    final uid=identity.resolveUid(_user?.uid??'');
    if(uid.isEmpty&&!identity.isDemoActive){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please sign in first.')));
      return;
    }
    setState(()=>_saving=true);
    try {
      await _db.setTimelineTopics(uid,_selected);
      if(mounted)context.pop(true);
    } catch(error) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString())));
    } finally {if(mounted)setState(()=>_saving=false);}
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(
      title:const Text('Add to Timeline'),
      actions:[TextButton(onPressed:_saving?null:_save,child:Text(_saving?'Saving…':'Done',style:const TextStyle(color:AppColors.white,fontWeight:FontWeight.w800)))],
    ),
    body:_loading?const Center(child:CircularProgressIndicator()):ListView(
      padding:const EdgeInsets.fromLTRB(14,12,14,30),
      children:[
        const Text('Choose what you want to see in your timeline',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:AppColors.darkGreen)),
        const SizedBox(height:6),
        const Text('Add or remove topics anytime. You can select as many as you want.',style:TextStyle(color:AppColors.homeMutedText)),
        const SizedBox(height:18),
        ..._section('Education', ['Admissions','Entry Tests','Exam Preparation','Study Help','Study Resources','Scholarships','Study Abroad','Degree & Programs']),
        ..._section('Career', ['Career','Jobs','Internships','Freelancing','Skills & Courses']),
        ..._section('Institutes', ['Institute Reviews','Institute Updates','Admission Deadlines','Fee & Financial Aid','Announcements']),
        ..._section('Student Life', ['Hostels','Transport','Student Life','Events & Seminars','Travel','Food & Cafes']),
        ..._section('Fun & Entertainment', ['Gaming','Esports','Sports','Cricket','Movies & Series','Music','Memes & Fun']),
        ..._section('Creative & Tech', ['Photography','Art & Creativity','Tech & Gadgets']),
        ..._section('Community', ['General Discussion','Questions & Answers']),
      ],
    ),
  );

  List<Widget> _section(String title,List<String> names)=>[
    Padding(padding:const EdgeInsets.only(top:8,bottom:8),child:Text(title,style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.darkGreen))),
    Wrap(
      spacing:8,runSpacing:8,
      children:names.map((name){
        final topic=TimelineTopics.byName(name)!;
        final selected=_selected.contains(name);
        return FilterChip(
          selected:selected,
          onSelected:(v)=>setState(()=>v?_selected.add(name):_selected.remove(name)),
          backgroundColor:AppColors.softGreen,
          selectedColor:AppColors.primaryGreen,
          checkmarkColor:AppColors.white,
          label:Text(topic.emoji+'  '+topic.name,style:TextStyle(color:selected?AppColors.white:AppColors.darkGreen,fontWeight:FontWeight.w600)),
        );
      }).toList(),
    ),
    const SizedBox(height:10),
  ];
}
