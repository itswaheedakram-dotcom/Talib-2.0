import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/issue_support_service.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});
  @override State<ReportIssueScreen> createState()=>_ReportIssueScreenState();
}
class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _key=GlobalKey<FormState>(), _title=TextEditingController(), _description=TextEditingController();
  String _category='Bug', _priority='Medium'; XFile? _image; bool _busy=false;
  static const _categories=['Bug','Login & Account','Profile','Community','Hostel','Institute','Messages & Groups','Other'];
  String? get _uid=>ActiveProfileController.instance.effectiveUid??FirebaseAuth.instance.currentUser?.uid;
  String get _name=>ActiveProfileController.instance.effectiveName??FirebaseAuth.instance.currentUser?.displayName??'Talib user';
  @override void dispose(){_title.dispose();_description.dispose();super.dispose();}
  Future<void> _pick() async {try{final x=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:82,maxWidth:1800);if(x!=null&&mounted)setState(()=>_image=x);}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not select this image.')));}}
  Future<void> _submit() async {
    if(_busy||!(_key.currentState?.validate()??false))return;final uid=_uid;
    if(uid==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please sign in or activate a Demo profile first.')));return;}
    setState(()=>_busy=true);
    try{
      final number=await IssueSupportService.instance.createTicket(reporterId:uid,reporterName:_name,category:_category,title:_title.text,description:_description.text,priority:_priority,screenshot:_image);
      if(!mounted)return;
      await showDialog<void>(context:context,barrierDismissible:false,builder:(ctx)=>AlertDialog(icon:const Icon(Icons.check_circle_outline_rounded,color:AppColors.primaryGreen,size:42),title:const Text('Report submitted'),content:Text('Your ticket number is '+number+'. Track its status and support replies in My Reports.'),actions:[FilledButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Done'))]));
      if(mounted){_title.clear();_description.clear();setState(()=>_image=null);}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not submit report: '+e.toString())));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Report an Issue'),actions:[TextButton.icon(onPressed:()=>context.push('/my-reports'),icon:const Icon(Icons.confirmation_number_outlined,color:AppColors.white),label:const Text('My Reports',style:TextStyle(color:AppColors.white)))]),
    body:SafeArea(child:Form(key:_key,child:ListView(padding:const EdgeInsets.all(16),children:[
      Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(16)),child:const Row(children:[Icon(Icons.support_agent_rounded,color:AppColors.darkGreen,size:32),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('How can we help?',style:TextStyle(fontWeight:FontWeight.w800,fontSize:17,color:AppColors.darkGreen)),SizedBox(height:5),Text('Describe the problem and keep your ticket number for updates.',style:TextStyle(color:AppColors.darkGreen))]))])),
      const SizedBox(height:18),const Text('Issue category',style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:7),
      DropdownButtonFormField<String>(value:_category,decoration:const InputDecoration(prefixIcon:Icon(Icons.category_outlined)),items:_categories.map((c)=>DropdownMenuItem(value:c,child:Text(c))).toList(),onChanged:(v)=>setState(()=>_category=v??'Other')),
      const SizedBox(height:14),const Text('Short title',style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:7),
      TextFormField(controller:_title,maxLength:120,textCapitalization:TextCapitalization.sentences,decoration:const InputDecoration(hintText:'e.g. Community page stays blank'),validator:(v)=>v==null||v.trim().isEmpty?'Please enter a short title.':null),
      const SizedBox(height:8),const Text('Describe the issue',style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:7),
      TextFormField(controller:_description,minLines:5,maxLines:9,maxLength:5000,textCapitalization:TextCapitalization.sentences,decoration:const InputDecoration(hintText:'What did you expect, what happened, and which screen were you using?'),validator:(v)=>v==null||v.trim().isEmpty?'Please describe the problem.':null),
      const SizedBox(height:8),const Text('Priority',style:TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:7),
      SegmentedButton<String>(segments:const[ButtonSegment(value:'Low',label:Text('Low'),icon:Icon(Icons.low_priority_rounded)),ButtonSegment(value:'Medium',label:Text('Medium'),icon:Icon(Icons.remove_circle_outline)),ButtonSegment(value:'High',label:Text('High'),icon:Icon(Icons.priority_high_rounded))],selected:{_priority},onSelectionChanged:(v)=>setState(()=>_priority=v.first)),
      const SizedBox(height:16),OutlinedButton.icon(onPressed:_busy?null:_pick,icon:const Icon(Icons.attach_file_rounded),label:Text(_image==null?'Attach screenshot (optional)':'Change screenshot')),
      if(_image!=null)...[const SizedBox(height:8),ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.file(File(_image!.path),height:170,fit:BoxFit.cover)),Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>setState(()=>_image=null),icon:const Icon(Icons.close),label:const Text('Remove')))],
      const SizedBox(height:12),FilledButton.icon(onPressed:_busy?null:_submit,icon:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:AppColors.white)):const Icon(Icons.send_rounded),label:Text(_busy?'Submitting…':'Submit report'),style:FilledButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:14))),
      TextButton(onPressed:()=>context.push('/help-faqs'),child:const Text('Check Help & FAQs first')),
    ]))));
}

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});
  @override Widget build(BuildContext context){
    final uid=ActiveProfileController.instance.effectiveUid??FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(appBar:AppBar(title:const Text('My Reports')),body:uid==null?const Center(child:Text('Sign in or activate a Demo profile to view reports.')):StreamBuilder<List<Map<String,dynamic>>>(stream:IssueSupportService.instance.watchMyTickets(uid),builder:(context,s){
      if(s.hasError)return const Center(child:Text('Could not load reports. Please try again.'));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final ts=s.data!;
      if(ts.isEmpty)return Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.inbox_outlined,size:52,color:AppColors.mutedText),const SizedBox(height:12),const Text('No reports yet',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),const SizedBox(height:8),const Text('Your support tickets will appear here.',textAlign:TextAlign.center),const SizedBox(height:12),FilledButton.icon(onPressed:()=>context.push('/report-issue'),icon:const Icon(Icons.add),label:const Text('Report an issue'))])));
      return ListView.separated(padding:const EdgeInsets.all(12),itemCount:ts.length,separatorBuilder:(_,__)=>const SizedBox(height:6),itemBuilder:(context,i){
        final t=ts[i], status=(t['status']??'open').toString();
        return Card(child:ListTile(leading:CircleAvatar(backgroundColor:AppColors.softGreen,child:Icon(_statusIcon(status),color:AppColors.darkGreen)),title:Text((t['title']??'Issue').toString(),maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Padding(padding:const EdgeInsets.only(top:5),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((t['ticketNumber']??t['id']).toString(),style:const TextStyle(fontWeight:FontWeight.w700)),Text((t['category']??'Other').toString()+' • '+statusLabel(status)),if((t['latestReply']??'').toString().isNotEmpty)Text('Reply: '+t['latestReply'].toString(),maxLines:2,overflow:TextOverflow.ellipsis)])),trailing:const Icon(Icons.chevron_right_rounded),onTap:()=>context.push('/my-reports/'+t['id'].toString())));
      });
    }));
  }
}
String statusLabel(String s)=>switch(s){'in_progress'=>'In Progress','resolved'=>'Resolved','closed'=>'Closed',_=>'Open'};
IconData _statusIcon(String s)=>switch(s){'in_progress'=>Icons.pending_actions_rounded,'resolved'=>Icons.check_circle_outline_rounded,'closed'=>Icons.lock_outline_rounded,_=>Icons.mark_email_unread_outlined};

class IssueTicketDetailScreen extends StatefulWidget {
  final String ticketId; final bool adminMode;
  const IssueTicketDetailScreen({super.key,required this.ticketId,this.adminMode=false});
  @override State<IssueTicketDetailScreen> createState()=>_IssueTicketDetailScreenState();
}
class _IssueTicketDetailScreenState extends State<IssueTicketDetailScreen>{
  final _reply=TextEditingController();String? _status;bool _saving=false;
  @override void dispose(){_reply.dispose();super.dispose();}
  Future<void> _save(Map<String,dynamic> t)async{
    final uid=ActiveProfileController.instance.effectiveUid??FirebaseAuth.instance.currentUser?.uid;if(uid==null)return;setState(()=>_saving=true);
    try{await IssueSupportService.instance.updateTicket(ticketId:widget.ticketId,actorUid:uid,actorName:ActiveProfileController.instance.effectiveName??FirebaseAuth.instance.currentUser?.displayName??'Talib Support',status:_status,reply:_reply.text);if(!mounted)return;_reply.clear();setState(()=>_status=null);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Ticket update saved.')));}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save ticket update: '+e.toString())));}
    finally{if(mounted)setState(()=>_saving=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.adminMode?'Manage Ticket':'Ticket Details')),body:StreamBuilder<Map<String,dynamic>?>(stream:IssueSupportService.instance.watchTicket(widget.ticketId),builder:(context,s){
    if(s.hasError)return const Center(child:Text('Could not load this ticket.'));
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final t=s.data;if(t==null)return const Center(child:Text('Ticket not found.'));
    final status=(t['status']??'open').toString();
    return ListView(padding:const EdgeInsets.all(16),children:[
      Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((t['ticketNumber']??widget.ticketId).toString(),style:const TextStyle(fontWeight:FontWeight.w800,color:AppColors.darkGreen)),const SizedBox(height:8),Text((t['title']??'Issue').toString(),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800,color:AppColors.darkGreen)),const SizedBox(height:8),Wrap(spacing:8,children:[Chip(label:Text(statusLabel(status))),Chip(label:Text((t['priority']??'Medium').toString())),Chip(label:Text((t['category']??'Other').toString()))])])),
      const SizedBox(height:14),const Text('Description',style:TextStyle(fontWeight:FontWeight.w800,fontSize:16)),const SizedBox(height:5),Text((t['description']??'').toString()),
      if((t['screenshotUrl']??'').toString().startsWith('http'))... [const SizedBox(height:14),const Text('Attached screenshot',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:6),ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.network(t['screenshotUrl'].toString(),fit:BoxFit.cover,errorBuilder:(_,__,___)=>const Text('Screenshot could not be loaded.')))],
      if((t['latestReply']??'').toString().isNotEmpty)...[const SizedBox(height:16),const Text('Latest support reply',style:TextStyle(fontWeight:FontWeight.w800,fontSize:16)),Card(child:ListTile(leading:const Icon(Icons.support_agent_rounded,color:AppColors.primaryGreen),title:Text((t['latestReplyBy']??'Talib Support').toString()),subtitle:Text(t['latestReply'].toString())))],
      const SizedBox(height:18),const Text('Complete ticket history',style:TextStyle(fontWeight:FontWeight.w800,fontSize:16)),
      StreamBuilder<List<Map<String,dynamic>>>(stream:IssueSupportService.instance.watchHistory(widget.ticketId),builder:(context,h){if(h.hasError)return const Text('History is temporarily unavailable.');if(!h.hasData)return const Padding(padding:EdgeInsets.all(12),child:Center(child:CircularProgressIndicator()));if(h.data!.isEmpty)return const Text('No history yet.');return Column(children:h.data!.map((e)=>Card(child:ListTile(leading:Icon(e['eventType']=='reply'?Icons.chat_bubble_outline:e['eventType']=='status_changed'?Icons.history_rounded:Icons.fiber_new_rounded,color:AppColors.primaryGreen),title:Text((e['message']??'').toString()),subtitle:Text((e['actorName']??'Talib').toString()+' • '+(e['eventType']??'update').toString()))).toList());}),
      if(widget.adminMode)...[const SizedBox(height:18),const Divider(),const Text('Manage report',style:TextStyle(fontWeight:FontWeight.w800,fontSize:17)),const SizedBox(height:8),DropdownButtonFormField<String>(value:_status??status,decoration:const InputDecoration(labelText:'Status'),items:const[DropdownMenuItem(value:'open',child:Text('Open')),DropdownMenuItem(value:'in_progress',child:Text('In Progress')),DropdownMenuItem(value:'resolved',child:Text('Resolved')),DropdownMenuItem(value:'closed',child:Text('Closed'))],onChanged:(v)=>setState(()=>_status=v)),const SizedBox(height:10),TextField(controller:_reply,minLines:3,maxLines:6,maxLength:2000,decoration:const InputDecoration(labelText:'Reply to user',hintText:'Write a helpful response…')),const SizedBox(height:8),FilledButton.icon(onPressed:_saving?null:()=>_save(t),icon:_saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:AppColors.white)):const Icon(Icons.save_outlined),label:Text(_saving?'Saving…':'Save update'))],
    ]);
  }));
}
