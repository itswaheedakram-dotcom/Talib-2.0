import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/active_profile_controller.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/database_service.dart';
import '../../institutes/data/institute_repository.dart';
import '../../institutes/data/institute_opportunity_repository.dart';
import '../../hostels/data/hostel_repository.dart';
import '../../models/hostel.dart';
import '../../models/post.dart';
import '../domain/search_catalog.dart';
import 'demo_search_catalog.dart';
import '../domain/smart_search_parser.dart';

const builtInCatalogs=<SearchCatalog>[
 SearchCatalog(id:'institutes',label:'Institutes',aliases:['institute','school','college','university'],facets:[SearchFacet('type','Institute type'),SearchFacet('sector','Sector'),SearchFacet('program','Program'),SearchFacet('status','Admission status')]),
 SearchCatalog(id:'hostels',label:'Hostels',aliases:['hostel','residence','accommodation'],facets:[SearchFacet('gender','For'),SearchFacet('type','Hostel type'),SearchFacet('roomType','Room type'),SearchFacet('rentBasis','Rent basis'),SearchFacet('budget','Maximum rent (PKR)',type:'number'),SearchFacet('ac','AC only',type:'toggle'),SearchFacet('availableOnly','Available beds only',type:'toggle')]),
 SearchCatalog(id:'courses',label:'Courses',aliases:['course','courses','program','programs'],facets:[SearchFacet('program','Program'),SearchFacet('mode','Delivery mode')]),
 SearchCatalog(id:'admissions',label:'Admissions',aliases:['admission','admissions'],facets:[SearchFacet('status','Status'),SearchFacet('program','Program')]),
 SearchCatalog(id:'scholarships',label:'Scholarships',aliases:['scholarship','scholarships','financial aid'],facets:[SearchFacet('status','Status'),SearchFacet('program','Program')]),
 SearchCatalog(id:'jobs',label:'Jobs',aliases:['job','jobs','vacancy','vacancies'],facets:[SearchFacet('field','Field'),SearchFacet('mode','Work mode')]),
 SearchCatalog(id:'internships',label:'Internships',aliases:['internship','internships'],facets:[SearchFacet('field','Field'),SearchFacet('mode','Work mode')]),
 SearchCatalog(id:'seminars',label:'Seminars',aliases:['seminar','seminars','event','events','workshop'],facets:[SearchFacet('mode','Mode'),SearchFacet('category','Topic')]),
 SearchCatalog(id:'people',label:'People',aliases:['people','profile','student','user'],facets:[SearchFacet('program','Program')]),
 SearchCatalog(id:'posts',label:'Posts',aliases:['post','community','discussion'],facets:[SearchFacet('category','Topic')]),
 SearchCatalog(id:'resources',label:'Resources',aliases:['resource','resources','notes','study material'],facets:[SearchFacet('category','Subject')]),
];

class SearchRegistry {
 final bool demo;
 final String uid;
 final SearchEngine engine=SearchEngine();
 final List<String> warnings=[];
 final _shared=_SharedLoads();
 SearchRegistry({required this.demo,required this.uid});
 Future<void> initialize()async{
  final descriptors={for(final c in builtInCatalogs)c.id:c};
  final published=<String>{};
  if(!demo){try{
   final snapshot=await FirebaseFirestore.instance.collection('searchCatalogs').where('enabled',isEqualTo:true).get();
   for(final doc in snapshot.docs){final c=SearchCatalog.fromMap(doc.id,doc.data());if(c.valid){descriptors[c.id]=c;published.add(c.id);}}
  }catch(_){warnings.add('Additional catalogues are unavailable. Retry to reload them.');}}
  for(final c in descriptors.values){engine.register(_CatalogAdapter(c,demo,uid,published.contains(c.id),_shared));}
  engine.resetScope('${demo?'demo':'real'}:$uid');
 }
}

class _Cursor {
 final DocumentSnapshot<Map<String,dynamic>>? native,generic;
 final bool nativeMore,genericMore;
 const _Cursor({this.native,this.generic,this.nativeMore=false,this.genericMore=false});
}
class _CatalogAdapter implements SearchAdapter {
 @override final SearchCatalog catalog;
 final bool demo,genericEnabled;
 final String uid;
 final _SharedLoads shared;
 _CatalogAdapter(this.catalog,this.demo,this.uid,this.genericEnabled,this.shared);
 @override Future<SearchPage> load({Object? cursor})async{
  final previous=cursor is _Cursor?cursor:null;
  final records=<SearchRecord>[if(demo&&cursor==null)...demoCatalogRecords.where((r)=>r.catalogId==catalog.id)];
  DocumentSnapshot<Map<String,dynamic>>? nativeCursor,genericCursor;
  var nativeMore=false,genericMore=false;
  final id=catalog.id;
  if(previous==null||previous.nativeMore){
   if(const ['institutes','courses','admissions','scholarships'].contains(id)){
    final ir=InstituteRepository.instance;await shared.institutes();if(ir.error!=null)throw StateError(ir.error!);
    if(id=='institutes'){
     for(final i in ir.items){records.add(SearchRecord(id:i.id,catalogId:id,title:i.name,description:'${i.description} ${i.address}',city:i.city,area:i.area.isEmpty?i.town:i.area,route:'/institute/${i.id}',tags:_instituteAliases(i.name),attributes:{'type':i.type,'sector':i.sector,'program':[...i.programs,...i.programGroups.values.expand((x)=>x)],'status':i.admissionStatus,'feeRange':i.feeRange,'facilities':i.facilities},isDemo:demo));}
    }else{
     final opportunities=InstituteOpportunityRepository.instance;await shared.opportunities();if(opportunities.error!=null)throw StateError(opportunities.error!);
     final kind=id=='courses'?'course':id=='admissions'?'admission':'scholarship';
     for(final o in opportunities.allItems.where((o)=>o.kind==kind)){
      final parent=ir.byId(o.instituteId);if(parent==null)continue;
      records.add(SearchRecord(id:o.id,catalogId:id,title:o.title,description:'${parent.name} ${o.description} ${o.eligibility}',city:parent.city,area:parent.area,route:'/institute/${parent.id}/opportunities?kind=$kind',tags:_instituteAliases(parent.name),attributes:{'status':o.displayStatus,'programStatus':{for(final key in o.programKeys)key:o.forProgram(key).statusAt()},'program':o.programKeys,'mode':o.deliveryMode,'provider':o.provider,'deadline':o.deadline},isDemo:demo));
     }
     if(id=='courses'){for(final i in ir.items){for(final p in {...i.programs,...i.programGroups.values.expand((v)=>v)}){
      records.add(SearchRecord(id:'${i.id}:$p',catalogId:id,title:p,description:i.name,city:i.city,area:i.area,route:'/institute/${i.id}/programs',tags:_instituteAliases(i.name),attributes:{'program':p,'provider':i.name},isDemo:demo));
     }}}
    }
   }else if(demo){
    if(id=='hostels'){records.addAll(HostelRepository.demoHostels.where((h)=>h.status=='approved').map(_hostel));}
    if(id=='people'){for(final p in temporaryProfiles){records.add(SearchRecord(id:p.id,catalogId:id,title:p.name,description:'${p.level} ${p.institute}',city:p.city,route:'/profile/${p.id}',attributes:{'username':p.username,'program':p.program},isDemo:true));}}
    if(id=='posts'){records.addAll((await DatabaseService().postsStream().first).map(_post));}
    if(id=='resources'){for(final d in await DatabaseService().demoResourcesStream(uid).first){records.add(_resource((d['id']??d['title']).toString(),d));}}
   }else if(const ['hostels','people','posts','resources'].contains(id)){
    Query<Map<String,dynamic>> query=FirebaseFirestore.instance.collection(id=='people'?'users':id);
    if(id=='hostels')query=query.where('status',isEqualTo:'approved');
    if(id=='people')query=query.where('privateProfile',isEqualTo:false);
    query=query.orderBy(FieldPath.documentId).limit(200);
    if(previous?.native!=null)query=query.startAfterDocument(previous!.native!);
    final snapshot=await query.get();nativeMore=snapshot.docs.length==200;if(snapshot.docs.isNotEmpty)nativeCursor=snapshot.docs.last;
    for(final doc in snapshot.docs){final d=doc.data();
     if(id=='hostels')records.add(_hostel(Hostel.fromDoc(doc)));
     if(id=='posts')records.add(_post(Post.fromDoc(doc)));
     if(id=='resources')records.add(_resource(doc.id,d));
     if(id=='people')records.add(SearchRecord(id:doc.id,catalogId:id,title:(d['name']??d['displayName']??'Student').toString(),description:(d['bio']??'').toString(),city:(d['city']??'').toString(),route:'/profile/${doc.id}',attributes:{'username':d['username']??'','program':d['program']??'','institute':d['institute']??''}));
    }
   }
  }
  if(!demo&&genericEnabled&&(previous==null||previous.genericMore)){
   // Fixed collection and schema; descriptor cannot redirect to private data.
   Query<Map<String,dynamic>> query=FirebaseFirestore.instance.collection('catalogItems').where('catalogId',isEqualTo:id).where('published',isEqualTo:true).orderBy(FieldPath.documentId).limit(200);
   if(previous?.generic!=null)query=query.startAfterDocument(previous!.generic!);
   final snapshot=await query.get();genericMore=snapshot.docs.length==200;if(snapshot.docs.isNotEmpty)genericCursor=snapshot.docs.last;
   records.addAll(snapshot.docs.map((d)=>publicCatalogRecord(d.id,d.data())));
  }
  return SearchPage(records,hasMore:nativeMore||genericMore,cursor:_Cursor(native:nativeCursor??previous?.native,generic:genericCursor??previous?.generic,nativeMore:nativeMore,genericMore:genericMore));
 }
 SearchRecord _hostel(Hostel h){
  final offers=h.rooms.isEmpty?<Map<String,dynamic>>[{'budget':SmartSearchParser.minimumPrice(h.price),'roomType':h.roomType,'ac':h.ac}]:h.rooms.map((r)=>{'budget':SmartSearchParser.minimumPrice(r.rent),'roomType':r.type,'rentBasis':r.rentBasis,'ac':r.ac,'availableOnly':r.availableBeds}).toList();
  final prices=offers.map((o)=>o['budget']).whereType<num>().toList()..sort();
  return SearchRecord(id:h.id,catalogId:'hostels',title:h.name,description:'${h.price} • ${h.gender} • ${h.description} ${h.address}',city:h.city,area:h.area,route:'/hostel/${h.id}',extra:h,attributes:{'gender':h.gender,'type':h.type,'roomType':offers.map((v)=>v['roomType']).toList(),'rentBasis':offers.map((v)=>v['rentBasis']).whereType<String>().toList(),'facilities':h.facilities,'offers':offers,'budget':prices.isEmpty?null:prices.first,'rating':h.rating},isDemo:demo);
 }
 SearchRecord _post(Post p)=>SearchRecord(id:p.id,catalogId:'posts',title:p.text,description:'By ${p.authorName}',route:'/community/post/${p.id}',tags:p.tags,attributes:{'category':p.category},updatedAt:p.createdAt,isDemo:demo);
 SearchRecord _resource(String id,Map<String,dynamic> d)=>SearchRecord(id:id,catalogId:'resources',title:(d['title']??'Study resource').toString(),description:(d['description']??'').toString(),attributes:{'category':d['category']??'','url':d['url']??''},isDemo:demo);
}
SearchRecord publicCatalogRecord(String id,Map<String,dynamic> d)=>SearchRecord(id:'catalog:$id',catalogId:(d['catalogId']??'').toString(),title:(d['title']??'').toString(),route:'/catalog/${Uri.encodeComponent((d['catalogId']??'').toString())}/${Uri.encodeComponent(id)}',description:(d['description']??'').toString(),city:(d['city']??'').toString(),area:(d['area']??'').toString(),tags:(d['tags'] is List?(d['tags'] as List).whereType<String>().toList():const []),attributes:d['attributes'] is Map?Map<String,dynamic>.from(d['attributes']):const {},published:d['published']==true,updatedAt:d['updatedAt'] is Timestamp?(d['updatedAt'] as Timestamp).toDate():null);

List<String> _instituteAliases(String name){final n=name.toLowerCase();return [if(n.contains('arid'))'arid',if(n.contains('bahauddin'))'bzu',if(n.contains('national university of sciences'))'nust',if(n.contains('engineering and technology'))'uet',if(n.contains('university of the punjab'))'punjab university',if(n.contains('islamia university'))'iub'];}

class _SharedLoads {
 Future<void>? _institutes,_opportunities;
 Future<void> institutes()=>_institutes??=InstituteRepository.instance.load().whenComplete(()=>_institutes=null);
 Future<void> opportunities()=>_opportunities??=InstituteOpportunityRepository.instance.loadAll().whenComplete(()=>_opportunities=null);
}
