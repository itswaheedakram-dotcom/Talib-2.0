import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../../../models/institute_opportunity.dart';
import '../../../models/hostel.dart';
import '../../../hostels/data/hostel_repository.dart';
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
  bool _loading=false, _searched=false;
  String? _error;
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
    setState(() { _parsed=q; _loading=true; _searched=true; _error=null; });
    final hits=< _Hit>[];
    try {
      final ir=InstituteRepository.instance;
      await ir.load();
      for(final i in ir.items) {
        if(!_instituteAllowed(i,q))continue;
        final score=_score(q,i.name,[i.type,i.subcategory,i.city,i.province,i.district,i.town,i.area,i.address,i.description,i.board,i.sector,i.nextProgram,i.admissionStatus,i.programs.join(' ')]);
        if(score>0)hits.add(_Hit(i.name,_instituteType(i.type),i.description.isEmpty?' ${i.sector} • ${i.programs.take(3).join(', ')}':i.description,[i.area,i.city,i.province].where((e)=>e.isNotEmpty).join(', '),'/institute/${i.id}',Icons.school_outlined,score,i));
      }

      final hostels=_demo?HostelRepository.demoHostels:await _realHostels();
      for(final h in hostels) {
        if(q.category!=GlobalSearchCategory.all&&q.category!=GlobalSearchCategory.hostels)continue;
        if(h.status.toLowerCase()!='approved')continue;
        if(q.location!=null&&!' ${h.city} ${h.address}'.toLowerCase().contains(q.location!.toLowerCase()))continue;
        if(q.area!=null&&!' ${h.area} ${h.address}'.toLowerCase().contains(q.area!.toLowerCase()))continue;
        if(q.gender!=null&&h.gender.toLowerCase()!=q.gender!.toLowerCase())continue;
        if(q.maxBudget!=null&&_money(h.price)>q.maxBudget!)continue;
        final score=_score(q,h.name,['hostel',h.city,h.area,h.type,h.gender,h.price,h.roomType,h.availability,h.meals,h.description,h.address,h.facilities.join(' ')])+(q.wantsBestRated?h.rating*2:0)+(h.isVerified?1:0);
        if(score>0)hits.add(_Hit(h.name,'Hostel','${h.price} • ${h.gender} • ${h.rating.toStringAsFixed(1)} ★',[h.area,h.city].where((e)=>e.isNotEmpty).join(', '),'/hostel/${h.id}',Icons.hotel_outlined,score,h));
      }

      final opportunities=InstituteOpportunityRepository.instance;
      await opportunities.loadAll();
      for(final o in opportunities.allItems) {
        if(q.category!=GlobalSearchCategory.all&&q.category!=GlobalSearchCategory.admissions&&q.category!=GlobalSearchCategory.scholarships&&q.category!=GlobalSearchCategory.institutes)continue;
        if(q.category==GlobalSearchCategory.admissions&&o.kind!='admission')continue;
        if(q.category==GlobalSearchCategory.scholarships&&o.kind!='scholarship')continue;
        if(q.wantsOpenAdmissions&&q.category==GlobalSearchCategory.admissions&&!o.status.toLowerCase().contains('open'))continue;
        final parent=ir.byId(o.instituteId);
        if(q.location!=null&&parent!=null&&!' ${parent.city} ${parent.province} ${parent.address}'.toLowerCase().contains(q.location!.toLowerCase()))continue;
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
            if(score>0)hits.add(_Hit(post.text.length>76?' ${post.text.substring(0,76)}…':post.text,'Community • ${post.category}','By ${post.authorName} • ${post.likesCount} likes • ${post.commentsCount} comments','', '/community/post/${post.id}',Icons.forum_outlined,score,post));
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
              final name=(data['name']??data['displayName']??data['fullName']??'Student').toString();
              final score=_score(q,name,['people','student','profile',(data['username']??'').toString(),(data['city']??'').toString(),(data['institute']??'').toString(),(data['program']??'').toString(),(data['bio']??'').toString()]);
              if(score>0)hits.add(_Hit(name,'Profile',[(data['program']??'').toString(),(data['institute']??'').toString()].where((v)=>v.isNotEmpty).join(' • '),(data['city']??'').toString(),'/profile/${doc.id}',Icons.person_outline,score));
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
      setState(() { _hits=hits.take(60).toList(); _loading=false; });
    } catch (_) {
      if(!mounted)return;
      setState(() { _loading=false; _error='Search complete nahi ho saki. Dobara try karein.'; });
    }
  }

  Future<List<Hostel>> _realHostels() async {
    try{return await HostelRepository().watchHostels().first;}catch(_){return const <Hostel>[];}
  }

  bool _instituteAllowed(Institute i,ParsedGlobalQuery q) {
    if(q.category!=GlobalSearchCategory.all&&q.category!=GlobalSearchCategory.institutes&&q.category!=GlobalSearchCategory.admissions&&q.category!=GlobalSearchCategory.scholarships)return false;
    if(q.location!=null&&!' ${i.city} ${i.district} ${i.province} ${i.address}'.toLowerCase().contains(q.location!.toLowerCase()))return false;
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

  void _open(_Hit h){if(h.extra is Hostel){context.push(h.route,extra:h.extra);}else{context.push(h.route);}}

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(title:const Text('Smart Global Search'),actions:[if(_controller.text.isNotEmpty)IconButton(onPressed:(){_controller.clear();setState(() { _hits=[]; _parsed=null; _searched=false; _error=null; });},icon:const Icon(Icons.close))]),
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
        if(_loading)const LinearProgressIndicator(minHeight:2,color:AppColors.primaryGreen),
        if(_error!=null)Padding(padding:const EdgeInsets.all(16),child:Text(_error!)),
        if(_searched&&!_loading&&_hits.isEmpty&&_error==null)const Expanded(child:Center(child:Padding(padding:EdgeInsets.all(24),child:Text('Matching listing nahi mili. Query ya location badal kar dekhein.',textAlign:TextAlign.center))))
        else Expanded(child:ListView.separated(padding:const EdgeInsets.all(12),itemCount:_hits.length,separatorBuilder:(_,__)=>const SizedBox(height:6),itemBuilder:(context,index){
          final h=_hits[index];return Card(color:AppColors.white,margin:EdgeInsets.zero,child:ListTile(
            leading:CircleAvatar(backgroundColor:AppColors.softGreen,foregroundColor:AppColors.darkGreen,child:Icon(h.icon)),
            title:Text(h.title,style:const TextStyle(fontWeight:FontWeight.w700,color:AppColors.darkGreen)),
            subtitle:Padding(padding:const EdgeInsets.only(top:5),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(h.type,style:const TextStyle(color:AppColors.primaryGreen,fontWeight:FontWeight.w600)),if(h.location.isNotEmpty)Text(h.location),if(h.subtitle.isNotEmpty)Text(h.subtitle,maxLines:2,overflow:TextOverflow.ellipsis)])),
            trailing:const Icon(Icons.chevron_right,color:AppColors.primaryGreen),onTap:()=>_open(h),
          ));
        })),
      ])),
    );
  }

  Widget _understood(ParsedGlobalQuery q)=>Container(
    margin:const EdgeInsets.fromLTRB(14,6,14,4),padding:const EdgeInsets.all(10),
    decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(14),border:Border.all(color:AppColors.divider)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Row(children:[Icon(Icons.psychology_alt_outlined,color:AppColors.darkGreen),SizedBox(width:6),Text('Maine ye samjha',style:TextStyle(fontWeight:FontWeight.w800,color:AppColors.darkGreen))]),
      const SizedBox(height:6),
      Wrap(spacing:5,runSpacing:3,children:q.understood.map((s)=>Chip(label:Text(s,style:const TextStyle(fontSize:11,color:AppColors.darkGreen)),backgroundColor:AppColors.white,side:BorderSide.none,visualDensity:VisualDensity.compact)).toList()),
    ]),
  );
}
