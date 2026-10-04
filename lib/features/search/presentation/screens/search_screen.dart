import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState() => _SearchScreenState();
}
class _SearchItem {
  final String title, type, subtitle, route;
  final IconData icon;
  const _SearchItem(this.title, this.type, this.subtitle, this.route, this.icon);
}
class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  static const _items = [
    _SearchItem('Institutes','Education','Schools, colleges and universities','/institutes',Icons.school),
    _SearchItem('Find Institute','Education','Find an institute by city or program','/find',Icons.location_on),
    _SearchItem('Scholarships','Funding','Scholarship opportunities','/scholarships',Icons.card_giftcard),
    _SearchItem('Courses','Learning','Online and on-campus courses','/courses',Icons.menu_book),
    _SearchItem('Seminars','Events','Technology, career and skills events','/seminars',Icons.event),
    _SearchItem('Hostels','Accommodation','Student hostels and facilities','/hostels',Icons.hotel),
    _SearchItem('Internships','Career','Internship opportunities','/internships',Icons.work),
    _SearchItem('Jobs','Career','Jobs and career opportunities','/jobs',Icons.business_center),
    _SearchItem('Community','Social','Student discussions and posts','/community',Icons.people),
  ];
  @override void dispose(){_controller.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final q=_query.toLowerCase();
    final results=_items.where((item)=>q.isEmpty||item.title.toLowerCase().contains(q)||item.type.toLowerCase().contains(q)||item.subtitle.toLowerCase().contains(q)).toList();
    return Scaffold(appBar:AppBar(title:const Text('Search')),body:Column(children:[
      Padding(padding:const EdgeInsets.all(12),child:TextField(controller:_controller,autofocus:true,onChanged:(v)=>setState(()=>_query=v.trim()),decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Search institutes, courses, jobs...',suffixIcon:_query.isEmpty?null:IconButton(icon:const Icon(Icons.clear),onPressed:(){_controller.clear();setState(()=>_query='');})))),
      Expanded(child:results.isEmpty?const Center(child:Text('No matching sections found.')):ListView.separated(padding:const EdgeInsets.fromLTRB(12,4,12,20),itemCount:results.length,separatorBuilder:(_,__)=>const Divider(height:1),itemBuilder:(_,i){final item=results[i];return ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:8,vertical:4),leading:CircleAvatar(child:Icon(item.icon)),title:Text(item.title,style:const TextStyle(fontWeight:FontWeight.w500)),subtitle:Text(item.type+' • '+item.subtitle),trailing:const Icon(Icons.chevron_right),onTap:()=>context.push(item.route));}}))
    ]));
  }
}
