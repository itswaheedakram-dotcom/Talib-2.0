import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/institute_repository.dart';
import '../../models/institute.dart';

class AddInstituteScreen extends StatefulWidget{
  final String type;
  const AddInstituteScreen({super.key,required this.type});
  @override State<AddInstituteScreen> createState()=>_AddInstituteScreenState();
}
class _AddInstituteScreenState extends State<AddInstituteScreen>{
  final _formKey=GlobalKey<FormState>();
  final _name=TextEditingController(),_campus=TextEditingController(),_province=TextEditingController(),_city=TextEditingController(),_description=TextEditingController(),_website=TextEditingController(),_eligibility=TextEditingController(),_minScore=TextEditingController(),_nextProgram=TextEditingController();
  String _sector='Private',_submission='Online';bool _saving=false;
  String get title=>switch(widget.type){'schools'=>'Add School','colleges'=>'Add College','universities'=>'Add University',_=>'Add Institute'};
  String get typeLabel=>switch(widget.type){'schools'=>'School','colleges'=>'College','universities'=>'University',_=>'Institute'};
  @override void dispose(){for(final c in[_name,_campus,_province,_city,_description,_website,_eligibility,_minScore,_nextProgram])c.dispose();super.dispose();}

  Future<void> _submit() async{
    if(!_formKey.currentState!.validate())return;
    setState(()=>_saving=true);
    final institute=Institute(id:'',name:_name.text.trim(),type:widget.type,campus:_campus.text.trim(),province:_province.text.trim(),city:_city.text.trim(),sector:_sector,description:_description.text.trim(),website:_website.text.trim(),submissionMode:_submission,eligibility:_eligibility.text.trim(),minScore:double.tryParse(_minScore.text.trim())??0,nextProgram:_nextProgram.text.trim(),address:'${_city.text.trim()}, ${_province.text.trim()}',status:'pending');
    final saved=await InstituteRepository.instance.add(institute);
    if(!mounted)return;
    setState(()=>_saving=false);
    if(saved==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Institute could not be saved. Please try again.')));return;}
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Institute added successfully and is now visible in Find Institute.')));
    context.pop();
  }

  @override Widget build(BuildContext context){
    const green=Color(0xFF00A66A),dark=Color(0xFF00543D);
    return Scaffold(appBar:AppBar(leading:IconButton(icon:const Icon(Icons.arrow_back_ios_new,size:18),onPressed:()=>context.pop()),title:Text(title)),
      body:Form(key:_formKey,child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,30),children:[
        Text('Institute Details',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:dark)),const SizedBox(height:5),
        Text('Add the information required by the Talib Add Institute test case.',style:TextStyle(color:Colors.grey.shade700)),const SizedBox(height:14),
        _field(_name,'Institute Name',Icons.account_balance_outlined,required:true),
        _field(_campus,'Campus',Icons.location_city_outlined),
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:_field(_province,'Province',Icons.map_outlined,required:true)),const SizedBox(width:10),Expanded(child:_field(_city,'City',Icons.location_on_outlined,required:true))]),
        DropdownButtonFormField<String>(initialValue:_sector,decoration:const InputDecoration(labelText:'Sector',prefixIcon:Icon(Icons.business_outlined)),items:const['Private','Government','Semi-government'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>_sector=v??_sector)),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(initialValue:_submission,decoration:const InputDecoration(labelText:'Application Submission Mode',prefixIcon:Icon(Icons.link_outlined)),items:const['Online','Physical'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>_submission=v??_submission)),
        const SizedBox(height:12),
        _field(_description,'Description',Icons.description_outlined,maxLines:4),
        _field(_website,'Website',Icons.language_outlined,keyboard:TextInputType.url),
        _field(_eligibility,'Eligibility Criteria',Icons.rule_outlined,maxLines:4,required:true),
        _field(_minScore,'Minimum Percentage / CGPA',Icons.percent,keyboard:const TextInputType.numberWithOptions(decimal:true)),
        _field(_nextProgram,'Next Education Program',Icons.menu_book_outlined),
        const SizedBox(height:8),
        Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFFEAF8F2),borderRadius:BorderRadius.circular(12)),child:Row(children:[const Icon(Icons.info_outline,color:green),const SizedBox(width:9),Expanded(child:Text('Your ${typeLabel.toLowerCase()} will be submitted for admin review. It is also available immediately in this session so the result can be verified.'))])),
        const SizedBox(height:18),
        SizedBox(height:50,child:FilledButton(onPressed:_saving?null:_submit,style:FilledButton.styleFrom(backgroundColor:green),child:_saving?const SizedBox(height:22,width:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('Submit Institute')))
      ]));
  }
  Widget _field(TextEditingController c,String label,IconData icon,{bool required=false,int maxLines=1,TextInputType? keyboard})=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextFormField(controller:c,maxLines:maxLines,keyboardType:keyboard,validator:required?(v)=>v==null||v.trim().isEmpty?'Required':null:null,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon))));
}
