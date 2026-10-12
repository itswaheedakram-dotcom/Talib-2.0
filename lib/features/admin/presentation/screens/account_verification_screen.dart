import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/account_verification_service.dart';
import '../../../../core/services/admin_access_service.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/widgets/user_identity.dart';

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key});
  @override State<AccountVerificationScreen> createState()=>_AccountVerificationScreenState();
}
class _AccountVerificationScreenState extends State<AccountVerificationScreen> {
  final service=AccountVerificationService.instance;
  final query=TextEditingController(),reason=TextEditingController();
  UserProfile? target;String category='';String? error;bool loading=false,saving=false;int epoch=0;
  @override void initState(){super.initState();AdminAccessService.instance.start();}
  @override void dispose(){query.dispose();reason.dispose();super.dispose();}
  Future<void> search()async{if(saving||loading)return;final request=++epoch;setState((){loading=true;target=null;error=null;});try{final user=await service.findUser(query.text);if(mounted&&request==epoch)setState((){target=user;reason.clear();category='';if(user==null)error='No account found. Enter its exact @username or account ID.';});}catch(_){if(mounted&&request==epoch)setState(()=>error='Unable to load this account. Check your access and connection.');}finally{if(mounted&&request==epoch)setState(()=>loading=false);}}
  Future<void> act(bool verify,String selectedCategory)async{
    final user=target;if(user==null||saving)return;
    if(!AccountVerificationService.categories.containsKey(selectedCategory)){setState(()=>error='Choose a verification category.');return;}
    if(reason.text.trim().length<10||reason.text.trim().length>1000){setState(()=>error='Add a reason/evidence summary (10–1000 characters).');return;}
    final yes=await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:Text(verify?'Verify this account?':'Revoke verification?'),content:Text('${user.name}\n@${user.username}\n${AccountVerificationService.categories[selectedCategory]}\n\n${reason.text.trim()}'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(verify?'Verify':'Revoke'))]));
    if(yes!=true||!mounted)return;setState((){saving=true;error=null;});
    try{await service.setVerification(uid:user.uid,category:selectedCategory,reason:reason.text,verified:verify);if(mounted){reason.clear();ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(verify?'Account verified.':'Verification revoked.')));}}catch(_){if(mounted)setState(()=>error='Action failed. Confirm super admin access and try again.');}finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:AdminAccessService.instance,builder:(context,_)=>Scaffold(appBar:AppBar(title:const Text('Account verification')),body:!service.canManage?const Center(child:Text('Super admin access required.')):ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Verify identity or official affiliation. Followers, ratings and payment do not qualify an account.'),const SizedBox(height:12),
    TextField(controller:query,onSubmitted:(_)=>search(),decoration:const InputDecoration(labelText:'Exact @username or account ID',prefixIcon:Icon(Icons.search))),const SizedBox(height:8),FilledButton(onPressed:loading||saving?null:search,child:Text(loading?'Searching…':'Find account')),
    if(error!=null)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
    if(target!=null)...[
      Card(child:ListTile(title:UserIdentity(uid:target!.uid,name:target!.name),subtitle:Text('Account ID: '+target!.uid),onTap:()=>context.push('/profile/'+Uri.encodeComponent(target!.uid)))),
      StreamBuilder<AccountVerification>(key:ValueKey(target!.uid),stream:service.watch(target!.uid),builder:(context,s){
        if(s.hasError)return const Text('Verification status unavailable. Retry the account search.');
        if(!s.hasData)return const Center(child:CircularProgressIndicator());final current=s.data!;
        return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text(current.verified?'Verified · '+AccountVerificationService.categories[current.category]!:'Not verified',style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:12),
          DropdownButtonFormField<String>(key:ValueKey(target!.uid),initialValue:category.isEmpty?null:category,isExpanded:true,decoration:const InputDecoration(labelText:'Verification category'),items:AccountVerificationService.categories.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value,maxLines:1,overflow:TextOverflow.ellipsis))).toList(),onChanged:saving?null:(v)=>setState(()=>category=v??category)),const SizedBox(height:12),
          TextField(controller:reason,maxLines:4,maxLength:1000,decoration:const InputDecoration(labelText:'Private reason / evidence summary',helperText:'Record how identity or affiliation was confirmed. Do not paste identity documents.')),
          FilledButton.icon(onPressed:saving?null:()=>act(true,category),icon:const Icon(Icons.verified_rounded),label:Text(saving?'Saving…':current.verified?'Update verification':'Verify account')),
          if(current.verified)OutlinedButton(onPressed:saving?null:()=>act(false,current.category),child:const Text('Revoke verification')),
        ]);
      }),
      const SizedBox(height:20),const Text('Verification history',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      StreamBuilder<List<Map<String,dynamic>>>(key:ValueKey('audit-'+target!.uid),stream:service.auditHistory(target!.uid),builder:(context,s){if(s.hasError)return const Text('History unavailable.');final records=s.data??[];if(records.isEmpty)return const Text('No verification actions yet.');return Column(children:records.map((r)=>ListTile(title:Text('${r['action']} · ${AccountVerificationService.categories[r['category']]}'),subtitle:Text('${r['reason']}\nAdmin: ${r['actorUid']}\n${r['createdAt'] is Timestamp?(r['createdAt'] as Timestamp).toDate().toLocal():r['createdAt']}'))).toList());}),
    ],
  ])));
}
