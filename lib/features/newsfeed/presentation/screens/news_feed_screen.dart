import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});
  static const green=Color(0xFF4CAF50), darkGreen=Color(0xFF1B5E20), lightGreen=Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    final items=[
      ('Admissions Open','Universities and colleges have started accepting applications for upcoming sessions.',Icons.school_rounded),
      ('Scholarship Update','Check the latest scholarship opportunities and eligibility information.',Icons.card_giftcard_rounded),
      ('Career Opportunity','New internships and entry-level opportunities are available for students.',Icons.work_outline_rounded),
    ];
    return Scaffold(
      appBar: AppBar(title:const Text('News Feed'),actions:[IconButton(onPressed:(){},icon:const Icon(Icons.notifications_none_rounded))]),
      body:ListView(padding:const EdgeInsets.fromLTRB(14,12,14,28),children:[
        Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:11),decoration:BoxDecoration(color:lightGreen,borderRadius:BorderRadius.circular(10)),child:const Row(children:[Icon(Icons.tune_rounded,color:darkGreen),SizedBox(width:8),Expanded(child:Text('Latest education, admissions and career updates',style:TextStyle(color:darkGreen,fontWeight:FontWeight.w600))),Icon(Icons.chevron_right,color:darkGreen)])),
        const SizedBox(height:14),
        ...items.map((item)=>Card(margin:const EdgeInsets.only(bottom:12),elevation:1,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),child:InkWell(borderRadius:BorderRadius.circular(12),onTap:(){},child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Container(width:52,height:52,decoration:BoxDecoration(color:lightGreen,borderRadius:BorderRadius.circular(10)),child:Icon(item.$3,color:green,size:28)),const SizedBox(width:12),Expanded(child:Text(item.$1,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700,color:darkGreen)))]),
          const SizedBox(height:11),Text(item.$2,style:const TextStyle(fontSize:13,height:1.4)),const SizedBox(height:10),const Row(children:[Text('Talib',style:TextStyle(color:green,fontWeight:FontWeight.w600)),Spacer(),Text('Read more  →',style:TextStyle(color:darkGreen,fontWeight:FontWeight.w600))])
        ])))),
        const SizedBox(height:4),
        InkWell(onTap:()=>context.push('/community'),borderRadius:BorderRadius.circular(12),child:Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:green,borderRadius:BorderRadius.circular(12)),child:const Row(children:[Icon(Icons.groups_rounded,color:Colors.white,size:32),SizedBox(width:12),Expanded(child:Text('Need guidance? Join the Community',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:15))),Icon(Icons.arrow_forward_ios,color:Colors.white,size:16)])))
      ]),
    );
  }
}
