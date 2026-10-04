import 'package:flutter/material.dart';

class Job{
  final String title,company,location,field,mode,salary,experience,deadline,description;final List<String> requirements;
  const Job({required this.title,required this.company,required this.location,required this.field,required this.mode,required this.salary,required this.experience,required this.deadline,required this.description,required this.requirements});
}
class JobsScreen extends StatefulWidget{const JobsScreen({super.key});@override State<JobsScreen> createState()=>_JobsScreenState();}
class _JobsScreenState extends State<JobsScreen>{
  final search=TextEditingController();String field='All',mode='All';
  static const jobs=[
    Job(title:'Junior Flutter Developer',company:'TechNova Solutions',location:'Lahore',field:'Software',mode:'Hybrid',salary:'Rs. 70,000 - 100,000',experience:'0-1 year',deadline:'30 Nov 2026',description:'Build and maintain mobile applications with a product-focused development team.',requirements:['Flutter/Dart knowledge','Git basics','Good problem-solving skills']),
    Job(title:'UI/UX Designer',company:'PixelCraft Studio',location:'Lahore',field:'Design',mode:'On-site',salary:'Rs. 60,000 - 90,000',experience:'1-2 years',deadline:'15 Dec 2026',description:'Create intuitive interfaces, prototypes and design systems for digital products.',requirements:['Figma','UI/UX fundamentals','Portfolio']),
    Job(title:'Digital Marketing Executive',company:'GrowthHub',location:'Remote',field:'Marketing',mode:'Remote',salary:'Rs. 55,000 - 80,000',experience:'1-2 years',deadline:'10 Dec 2026',description:'Plan and execute digital campaigns, content and social media activities.',requirements:['Digital marketing knowledge','Communication skills','Analytics basics']),
    Job(title:'Accounts Officer',company:'Prime Advisory',location:'Islamabad',field:'Finance',mode:'On-site',salary:'Rs. 65,000 - 85,000',experience:'1-2 years',deadline:'05 Dec 2026',description:'Handle financial records, reporting and day-to-day accounting operations.',requirements:['Accounting fundamentals','Excel','B.Com/ACCA preferred']),
    Job(title:'Electrical Engineer',company:'PowerTech Industries',location:'Multan',field:'Engineering',mode:'On-site',salary:'Rs. 90,000 - 130,000',experience:'2-3 years',deadline:'20 Dec 2026',description:'Support industrial engineering projects, maintenance and technical documentation.',requirements:['Engineering degree','Technical knowledge','Safety awareness']),
    Job(title:'Backend Developer',company:'CodeWorks',location:'Remote',field:'Software',mode:'Remote',salary:'Rs. 100,000 - 150,000',experience:'1-2 years',deadline:'25 Nov 2026',description:'Develop APIs and backend services with a focus on reliable and scalable systems.',requirements:['REST APIs','Node.js or similar','Database fundamentals']),
  ];
  List<Job> get filtered{final q=search.text.toLowerCase().trim();return jobs.where((j)=>(q.isEmpty||'${j.title} ${j.company} ${j.location} ${j.field}'.toLowerCase().contains(q))&&(field=='All'||j.field==field)&&(mode=='All'||j.mode==mode)).toList();}
  @override Widget build(BuildContext context){final list=filtered;return Scaffold(
    appBar:AppBar(title:const Text('Jobs'),actions:[IconButton(onPressed:showFilters,icon:const Icon(Icons.tune))]),
    body:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,8,16,12),child:TextField(controller:search,onChanged:(_)=>setState((){}),decoration:InputDecoration(hintText:'Search jobs, companies...',prefixIcon:const Icon(Icons.search),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16))))),
      SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:['All','Software','Design','Marketing','Finance','Engineering'].map((v)=>Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(v),selected:field==v,onSelected:(_)=>setState(()=>field=v)))).toList())),
      Padding(padding:const EdgeInsets.fromLTRB(16,14,16,8),child:Align(alignment:Alignment.centerLeft,child:Text('${list.length} jobs',style:const TextStyle(fontWeight:FontWeight.w600)))),
      Expanded(child:list.isEmpty?const Center(child:Text('No jobs found')):ListView.builder(padding:const EdgeInsets.fromLTRB(16,4,16,24),itemCount:list.length,itemBuilder:(context,i){final j=list[i];return Card(margin:const EdgeInsets.only(bottom:12),child:ListTile(
        contentPadding:const EdgeInsets.all(16),title:Text(j.title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Padding(padding:const EdgeInsets.only(top:8),child:Text('${j.company}\n${j.field} • ${j.mode}\n${j.location} • ${j.salary}\nDue ${j.deadline}')),isThreeLine:true,trailing:const Icon(Icons.chevron_right),onTap:()=>details(j)));})),
    ]));}
  void showFilters()=>showModalBottomSheet(context:context,showDragHandle:true,builder:(_)=>StatefulBuilder(builder:(c,setSheet)=>Padding(padding:const EdgeInsets.fromLTRB(20,8,20,24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Filter jobs',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:16),
    Wrap(spacing:8,children:['All','Remote','Hybrid','On-site'].map((v)=>ChoiceChip(label:Text(v),selected:mode==v,onSelected:(_){setSheet((){});setState(()=>mode=v);})).toList()),const SizedBox(height:16),
    SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Apply Filters'))),
  ])));
  void details(Job j)=>showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,builder:(_)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(20,8,20,24),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(j.title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),const SizedBox(height:6),Text(j.company,style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:16),
    Text(j.description),const SizedBox(height:18),Text('Requirements',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),
    ...j.requirements.map((r)=>ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.check_circle_outline),title:Text(r))),
    Text('Application deadline: ${j.deadline}',style:const TextStyle(fontWeight:FontWeight.w600)),const SizedBox(height:16),
    SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Apply Now'))),
  ]))));
}
