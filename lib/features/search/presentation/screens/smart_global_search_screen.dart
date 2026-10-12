import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/verified_account_name.dart';
import '../../data/search_registry.dart';
import '../../domain/search_catalog.dart';

class SmartGlobalSearchScreen extends StatefulWidget {
 const SmartGlobalSearchScreen({super.key,this.initialCategory});
 final String? initialCategory;
 @override State<SmartGlobalSearchScreen> createState()=>_SmartGlobalSearchScreenState();
}
class _SmartGlobalSearchScreenState extends State<SmartGlobalSearchScreen> {
 final _text=TextEditingController();
 SearchRegistry? _registry;
 SearchResponse? _response;
 Map<String,String> _filters={};
 List<String> _recent=[];
 String? _category;
 String _sort='Relevance',_scope='';
 bool _loading=false,_ready=false;
 int _epoch=0,_limit=20;
 Timer? _debounce;
 StreamSubscription<User?>? _auth;
 bool get _demo=>ActiveProfileController.instance.isDemo||!FirebaseService.initialized;
 String get _uid=>_demo?(ActiveProfileController.instance.effectiveUid??'demo-user-1'):(FirebaseAuth.instance.currentUser?.uid??'signed-out');
 String get _currentScope=>'${_demo?'demo':'real'}:$_uid';
 String get _recentKey=>'talib.search.recent.$_scope';
 @override void initState(){super.initState();_category=widget.initialCategory;ActiveProfileController.instance.addListener(_identityChanged);if(FirebaseService.initialized)_auth=FirebaseAuth.instance.authStateChanges().listen((_)=>_identityChanged());_initialize();}
 void _identityChanged(){if(_scope!=_currentScope)_initialize();}
 Future<void> _initialize()async{
  final request=++_epoch;_scope=_currentScope;final scope=_scope;
  final registry=SearchRegistry(demo:_demo,uid:_uid);
  if(mounted)setState((){_registry=null;_response=null;_recent=[];_ready=false;_loading=false;_filters={};_text.clear();});
  await registry.initialize();final prefs=await SharedPreferences.getInstance();
  if(!mounted||request!=_epoch||scope!=_currentScope)return;
  setState((){_registry=registry;_ready=true;_recent=prefs.getStringList(_recentKey)??[];});
  if(widget.initialCategory!=null)await _search();
 }
 @override void dispose(){_epoch++;_debounce?.cancel();_auth?.cancel();ActiveProfileController.instance.removeListener(_identityChanged);_text.dispose();super.dispose();}
 Future<void> _saveRecent()async{final key=_recentKey;final values=List<String>.from(_recent);final prefs=await SharedPreferences.getInstance();await prefs.setStringList(key,values);}
 Future<void> _search({String? input,bool more=false,bool refresh=false})async{
  final registry=_registry;if(registry==null)return;
  if(input!=null)_text.text=input;
  final query=_text.text.trim();final request=++_epoch,scope=_scope;
  FocusScope.of(context).unfocus();setState((){_loading=true;if(!more)_limit=20;});
  final result=await registry.engine.search(query,category:_category,filters:_filters,sort:_sort,more:more,refresh:refresh);
  if(!mounted||request!=_epoch||scope!=_currentScope)return;
  setState((){_response=result;_loading=false;if(query.isNotEmpty){_recent.remove(query);_recent.insert(0,query);_recent=_recent.take(8).toList();}});await _saveRecent();
 }
 void _changed(String value){_epoch++;_debounce?.cancel();setState((){_loading=false;_response=null;});_debounce=Timer(const Duration(milliseconds:250),(){if(mounted)setState((){});});}
 void _clear(){_text.clear();_filters={};_changed('');}
 List<String> get _suggestions{
  final query=SearchEngine.normalize(_text.text);if(query.isEmpty)return [];
  final engine=_registry?.engine;if(engine==null)return [];
  return <String>{...engine.catalogs.map((c)=>c.label),...engine.cachedRecords.map((r)=>r.title),...engine.cachedRecords.map((r)=>r.city),..._recent}.where((v)=>v.isNotEmpty&&SearchEngine.normalize(v).contains(query)&&v!=_text.text).take(6).toList();
 }
 Future<void> _editFilters()async{
  final engine=_registry!.engine;final category=_response?.category??_category??'all';
  final descriptor=engine.catalogs.where((c)=>c.id==category).firstOrNull;
  final facets=[const SearchFacet('city','City'),const SearchFacet('area','Area / town'),...?descriptor?.facets];
  final draft={...?_response?.filters,..._filters};
  final controls=<String,TextEditingController>{for(final f in facets.where((f)=>f.type=='number'))f.key:TextEditingController(text:(draft[f.key]??'').replaceFirst('<=',''))};
  final applied=await showModalBottomSheet<Map<String,String>>(context:context,isScrollControlled:true,showDragHandle:true,builder:(sheet)=>StatefulBuilder(builder:(context,update)=>Padding(padding:EdgeInsets.fromLTRB(20,8,20,MediaQuery.of(context).viewInsets.bottom+24),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[Expanded(child:Text('Filters',style:Theme.of(context).textTheme.titleLarge)),TextButton(onPressed:()=>update((){for(final f in facets){draft[f.key]='';controls[f.key]?.clear();}}),child:const Text('Clear all'))]),
   if(category=='all')const Padding(padding:EdgeInsets.only(bottom:12),child:Text('Choose a category for its specific filters.')),
   for(final f in facets)if(f.type=='toggle')SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(f.label),value:draft[f.key]=='true',onChanged:(v)=>update(()=>draft[f.key]=v?'true':''))else if(f.type=='number')Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:controls[f.key],keyboardType:TextInputType.number,decoration:InputDecoration(labelText:f.label)))else Padding(padding:const EdgeInsets.only(bottom:12),child:DropdownButtonFormField<String>(value:draft[f.key]??'',isExpanded:true,decoration:InputDecoration(labelText:f.label),items:[const DropdownMenuItem(value:'',child:Text('Any')),...{...engine.values(category,f.key),if((draft[f.key]??'').isNotEmpty)draft[f.key]!}.map((v)=>DropdownMenuItem(value:v,child:Text(v)))],onChanged:(v)=>update(()=>draft[f.key]=v??''))),
   const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton(onPressed:(){for(final entry in controls.entries){final text=entry.value.text.trim();if(text.isNotEmpty&&(double.tryParse(text)==null||double.parse(text)<0)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter a valid positive amount.')));return;}draft[entry.key]=text.isEmpty?'':'<=$text';}Navigator.pop(sheet,draft);},child:const Text('Apply filters'))),
  ])))));
  for(final c in controls.values){c.dispose();}if(applied!=null&&mounted){_filters=applied;await _search();}
 }
 void _open(SearchRecord r){if(r.route.isNotEmpty){context.push(r.route,extra:r.extra);}else{Navigator.of(context).push(MaterialPageRoute(builder:(_)=>CatalogRecordScreen(record:r)));}}
 @override Widget build(BuildContext context){
  final engine=_registry?.engine,response=_response;
  final selected=response?.category??_category??'all';
  final warnings=[...?_registry?.warnings,...?response?.warnings];
  return Scaffold(appBar:AppBar(title:const Text('Search')),body:SafeArea(child:Column(children:[
   Padding(padding:const EdgeInsets.fromLTRB(16,12,16,8),child:TextField(controller:_text,textInputAction:TextInputAction.search,onSubmitted:(v)=>_search(),onChanged:_changed,decoration:InputDecoration(hintText:'Search Talib…',prefixIcon:const Icon(Icons.search),suffixIcon:_text.text.isEmpty?null:IconButton(tooltip:'Clear search',onPressed:_clear,icon:const Icon(Icons.close)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14))))),
   if(!_ready)const LinearProgressIndicator(),
   if(engine!=null)SizedBox(height:48,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16),children:[for(final c in [const SearchCatalog(id:'all',label:'All'),...engine.catalogs])Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(c.label),selected:selected==c.id,onSelected:(_){_category=c.id;_filters={};_search();}))])),
   if(response!=null)Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[Expanded(child:Text('${response.matches.length}${response.hasMore?'+':''} results')),TextButton.icon(onPressed:_loading?null:_editFilters,icon:const Icon(Icons.tune,size:18),label:const Text('Filters')),PopupMenuButton<String>(tooltip:'Sort results',initialValue:_sort,onSelected:(v){_sort=v;_search();},itemBuilder:(_)=>[for(final s in ['Relevance','Newest',if(selected=='hostels')...['Top rated','Price low']])PopupMenuItem(value:s,child:Text(s))],child:Padding(padding:const EdgeInsets.all(8),child:Text(_sort)))])),
   if(response!=null&&response.filters.values.any((v)=>v.isNotEmpty))SizedBox(height:42,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16),children:[for(final e in response.filters.entries.where((e)=>e.value.isNotEmpty))Padding(padding:const EdgeInsets.only(right:6),child:InputChip(label:Text('${e.key}: ${e.value}'),onDeleted:(){_filters={...response.filters,e.key:''};_search();}))])),
   if(warnings.isNotEmpty)Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[const Icon(Icons.info_outline,size:18),const SizedBox(width:8),Expanded(child:Text(warnings.join('\n'),maxLines:3,overflow:TextOverflow.ellipsis)),TextButton(onPressed:_loading?null:()=>_initialize(),child:const Text('Retry'))])),
   if(_loading)const LinearProgressIndicator(),
   Expanded(child:response==null?_discovery():response.matches.isEmpty&&!_loading?Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.search_off,size:44),const SizedBox(height:12),Text(warnings.isEmpty?'No matching results':'Some sources could not be loaded',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:8),const Text('Try another name, category or location.',textAlign:TextAlign.center),TextButton(onPressed:(){_filters={for(final k in response.filters.keys)k:''};_search(refresh:true);},child:const Text('Clear filters and retry'))]))):ListView.separated(padding:const EdgeInsets.all(16),itemCount:(response.matches.length<_limit?response.matches.length:_limit)+((response.matches.length>_limit||response.hasMore)?1:0),separatorBuilder:(_,__)=>const Divider(height:16),itemBuilder:(context,index){
    if(index>=response.matches.length||index>=_limit)return TextButton(onPressed:_loading?null:(){if(_limit<response.matches.length){setState(()=>_limit+=20);}else{_limit+=20;_search(more:true);}},child:Text(response.hasMore&&_limit>=response.matches.length?'Load more':'Show more'));
    final r=response.matches[index].record;final label=engine?.catalogs.where((c)=>c.id==r.catalogId).firstOrNull?.label??r.catalogId;
    return ListTile(contentPadding:EdgeInsets.zero,leading:CircleAvatar(child:Icon(catalogIcon(r.catalogId))),title:r.catalogId=='people'?VerifiedAccountName(uid:r.id,name:r.title,compact:true):Text(r.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w600)),subtitle:Text([label+(r.isDemo?' • Demo':''),[r.area,r.city].where((v)=>v.isNotEmpty).join(', '),r.description].where((v)=>v.isNotEmpty).join('\n'),maxLines:3,overflow:TextOverflow.ellipsis),trailing:const Icon(Icons.chevron_right),onTap:()=>_open(r));
   })),
  ])));
 }
 Widget _discovery()=>ListView(padding:const EdgeInsets.all(16),children:[
  if(_suggestions.isNotEmpty)...[const Text('Suggestions',style:TextStyle(fontWeight:FontWeight.w600)),for(final s in _suggestions)ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.search),title:Text(s,maxLines:1,overflow:TextOverflow.ellipsis),onTap:()=>_search(input:s))],
  if(_text.text.isEmpty&&_recent.isNotEmpty)...[Row(children:[const Expanded(child:Text('Recent searches',style:TextStyle(fontWeight:FontWeight.w600))),TextButton(onPressed:(){setState(()=>_recent=[]);_saveRecent();},child:const Text('Clear all'))]),for(final s in _recent)ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.history),title:Text(s),trailing:IconButton(tooltip:'Remove recent search',icon:const Icon(Icons.close),onPressed:(){setState(()=>_recent.remove(s));_saveRecent();}),onTap:()=>_search(input:s))],
  if(_text.text.isEmpty)...[const SizedBox(height:12),const Text('Explore Talib',style:TextStyle(fontWeight:FontWeight.w600)),const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[for(final c in _registry?.engine.catalogs??<SearchCatalog>[])ActionChip(avatar:Icon(catalogIcon(c.id),size:18),label:Text(c.label),onPressed:(){_category=c.id;_search();})])],
 ]);
}
IconData catalogIcon(String id)=>switch(id){'institutes'=>Icons.school_outlined,'hostels'=>Icons.hotel_outlined,'courses'=>Icons.menu_book_outlined,'admissions'=>Icons.event_available_outlined,'scholarships'=>Icons.card_giftcard_outlined,'jobs'=>Icons.work_outline,'internships'=>Icons.badge_outlined,'seminars'=>Icons.event_outlined,'people'=>Icons.person_outline,'posts'=>Icons.forum_outlined,'resources'=>Icons.library_books_outlined,_=>Icons.category_outlined};
class CatalogRecordScreen extends StatelessWidget {
 final SearchRecord record;
 const CatalogRecordScreen({super.key,required this.record});
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(record.catalogId)),body:ListView(padding:const EdgeInsets.all(20),children:[Text(record.title,style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:12),if(record.isDemo)const Text('Demo listing'),Text([record.area,record.city].where((v)=>v.isNotEmpty).join(', ')),const SizedBox(height:16),Text(record.description),const SizedBox(height:16),for(final e in record.attributes.entries)Padding(padding:const EdgeInsets.only(bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e.key,style:const TextStyle(fontWeight:FontWeight.w600)),SelectableText(SearchRecord.flatten(e.value))]))]));
}
