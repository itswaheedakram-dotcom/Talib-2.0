import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/admin_access_service.dart';
import '../../../../core/services/issue_support_service.dart';

class HelpFaqsScreen extends StatefulWidget {
  const HelpFaqsScreen({super.key});
  @override State<HelpFaqsScreen> createState()=>_HelpFaqsScreenState();
}
class _HelpFaqsScreenState extends State<HelpFaqsScreen>{
  final _search=TextEditingController();String _category='All';
  @override void dispose(){_search.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Help & FAQs'),actions:[IconButton(tooltip:'My Reports',onPressed:()=>context.push('/my-reports'),icon:const Icon(Icons.confirmation_number_outlined))]),body:StreamBuilder<List<Map<String,dynamic>>>(stream:IssueSupportService.instance.watchFaqs(),builder:(context,s){
    final faqs=s.data??IssueSupportService.defaultFaqs;final cats=<String>{'All',...faqs.map((f)=>(f['category']??'General').toString())}.toList();final q=_search.text.trim().toLowerCase();
    final filtered=faqs.where((f)=>(_category=='All'||f['category']==_category)&&((f['question'].toString()+' '+f['answer'].toString()).toLowerCase().contains(q))).toList();
    return ListView(padding:const EdgeInsets.all(16),children:[
      Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(16)),child:const Row(children:[Icon(Icons.support_agent_rounded,color:AppColors.darkGreen,size:34),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Talib Help Centre',style:TextStyle(fontWeight:FontWeight.w800,fontSize:18,color:AppColors.darkGreen)),SizedBox(height:4),Text('Search common questions or contact support.',style:TextStyle(color:AppColors.darkGreen))]))])),
      const SizedBox(height:14),TextField(controller:_search,onChanged:(_)=>setState((){}),decoration:const InputDecoration(prefixIcon:Icon(Icons.search_rounded),hintText:'Search help topics…')),
      const SizedBox(height:10),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:cats.map((c)=>Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(label:Text(c),selected:_category==c,onSelected:(_)=>setState(()=>_category=c)))).toList())),
      if(s.hasError)const Padding(padding:EdgeInsets.all(8),child:Text('Showing default FAQs. Online updates could not be loaded.')),
      if(filtered.isEmpty)const Padding(padding:EdgeInsets.symmetric(vertical:28),child:Center(child:Text('No matching FAQs. Try another search or contact support.'))),
      ...filtered.map((f)=>Card(child:ExpansionTile(leading:const Icon(Icons.help_outline_rounded,color:AppColors.primaryGreen),title:Text(f['question'].toString(),style:const TextStyle(fontWeight:FontWeight.w700)),childrenPadding:const EdgeInsets.fromLTRB(16,0,16,16),expandedCrossAxisAlignment:CrossAxisAlignment.start,children:[Text(f['answer'].toString())]))),
      const SizedBox(height:14),Card(child:ListTile(leading:const CircleAvatar(backgroundColor:AppColors.softGreen,child:Icon(Icons.mark_email_unread_outlined,color:AppColors.darkGreen)),title:const Text('Still need help?',style:TextStyle(fontWeight:FontWeight.w800)),subtitle:const Text('Send a report and track the support team’s reply.'),trailing:const Icon(Icons.chevron_right_rounded),onTap:()=>context.push('/report-issue'))),
    ]);
  }));
}

class AdminFaqManagementScreen extends StatelessWidget{
  const AdminFaqManagementScreen({super.key});
  bool _allowed(){final a=AdminAccessService.instance;return a.isDemoSuperAdmin||a.isSuperAdmin||a.can('manage_faqs');}
  Future<void> _edit(BuildContext context,Map<String,dynamic>? faq)async{
    final q=TextEditingController(text:faq?['question']?.toString()??'');final a=TextEditingController(text:faq?['answer']?.toString()??'');final c=TextEditingController(text:faq?['category']?.toString()??'General');final o=TextEditingController(text:(faq?['order']??100).toString());var enabled=faq?['isEnabled']!=false;final key=GlobalKey<FormState>();
    final save=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:Text(faq==null?'Add FAQ':'Edit FAQ'),content:SizedBox(width:480,child:SingleChildScrollView(child:Form(key:key,child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextFormField(controller:q,maxLength:240,decoration:const InputDecoration(labelText:'Question'),validator:(v)=>v==null||v.trim().isEmpty?'Question is required.':null),
      TextFormField(controller:a,maxLength:4000,minLines:3,maxLines:7,decoration:const InputDecoration(labelText:'Answer'),validator:(v)=>v==null||v.trim().isEmpty?'Answer is required.':null),
      TextFormField(controller:c,maxLength:80,decoration:const InputDecoration(labelText:'Category'),validator:(v)=>v==null||v.trim().isEmpty?'Category is required.':null),
      TextFormField(controller:o,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Sort order')),
      SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Enabled'),value:enabled,onChanged:(v)=>setD(()=>enabled=v)),
    ])))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>key.currentState?.validate()==true?Navigator.pop(ctx,true):null,child:const Text('Save FAQ'))])));
    if(save==true){try{await IssueSupportService.instance.saveFaq(id:faq?['id']?.toString(),question:q.text,answer:a.text,category:c.text,order:int.tryParse(o.text)??100,enabled:enabled);if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('FAQ saved.')));}catch(e){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save FAQ: '+e.toString())));}}
    q.dispose();a.dispose();c.dispose();o.dispose();
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Manage Help & FAQs'),actions:[if(_allowed())IconButton(tooltip:'Add FAQ',onPressed:()=>_edit(context,null),icon:const Icon(Icons.add_rounded))]),body:!_allowed()?const Center(child:Text('You do not have permission to manage FAQs.')):StreamBuilder<List<Map<String,dynamic>>>(stream:IssueSupportService.instance.watchFaqs(includeDisabled:true),builder:(context,s){
    final faqs=s.data??IssueSupportService.defaultFaqs;
    return ListView(padding:const EdgeInsets.all(12),children:[const Padding(padding:EdgeInsets.all(8),child:Text('Default FAQs are built into Talib. Real changes use Firebase; Demo changes stay isolated from real data.',style:TextStyle(color:AppColors.mutedText))),...faqs.map((f)=>Card(child:ListTile(leading:const Icon(Icons.help_outline_rounded,color:AppColors.primaryGreen),title:Text(f['question'].toString(),maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text((f['category']??'General').toString()+' • Enabled'),trailing:const Icon(Icons.edit_outlined),onTap:()=>_edit(context,f))))]);
  }));
}
