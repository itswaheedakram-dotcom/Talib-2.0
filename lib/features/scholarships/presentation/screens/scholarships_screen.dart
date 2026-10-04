import 'package:flutter/material.dart';

class ScholarshipsScreen extends StatefulWidget {
  const ScholarshipsScreen({super.key});
  @override State<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}
class _ScholarshipsScreenState extends State<ScholarshipsScreen> {
  String level='All', field='All', search='';
  static const items=[
    _S('HEC Undergraduate Scholarship','Undergraduate','All fields','Pakistan','Tuition, stipend and related support',Icons.school_outlined),
    _S('Ehsaas Undergraduate Scholarship','Undergraduate','All fields','Pakistan','Need-based financial assistance',Icons.volunteer_activism_outlined),
    _S('Punjab Educational Endowment Fund','Undergraduate','All fields','Punjab','Support for eligible students',Icons.account_balance_outlined),
    _S('HEC MS Scholarship','MS','All fields','Pakistan','Financial support for postgraduate study',Icons.science_outlined),
    _S('Need-Based Scholarship','Undergraduate','Computer Science','Pakistan','Financial aid for eligible students',Icons.computer_outlined),
    _S('STEM Scholarship','MS','Engineering','Pakistan','Support for STEM postgraduate study',Icons.biotech_outlined),
  ];
  List<_S> get filtered => items.where((s){
    final q=search.toLowerCase().trim();
    return (q.isEmpty || s.name.toLowerCase().contains(q) || s.field.toLowerCase().contains(q))
      && (level=='All' || s.level==level) && (field=='All' || s.field==field);
  }).toList();

  @override Widget build(BuildContext context) {
    final list=filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('Scholarships'), actions:[
        IconButton(onPressed: showFilters, icon: const Icon(Icons.tune))
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20,12,20,30),
        children:[
          Text('Find financial support',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:6),
          const Text('Explore scholarships and financial-aid opportunities for your education.'),
          const SizedBox(height:18),
          SearchBar(hintText:'Search scholarships',leading:const Icon(Icons.search),onChanged:(v)=>setState(()=>search=v)),
          const SizedBox(height:16),
          Text('${list.length} opportunities',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:10),
          if(list.isEmpty) const Padding(padding:EdgeInsets.all(30),child:Center(child:Text('No scholarships match your search.'))),
          ...list.map((s)=>Card(
            margin:const EdgeInsets.only(bottom:12),
            child:ListTile(
              contentPadding:const EdgeInsets.all(16),
              leading:CircleAvatar(child:Icon(s.icon)),
              title:Text(s.name,style:const TextStyle(fontWeight:FontWeight.w800)),
              subtitle:Padding(padding:const EdgeInsets.only(top:8),child:Text('${s.level} • ${s.field}\n${s.location}\n${s.summary}')),
              trailing:const Icon(Icons.chevron_right),
              onTap:()=>details(s),
            ),
          )),
        ],
      ),
    );
  }

  void showFilters()=>showModalBottomSheet(
    context:context,showDragHandle:true,
    builder:(_)=>StatefulBuilder(builder:(context,setSheet)=>Padding(
      padding:const EdgeInsets.fromLTRB(20,8,20,28),
      child:Wrap(runSpacing:16,children:[
        Text('Scholarship filters',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
        _Group('Study level',['All','Undergraduate','MS'],level,(v)=>setSheet(()=>level=v)),
        _Group('Field',['All','All fields','Computer Science','Engineering'],field,(v)=>setSheet(()=>field=v)),
        Row(children:[
          Expanded(child:OutlinedButton(onPressed:(){setState(()=>level='All');setState(()=>field='All');Navigator.pop(context);},child:const Text('Clear'))),
          const SizedBox(width:12),
          Expanded(child:FilledButton(onPressed:(){setState((){});Navigator.pop(context);},child:const Text('Apply'))),
        ]),
      ]),
    )),
  );

  void details(_S s)=>showModalBottomSheet(
    context:context,showDragHandle:true,
    builder:(_)=>Padding(
      padding:const EdgeInsets.fromLTRB(20,8,20,30),
      child:Wrap(runSpacing:12,children:[
        Text(s.name,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
        Text(s.summary),Text('Study level: ${s.level}'),Text('Field: ${s.field}'),Text('Location: ${s.location}'),
        FilledButton.icon(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.open_in_new),label:const Text('View opportunity')),
      ]),
    ),
  );
}
class _Group extends StatelessWidget {
  final String title,selected; final List<String> values; final ValueChanged<String> onChanged;
  const _Group(this.title,this.values,this.selected,this.onChanged);
  @override Widget build(BuildContext c)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:8),
    Wrap(spacing:8,children:values.map((v)=>ChoiceChip(label:Text(v),selected:selected==v,onSelected:(_)=>onChanged(v))).toList()),
  ]);
}
class _S { final String name,level,field,location,summary; final IconData icon; const _S(this.name,this.level,this.field,this.location,this.summary,this.icon); }
