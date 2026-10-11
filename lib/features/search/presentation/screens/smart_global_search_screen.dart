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
  int _searchEpoch=0, _visibleLimit=60;
  List<String> _warnings=[];
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

  @override void dispose(){_searchEpoch++;_controller.dispose();super.dispose();}

  Future<void> search([String? input]) async {
    final request=++_searchEpoch;
    bool current()=>mounted && request==_searchEpoch;
    final warnings=<String>[];
    final text=(input??_controller.text).trim();
    if(text.isEmpty)return;
    _controller.text=text;
    final q=SmartSearchParser.parse(text);
    final mode=_demo?'demo:${ActiveProfileController.instance.effectiveUid}':'real';
    if(_loadedMode!=mode){_loadedMode=mode;_institutesLoaded=false;_opportunitiesLoaded=false;_hostelCache=null;}
    setState(() { _parsed=q; _hits=[]; _loading=true; _searched=true; _error=null; _warnings=[]; _visibleLimit=60; _revealResults=false; });
    final hits=< _Hit>[];
    try {
      final ir=InstituteRepository.instance;
      if(!_institutesLoaded && {GlobalSearchCategory.all, GlobalSearchCategory.institutes, GlobalSearchCategory.admissions, GlobalSearchCategory.scholarships}.contains(q.category)) {
        await ir.load(); if(!current())return;
        _institutesLoaded=ir.error==null;
        if(ir.error!=null)warnings.add('Institutes could not be loaded. Please retry.');
      }
      for(final i in ir.error==null ? ir.items : <Institute>[]) {
        if(!_instituteAllowed(i,q))continue;
        final score=_score(q,i.name,[i.type,i.subcategory,i.city,i.province,i.district,i.town,i.area,i.address,i.description,i.board,i.sector,i.nextProgram,i.admissionStatus,[...i.programs,...i.programGroups.values.expand((names)=>names)].join(' ')]);
        if(score>0)hits.add(_Hit(i.name,_instituteType(i.type),i.description.isEmpty?' ${i.sector} • ${i.programs.take(3).join(', ')}':i.description,[i.area,i.city,i.province].where((e)=>e.isNotEmpty).join(', '),'/institute/${i.id}',Icons.school_outlined,score,i));
      }

      if(_hostelCache==null && {GlobalSearchCategory.all,GlobalSearchCategory.hostels}.contains(q.category)) {
        try { final loaded=_demo?HostelRepository.demoHostels:await _realHostels();
          if(!current())return; _hostelCache=loaded;
        } catch (_) { warnings.add('Hostels could not be loaded. Please retry.'); }
      }
      final hostels=_hostelCache??<Hostel>[];
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
        if(q.maxBudget!=null) {
          final price=SmartSearchParser.minimumPrice(h.price);
          if(price==null||price>q.maxBudget!)continue;
        }
        final relevance=_score(q,h.name,['hostel',h.city,h.area,h.type,h.gender,h.price,h.roomType,h.availability,h.meals,h.description,h.address,h.facilities.join(' '),h.rooms.map((room)=>room.type).join(' '),(h.ac||h.rooms.any((room)=>room.ac))?'ac':'']);
        if(relevance<=0)continue;
        final score=relevance+(q.wantsBestRated?h.rating*2:0)+(h.isVerified?1:0);
        if(score>0)hits.add(_Hit(h.name,'Hostel','${h.price} • ${h.gender} • ${h.rating.toStringAsFixed(1)} ★',[h.area,h.city].where((e)=>e.isNotEmpty).join(', '),'/hostel/${h.id}',Icons.hotel_outlined,score,h));
      }

      final opportunities=InstituteOpportunityRepository.instance;
      if(!_opportunitiesLoaded && {GlobalSearchCategory.all, GlobalSearchCategory.admissions, GlobalSearchCategory.scholarships,GlobalSearchCategory.institutes}.contains(q.category)) {
        await opportunities.loadAll(); if(!current())return;
        _opportunitiesLoaded=opportunities.error==null;
        if(opportunities.error!=null)warnings.add('Institute updates could not be loaded. Please retry.');
      }
      for(final o in opportunities.error==null ? opportunities.allItems : []) {
        if(q.category!=GlobalSearchCategory.all&&q.category!=GlobalSearchCategory.admissions&&q.category!=GlobalSearchCategory.scholarships&&q.category!=GlobalSearchCategory.institutes)continue;
        if(q.category==GlobalSearchCategory.admissions&&o.kind!='admission')continue;
        if(q.category==GlobalSearchCategory.scholarships&&o.kind!='scholarship')continue;
        if(q.wantsOpenAdmissions && o.kind=='admission') {
          final open=q.program!=null && o.programKeys.isNotEmpty
              ? o.programKeys.where((key)=>_programMatches(q.program!,[key]))
                  .any((key)=>o.forProgram(key).statusAt()=='Open')
              : o.displayStatus=='Open';
          if(!open)continue;
        }
        final parent=ir.byId(o.instituteId);
        if(parent==null)continue;
        if(q.area!=null && !' ${parent.area} ${parent.town} ${parent.address}'.toLowerCase().contains(q.area!.toLowerCase()))continue;
        if(q.instituteName!=null && !_namedInstitute(parent,q.instituteName!))continue;
        if(q.program!=null && !_programMatches(q.program!,[...parent.programs,...parent.programGroups.values.expand((names)=>names),...o.programKeys,o.title]))continue;
        if(_filterAdmissionStatus!='All'&&o.displayStatus!=_filterAdmissionStatus)continue;
        if(_filterInstituteType!='All'&&parent!=null&&parent.type!=_filterInstituteType)continue;
        if(_filterProgram!='All'&&parent!=null&&!_programMatches(_filterProgram,[...parent.programs,...parent.programGroups.values.expand((names)=>names),...o.programKeys]))continue;
        if(_filterSector!='All'&&parent!=null&&parent.sector!=_filterSector)continue;
        if(_filterFeeRange!='All'&&parent!=null&&parent.feeRange!=_filterFeeRange)continue;
        if(q.location!=null&&parent!=null&&!' ${parent.city} ${parent.province} ${parent.address}'.toLowerCase().contains(q.location!.toLowerCase()))continue;
        if(_filterCity!='All'&&parent!=null&&parent.city!=_filterCity)continue;
        if(_filterArea!='All'&&parent!=null&&parent.area!=_filterArea&&parent.town!=_filterArea)continue;
        final score=_score(q,o.title,[o.kind,o.displayStatus,...o.programKeys,o.academicYear,o.intake,o.eligibility,o.description,o.provider,o.feeDetails,parent?.name??'',parent.city,parent.area,parent.town,parent.address,[...parent.programs,...parent.programGroups.values.expand((names)=>names)].join(' ')]);
        if(score>0)hits.add(_Hit(o.title,_title(o.kind),'${o.displayStatus} • ${o.academicYear} • ${parent?.name??o.provider}',parent?.city??'',parent==null?'/institutes':'/institute/${parent.id}/opportunities',Icons.event_available_outlined,score,o));
      }

      if(_demo && (q.category==GlobalSearchCategory.all||q.category==GlobalSearchCategory.scholarships)) {
        for(final s in _scholarships) {
          final score=_score(q,s.$1,['scholarship',s.$2,s.$3,s.$4,s.$5]);
          if(score>0)hits.add(_Hit('${s.$1} (Demo)','Scholarship • Demo','${s.$2} • ${s.$3} • ${s.$5}',s.$4,'/scholarships',Icons.card_giftcard_outlined,score));
        }
      }

      // Bounded Firebase resource lookup only in real identity mode.
      if(!_demo&&(q.category==GlobalSearchCategory.all||q.category==GlobalSearchCategory.resources)) {
        try {
          final docs=await _readAll(FirebaseFirestore.instance.collection('resources'),current);
          if(!current())return;
          for(final d in docs) {
            final data=d.data(),title=(data['title']??'Study Resource').toString(),desc=(data['description']??'').toString();
            final score=_score(q,title,['resource','study material',desc,(data['category']??'').toString()]);
            if(score>0)hits.add(_Hit(title,'Resource',desc,'Study material','/resources',Icons.menu_book_outlined,score));
          }
        } catch (_) { warnings.add('Resources could not be loaded. Please retry.'); }
      }

      // Community: fetch records from the active identity's source, then
      // rank locally with the new parser (not the legacy query filter).
      if(q.category==GlobalSearchCategory.all||q.category==GlobalSearchCategory.community) {
        try {
          final posts=await DatabaseService().postsStream().first;
          if(!current())return;
          for(final Post post in posts) {
            final score=_score(q,post.text,['community','post',post.authorName,post.category,post.tags.join(' '),post.attachments.map((a)=>a.values.join(' ')).join(' ')]);
            if(score>0)hits.add(_Hit(post.text.length>76?' ${post.text.substring(0,76)}…':post.text,'Community • ${post.category}','By ${post.authorName}\n${post.authorId}\n${post.likesCount} likes • ${post.commentsCount} comments','', '/community/post/${post.id}',Icons.forum_outlined,score,post));
          }
        } catch (_) { warnings.add('Community posts could not be loaded. Please retry.'); }
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
            final docs=await _readAll(FirebaseFirestore.instance.collection('users').where('privateProfile',isEqualTo:false),current);
            if(!current())return;
            for(final doc in docs) {
              final data=doc.data();
              final name=(data[ProfileFields.name]??data['displayName']??data['fullName']??'Student').toString();
              final score=_score(q,name,['people','student','profile',(data['username']??'').toString(),(data[ProfileFields.city]??'').toString(),(data['institute']??'').toString(),(data['program']??'').toString(),(data[ProfileFields.bio]??'').toString()]);
              if(score>0)hits.add(_Hit(name,'Profile',[(data['program']??'').toString(),(data['institute']??'').toString()].where((v)=>v.isNotEmpty).join(' • '),(data[ProfileFields.city]??'').toString(),'/profile/${doc.id}',Icons.person_outline,score));
            }
          } catch (_) { warnings.add('Public profiles could not be loaded. Please retry.'); }
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
        } catch (_) { warnings.add('Demo resources could not be loaded. Please retry.'); }
      }

      hits.sort((a,b)=>b.score.compareTo(a.score));
      if(!current())return;
      setState(() { _hits=hits; _warnings=warnings; _loading=false; _revealResults=true; });
    } catch (_) {
      if(!current())return;
      setState(() { _warnings=warnings; _loading=false; _revealResults=true; _error='Search complete nahi ho saki. Dobara try karein.'; });
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String,dynamic>>>> _readAll(
      Query<Map<String,dynamic>> source, bool Function() current) async {
    final docs=<QueryDocumentSnapshot<Map<String,dynamic>>>[];
    QueryDocumentSnapshot<Map<String,dynamic>>? cursor;
    while(current()) {
      var pageQuery=source.orderBy(FieldPath.documentId).limit(100);
      if(cursor!=null)pageQuery=pageQuery.startAfterDocument(cursor);
      final page=await pageQuery.get();
      if(!current())return docs;
      docs.addAll(page.docs);
      if(page.docs.length<100)break;
      cursor=page.docs.last;
    }
    return docs;
  }

  Future<List<Hostel>> _realHostels()=>HostelRepository().watchHostels().first;

  bool _programMatches(String wanted,Iterable<String> names) {
    final needle=SmartSearchParser.normalize(wanted);
    return names.any((name) {
      final value=SmartSearchParser.normalize(name);
      if(needle=='bs')return RegExp(r'\bbs\b').hasMatch(value)||value=='undergraduate';
      if(needle=='computer science')return value.contains('computer science')||value=='cs';
      return RegExp(r'\b'+RegExp.escape(needle)+r'\b').hasMatch(value);
    });
  }

  bool _namedInstitute(Institute institute,String wanted) {
    final name=SmartSearchParser.normalize(institute.name);
    final needle=SmartSearchParser.normalize(wanted);
    return name.contains(needle)
        || (needle=='bzu'&&name.contains('bahauddin zakariya'))
        || (needle=='uet'&&name.contains('university of engineering and technology'))
        || (needle=='nust'&&name.contains('national university of sciences and technology'))
        || (needle=='punjab university'&&name.contains('university of the punjab'));
  }

  bool _instituteAllowed(Institute i,ParsedGlobalQuery q) {
    if(q.category!=GlobalSearchCategory.all&&q.category!=GlobalSearchCategory.institutes&&q.category!=GlobalSearchCategory.admissions&&q.category!=GlobalSearchCategory.scholarships)return false;
    if(q.location!=null&&!' ${i.city} ${i.district} ${i.province} ${i.address}'.toLowerCase().contains(q.location!.toLowerCase()))return false;
    if(_filterCity!='All'&&i.city!=_filterCity)return false;
    if(_filterArea!='All'&&i.area!=_filterArea&&i.town!=_filterArea)return false;
    if(_filterInstituteType!='All'&&i.type!=_filterInstituteType)return false;
    if(_filterProgram!='All'&&_filterProgram!=''&&!_programMatches(_filterProgram,[...i.programs,...i.programGroups.values.expand((names)=>names),i.nextProgram]))return false;
    if(_filterSector!='All'&&i.sector!=_filterSector)return false;
    if(_filterAdmissionStatus!='All'&&i.admissionStatus!=_filterAdmissionStatus)return false;
    if(_filterFeeRange!='All'&&i.feeRange!=_filterFeeRange)return false;
    if(q.area!=null&&!' ${i.area} ${i.town} ${i.address}'.toLowerCase().contains(q.area!.toLowerCase()))return false;
    if(q.program!=null&&!_programMatches(q.program!,[...i.programs,...i.programGroups.values.expand((names)=>names),i.nextProgram]))return false;
    if(q.instituteName!=null&&!_namedInstitute(i,q.instituteName!))return false;
    // Admission and scholarship searches return actual published opportunities.
    if(q.category==GlobalSearchCategory.admissions||q.category==GlobalSearchCategory.scholarships)return false;
    if(q.category==GlobalSearchCategory.institutes) {
      if(RegExp(r'\bschool\b').hasMatch(q.normalized)&&i.type!='schools')return false;
      if(RegExp(r'\bcollege\b').hasMatch(q.normalized)&&i.type!='colleges')return false;
      if(RegExp(r'\buniversity\b').hasMatch(q.normalized)&&q.instituteName==null&&i.type!='universities')return false;
    }
    return true;
  }

  double _score(ParsedGlobalQuery q,String title,List<String> fields) {
    final hay=SmartSearchParser.normalize('$title ${fields.join(' ')}');
    if(q.location!=null&&!hay.contains(SmartSearchParser.normalize(q.location!)))return 0;
    if(q.area!=null&&!hay.contains(SmartSearchParser.normalize(q.area!)))return 0;
    final titleNorm=SmartSearchParser.normalize(title);
    var score=0.0;
    for(final term in q.terms) {
      if(titleNorm.split(' ').contains(term))score+=4;
      else if(titleNorm.contains(term))score+=2.5;
      else if(hay.contains(term))score+=1;
      else if(_near(hay,term))score+=0.5;
      else return 0; // A city/category alone must not satisfy unrelated keywords.
    }
    if(q.location!=null&&hay.contains(q.location!.toLowerCase()))score+=3;
    if(q.area!=null&&hay.contains(q.area!.toLowerCase()))score+=3;
    if(q.program!=null&&_programMatches(q.program!,[hay]))score+=2;
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

  String _instituteType(String t){final v=t.toLowerCase();if(v.contains('school'))return 'School';if(v.contains('college'))return 'College';if(v.contains('universit'))return 'University';return 'Institute';}
  String _title(String v)=>v.isEmpty?v:'${v[0].toUpperCase()}${v.substring(1)}';

  Future<void> _refresh() async {
    _institutesLoaded=false;_opportunitiesLoaded=false;_hostelCache=null;
    await search();
  }

  void _open(_Hit h){if(h.extra is Hostel){context.push(h.route,extra:h.extra);}else{context.push(h.route);}}

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(title:Text('Smart Global Search'),actions:[IconButton(tooltip:'Refresh results',onPressed:_loading||_controller.text.trim().isEmpty?null:_refresh,icon:Icon(Icons.refresh)),if(_controller.text.isNotEmpty)IconButton(onPressed:(){_searchEpoch++;_controller.clear();setState(() { _hits=[]; _parsed=null; _searched=false; _loading=false; _revealResults=false; _warnings=[]; _error=null; _filterCity='All';_filterArea='All';_filterGender='All';_filterHostelType='All';_filterRoomType='All';_filterInstituteType='All';_filterProgram='All';_filterSector='All';_filterAdmissionStatus='All';_filterFeeRange='All';_filterAcOnly=false; });},icon:Icon(Icons.close))]),
      body:SafeArea(child:Column(children:[
        Padding(padding:EdgeInsets.fromLTRB(14,14,14,8),child:TextField(
          controller:_controller,textInputAction:TextInputAction.search,onSubmitted:search,onChanged:(_){_searchEpoch++;setState((){_loading=false;_searched=false;_revealResults=false;_parsed=null;_hits=[];_warnings=[];_error=null;});},
          decoration:InputDecoration(hintText:'Lahore mein girls hostel under 15000',prefixIcon:Icon(Icons.travel_explore,color:AppPalette.of(context).accent),suffixIcon:IconButton(onPressed:_loading?null:()=>search(),icon:Icon(Icons.search,color:AppPalette.of(context).accent)),filled:true,fillColor:AppPalette.of(context).surface,border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide(color:AppPalette.of(context).border))),
        )),
        if(!_searched) Padding(padding:EdgeInsets.fromLTRB(16,4,16,8),child:Align(alignment:Alignment.centerLeft,child:Text('Apni normal zuban mein search karein',style:TextStyle(color:AppPalette.of(context).muted)))),
        if(!_searched) Padding(padding:EdgeInsets.symmetric(horizontal:12),child:Wrap(spacing:7,runSpacing:5,children:[
          'Lahore mein Educators','Johar Town mein achy hostel','Girls hostel under 15000','Arid mein admission open hai?','Scholarship for BS students'
        ].map((s)=>ActionChip(label:Text(s),backgroundColor:AppPalette.of(context).softSurface,side:BorderSide.none,onPressed:()=>search(s))).toList())),
        if(_parsed!=null)_understood(_parsed!),
        if(_warnings.isNotEmpty) Padding(padding:EdgeInsets.symmetric(horizontal:16,vertical:6),child:Text(_warnings.join('\n'),style:TextStyle(color:Theme.of(context).colorScheme.error))),
        if(_error!=null)Padding(padding:EdgeInsets.all(16),child:Text(_error!)),
        Expanded(
          child: _loading || !_revealResults
              ? (_searched ? const _SearchResultShimmer() : SizedBox.shrink())
              : _searched && _hits.isEmpty && _error==null
                  ? Center(child:Padding(padding:EdgeInsets.all(24),child:Text('Matching listing nahi mili. Query ya location badal kar dekhein.',textAlign:TextAlign.center)))
                  : ListView.separated(
                      padding:EdgeInsets.all(12),
                      itemCount:_hits.length>_visibleLimit?_visibleLimit+1:_hits.length,
                      separatorBuilder:(_,__)=>SizedBox(height:6),
                      itemBuilder:(context,index){
                        if(index==_visibleLimit)return TextButton(onPressed:()=>setState(()=>_visibleLimit+=60),child:Text('Show more results'));
                        final h=_hits[index];return Card(color:AppPalette.of(context).surface,margin:EdgeInsets.zero,child:ListTile(
                          leading:CircleAvatar(backgroundColor:AppPalette.of(context).softSurface,foregroundColor:AppPalette.of(context).ink,child:Icon(h.icon)),
                          title:Text(h.title,style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.of(context).ink)),
                          subtitle:Padding(padding:EdgeInsets.only(top:5),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(h.type,style:TextStyle(color:AppPalette.of(context).accent,fontWeight:FontWeight.w600)),if(h.location.isNotEmpty)Text(h.location),if(h.subtitle.isNotEmpty)Text(h.subtitle,maxLines:2,overflow:TextOverflow.ellipsis)])),
                          trailing:Icon(Icons.chevron_right,color:AppPalette.of(context).accent),onTap:()=>_open(h),
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
    final programs=<String>{...instituteItems.expand((i)=>[...i.programs,...i.programGroups.values.expand((names)=>names)]),...instituteItems.map((i)=>i.nextProgram)}..removeWhere((v)=>v.trim().isEmpty);
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
            }),child:Text('Clear all')),
          ]),
          SizedBox(height:10),
          _filterDropdown('City / location',options(cities),city,(v)=>setSheet(()=>city=v)),
          _filterDropdown('Area / town',options(areas),area,(v)=>setSheet(()=>area=v)),
          TextField(controller:budgetController,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:'Maximum budget / rent (PKR)')),
          SizedBox(height:8),
          _filterDropdown('Hostel gender',options(HostelRegistry.genders,all:'All'),gender,(v)=>setSheet(()=>gender=v)),
          _filterDropdown('Hostel type',options(HostelRegistry.types),hostelType,(v)=>setSheet(()=>hostelType=v)),
          _filterDropdown('Room type',options(HostelRegistry.roomTypes),roomType,(v)=>setSheet(()=>roomType=v)),
          SwitchListTile(contentPadding:EdgeInsets.zero,title:Text('AC room / hostel only'),value:acOnly,onChanged:(v)=>setSheet(()=>acOnly=v)),
          Divider(),
          Text('Institute filters',style:TextStyle(fontWeight:FontWeight.w700,color:AppPalette.of(context).ink)),
          _filterDropdown('Institute type',[
            DropdownMenuItem(value:'All',child:Text('All')),
            ...catalog.types.map((t)=>DropdownMenuItem(value:t.id,child:Text(t.label))),
          ],instituteType,(v)=>setSheet(()=>instituteType=v)),
          _filterDropdown('Program / degree',options(programs),program,(v)=>setSheet(()=>program=v)),
          _filterDropdown('Sector',options(sectors),sector,(v)=>setSheet(()=>sector=v)),
          _filterDropdown('Admission status',options(InstituteCatalog.admissionStatuses,all:'All'),admissionStatus,(v)=>setSheet(()=>admissionStatus=v)),
          _filterDropdown('Fee range',options(feeRanges),feeRange,(v)=>setSheet(()=>feeRange=v)),
          SizedBox(height:16),
          SizedBox(width:double.infinity,child:FilledButton(
            onPressed:(){
              var base=parsed.original;
              const aliases=['Depalpur','Dipalpur','Depal Pur','Dera Ghazi Khan','D.G. Khan','DG Khan','D G Khan','Okara','Lahore','Lahor','Islamabad','Islam Abad','Rawalpindi','Pindi','Multan','Bahawalpur','Bahawal Poor','Faisalabad','Faisal Abad','Karachi','Krachi','Peshawar','Peshawer','Quetta','Gujranwala','Sialkot','Sargodha','Johar Town','Gulberg','Bosan Road','Bosan','New Campus','Baghdad-ul-Jadeed'];
              for(final alias in aliases){base=base.replaceAll(RegExp(r'\b'+RegExp.escape(alias)+r'\b',caseSensitive:false),' ');}
              base=base.replaceAll(RegExp(r'\b(?:under|below|less than|max|maximum|budget|rs|pkr)?\s*\d[\d,]{3,}\b',caseSensitive:false),' ');
              base=base.replaceAll(RegExp(r'\b(?:girls?|female|women|ladies|boys?|male|men)\b',caseSensitive:false),' ');
              final parts=<String>[base.trim()];
              if(city!='All')parts.add('in $city');
              if(area!='All')parts.add(area);
              if(budgetController.text.trim().isNotEmpty)parts.add('under ${budgetController.text.trim()}');
              if(gender!='All')parts.add(gender=='Female'?'girls':gender=='Male'?'boys':'both genders');
              
              
              
              
              
              
              
              
              setState((){
                _filterCity=city;_filterArea=area;_filterGender=gender;
                _filterHostelType=hostelType;_filterRoomType=roomType;_filterAcOnly=acOnly;
                _filterInstituteType=instituteType;_filterProgram=program;_filterSector=sector;
                _filterAdmissionStatus=admissionStatus;_filterFeeRange=feeRange;
              });
              _controller.text=parts.where((v)=>v.trim().isNotEmpty).join(' ');
              Navigator.pop(sheetContext,true);
            },
            child:Text('Apply filters'),
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
      padding:EdgeInsets.only(bottom:8),
      child:DropdownButtonFormField<String>(
        value:safeValue,
        isExpanded:true,
        decoration:InputDecoration(labelText:label,border:OutlineInputBorder()),
        items:items,
        onChanged:(value){if(value!=null)onChanged(value);},
      ),
    );
  }

  Widget _understood(ParsedGlobalQuery q)=>Container(
    width:double.infinity,
    margin:EdgeInsets.fromLTRB(14,6,14,4),
    padding:EdgeInsets.all(12),
    decoration:BoxDecoration(color:AppPalette.of(context).softSurface,borderRadius:BorderRadius.circular(14),border:Border.all(color:AppPalette.of(context).border)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(Icons.psychology_alt_outlined,color:AppPalette.of(context).ink),SizedBox(width:6),Text(q.isRomanUrdu?'Maine ye samjha':'What I understood',style:TextStyle(fontWeight:FontWeight.w800,color:AppPalette.of(context).ink))]),
      SizedBox(height:7),
      _WordByWordText(key:ValueKey(q.summary),text:q.summary,style:TextStyle(color:AppPalette.of(context).ink,height:1.45)),
      if(_loading) Padding(
        padding:EdgeInsets.only(top:9),
        child:_SearchThinkingStatus(isRomanUrdu:q.isRomanUrdu),
      ),
      Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:_editFilters,icon:Icon(Icons.tune,size:17),label:Text(q.isRomanUrdu?'Filters badlein':'Edit filters'))),
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
    _timer=Timer.periodic(Duration(milliseconds:420),(timer){
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
      duration:Duration(milliseconds:100),
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
    _timer=Timer.periodic(Duration(milliseconds:1750),(_){
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
          valueColor:AlwaysStoppedAnimation<Color>(AppPalette.of(context).accent),
        ),
      ),
      SizedBox(width:8),
      Expanded(child:AnimatedSwitcher(
        duration:Duration(milliseconds:260),
        child:Text(messages[_step],key:ValueKey(_step),style:TextStyle(color:AppPalette.of(context).muted,fontSize:12,fontStyle:FontStyle.italic)),
      )),
      SizedBox(width:4),
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
    _timer=Timer.periodic(Duration(milliseconds:380),(_){
      if(mounted)setState(()=>_dots=_dots%3+1);
    });
  }
  @override void dispose(){_timer?.cancel();super.dispose();}
  @override Widget build(BuildContext context)=>Text(
    List.filled(_dots,'•').join(' '),
    style:TextStyle(color:AppPalette.of(context).accent,fontWeight:FontWeight.w800),
  );
}

class _SearchResultShimmer extends StatefulWidget {
  const _SearchResultShimmer();
  @override State<_SearchResultShimmer> createState()=>_SearchResultShimmerState();
}

class _SearchResultShimmerState extends State<_SearchResultShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller=AnimationController(vsync:this,duration:Duration(milliseconds:950))..repeat(reverse:true);
  @override void dispose(){_controller.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    return AnimatedBuilder(
      animation:_controller,
      builder:(context,_)=>ListView.builder(
        padding:EdgeInsets.all(12),
        itemCount:6,
        itemBuilder:(context,index){
          final opacity=0.28+(_controller.value*0.42);
          return Opacity(
            opacity:opacity,
            child:Container(
              margin:EdgeInsets.only(bottom:9),
              padding:EdgeInsets.all(14),
              decoration:BoxDecoration(color:AppPalette.of(context).surface,borderRadius:BorderRadius.circular(16),border:Border.all(color:AppPalette.of(context).border)),
              child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Container(width:46,height:46,decoration:BoxDecoration(color:AppPalette.of(context).softSurface,shape:BoxShape.circle)),
                SizedBox(width:12),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Container(height:15,width:180,decoration:BoxDecoration(color:AppPalette.of(context).border,borderRadius:BorderRadius.circular(5))),
                  SizedBox(height:10),
                  Container(height:10,width:95,decoration:BoxDecoration(color:AppPalette.of(context).softSurface,borderRadius:BorderRadius.circular(5))),
                  SizedBox(height:8),
                  Container(height:10,width:double.infinity,decoration:BoxDecoration(color:AppPalette.of(context).border,borderRadius:BorderRadius.circular(5))),
                  SizedBox(height:6),
                  Container(height:10,width:145,decoration:BoxDecoration(color:AppPalette.of(context).softSurface,borderRadius:BorderRadius.circular(5))),
                ])),
              ]),
            ),
          );
        },
      ),
    );
  }
}
