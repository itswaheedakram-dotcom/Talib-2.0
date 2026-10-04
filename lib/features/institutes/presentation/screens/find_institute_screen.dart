import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/institute_repository.dart';
import '../../../models/institute.dart';

class FindInstituteScreen extends StatefulWidget {
  const FindInstituteScreen({super.key});
  @override State<FindInstituteScreen> createState() => _FindInstituteScreenState();
}
class _FindInstituteScreenState extends State<FindInstituteScreen> {
  final _searchController = TextEditingController();
  String _education='All', _province='All provinces', _city='All cities', _sector='All sectors', _program='All programs';

  @override void initState() { super.initState(); InstituteRepository.instance.addListener(_onChanged); InstituteRepository.instance.load(); }
  void _onChanged(){if(mounted)setState((){});}
  @override void dispose(){InstituteRepository.instance.removeListener(_onChanged);_searchController.dispose();super.dispose();}

  List<Institute> get _results {
    final q=_searchController.text.trim().toLowerCase();
    return InstituteRepository.instance.items.where((i){
      final searchable='${i.name} ${i.city} ${i.province} ${i.campus} ${i.description} ${i.programs.join(' ')}'.toLowerCase();
      return (q.isEmpty||searchable.contains(q)) &&
        (_education=='All'||_label(i.type)==_education) &&
        (_province=='All provinces'||i.province==_province) &&
        (_city=='All cities'||i.city==_city) &&
        (_sector=='All sectors'||i.sector==_sector) &&
        (_program=='All programs'||i.programs.any((p)=>p.toLowerCase()==_program.toLowerCase()));
    }).toList();
  }
  String _label(String type)=>switch(type){'schools'=>'School','colleges'=>'College','universities'=>'University',_=>type};

  void _showFilters(){
    var education=_education,province=_province,city=_city,sector=_sector,program=_program;
    showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,
      builder:(sheetContext)=>StatefulBuilder(builder:(context,sheetSet)=>Padding(
        padding:EdgeInsets.fromLTRB(20,8,20,24+MediaQuery.viewInsetsOf(context).bottom),
        child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Find Institute',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800)),const SizedBox(height:16),
          _Group('Current / Next Education',['All','School','College','University'],education,(v)=>sheetSet(()=>education=v)),
          _Group('Province',['All provinces','Punjab','Sindh','Khyber Pakhtunkhwa','Balochistan','Islamabad Capital Territory'],province,(v)=>sheetSet(()=>province=v)),
          _Group('City',['All cities','Lahore','Multan','Bahawalpur','Islamabad','Rawalpindi'],city,(v)=>sheetSet(()=>city=v)),
          _Group('Sector',['All sectors','Private','Government','Semi-government'],sector,(v)=>sheetSet(()=>sector=v)),
          _Group('Program',['All programs','Matric','Intermediate','FA','FSc','ICS','I.Com','BS','MS','MPhil','PhD'],program,(v)=>sheetSet(()=>program=v)),
          Row(children:[
            Expanded(child:OutlinedButton(onPressed:(){setState((){_education='All';_province='All provinces';_city='All cities';_sector='All sectors';_program='All programs';});Navigator.pop(sheetContext);},child:const Text('Clear all'))),
            const SizedBox(width:12),
            Expanded(child:FilledButton(onPressed:(){setState((){_education=education;_province=province;_city=city;_sector=sector;_program=program;});Navigator.pop(sheetContext);},child:const Text('Find now'))),
          ])
        ]))
      ))
    );
  }

  @override Widget build(BuildContext context){
    final results=_results; final repo=InstituteRepository.instance;
    return Scaffold(appBar:AppBar(title:const Text('Find Institute'),actions:[IconButton(onPressed:_showFilters,icon:const Icon(Icons.tune))]),
      body:RefreshIndicator(onRefresh:repo.load,child:CustomScrollView(slivers:[
        SliverPadding(padding:const EdgeInsets.fromLTRB(20,10,20,18),sliver:SliverList(delegate:SliverChildListDelegate([
          const Text('Find the right institute',style:TextStyle(fontSize:23,fontWeight:FontWeight.w800)),const SizedBox(height:6),
          const Text('Use the filters from the original Talib test case to find matching institutes.'),const SizedBox(height:16),
          TextField(controller:_searchController,onChanged:(_)=>setState((){}),decoration:InputDecoration(hintText:'Search institute, city or program',prefixIcon:const Icon(Icons.search),suffixIcon:_searchController.text.isEmpty?null:IconButton(onPressed:(){_searchController.clear();setState((){});},icon:const Icon(Icons.clear)))),
          const SizedBox(height:12),
          Wrap(spacing:7,runSpacing:7,children:[Chip(label:Text(_education)),Chip(label:Text(_province)),Chip(label:Text(_city)),Chip(label:Text(_sector)),Chip(label:Text(_program))]),
          const SizedBox(height:14),
          Row(children:[Text('${results.length} institutes found',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),const Spacer(),TextButton.icon(onPressed:_showFilters,icon:const Icon(Icons.tune,size:18),label:const Text('Filters'))])
        ]))),
        if(repo.loading) const SliverToBoxAdapter(child:LinearProgressIndicator(minHeight:2)),
        if(results.isEmpty) const SliverFillRemaining(hasScrollBody:false,child:Center(child:Padding(padding:EdgeInsets.all(30),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.search_off_rounded,size:54),SizedBox(height:12),Text('No matching institutes',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),SizedBox(height:6),Text('Change your filters or search term and try again.',textAlign:TextAlign.center)]))))
        else SliverPadding(padding:const EdgeInsets.fromLTRB(20,0,20,32),sliver:SliverList.builder(itemCount:results.length,itemBuilder:(context,index){
          final i=results[index]; return Padding(padding:const EdgeInsets.only(bottom:10),child:Card(child:ListTile(contentPadding:const EdgeInsets.all(12),
            leading:CircleAvatar(child:Icon(_icon(i.type))),title:Text(i.name,style:const TextStyle(fontWeight:FontWeight.w800)),
            subtitle:Text('${_label(i.type)} • ${i.city}${i.sector.isEmpty?'':' • ${i.sector}'}'),trailing:const Icon(Icons.chevron_right),
            onTap:()=>context.push('/institute/${i.id}'))));
        }))
      ]));
  }
  IconData _icon(String type)=>switch(type){'schools'=>Icons.school_outlined,'colleges'=>Icons.account_balance_outlined,_=>Icons.account_balance};
}
class _Group extends StatelessWidget{
  final String title;final List<String> values;final String selected;final ValueChanged<String> onChanged;
  const _Group(this.title,this.values,this.selected,this.onChanged);
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:7),
    Wrap(spacing:7,runSpacing:7,children:values.map((v)=>ChoiceChip(label:Text(v),selected:selected==v,onSelected:(_)=>onChanged(v))).toList())
  ]));
}
