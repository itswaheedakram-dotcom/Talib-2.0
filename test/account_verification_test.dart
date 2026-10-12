import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talib_2/core/services/account_verification_service.dart';
import 'package:talib_2/core/services/active_profile_controller.dart';
import 'package:talib_2/core/services/admin_access_service.dart';
import 'package:talib_2/core/widgets/verified_account_name.dart';

void main(){
  final service=AccountVerificationService.instance;
  setUp((){ActiveProfileController.instance.activate(temporaryProfiles.firstWhere((p)=>p.id=='demo-user-6'));AdminAccessService.instance.start();});
  tearDown(()=>ActiveProfileController.instance.clear());
  test('unknown categories cannot show verified status',(){expect(const AccountVerification(status:'verified',category:'fake').verified,false);expect(const AccountVerification(status:'revoked',category:'official_team').verified,false);});
  test('demo verify/revoke records actor and private reason',()async{
    await service.setVerification(uid:'demo-user-1',category:'education_professional',reason:'Teaching affiliation confirmed by the institute.',verified:true);
    expect((await service.watch('demo-user-1').first).verified,true);
    expect((await service.auditHistory('demo-user-1').first).first['actorUid'],'demo-user-6');
    await service.setVerification(uid:'demo-user-1',category:'education_professional',reason:'Affiliation was withdrawn by the institute.',verified:false);
    expect((await service.watch('demo-user-1').first).verified,false);
    expect((await service.auditHistory('demo-user-1').first).length,2);
  });
  test('ordinary demo user cannot grant verification',()async{
    ActiveProfileController.instance.activate(temporaryProfiles.first);await AdminAccessService.instance.refresh();
    expect(service.setVerification(uid:'demo-user-1',category:'official_team',reason:'Pretending to be official.',verified:true),throwsStateError);
  });
  test('demo admin cannot change real accounts',(){expect(service.setVerification(uid:'real-account',category:'official_team',reason:'The official team was confirmed.',verified:true),throwsStateError);});
  testWidgets('green tick appears, explains category and disappears after revoke',(tester)async{
    await service.setVerification(uid:'demo-user-2',category:'hostel_representative',reason:'Ownership documents and identity checked.',verified:true);
    await tester.pumpWidget(const MaterialApp(home:Scaffold(body:VerifiedAccountName(uid:'demo-user-2',name:'Ali'))));await tester.pumpAndSettle();
    expect(find.byIcon(Icons.verified_rounded),findsOneWidget);
    await tester.tap(find.byIcon(Icons.verified_rounded));await tester.pumpAndSettle();
    expect(find.text('Talib verified account'),findsOneWidget);expect(find.text('Hostel owner / representative'),findsOneWidget);
    await tester.tapAt(const Offset(10,10));await tester.pumpAndSettle();
    await service.setVerification(uid:'demo-user-2',category:'hostel_representative',reason:'Owner authority was revoked after review.',verified:false);await tester.pumpAndSettle();
    expect(find.byIcon(Icons.verified_rounded),findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
