import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/admin_access_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../domain/search_catalog.dart';

/// Trusted publication surface. Only public catalogue fields belong here.
class CatalogAdminScreen extends StatefulWidget {
 const CatalogAdminScreen({super.key});
 @override State<CatalogAdminScreen> createState()=>_CatalogAdminScreenState();
}
class _CatalogAdminScreenState extends State<CatalogAdminScreen> {
 final _id=TextEditingController(),_label=TextEditingController(),_aliases=TextEditingController(),_facets=TextEditingController(text:'[]');
 final _title=TextEditingController(),_description=TextEditingController(),_city=TextEditingController(),_area=TextEditingController(),_tags=TextEditingController(),_attributes=TextEditingController(text:'{}');
 bool _published=false,_busy=false;
 String? _itemId;
 bool get _allowed=>AdminAccessService.instance.isSuperAdmin&&!ActiveProfileController.instance.isDemo;
 @override void dispose(){for(final c in [_id,_label,_aliases,_facets,_title,_description,_city,_area,_tags,_attributes]){c.dispose();}super.dispose();}
 Future<void> _perform(Future<void> Function() action)async{
  if(!_allowed||_busy)return;setState(()=>_busy=true);
  try{await action();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Saved. Published catalogues appear in search automatically.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save: $e')));}finally{if(mounted)setState(()=>_busy=false);}
 }
 Future<void> _catalog()async{
  final raw=jsonDecode(_facets.text);if(raw is! List)throw const FormatException('Filters must be a JSON list.');
  final facets=raw.map((v)=>SearchFacet.fromMap(Map<String,dynamic>.from(v as Map))).toList();
  final c=SearchCatalog(id:_id.text.trim(),label:_label.text.trim(),aliases:_aliases.text.split(',').map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList(),facets:facets);
  if(!c.valid||facets.any((f)=>!f.valid))throw const FormatException('Use a lowercase catalogue ID, a label and valid filter definitions.');
  await FirebaseFirestore.instance.collection('searchCatalogs').doc(c.id).set({...c.toMap(),'updatedAt':FieldValue.serverTimestamp()});
 }
 Future<void> _item()async{
  final raw=jsonDecode(_attributes.text);if(raw is! Map)throw const FormatException('Attributes must be a JSON object.');
  if(_title.text.trim().isEmpty||_title.text.length>200||_description.text.length>6000)throw const FormatException('Title is required (max 200 characters). Description max 6000.');
  final reference=FirebaseFirestore.instance.collection('searchCatalogs').doc(_id.text.trim());final catalog=await reference.get();if(catalog.data()?['enabled']!=true)throw const FormatException('Register or enable this catalogue first.');
  final items=FirebaseFirestore.instance.collection('catalogItems');final doc=_itemId==null?items.doc():items.doc(_itemId);await doc.set({'catalogId':reference.id,'title':_title.text.trim(),'description':_description.text.trim(),'city':_city.text.trim(),'area':_area.text.trim(),'tags':_tags.text.split(',').map((v)=>v.trim()).where((v)=>v.isNotEmpty).toList(),'attributes':Map<String,dynamic>.from(raw),'published':_published,'updatedAt':FieldValue.serverTimestamp()});_itemId=doc.id;
 }
 Widget _field(TextEditingController c,String label,{int lines=1})=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:c,maxLines:lines,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
 @override Widget build(BuildContext context)=>ListenableBuilder(listenable:AdminAccessService.instance,builder:(context,_)=>Scaffold(appBar:AppBar(title:const Text('Catalogue registry')),body:!_allowed?const Center(child:Text('Super admin access is required. Demo cannot publish live data.')):ListView(padding:const EdgeInsets.all(20),children:[
  const Text('Register a catalogue',style:TextStyle(fontWeight:FontWeight.bold,fontSize:20)),const SizedBox(height:12),
  const Text('Only public information belongs here. The catalogue label, aliases and filters automatically appear in global search.'),const SizedBox(height:16),
  _field(_id,'Stable catalogue ID (e.g. transport)'),_field(_label,'Display name'),_field(_aliases,'Search aliases, separated by commas'),_field(_facets,'Filters JSON: [{"key":"mode","label":"Mode","type":"choice"}]',lines:3),
  FilledButton(onPressed:_busy?null:()=>_perform(_catalog),child:const Text('Register / update catalogue')),
  const Divider(height:32),const Text('Public listing',style:TextStyle(fontWeight:FontWeight.bold,fontSize:20)),const SizedBox(height:12),
  _field(_title,'Title'),_field(_description,'Description',lines:3),_field(_city,'City'),_field(_area,'Area / town'),_field(_tags,'Tags, separated by commas'),_field(_attributes,'Public attributes JSON (e.g. {"mode":"Online"})',lines:4),
  SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Publish in search'),subtitle:const Text('Off saves a private draft.'),value:_published,onChanged:_busy?null:(v)=>setState(()=>_published=v)),
  FilledButton(onPressed:_busy?null:()=>_perform(_item),child:Text(_itemId==null?'Save listing':'Update listing')),
  TextButton(onPressed:_busy?null:(){setState((){_itemId=null;_published=false;for(final c in [_title,_description,_city,_area,_tags]){c.clear();}_attributes.text='{}';});},child:const Text('New listing')),
  const Divider(height:32),const Text('Existing catalogues — tap to edit'),
  StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('searchCatalogs').snapshots(),builder:(context,snapshot){if(snapshot.hasError)return const Text('Catalogues could not be loaded.');return Column(children:[for(final d in snapshot.data?.docs??<QueryDocumentSnapshot<Map<String,dynamic>>>[])ListTile(title:Text((d.data()['label']??d.id).toString()),subtitle:Text(d.id),trailing:Switch(value:d.data()['enabled']==true,onChanged:_busy?null:(v)=>_perform(()=>d.reference.update({'enabled':v,'updatedAt':FieldValue.serverTimestamp()}))),onTap:(){final c=SearchCatalog.fromMap(d.id,d.data());setState((){_id.text=c.id;_label.text=c.label;_aliases.text=c.aliases.join(', ');_facets.text=jsonEncode(c.facets.map((f)=>f.toMap()).toList());});})]);}),
  const Text('Existing listings — tap to edit or unpublish'),
  StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream:FirebaseFirestore.instance.collection('catalogItems').limit(100).snapshots(),builder:(context,snapshot){if(snapshot.hasError)return const Text('Listings could not be loaded.');return Column(children:[for(final d in snapshot.data?.docs??<QueryDocumentSnapshot<Map<String,dynamic>>>[])ListTile(title:Text((d.data()['title']??'').toString()),subtitle:Text('${d.data()['catalogId']} • ${d.data()['published']==true?'Published':'Draft'}'),onTap:(){final v=d.data();setState((){_itemId=d.id;_id.text=(v['catalogId']??'').toString();_title.text=(v['title']??'').toString();_description.text=(v['description']??'').toString();_city.text=(v['city']??'').toString();_area.text=(v['area']??'').toString();_tags.text=(v['tags'] as List? ??[]).join(', ');_attributes.text=jsonEncode(v['attributes']??{});_published=v['published']==true;});})]);}),
 ])));
}
