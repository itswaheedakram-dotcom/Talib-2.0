import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/database_service.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});
  @override State<CoursesScreen> createState()=>_CoursesScreenState();
}
class _CoursesScreenState extends State<CoursesScreen>{
  String level='All',field='All',mode='All',search='';
  static const courses=[
    _C('BS Computer Science','Undergraduate','Computer Science','On Campus','4 years',Icons.computer_outlined),
    _C('BS Software Engineering','Undergraduate','Computer Science','On Campus','4 years',Icons.code_outlined),
    _C('BS Information Technology','Undergraduate','Information Technology','On Campus','4 years',Icons.devices_outlined),
    _C('BS Business Administration','Undergraduate','Business','On Campus','4 years',Icons.business_center_outlined),
    _C('MS Computer Science','MS','Computer Science','On Campus','2 years',Icons.science_outlined),
    _C('MPhil Education','MPhil','Education','On Campus','2 years',Icons.menu_book_outlined),
    _C('Diploma in Web Development','Diploma','Computer Science','Online','6 months',Icons.web_outlined),
    _C('Digital Marketing Certificate','Certificate','Business','Online','3 months',Icons.campaign_outlined),
  ];
  List<_C> get filtered=>courses.where((c){
    final q=search.toLowerCase().trim();
    return (q.isEmpty||c.name.toLowerCase().contains(q)||c.field.toLowerCase().contains(q))
      &&(level=='All'||c.level==level)&&(field=='All'||c.field==field)&&(mode=='All'||c.mode==mode);
  }).toList();
  @override Widget build(BuildContext context){
    final list=filtered;
    return Scaffold(
      appBar:AppBar(title:const Text('Courses'),actions:[IconButton(onPressed:showFilters,icon:const Icon(Icons.tune))]),
      body:ListView(padding:const EdgeInsets.fromLTRB(20,12,20,30),children:[
        Text('Explore courses',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
        const SizedBox(height:6),const Text('Find degree, diploma and certificate programs that match your goals.'),
        const SizedBox(height:18),
        SearchBar(hintText:'Search courses or fields',leading:const Icon(Icons.search),onChanged:(v)=>setState(()=>search=v)),
        const SizedBox(height:16),Text('${list.length} courses found',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
        const SizedBox(height:10),
        if(list.isEmpty)const Padding(padding:EdgeInsets.all(30),child:Center(child:Text('No courses match your search.'))),
        ...list.map((c)=>Card(margin:const EdgeInsets.only(bottom:12),child:ListTile(
          contentPadding:const EdgeInsets.all(16),leading:CircleAvatar(child:Icon(c.icon)),
          title:Text(c.name,style:const TextStyle(fontWeight:FontWeight.w800)),
          subtitle:Padding(padding:const EdgeInsets.only(top:8),child:Text('${c.level} • ${c.field}\n${c.mode} • ${c.duration}')),
          trailing:const Icon(Icons.chevron_right),onTap:()=>details(c),
        ))),
      ]),
    );
  }
  Future<void> _enroll(_C c) async { Navigator.pop(context); final user=AuthService().currentUser; if(user==null){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please sign in to save a course.')));return;} await DatabaseService().saveApplication(collection:'courses',itemId:c.name,title:c.name,applicantId:user.uid,applicantName:user.displayName??user.email??'Student'); if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Course saved to your interests.'))); }
  void showFilters()=>showModalBottomSheet(context:context,showDragHandle:true,builder:(_)=>StatefulBuilder(builder:(context,setSheet)=>Padding(
    padding:const EdgeInsets.fromLTRB(20,8,20,28),child:Wrap(runSpacing:16,children:[
      Text('Course filters',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
      _Group('Study level',['All','Undergraduate','MS','MPhil','Diploma','Certificate'],level,(v)=>setSheet(()=>level=v)),
      _Group('Field',['All','Computer Science','Information Technology','Business','Education'],field,(v)=>setSheet(()=>field=v)),
      _Group('Mode',['All','On Campus','Online'],mode,(v)=>setSheet(()=>mode=v)),
      Row(children:[
        Expanded(child:OutlinedButton(onPressed:(){setState((){level='All';field='All';mode='All';});Navigator.pop(context);},child:const Text('Clear'))),
        const SizedBox(width:12),Expanded(child:FilledButton(onPressed:(){setState((){});Navigator.pop(context);},child:const Text('Apply'))),
      ]),
    ]),
  )));
  void details(_C c)=>showModalBottomSheet(context:context,showDragHandle:true,builder:(_)=>Padding(
    padding:const EdgeInsets.fromLTRB(20,8,20,30),child:Wrap(runSpacing:12,children:[
      Text(c.name,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
      Text('Study level: ${c.level}'),Text('Field: ${c.field}'),Text('Mode: ${c.mode}'),Text('Duration: ${c.duration}'),
      FilledButton.icon(onPressed:()=>_enroll(c),icon:const Icon(Icons.school_outlined),label:const Text('Enroll / Save Interest')),
    ]),
  ));
}
class _Group extends StatelessWidget{final String title,selected;final List<String> values;final ValueChanged<String> onChanged;const _Group(this.title,this.values,this.selected,this.onChanged);
@override Widget build(BuildContext c)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:8),Wrap(spacing:8,children:values.map((v)=>ChoiceChip(label:Text(v),selected:selected==v,onSelected:(_)=>onChanged(v))).toList())]);}
class _C{final String name,level,field,mode,duration;final IconData icon;const _C(this.name,this.level,this.field,this.mode,this.duration,this.icon);}
