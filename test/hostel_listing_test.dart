import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talib_2/features/hostels/presentation/screens/list_hostel_screen.dart';
import 'package:talib_2/features/hostels/data/hostel_room.dart';
import 'package:talib_2/features/models/hostel.dart';
import 'package:talib_2/features/hostels/data/hostel_repository.dart';
import 'package:talib_2/core/services/active_profile_controller.dart';
import 'package:talib_2/core/services/admin_access_service.dart';

void main(){
  const room=HostelRoom(type:'4-Seater',rent:'10000',securityFee:'0',rentBasis:'Per bed',securityPolicy:'No security fee',roomCount:2,totalBeds:8,availableBeds:3,ac:true);
  test('structured rent and security survive serialization',(){final restored=HostelRoom.fromMap(room.toMap());expect(restored.rentLabel,'PKR 10000 / month / bed');expect(restored.roomCount,2);expect(restored.securityPolicy,'No security fee');expect(restored.validationError,isNull);});
  test('bed and price validation rejects invalid configurations',(){for(final data in [{'availableBeds':9},{'availableBeds':-1},{'rent':'0'},{'rent':'abc'},{'securityFee':'-1'},{'rentBasis':''},{'roomCount':0}]){expect(HostelRoom.fromMap({...room.toMap(),...data}).validationError,isNotNull);}});
  test('legacy room labels remain unchanged',(){final legacy=HostelRoom.fromMap({'type':'Single','rent':'Rs 8,000'});expect(legacy.rentLabel,'Rs 8,000');expect(legacy.securityPolicy,'Not specified');});
  test('editing listing retains ownership verification reviews and metadata',(){const h=Hostel(id:'hostel',name:'Old',city:'Lahore',area:'Town',ownerId:'owner',status:'approved',isVerified:true,rating:4.5,reviewCount:3,ratingTotal:13.5,listingDetails:{'country':'Pakistan','publicPhone':false},rooms:[room]);final edited=h.copyWithDetails({'name':'Updated'});expect(edited.ownerId,'owner');expect(edited.status,'approved');expect(edited.rating,4.5);expect(edited.isVerified,true);expect(edited.listingDetails['publicPhone'],false);expect(edited.rooms.first.rentBasis,'Per bed');});
  test('demo super admin can edit a hostel owned by someone else',()async{ActiveProfileController.instance.activate(temporaryProfiles.firstWhere((p)=>p.id=='demo-user-6'));AdminAccessService.instance.start();const h=Hostel(id:'',name:'Admin listing',city:'Lahore',area:'Town',ownerId:'other-owner',rooms:[room],listingDetails:{'publicPhone':false});final id=await HostelRepository().saveListingSafe(h,userId:'demo-user-6',privatePhone:'03001234567',demo:true);final stored=HostelRepository.demoHostels.firstWhere((h)=>h.id==id);expect(stored.ownerId,'other-owner');expect(stored.phone,isEmpty);expect(await HostelRepository().privateContact(stored),'03001234567');await HostelRepository.deleteHostelSafe(stored);ActiveProfileController.instance.clear();});
  test('non-owner cannot edit full listing',()async{ActiveProfileController.instance.clear();await AdminAccessService.instance.refresh();const h=Hostel(id:'',name:'Protected',city:'Lahore',area:'Town',ownerId:'owner',rooms:[room]);expect(HostelRepository().saveListingSafe(h,userId:'intruder',privatePhone:'',demo:true),throwsStateError);});
  testWidgets('hostel draft restores and form requires explicit gender/type selection',(tester)async{
    SharedPreferences.setMockInitialValues({});
    ActiveProfileController.instance.activate(temporaryProfiles.first);
    await tester.pumpWidget(const MaterialApp(home:ListHostelScreen()));await tester.pumpAndSettle();
    final boys=tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip,'Boys'));expect(boys.selected,false);
    final name=find.byWidgetPredicate((w)=>w is TextFormField&&w.decoration?.labelText=='Hostel name');
    await tester.enterText(name,'Saved hostel');
    await tester.tap(find.byTooltip('Save draft'));await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home:ListHostelScreen()));await tester.pumpAndSettle();
    expect(find.text('Resume saved draft?'),findsOneWidget);
    await tester.tap(find.text('Resume'));await tester.pumpAndSettle();
    final restored=tester.widget<TextFormField>(find.byWidgetPredicate((w)=>w is TextFormField&&w.decoration?.labelText=='Hostel name'));
    expect(restored.controller!.text,'Saved hostel');
    await tester.pumpWidget(const SizedBox());ActiveProfileController.instance.clear();
  });

}
