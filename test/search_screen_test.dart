import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/services/active_profile_controller.dart';
import '../lib/features/search/presentation/screens/smart_global_search_screen.dart';
import '../lib/features/search/data/search_registry.dart';
void main(){
 setUp((){SharedPreferences.setMockInitialValues({});ActiveProfileController.instance.activate(temporaryProfiles.first);});
 tearDown(()=>ActiveProfileController.instance.clear());
 test('Demo global search includes all module catalogues without live reads',()async{
  final registry=SearchRegistry(demo:true,uid:'demo-user-1');await registry.initialize();
  for(final category in ['courses','scholarships','jobs','internships','seminars']){final result=await registry.engine.search('',category:category);expect(result.matches,isNotEmpty,reason:category);expect(result.matches.every((m)=>m.record.isDemo),isTrue);}
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
