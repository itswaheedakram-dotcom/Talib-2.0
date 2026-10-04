import 'package:flutter/material.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});
  @override State<CoursesScreen> createState() => _CoursesScreenState();
}
class _CoursesScreenState extends State<CoursesScreen> {
  String _level='All', _field='All', _mode='All', _search='';
  static const _courses=[
    _C('BS Computer Science','Undergraduate','Computer Science','On Campus','4 years',Icons.computer_outlined),
    _C('BS Software Engineering','Undergraduate','Computer Science','On Campus','4 years',Icons.code_outlined),
    _C('BS Information Technology','Undergraduate','Information Technology','On Campus','4 years',Icons.devices_outlined),
    _C('BS Business Administration','Undergraduate','Business','On Campus','4 years',Icons.business_center_outlined),
    _C('MS Computer Science','MS','Computer Science','On Campus','2 years',Icons.science_outlined),
    _C('MPhil Education','MPhil','Education','On Campus','2 years',Icons.menu_book_outlined),
    _C('Diploma in Web Development','Diploma','Computer Science','Online','6 months',Icons.web_outlined),
    _C('Digital Marketing Certificate','Certificate','Business','Online','3 months',Icons.campaign_outlined),
  ];
  List<_C> get filtered {
    final q=_search.trim().toLowerCase();
    return _courses.where((c)=>(q.isEmpty||c.name.toLowerCase().contains(q)||c.field.toLowerCase().contains(q))&&(_level=='All'||c.level==_level)&&(_field=='All'||c.field==_field)&&(_mode=='All'||c.mode==_mode)).toList();
  }
  @override Widget build(BuildContext context){
    final list=filtered;
    return Scaffold(
      appBar:AppBar(title:const Text('Courses'),actions:[IconButton(onPressed:_filters,icon:const Icon(Icons.tune))]),
      body:CustomScrollView(slivers:[
        SliverPadding(padding:const EdgeInsets.fromLTRB(20,8,20,18),sliver:SliverList(delegate:SliverChildListDelegate([
          Text('Explore courses',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:6),const Text('Find degree, diploma and certificate programs that match your goals.'),
          const SizedBox(height:18),SearchBar(hintText:'Search courses or fields',leading:const Icon(Icons.search),onChanged:(v)=>setState(()=>_search=v)),
          const SizedBox(height:14),Wrap(spacing:8,runSpacing:8,children:[Chip(label:Text('Level: '+_level)),Chip(label:Text('Field: '+_field)),Chip(label:Text('Mode: '+_mode))]),
          const SizedBox(height:18),Text(list.length.toString()+' courses found',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
        ]))),
        if(list.isEmpty) const SliverFillRemaining(hasScrollBody:false,child:Center(child:Text('No courses match your search.')))
        else SliverPadding(padding:const EdgeInsets.fromLTRB(20,0,20,32),sliver:SliverList.builder(itemCount:list.length,itemBuilder:(_,i){
          final c=list[i];
          return Padding(padding:const EdgeInsets.only(bottom:12),child:Card(child:ListTile(
            contentPadding:const EdgeInsets.all(16),leading:CircleAvatar(child:Icon(c.icon)),
            title:Text(c.name,style:const TextStyle(fontWeight:FontWeight.w800)),
            subtitle:Padding(padding:const EdgeInsets.only(top:8),child:Text(c.level+' • '+c.field+'\\n'+c.mode+' • '+c.duration)),
            isThreeLine:true,trailing:const Icon(Icons.chevron_right),onTap:()=>_details(c),
          )));
        })),
      ]),
    );
  }
  void _filters()=>showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(_)=>StatefulBuilder(builder:(context,ss)=>Padding(
    padding:const EdgeInsets.fromLTRB(20,8,20,28),child:Wrap(runSpacing:18,children:[
      Text('Course filters',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
      _G('Study level',const ['All','Undergraduate','MS','MPhil','Diploma','Certificate'],_level,(v)=>ss(()=>_level=v)),
      _G('Field',const ['All','Computer Science','Information Technology','Business','Education'],_field,(v)=>ss(()=>_field=v)),
      _G('Mode',const ['All','On Campus','Online'],_mode,(v)=>ss(()=>_mode=v)),
      Row(children:[Expanded(child:OutlinedButton(onPressed:(){setState((){_level='All';_field='All';_mode='All';});Navigator.pop(context);},child:const Text('Clear'))),const SizedBox(width:12),Expanded(child:FilledButton(onPressed:(){setState((){});Navigator.pop(context);},child:const Text('Apply')))]),
    ])));
  void _details(_C c)=>showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(_)=>Padding(
    padding:const EdgeInsets.fromLTRB(20,8,20,30),child:Wrap(runSpacing:12,children:[
      Text(c.name,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
      Text('Study level: '+c.level),Text('Field: '+c.field),Text('Mode: '+c.mode),Text('Duration: '+c.duration),
      FilledButton.icon(onPressed:(){},icon:const Icon(Icons.school_outlined),label:const Text('View course')),
    ]));
}
class _G extends StatelessWidget{final String title,selected;final List<String> values;final ValueChanged<String> onChanged;const _G(this.title,this.values,this.selected,this.onChanged);
@override Widget build(BuildContext c)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:8),Wrap(spacing:8,children:values.map((v)=>ChoiceChip(label:Text(v),selected:selected==v,onSelected:(_)=>onChanged(v))).toList())]);}
class _C{final String name,level,field,mode,duration;final IconData icon;const _C(this.name,this.level,this.field,this.mode,this.duration,this.icon);}
