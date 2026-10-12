import 'package:flutter_test/flutter_test.dart';
import '../lib/features/search/domain/search_catalog.dart';
class FakeAdapter implements SearchAdapter {
 @override final SearchCatalog catalog;
 final List<SearchRecord> records;
 int reads=0;
 bool fail=false;
 FakeAdapter(this.catalog,this.records);
 @override Future<SearchPage> load({Object? cursor})async{reads++;if(fail)throw StateError('unavailable');return SearchPage(records);}
}
void main(){
 test('future catalogue participates without enum or UI changes',()async{
  final engine=SearchEngine();final adapter=FakeAdapter(const SearchCatalog(id:'transport',label:'Transport',aliases:['bus','buses'],facets:[SearchFacet('mode','Mode')]),[const SearchRecord(id:'bus-1',catalogId:'transport',title:'Campus shuttle',city:'Lahore',attributes:{'mode':'Shared','schedule':{'days':['Monday']}})]);engine.register(adapter);
  final result=await engine.search('bus Lahore');expect(result.category,'transport');expect(result.matches.single.record.id,'bus-1');
  expect((await engine.search('Monday',category:'transport')).matches.length,1);expect(engine.values('transport','mode'),['Shared']);expect(adapter.reads,1);
 });
 test('plural hostels browse all published hostel records',()async{
  final engine=SearchEngine()..register(FakeAdapter(const SearchCatalog(id:'hostels',label:'Hostels',aliases:['hostel']),[const SearchRecord(id:'1',catalogId:'hostels',title:'Garden residence'),const SearchRecord(id:'2',catalogId:'hostels',title:'Draft',published:false)]));
  expect((await engine.search('hostels')).matches.single.record.id,'1');
 });
 test('budget and AC must match same room offer',()async{
  final engine=SearchEngine()..register(FakeAdapter(const SearchCatalog(id:'hostels',label:'Hostels'),[const SearchRecord(id:'1',catalogId:'hostels',title:'Rooms',attributes:{'offers':[{'budget':10000,'ac':false},{'budget':20000,'ac':true}]})]));
  expect((await engine.search('',category:'hostels',filters:{'budget':'15000','ac':'true'})).matches,isEmpty);
  expect((await engine.search('',category:'hostels',filters:{'budget':'22000','ac':'true'})).matches.length,1);
 });
 test('exact username ranks first, clearing inferred location works',()async{
  final engine=SearchEngine()..register(FakeAdapter(const SearchCatalog(id:'people',label:'People'),[const SearchRecord(id:'1',catalogId:'people',title:'Waheed Akram',city:'Lahore',attributes:{'username':'waheed'}),const SearchRecord(id:'2',catalogId:'people',title:'Waheed Academy',city:'Multan')]));
  expect((await engine.search('@waheed')).matches.first.record.id,'1');
  expect((await engine.search('Lahore',filters:{'city':''})).matches.length,2);
 });
 test('source failure retains other sources; changing identity clears cache',()async{
  final good=FakeAdapter(const SearchCatalog(id:'jobs',label:'Jobs'),[const SearchRecord(id:'1',catalogId:'jobs',title:'Developer')]);final bad=FakeAdapter(const SearchCatalog(id:'events',label:'Events'),[])..fail=true;
  final engine=SearchEngine()..register(good)..register(bad);final result=await engine.search('Developer');expect(result.matches.length,1);expect(result.warnings.length,1);engine.resetScope('other-user');expect(engine.cachedRecords,isEmpty);
 });
 test('AC and availability natural query stays in hostel filters',()async{
  final engine=SearchEngine()..register(FakeAdapter(const SearchCatalog(id:'hostels',label:'Hostels',aliases:['hostel']),[const SearchRecord(id:'1',catalogId:'hostels',title:'Garden',attributes:{'offers':[{'ac':true,'availableOnly':2}]}),const SearchRecord(id:'2',catalogId:'hostels',title:'Old rooms',attributes:{'offers':[{'ac':false,'availableOnly':0}]})]));
  expect((await engine.search('available AC hostels')).matches.single.record.id,'1');
 });
 test('named institute aliases do not return unrelated institutes',()async{
  final engine=SearchEngine()..register(FakeAdapter(const SearchCatalog(id:'institutes',label:'Institutes'),[const SearchRecord(id:'1',catalogId:'institutes',title:'Pir Mehr Ali Shah Arid Agriculture University',tags:['arid']),const SearchRecord(id:'2',catalogId:'institutes',title:'Other university')]));
  expect((await engine.search('Arid')).matches.single.record.id,'1');
 });
 test('invalid registry IDs are rejected',(){expect(()=>SearchEngine().register(FakeAdapter(const SearchCatalog(id:'../users',label:'Secret'),[])),throwsArgumentError);});
}
