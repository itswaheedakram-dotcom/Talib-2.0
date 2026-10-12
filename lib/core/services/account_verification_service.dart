import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'admin_access_service.dart';
import 'active_profile_controller.dart';
import 'firebase_service.dart';
import 'user_profile_repository.dart';

class AccountVerification {
  final String status,category;
  final DateTime? verifiedAt;
  const AccountVerification({this.status='unverified',this.category='',this.verifiedAt});
  bool get verified=>status=='verified'&&AccountVerificationService.categories.containsKey(category);
  factory AccountVerification.fromMap(Map<String,dynamic> data)=>AccountVerification(status:(data['status']??'unverified').toString(),category:(data['category']??'').toString(),verifiedAt:data['verifiedAt'] is Timestamp?(data['verifiedAt'] as Timestamp).toDate():data['verifiedAt'] is DateTime?data['verifiedAt']:null);
}

class AccountVerificationService {
  AccountVerificationService._();
  static final instance=AccountVerificationService._();
  static const categories=<String,String>{'official_team':'Talib official team','institute_representative':'Institute representative','education_professional':'Teacher / education professional','hostel_representative':'Hostel owner / representative','public_figure':'Public figure','organization':'Organization'};
  final _demo=<String,AccountVerification>{};
  final _demoAudits=<Map<String,dynamic>>[];
  final _changes=StreamController<void>.broadcast();
  bool get demo=>ActiveProfileController.instance.isDemo||!FirebaseService.initialized;
  bool get canManage=>demo?AdminAccessService.instance.isDemoSuperAdmin:AdminAccessService.instance.isSuperAdmin;
  Stream<AccountVerification> watch(String uid){
    if(uid.startsWith('demo-user-'))return Stream<AccountVerification>.multi((controller){
      controller.add(_demo[uid]??const AccountVerification());
      final sub=_changes.stream.listen((_)=>controller.add(_demo[uid]??const AccountVerification()));controller.onCancel=sub.cancel;
    });
    if(!FirebaseService.initialized||uid.isEmpty)return Stream.value(const AccountVerification());
    return FirebaseFirestore.instance.collection('accountVerifications').doc(uid).snapshots().map((doc)=>AccountVerification.fromMap(doc.data()??{}));
  }
  Future<UserProfile?> findUser(String query)async{
    if(!canManage)throw StateError('Only the super admin may verify accounts.');
    final key=query.trim().replaceFirst(RegExp(r'^@'),'').toLowerCase();if(key.isEmpty)return null;
    if(demo){for(final p in temporaryProfiles){final profile=UserProfileRepository.instance.demoProfile(p.id);if(profile.username.toLowerCase()==key||p.username.toLowerCase()==key||p.id==query.trim())return profile;}return null;}
    final db=FirebaseFirestore.instance;
    final claim=await db.collection('usernames').doc(key).get();
    final claimedUid=claim.data()?['uid']?.toString();
    if(claimedUid!=null){final doc=await db.collection('users').doc(claimedUid).get();if(doc.exists)return UserProfile.fromMap(doc.id,doc.data()!);}
    final legacy=await db.collection('users').where('username',isEqualTo:key).limit(2).get();
    if(legacy.docs.length>1)throw StateError('This username is ambiguous. Use the account ID.');
    if(legacy.docs.isNotEmpty){final doc=legacy.docs.single;return UserProfile.fromMap(doc.id,doc.data());}
    if(!query.trim().contains('/')){final doc=await db.collection('users').doc(query.trim()).get();if(doc.exists)return UserProfile.fromMap(doc.id,doc.data()!);}
    return null;
  }
  Future<void> setVerification({required String uid,required String category,required String reason,required bool verified})async{
    if(!canManage)throw StateError('Only the super admin may verify or revoke accounts.');
    if(!categories.containsKey(category))throw ArgumentError('Choose a verification category.');
    final note=reason.trim();if(note.length<10||note.length>1000)throw ArgumentError('Add a reason/evidence summary between 10 and 1000 characters.');
    if(demo){if(!verified&&_demo[uid]?.verified!=true)throw StateError('Account is not currently verified.');if(!uid.startsWith('demo-user-'))throw StateError('Demo admin cannot change real accounts.');final at=DateTime.now();_demo[uid]=AccountVerification(status:verified?'verified':'revoked',category:category,verifiedAt:verified?at:_demo[uid]?.verifiedAt);_demoAudits.insert(0,{'targetUid':uid,'actorUid':ActiveProfileController.instance.effectiveUid,'action':verified?'verify':'revoke','category':category,'reason':note,'createdAt':at});_changes.add(null);return;}
    if(uid.startsWith('demo-user-'))throw StateError('Real verification cannot change demo accounts.');
    final db=FirebaseFirestore.instance;final actor=FirebaseAuth.instance.currentUser?.uid;if(actor==null)throw StateError('Sign in first.');
    final ref=db.collection('accountVerifications').doc(uid);final audit=db.collection('accountVerificationAudits').doc();
    await db.runTransaction((tx)async{
      final user=await tx.get(db.collection('users').doc(uid));if(!user.exists)throw StateError('Account not found.');
      final previous=await tx.get(ref);final before=previous.data()??{};final now=FieldValue.serverTimestamp();
      if(!verified&&before['status']!='verified')throw StateError('This account is not currently verified.');
      tx.set(ref,{'status':verified?'verified':'revoked','category':category,'verifiedAt':verified?now:before['verifiedAt'],'updatedAt':now,'auditId':audit.id});
      tx.set(audit,{'targetUid':uid,'actorUid':actor,'action':verified?'verify':'revoke','category':category,'reason':note,'createdAt':now,'previousStatus':before['status']??'unverified'});
    });
  }
  Stream<List<Map<String,dynamic>>> auditHistory(String uid){
    if(!canManage)return Stream.error(StateError('Super admin access required.'));
    if(demo)return Stream<List<Map<String,dynamic>>>.multi((controller){void emit()=>controller.add(_demoAudits.where((a)=>a['targetUid']==uid).toList());emit();final sub=_changes.stream.listen((_)=>emit());controller.onCancel=sub.cancel;});
    return FirebaseFirestore.instance.collection('accountVerificationAudits').where('targetUid',isEqualTo:uid).snapshots().map((s){final list=s.docs.map((d)=>d.data()).toList();list.sort((a,b){final x=a['createdAt'],y=b['createdAt'];return x is Timestamp&&y is Timestamp?y.compareTo(x):0;});return list;});
  }
}
