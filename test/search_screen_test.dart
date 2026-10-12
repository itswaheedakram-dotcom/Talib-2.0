import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/services/active_profile_controller.dart';
import '../lib/features/search/presentation/screens/smart_global_search_screen.dart';
import '../lib/features/search/data/search_registry.dart';
import '../lib/features/search/domain/search_catalog.dart';
void main(){
 setUp((){SharedPreferences.setMockInitialValues({});ActiveProfileController.instance.activate(temporaryProfiles.first);});
 tearDown(()=>ActiveProfileController.instance.clear());
 test('Demo global search includes all module catalogues without live reads',()async{
  final registry=SearchRegistry(demo:true,uid:'demo-user-1');await registry.initialize();
  expect((await registry.engine.search('Scholarship for BS students')).matches,isNotEmpty);
  for(final category in ['courses','scholarships','jobs','internships','seminars']){final result=await registry.engine.search('',category:category);expect(result.matches,isNotEmpty,reason:category);expect(result.matches.every((m)=>m.record.isDemo),isTrue);}
 });
 test('registry adds, updates and removes future catalogues without restarting',()async{
  final registry=SearchRegistry(demo:true,uid:'demo-user-1');await registry.initialize();
  expect(registry.applyCatalogs([const SearchCatalog(id:'transport',label:'Transport')]),isTrue);expect(registry.engine.catalogs.any((c)=>c.id=='transport'),isTrue);
  expect(registry.applyCatalogs([const SearchCatalog(id:'transport',label:'Transport')]),isFalse);
  expect(registry.applyCatalogs([const SearchCatalog(id:'transport',label:'Campus transport',facets:[SearchFacet('mode','Mode')])]),isTrue);expect(registry.engine.catalogs.singleWhere((c)=>c.id=='transport').label,'Campus transport');
  registry.applyCatalogs([]);expect(registry.engine.catalogs.any((c)=>c.id=='transport'),isFalse);expect(registry.engine.catalogs.any((c)=>c.id=='hostels'),isTrue);
 });
 testWidgets('compact search submits plural hostels and stores removable recents',(tester)async{
  await tester.pumpWidget(const MaterialApp(home:SmartGlobalSearchScreen()));await tester.pumpAndSettle();
  expect(find.text('Search'),findsOneWidget);expect(find.text('What I understood'),findsNothing);
  await tester.enterText(find.byType(TextField),'hostels');await tester.testTextInput.receiveAction(TextInputAction.search);await tester.pumpAndSettle();
  expect(find.textContaining('results'),findsOneWidget);expect(find.byType(ListTile),findsWidgets);expect(find.text('No matching results'),findsNothing);
  await tester.tap(find.byTooltip('Clear search'));await tester.pumpAndSettle();
  expect(find.text('Recent searches'),findsOneWidget);expect(find.text('hostels'),findsOneWidget);
  await tester.tap(find.byTooltip('Remove recent search'));await tester.pumpAndSettle();expect(find.text('hostels'),findsNothing);
  await tester.pumpWidget(const SizedBox.shrink());
 });
}
