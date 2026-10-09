import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminInstituteClaimsScreen extends StatelessWidget {
  const AdminInstituteClaimsScreen({super.key});
  Future<void> _setStatus(
    BuildContext context,
    String claimId,
    Map<String, dynamic> data,
    String status,
  ) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final claimRef = db.collection('instituteClaims').doc(claimId);
    batch.update(claimRef, {
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    if (status == 'approved') {
      final instituteId = (data['instituteId'] ?? '').toString();
      final representativeId = (data['representativeId'] ?? '').toString();
      if (instituteId.isEmpty || representativeId.isEmpty) {
        throw StateError('Claim is missing its institute or representative ID.');
      }
      batch.update(db.collection('institutes').doc(instituteId), {
        'ownerId': representativeId,
        'representativeId': representativeId,
        'ownershipVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(db.collection('users').doc(representativeId), {
        'role': 'instituteRepresentative',
        'instituteAdmin': true,
        'instituteId': instituteId,
        'instituteName': data['instituteName'],
        'designation': data['designation'],
      }, SetOptions(merge: true));
    }

    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'approved' ? 'Claim approved and ownership linked.' : 'Claim rejected.')),
      );
    }
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Institute Claims')),
    body:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
      stream:FirebaseFirestore.instance.collection('instituteClaims').where('status',isEqualTo:'pending').orderBy('createdAt',descending:true).snapshots(),
      builder:(context,snap){
        if(snap.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
        if(snap.hasError)return const Center(child:Text('Could not load claims.'));
        final docs=snap.data?.docs ?? const [];
        if(docs.isEmpty)return const Center(child:Text('No pending claims.'));
        return ListView.separated(padding:const EdgeInsets.all(12),itemCount:docs.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i){
          final d=docs[i]; final x=d.data();
          return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text((x['instituteName']??'Institute').toString(),style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700)),
            const SizedBox(height:6),
            Text('Representative: '+(x['representativeName']??'').toString()),
            Text('Designation: '+(x['designation']??'').toString()),
            Text('Email: '+(x['representativeEmail']??'').toString()),
            Text('Method: '+(x['verificationMethod']??'').toString()),
            const SizedBox(height:6), Text((x['verificationDetails']??'').toString()),
            const SizedBox(height:10),
            Row(children:[Expanded(child:OutlinedButton(onPressed:()=>_setStatus(context,d.id,x,'rejected'),child:const Text('Reject'))),const SizedBox(width:10),Expanded(child:FilledButton(onPressed:()=>_setStatus(context,d.id,x,'approved'),child:const Text('Approve')))]),
          ])));
        });
      },
    ),
  );
}