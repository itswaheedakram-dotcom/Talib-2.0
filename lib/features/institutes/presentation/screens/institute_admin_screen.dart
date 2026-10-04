import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InstituteAdminScreen extends StatefulWidget {
  final String claimId;
  const InstituteAdminScreen({super.key, required this.claimId});
  @override State<InstituteAdminScreen> createState()=>_InstituteAdminScreenState();
}
class _InstituteAdminScreenState extends State<InstituteAdminScreen> {
  final _name=TextEditingController(); final _address=TextEditingController(); final _phone=TextEditingController(); final _description=TextEditingController();
  bool _busy=false;
  @override void dispose(){_name.dispose();_address.dispose();_phone.dispose();_description.dispose();super.dispose();}
  Future<void> _loadAndSave({bool save=false}) async {
    final me=FirebaseAuth.instance.currentUser; if(me==null)return;
    final claim=await FirebaseFirestore.instance.collection('instituteClaims').doc(widget.claimId).get();
    final data=claim.data()??{};
    if(data['representativeId']!=me.uid || data['status']!='approved'){ if(mounted) setState(()=>_busy=false); return; }
    final id=(data['instituteId']??'').toString();
    final ref=FirebaseFirestore.instance.collection('institutes').doc(id);
    if(!save){
      final doc=await ref.get(); final x=doc.data()??{};
      _name.text=(x['name']??data['instituteName']??'').toString(); _address.text=(x['address']??'').toString(); _phone.text=(x['phone']??'').toString(); _description.text=(x['description']??'').toString();
      if(mounted)setState(()=>_busy=false); return;
    }
    await ref.set({'name':_name.text.trim(),'address':_address.text.trim(),'phone':_phone.text.trim(),'description':_description.text.trim(),'status':'verified','updatedBy':me.uid,'updatedAt':FieldValue.serverTimestamp()},SetOptions(merge:true));
    if(mounted){setState(()=>_busy=false);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Institute profile updated.')));}
  }
  @override void initState(){super.initState(); _loadAndSave();}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Manage Institute')),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      TextField(controller:_name,decoration:const InputDecoration(labelText:'Institute name')),
      const SizedBox(height:12),TextField(controller:_address,decoration:const InputDecoration(labelText:'Address')),
      const SizedBox(height:12),TextField(controller:_phone,decoration:const InputDecoration(labelText:'Contact phone')),
      const SizedBox(height:12),TextField(controller:_description,maxLines:4,decoration:const InputDecoration(labelText:'About institute')),
      const SizedBox(height:20),
      FilledButton(onPressed:_busy?null:(){setState(()=>_busy=true);_loadAndSave(save:true);},child:const Text('Save Changes')),
    ]),
  );
}
