import '../../../../core/models/user_profile.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../models/post.dart';
import '../../../institutes/data/institute_repository.dart';
import '../../../institutes/data/institute_opportunity_repository.dart';
import '../../../models/institute.dart';
import '../../../models/hostel.dart';
import '../../../hostels/data/hostel_repository.dart';
import '../../../hostels/data/hostel_registry.dart';
import '../../../institutes/data/institute_catalog.dart';
import '../../domain/smart_search_parser.dart';

class _Hit {
  final String title, type, subtitle, location, route;
  final IconData icon;
  final double score;
  final Object? extra;
  const _Hit(this.title,this.type,this.subtitle,this.location,this.route,this.icon,this.score,[this.extra]);
}

class SmartGlobalSearchScreen extends StatefulWidget {
  const SmartGlobalSearchScreen({super.key});
  @override State<SmartGlobalSearchScreen> createState()=>_SmartGlobalSearchScreenState();
}

class _SmartGlobalSearchScreenState extends State<SmartGlobalSearchScreen> {
  final _controller=TextEditingController();
  List<_Hit> _hits=[];
  ParsedGlobalQuery? _parsed;
  bool _loading=false, _searched=false, _revealResults=false;
  String? _error;
  String? _loadedMode;
  bool _institutesLoaded=false, _opportunitiesLoaded=false;
  List<Hostel>? _hostelCache;
  String _filterCity='All', _filterArea='All', _filterGender='All';
  String _filterHostelType='All', _filterRoomType='All';
  String _filterInstituteType='All', _filterProgram='All', _filterSector='All';
  String _filterAdmissionStatus='All', _filterFeeRange='All';
  bool _filterAcOnly=false;
  bool get _demo => ActiveProfileController.instance.isDemo || !FirebaseService.initialized;

  static const _scholarships=[
    ('HEC Undergraduate Scholarship','Undergraduate','All fields','Pakistan','Tuition and stipend'),
    ('Ehsaas Undergraduate Scholarship','Undergraduate','All fields','Pakistan','Need-based financial assistance'),
    ('Punjab Educational Endowment Fund','Undergraduate','All fields','Punjab','Support for eligible students'),
    ('HEC MS Scholarship','MS','All fields','Pakistan','Postgraduate financial support'),
    ('Need-Based Scholarship','Undergraduate','Computer Science','Pakistan','Financial aid for eligible students'),
    ('STEM Scholarship','MS','Engineering','Pakistan','Support for STEM study'),
  ];

  @override void dispose(){_controller.dispose();super.dispose();}

  Future<void> search([String? input]) async {
    final text=(input??_controller.text).trim();
    if(text.isEmpty)return;
    _controller.text=text;
    final q=SmartSearchParser.parse(text);
    final mode=_demo?'demo':'real';
    if(_loadedMode!=mode){_loadedMode=mode;_institutesLoaded=false;_opportunitiesLoaded=false;_hostelCache=null;}
    setState(() { _parsed=q; _hits=[]; _loading=true; _searched=true; _error=null; _revealResults=false; });
    final hits=< _Hit>[];
    try {
      final ir=InstituteRepository.instance;
      if(!_institutesLoaded){await ir.load();_institutesLoaded=true;}
      for(final i in ir.items) {
        if(!_instituteAllowed(i,q))continue;
        final score=_score(q,i.name,[i.type,i.subcategory,i.city,i.province,i.district,i.town,i.area,i.address,i.description,i.board,i.sector,i.nextProgram,i.admissionStatus,i.programs.join(' ')]);
        if(score>0)hits.add(_Hit(i.name,_instituteType(i.type),i.description.isEmpty?' ${i.sector} • ${i.programs.take(3).join(', ')}':i.description,[i.area,i.city,i.province].where((e)=>e.isNotEmpty).join(', '),'/institute/${i.id}',Icons.school_outlined,score,i));
      }

      if(_hostelCache==null){_hostelCache=_demo?HostelRepository.demoHostels:await _realHostels();}
      final hostels=_hostelCache!;
      for(final h in hostels) {
        if(q.category!=GlobalSearchCategory.all&&q.category!=GlobalSearchCategory.hostels)continue;
        if(h.status.toLowerCase()!='approved')continue;
        if(_filterCity!='All'&&h.city!=_filterCity)continue;
        if(_filterArea!='All'&&h.area!=_filterArea)continue;
        if(_filterGender!='All'&&h.gender!=_filterGender)continue;
        if(_filterHostelType!='All'&&h.type!=_filterHostelType)continue;
        if(_filterRoomType!='All'&&h.roomType!=_filterRoomType&&!h.rooms.any((room)=>room.type==_filterRoomType))continue;
        if(_filterAcOnly&&!h.ac&&!h.rooms.any((room)=>room.ac))continue;
        if(q.location!=null&&!' ${h.city} ${h.address}'.toLowerCase().contains(q.location!.toLowerCase()))continue;
        if(q.area!=null&&!' ${h.area} ${h.address}'.toLowerCase().contains(q.area!.toLowerCase()))continue;
        if(q.gender!=null&&h.gender.toLowerCase()!=q.gender!.toLowerCase())continue;
        if(q.maxBudget!=null&&_money(h.price)>q.maxBudget!)continue;
        final score=_score(q,h.name,['hostel',h.city,h.area,h.type,h.gender,h.price,h.roomType,h.availability,h.meals,h.description,h.address,h.facilities.join(' ')])+(q.wantsBestRated?h.rating*2:0)+(h.isVerified?1:0);
        if(score>0)hits.add(_Hit(h.name,'Hostel','${h.price} • ${h.gender} • ${h.rating.toStringAsFixed(1)} ★',[h.area,h.city].where((e)=>e.isNotEmpty).join(', '),'/hostel/${h.id}',Icons.hotel_outlined,score,h));
      }

      final opportunities=InstituteOpportunityRepository.instance;
      if(!_opportunitiesLoaded){await opportunities.loadAll();_opportunitiesLoaded=true;}
      for(final o in opportunities.allItems) {
        if(q.category!=GlobalSearchCategory.all&&q.category!=GlobalSearchCategory.admissions&&q.category!=GlobalSearchCategory.scholarships&&q.category!=GlobalSearchCategory.institutes)continue;
        if(q.category==GlobalSearchCategory.admissions&&o.kind!='admission')continue;
        if(q.category==GlobalSearchCategory.scholarships&&o.kind!='scholarship')continue;
        if(q.wantsOpenAdmissions&&q.category==GlobalSearchCategory.admissions&&!o.status.toLowerCase().contains('open'))continue;
        final parent=ir.byId(o.instituteId);
        if(_filterAdmissionStatus!='All'&&parent!=null&&parent.admissionStatus!=_filterAdmissionStatus)continue;
        if(_filterInstituteType!='All'&&parent!=null&&parent.type!=_filterInstituteType)continue;
        if(_filterProgram!='All'&&parent!=null&&!parent.programs.any((p)=>p.toLowerCase()==_filterProgram.toLowerCase())&&parent.nextProgram.toLowerCase()!=_filterProgram.toLowerCase())continue;
        if(_filterSector!='All'&&parent!=null&&parent.sector!=_filterSector)continue;
        if(_filterFeeRange!='All'&&parent!=null&&parent.feeRange!=_filterFeeRange)continue;
        if(q.location!=null&&parent!=null&&!' ${parent.city} ${parent.province} ${parent.address}'.toLowerCase().contains(q.location!.toLowerCase()))continue;
        if(_filterCity!='All'&&parent!=null&&parent.city!=_filterCity)continue;
        if(_filterArea!='All'&&parent!=null&&parent.area!=_filterArea&&parent.town!=_filterArea)continue;
        final score=_score(q,o.title,[o.kind,o.status,o.academicYear,o.intake,o.eligibility,o.description,o.provider,o.feeDetails,parent?.name??'',parent?.city??'',parent?.programs.join(' ')??'']);
        if(score>0)hits.add(_Hit(o.title,_title(o.kind),'${o.status} • ${o.academicYear} • ${parent?.name??o.provider}',parent?.city??'',parent==null?'/institutes':'/institute/${parent.id}/opportunities',Icons.event_available_outlined,score,o));
      }

      if(q.category==GlobalSearchCategory.all||q.category==GlobalSearchCategory.scholarships) {
        for(final s in _scholarships) {
          final score=_score(q,s.$1,['scholarship',s.$2,s.$3,s.$4,s.$5]);
          if(score>0)hits.add(_Hit(s.$1,'Scholarship','${s.$2} • ${s.$3} • ${s.$5}',s.$4,'/scholarships',Icons.card_giftcard_outlined,score));
        }
      }

      // Bounded Firebase resource lookup only in real identity mode.
      if(!_demo&&(q.category==GlobalSearchCategory.all||q.category==GlobalSearchCategory.resources)) {
        try {
          final docs=await FirebaseFirestore.instance.collection('resources').limit(100).get();
          for(final d in docs.docs) {
            final data=d.data(),title=(data['title']??'Study Resource').toString(),desc=(data['description']??'').toString();
            final score=_score(q,title,['resource','study material',desc,(data['category']??'').toString()]);
            if(score>0)hits.add(_Hit(title,'Resource',desc,'Study material','/resources',Icons.menu_book_outlined,score));
          }
        } catch (_) {}
      }

      // Community: fetch records from the active identity's source, then
      // rank locally with the new parser (not the legacy query filter).
      if(q.category==GlobalSearchCategory.all||q.category==GlobalSearchCategory.community) {
        try {
          final posts=await DatabaseService().postsStream().first;
          for(final Post post in posts) {
            final score=_score(q,post.text,['community','post',post.authorName,post.category,post.tags.join(' '),post.attachments.map((a)=>a.values.join(' ')).join(' ')]);
            if(score>0)hits.add(_Hit(post.text.length>76?' ${post.text.substring(0,76)}…':post.text,'Community • ${post.category}','By ${post.authorName}\nUID: ${post.authorId}\n${post.likesCount} likes • ${post.commentsCount} comments','', '/community/post/${post.id}',Icons.forum_outlined,score,post));
          }
        } catch (_) {}
      }

      // People use the active demo profile catalogue in Demo mode and a
      // bounded users collection read for a real account.
      if(q.category==GlobalSearchCategory.all||q.category==GlobalSearchCategory.people) {
        if(_demo) {
          for(final person in temporaryProfiles) {
            final score=_score(q,person.name,['people','student','profile',person.username,person.city,person.level,person.institute,person.program]);
            if(score>0)hits.add(_Hit(person.name,'Student / Profile','${person.level} • ${person.institute}',person.city,'/profile/${person.id}',Icons.person_outline,score));
          }
        } else {
          try {
            final docs=await FirebaseFirestore.instance.collection('users').limit(100).get();
            for(final doc in docs.docs) {
              final data=doc.data();
              final name=(data[ProfileFields.name]??data['displayName']??data['fullName']??'Student').toString();
              final score=_score(q,name,['people','student','profile',(data['username']??'').toString(),(data[ProfileFields.city]??'').toString(),(data['institute']??'').toString(),(data['program']??'').toString(),(data[ProfileFields.bio]??'').toString()]);
              if(score>0)hits.add(_Hit(name,'Profile',[(data['program']??'').toString(),(data['institute']??'').toString()].where((v)=>v.isNotEmpty).join(' • '),(data[ProfileFields.city]??'').toString(),'/profile/${doc.id}',Icons.person_outline,score));
            }
          } catch (_) {}
        }
      }

      // Demo resources stay inside DemoDataService; they are never read from
      // the Firebase collection while a temporary profile is active.
      if(_demo&&(q.category==GlobalSearchCategory.all||q.category==GlobalSearchCategory.resources)) {
        try {
          final uid=ActiveProfileController.instance.effectiveUid??'demo-user-1';
          final docs=await DatabaseService().demoResourcesStream(uid).first;
          for(final data in docs) {
            final title=(data['title']??'Study Resource').toString();
            final description=(data['description']??'').toString();
            final score=_score(q,title,['resource','study material',description,(data['url']??'').toString()]);
            if(score>0)hits.add(_Hit(title,'Resource',description,'Study material','/resources',Icons.menu_book_outlined,score));
          }
        } catch (_) {}
      }

      hits.sort((a,b)=>b.score.compareTo(a.score));
      if(!mounted)return;
      await _finishThinking(q);
      if(!mounted)return;
      setState(() { _hits=hits.take(60).toList(); _loading=false; _revealResults=true; });
    } catch (_) {
      if(!mounted)return;
      await _finishThinking(q);
      if(!mounted)return;
      setState(() { _loading=false; _revealResults=true; _error='Search complete nahi ho saki. Dobara try karein.'; });
    }
  }

  Future<void> _finishThinking(ParsedGlobalQuery q) async {
    // Let the word-by-word narration finish before showing any result cards.
    final wordCount=q.summary.split(RegExp(r'\s+')).where((word)=>word.isNotEmpty).length;
    final narration=Duration(milliseconds:wordCount*420);
    final minimum=const Duration(milliseconds:6500);
    await Future<void>.delayed(narration>minimum?narration:minimum);
  }

  Future<List<Hostel>> _realHostels() async {
    try{return await HostelRepository().watchHostels().first;}catch(_){return const <Hostel>[];}
  }

  bool _instituteAllowed(Institute i,ParsedGlobalQuery q) {
    if(q.category!=GlobalSearchCategory.all&&q.category!=GlobalSearchCategory.institutes&&q.category!=GlobalSearchCategory.admissions&&q.category!=GlobalSearchCategory.scholarships)return false;
    if(q.location!=null&&!' ${i.city} ${i.district} ${i.province} ${i.address}'.toLowerCase().contains(q.location!.toLowerCase()))return false;
    if(_filterCity!='All'&&i.city!=_filterCity)return false;
    if(_filterArea!='All'&&i.area!=_filterArea&&i.town!=_filterArea)return false;
    if(_filterInstituteType!='All'&&i.type!=_filterInstituteType)return false;
    if(_filterProgram!='All'&&_filterProgram!=''&&!i.programs.any((p)=>p.toLowerCase()==_filterProgram.toLowerCase())&&i.nextProgram.toLowerCase()!=_filterProgram.toLowerCase())return false;
    if(_filterSector!='All'&&i.sector!=_filterSector)return false;
    if(_filterAdmissionStatus!='All'&&i.admissionStatus!=_filterAdmissionStatus)return false;
    if(_filterFeeRange!='All'&&i.feeRange!=_filterFeeRange)return false;
    if(q.area!=null&&!' ${i.area} ${i.town} ${i.address}'.toLowerCase().contains(q.area!.toLowerCase()))return false;
    if(q.program!=null&&!' ${i.programs.join(' ')} ${i.nextProgram} ${i.name} ${i.description}'.toLowerCase().contains(q.program!.toLowerCase())&&q.program!.toLowerCase()!='bs')return false;
    if(q.instituteName!=null) {
      final needle=q.instituteName!.toLowerCase(),name=i.name.toLowerCase();
      final found=name.contains(needle)||(needle=='arid'&&name.contains('arid'))||(needle=='bzu'&&name.contains('zakariya'))||(needle=='uet'&&name.contains('engineering'))||(needle=='nust'&&name.contains('nust'));
      if(!found)return false;
    }
    return true;
  }

  double _score(ParsedGlobalQuery q,String title,List<String> fields) {
    final hay='$title ${fields.join(' ')}'.toLowerCase();
    final titleNorm=SmartSearchParser.normalize(title);
    var score=0.0;
    for(final term in q.terms) {
      if(titleNorm.split(' ').contains(term))score+=4;
      else if(titleNorm.contains(term))score+=2.5;
      else if(hay.contains(term))score+=1;
      else if(_near(hay,term))score+=0.5;
    }
    if(q.location!=null&&hay.contains(q.location!.toLowerCase()))score+=3;
    if(q.area!=null&&hay.contains(q.area!.toLowerCase()))score+=3;
    if(q.program!=null&&hay.contains(q.program!.toLowerCase()))score+=2;
    if(q.instituteName!=null&&hay.contains(q.instituteName!.toLowerCase()))score+=4;
    final expected=switch(q.category){
      GlobalSearchCategory.institutes=>['institute','school','college','university','educators','education'],
      GlobalSearchCategory.admissions=>['admission','open','intake','deadline'],
      GlobalSearchCategory.hostels=>['hostel','room','residence','accommodation'],
      GlobalSearchCategory.scholarships=>['scholarship','funding','stipend','financial'],
      GlobalSearchCategory.resources=>['resource','notes','paper','study','book'],
      GlobalSearchCategory.community=>['community','post','discussion'],
      GlobalSearchCategory.people=>['profile','student','person'],
      GlobalSearchCategory.all=>const <String>[],
    };
    if(expected.isNotEmpty){if(expected.any(hay.contains))score+=2;else return 0;}
    if(q.wantsOpenAdmissions&&hay.contains('open'))score+=3;
    if(score==0&&q.terms.isEmpty&&q.location==null&&q.area==null&&q.program==null&&q.instituteName==null)score=1;
    return score;
  }

  bool _near(String hay,String term) {
    if(term.length<4)return false;
    for(final word in hay.split(RegExp(r'[^a-z0-9]+'))) {
      if((word.length-term.length).abs()>1||word.length<4)continue;
      var i=0,j=0,edits=0;
      while(i<word.length&&j<term.length) {
        if(word[i]==term[j]){i++;j++;continue;}
        if(++edits>1)break;
        if(word.length>term.length)i++;else if(term.length>word.length)j++;else{i++;j++;}
      }
      if(i<word.length||j<term.length)edits++;
      if(edits<=1)return true;
    }
    return false;
  }
  int _money(String text){final m=RegExp(r'\d[\d,]*').firstMatch(text);return m==null?1<<30:int.tryParse(m.group(0)!.replaceAll(',',''))??(1<<30);}
  String _instituteType(String t){final v=t.toLowerCase();if(v.contains('school'))return 'School';if(v.contains('college'))return 'College';return 'Institute';}
  String _title(String v)=>v.isEmpty?v:'${v[0].toUpperCase()}${v.substring(1)}';

  Future<void> _refresh() async {
    _institutesLoaded=false;_opportunitiesLoaded=false;_hostelCache=null;
    await search();
  }

  void _open(_Hit h){if(h.extra is Hostel){context.push(h.route,extra:h.extra);}else{context.push(h.route);}}

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(title:const Text('Smart Global Search'),actions:[IconButton(tooltip:'Refresh results',onPressed:_loading||_controller.text.trim().isEmpty?null:_refresh,icon:const Icon(Icons.refresh)),if(_controller.text.isNotEmpty)IconButton(onPressed:(){_controller.clear();setState(() { _hits=[]; _parsed=null; _searched=false; _error=null; });},icon:const Icon(Icons.close))]),
      body:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(14,14,14,8),child:TextField(
          controller:_controller,textInputAction:TextInputAction.search,onSubmitted:search,onChanged:(_)=>setState((){}),
          decoration:InputDecoration(hintText:'Lahore mein girls hostel under 15000',prefixIcon:const Icon(Icons.travel_explore,color:AppColors.primaryGreen),suffixIcon:IconButton(onPressed:_loading?null:()=>search(),icon:const Icon(Icons.search,color:AppColors.primaryGreen)),filled:true,fillColor:AppColors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:const BorderSide(color:AppColors.divider))),
        )),
        if(!_searched) Padding(padding:const EdgeInsets.fromLTRB(16,4,16,8),child:Align(alignment:Alignment.centerLeft,child:Text('Apni normal zuban mein search karein',style:TextStyle(color:AppColors.mutedText)))),
        if(!_searched) Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Wrap(spacing:7,runSpacing:5,children:[
          'Lahore mein Educators','Johar Town mein achy hostel','Girls hostel under 15000','Arid mein admission open hai?','Scholarship for BS students'
        ].map((s)=>ActionChip(label:Text(s),backgroundColor:AppColors.softGreen,side:BorderSide.none,onPressed:()=>search(s))).toList())),
        if(_parsed!=null)_understood(_parsed!),
        if(_error!=null)Padding(padding:const EdgeInsets.all(16),child:Text(_error!)),
        Expanded(
          child: _loading || !_revealResults
              ? (_searched ? const _SearchResultShimmer() : const SizedBox.shrink())
              : _searched && _hits.isEmpty && _error==null
                  ? const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('Matching listing nahi mili. Query ya location badal kar dekhein.',textAlign:TextAlign.center)))
                  : ListView.separated(
                      padding:const EdgeInsets.all(12),
                      itemCount:_hits.length,
                      separatorBuilder:(_,__)=>const SizedBox(height:6),
                      itemBuilder:(context,index){
                        final h=_hits[index];return Card(color:AppColors.white,margin:EdgeInsets.zero,child:ListTile(
                          leading:CircleAvatar(backgroundColor:AppColors.softGreen,foregroundColor:AppColors.darkGreen,child:Icon(h.icon)),
                          title:Text(h.title,style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.darkGreen)),
                          subtitle:Padding(padding:const EdgeInsets.only(top:5),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(h.type,style:const TextStyle(color:AppColors.primaryGreen,fontWeight:FontWeight.w600)),if(h.location.isNotEmpty)Text(h.location),if(h.subtitle.isNotEmpty)Text(h.subtitle,maxLines:2,overflow:TextOverflow.ellipsis)])),
                          trailing:const Icon(Icons.chevron_right,color:AppColors.primaryGreen),onTap:()=>_open(h),
                        ));
                      }),
        ),
      ])),
    );
  }

  Future<void> _editFilters() async {
    final parsed=_parsed;
    if(parsed==null)return;
    final instituteItems=InstituteRepository.instance.items;
    final hostels=_hostelCache??HostelRepository.demoHostels;
    final cities=<String>{...instituteItems.map((i)=>i.city),...hostels.map((h)=>h.city)}..removeWhere((v)=>v.trim().isEmpty);
    final areas=<String>{...instituteItems.map((i)=>i.area),...instituteItems.map((i)=>i.town),...hostels.map((h)=>h.area)}..removeWhere((v)=>v.trim().isEmpty);
    final programs=<String>{...instituteItems.expand((i)=>i.programs),...instituteItems.map((i)=>i.nextProgram)}..removeWhere((v)=>v.trim().isEmpty);
    final sectors=<String>{...instituteItems.map((i)=>i.sector)}..removeWhere((v)=>v.trim().isEmpty);
    final feeRanges=<String>{...instituteItems.map((i)=>i.feeRange)}..removeWhere((v)=>v.trim().isEmpty);
    final catalog=InstituteCatalog.instance;
    String city=_filterCity!='All'?_filterCity:(parsed.location??'All');
    String area=_filterArea!='All'?_filterArea:(parsed.area??'All');
    String budget=parsed.maxBudget?.toString()??'';
    String gender=_filterGender!='All'?_filterGender:(parsed.gender??'All');
    String hostelType=_filterHostelType;
    String roomType=_filterRoomType;
    String instituteType=_filterInstituteType;
    String program=_filterProgram!='All'?_filterProgram:(parsed.program??'All');
    String sector=_filterSector;
    String admissionStatus=_filterAdmissionStatus;
    String feeRange=_filterFeeRange;
    bool acOnly=_filterAcOnly;
    final budgetController=TextEditingController(text:budget);
    List<DropdownMenuItem<String>> options(Iterable<String> values,{String all='All'}){
      final sorted=values.toSet().where((v)=>v.trim().isNotEmpty).toList()..sort();
      return [DropdownMenuItem(value:all,child:Text(all)),...sorted.map((v)=>DropdownMenuItem(value:v,child:Text(v)))];
    }
    final applied=await showModalBottomSheet<bool>(
      context:context,showDragHandle:true,isScrollControlled:true,
      builder:(sheetContext)=>StatefulBuilder(builder:(context,setSheet)=>Padding(
        padding:EdgeInsets.fromLTRB(18,10,18,MediaQuery.of(context).viewInsets.bottom+22),
        child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Expanded(child:Text('Search filters',style:Theme.of(context).textTheme.titleLarge)),
            TextButton(onPressed:()=>setSheet((){
              city='All';area='All';budgetController.clear();gender='All';hostelType='All';roomType='All';instituteType='All';program='All';sector='All';admissionStatus='All';feeRange='All';acOnly=false;
            }),child:const Text('Clear all')),
          ]),
          const SizedBox(height:10),
          _filterDropdown('City / location',options(cities),city,(v)=>setSheet(()=>city=v)),
          _filterDropdown('Area / town',options(areas),area,(v)=>setSheet(()=>area=v)),
          TextField(controller:budgetController,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Maximum budget / rent (PKR)')),
          const SizedBox(height:8),
          _filterDropdown('Hostel gender',options(HostelRegistry.genders,all:'All'),gender,(v)=>setSheet(()=>gender=v)),
          _filterDropdown('Hostel type',options(HostelRegistry.types),hostelType,(v)=>setSheet(()=>hostelType=v)),
          _filterDropdown('Room type',options(HostelRegistry.roomTypes),roomType,(v)=>setSheet(()=>roomType=v)),
          SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('AC room / hostel only'),value:acOnly,onChanged:(v)=>setSheet(()=>acOnly=v)),
          const Divider(),
          const Text('Institute filters',style:TextStyle(fontWeight:FontWeight.w700,color:AppColors.darkGreen)),
          _filterDropdown('Institute type',[
            const DropdownMenuItem(value:'All',child:Text('All')),
            ...catalog.types.map((t)=>DropdownMenuItem(value:t.id,child:Text(t.label))),
          ],instituteType,(v)=>setSheet(()=>instituteType=v)),
          _filterDropdown('Program / degree',options(programs),program,(v)=>setSheet(()=>program=v)),
          _filterDropdown('Sector',options(sectors),sector,(v)=>setSheet(()=>sector=v)),
          _filterDropdown('Admission status',options(InstituteCatalog.admissionStatuses,all:'All'),admissionStatus,(v)=>setSheet(()=>admissionStatus=v)),
          _filterDropdown('Fee range',options(feeRanges),feeRange,(v)=>setSheet(()=>feeRange=v)),
          const SizedBox(height:16),
          SizedBox(width:double.infinity,child:FilledButton(
            onPressed:(){
              var base=parsed.original;
              const aliases=['Lahore','Lahor','Islamabad','Islam Abad','Rawalpindi','Pindi','Multan','Bahawalpur','Bahawal Poor','Faisalabad','Faisal Abad','Karachi','Krachi','Peshawar','Peshawer','Quetta','Gujranwala','Sialkot','Sargodha','Johar Town','Gulberg','Bosan Road','Bosan','New Campus','Baghdad-ul-Jadeed'];
              for(final alias in aliases){base=base.replaceAll(RegExp(r'\b'+RegExp.escape(alias)+r'\b',caseSensitive:false),' ');}
              base=base.replaceAll(RegExp(r'\b(?:under|below|less than|max|maximum|budget|rs|pkr)?\s*\d[\d,]{3,}\b',caseSensitive:false),' ');
              base=base.replaceAll(RegExp(r'\b(?:girls?|female|women|ladies|boys?|male|men)\b',caseSensitive:false),' ');
              final parts=<String>[base.trim()];
              if(city!='All')parts.add('in $city');
              if(area!='All')parts.add(area);
              if(budgetController.text.trim().isNotEmpty)parts.add('under ${budgetController.text.trim()}');
              if(gender!='All')parts.add(gender=='Female'?'girls':gender=='Male'?'boys':'both genders');
              if(hostelType!='All')parts.add(hostelType);
              if(roomType!='All')parts.add(roomType);
              if(acOnly)parts.add('AC');
              if(instituteType!='All')parts.add(catalog.labelFor(instituteType));
              if(program!='All')parts.add(program);
              if(sector!='All')parts.add(sector);
              if(admissionStatus!='All')parts.add(admissionStatus);
              if(feeRange!='All')parts.add(feeRange);
              setState((){
                _filterCity=city;_filterArea=area;_filterGender=gender;
                _filterHostelType=hostelType;_filterRoomType=roomType;_filterAcOnly=acOnly;
                _filterInstituteType=instituteType;_filterProgram=program;_filterSector=sector;
                _filterAdmissionStatus=admissionStatus;_filterFeeRange=feeRange;
              });
              _controller.text=parts.where((v)=>v.trim().isNotEmpty).join(' ');
              Navigator.pop(sheetContext,true);
            },
            child:const Text('Apply filters'),
          )),
        ])),
      )),
    );
    budgetController.dispose();
    if(applied==true)await search();
  }

  Widget _filterDropdown(String label,List<DropdownMenuItem<String>> items,String selected,ValueChanged<String> onChanged){
    final safeValue=items.any((item)=>item.value==selected)?selected:(items.isNotEmpty?items.first.value:'All');
    return Padding(
      padding:const EdgeInsets.only(bottom:8),
      child:DropdownButtonFormField<String>(
        value:safeValue,
        isExpanded:true,
        decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),
        items:items,
        onChanged:(value){if(value!=null)onChanged(value);},
      ),
    );
  }

  Widget _understood(ParsedGlobalQuery q)=>Container(
    width:double.infinity,
    margin:const EdgeInsets.fromLTRB(14,6,14,4),
    padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(14),border:Border.all(color:AppColors.divider)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.psychology_alt_outlined,color:AppColors.darkGreen),const SizedBox(width:6),Text(q.isRomanUrdu?'Maine ye samjha':'What I understood',style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.darkGreen))]),
      const SizedBox(height:7),
      _WordByWordText(key:ValueKey(q.summary),text:q.summary,style:const TextStyle(color:AppColors.darkGreen,height:1.45)),
      if(_loading) Padding(
        padding:const EdgeInsets.only(top:9),
        child:_SearchThinkingStatus(isRomanUrdu:q.isRomanUrdu),
      ),
      Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:_editFilters,icon:const Icon(Icons.tune,size:17),label:Text(q.isRomanUrdu?'Filters badlein':'Edit filters'))),
    ]),
  );
}


class _WordByWordText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _WordByWordText({super.key,required this.text,required this.style});
  @override State<_WordByWordText> createState()=>_WordByWordTextState();
}

class _WordByWordTextState extends State<_WordByWordText> {
  Timer? _timer;
  int _visibleWords=0;
  List<String> get _words=>widget.text.split(RegExp(r'\s+')).where((word)=>word.isNotEmpty).toList();

  @override void initState(){super.initState();_startTyping();}
  @override void didUpdateWidget(covariant _WordByWordText oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.text!=widget.text)_startTyping();
  }
  void _startTyping(){
    _timer?.cancel();
    _visibleWords=0;
    final count=_words.length;
    if(count==0)return;
    _timer=Timer.periodic(const Duration(milliseconds:420),(timer){
      if(!mounted)return;
      setState(()=>_visibleWords=(_visibleWords+1).clamp(0,count));
      if(_visibleWords>=count)timer.cancel();
    });
  }
  @override void dispose(){_timer?.cancel();super.dispose();}
  @override Widget build(BuildContext context){
    final words=_words;
    final shown=words.take(_visibleWords).join(' ');
    return AnimatedSwitcher(
      duration:const Duration(milliseconds:100),
      child:Text(
        shown.isEmpty?'▍':'$shown${_visibleWords<words.length?' ▍':''}',
        key:ValueKey(_visibleWords),
        style:widget.style,
      ),
    );
  }
}

class _SearchThinkingStatus extends StatefulWidget {
  final bool isRomanUrdu;
  const _SearchThinkingStatus({required this.isRomanUrdu});
  @override State<_SearchThinkingStatus> createState()=>_SearchThinkingStatusState();
}

class _SearchThinkingStatusState extends State<_SearchThinkingStatus> {
  Timer? _timer;
  int _step=0;
  static const _roman=[
    'Aap ki query ko samajh raha hoon',
    'Relevant categories aur filters match kar raha hoon',
    'Available listings ko compare kar raha hoon',
    'Sab se relevant results arrange kar raha hoon',
  ];
  static const _english=[
    'Understanding your search',
    'Matching relevant categories and filters',
    'Comparing available listings',
    'Ranking the most relevant results',
  ];
  @override void initState(){
    super.initState();
    _timer=Timer.periodic(const Duration(milliseconds:1750),(_){
      if(mounted)setState(()=>_step=(_step+1)%4);
    });
  }
  @override void dispose(){_timer?.cancel();super.dispose();}
  @override Widget build(BuildContext context){
    final messages=widget.isRomanUrdu?_roman:_english;
    return Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
      SizedBox(
        width:16,height:16,
        child:CircularProgressIndicator(
          strokeWidth:2,
          valueColor:AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      ),
      const SizedBox(width:8),
      Expanded(child:AnimatedSwitcher(
        duration:const Duration(milliseconds:260),
        child:Text(messages[_step],key:ValueKey(_step),style:const TextStyle(color:AppColors.mutedText,fontSize:12,fontStyle:FontStyle.italic)),
      )),
      const SizedBox(width:4),
      _ThinkingDots(),
    ]);
  }
}

class _ThinkingDots extends StatefulWidget {
  @override State<_ThinkingDots> createState()=>_ThinkingDotsState();
}
class _ThinkingDotsState extends State<_ThinkingDots> {
  Timer? _timer;
  int _dots=1;
  @override void initState(){
    super.initState();
    _timer=Timer.periodic(const Duration(milliseconds:380),(_){
      if(mounted)setState(()=>_dots=_dots%3+1);
    });
  }
  @override void dispose(){_timer?.cancel();super.dispose();}
  @override Widget build(BuildContext context)=>Text(
    List.filled(_dots,'•').join(' '),
    style:const TextStyle(color:AppColors.primaryGreen,fontWeight:FontWeight.w800),
  );
}

class _SearchResultShimmer extends StatefulWidget {
  const _SearchResultShimmer();
  @override State<_SearchResultShimmer> createState()=>_SearchResultShimmerState();
}

class _SearchResultShimmerState extends State<_SearchResultShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller=AnimationController(vsync:this,duration:const Duration(milliseconds:950))..repeat(reverse:true);
  @override void dispose(){_controller.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    return AnimatedBuilder(
      animation:_controller,
      builder:(context,_)=>ListView.builder(
        padding:const EdgeInsets.all(12),
        itemCount:6,
        itemBuilder:(context,index){
          final opacity=0.28+(_controller.value*0.42);
          return Opacity(
            opacity:opacity,
            child:Container(
              margin:const EdgeInsets.only(bottom:9),
              padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(color:AppColors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:AppColors.divider)),
              child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Container(width:46,height:46,decoration:const BoxDecoration(color:AppColors.softGreen,shape:BoxShape.circle)),
                const SizedBox(width:12),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Container(height:15,width:180,decoration:BoxDecoration(color:AppColors.divider,borderRadius:BorderRadius.circular(5))),
                  const SizedBox(height:10),
                  Container(height:10,width:95,decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(5))),
                  const SizedBox(height:8),
                  Container(height:10,width:double.infinity,decoration:BoxDecoration(color:AppColors.divider,borderRadius:BorderRadius.circular(5))),
                  const SizedBox(height:6),
                  Container(height:10,width:145,decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(5))),
                ])),
              ]),
            ),
          );
        },
      ),
    );
  }
}
