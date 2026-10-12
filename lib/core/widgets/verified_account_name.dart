import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../services/account_verification_service.dart';

class VerifiedAccountName extends StatelessWidget {
  final String uid,name;
  final TextStyle? style;
  final bool compact;
  const VerifiedAccountName({super.key,required this.uid,required this.name,this.style,this.compact=false});
  @override Widget build(BuildContext context)=>Row(mainAxisSize:MainAxisSize.min,children:[
    Flexible(child:Text(name,style:style,maxLines:compact?1:null,overflow:compact?TextOverflow.ellipsis:null)),
    GreenVerificationBadge(uid:uid),
  ]);
}
class GreenVerificationBadge extends StatelessWidget {
  final String uid;
  const GreenVerificationBadge({super.key,required this.uid});
  @override Widget build(BuildContext context)=>StreamBuilder<AccountVerification>(key:ValueKey(uid),stream:AccountVerificationService.instance.watch(uid),builder:(context,snapshot){
    final record=snapshot.data;if(snapshot.hasError||record==null||!record.verified)return const SizedBox.shrink();
    final category=AccountVerificationService.categories[record.category]!;
    final dark=Theme.of(context).brightness==Brightness.dark;
    return Padding(padding:const EdgeInsets.only(left:5),child:Semantics(button:true,label:'Talib verified account: '+category,child:Tooltip(message:'Talib verified · '+category,child:InkWell(
      borderRadius:BorderRadius.circular(20),onTap:()=>showModalBottomSheet<void>(context:context,useSafeArea:true,builder:(context)=>Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.verified_rounded,color:dark?AppColors.brightGreen:AppColors.primaryGreen,size:42),const SizedBox(height:12),const Text('Talib verified account',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text(category),if(record.verifiedAt!=null)Text('Verified on '+record.verifiedAt!.toLocal().toString().split(' ').first),const SizedBox(height:12),const Text('Talib has checked this account’s identity or official affiliation. This does not guarantee its advice, conduct or service quality.',textAlign:TextAlign.center)]))),
      child:Container(padding:const EdgeInsets.all(2),decoration:BoxDecoration(color:dark?AppColors.darkSurface:Colors.white,shape:BoxShape.circle),child:Icon(Icons.verified_rounded,size:18,color:dark?AppColors.brightGreen:AppColors.primaryGreen)),
    ))));
  });
}
