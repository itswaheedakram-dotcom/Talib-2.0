import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/admin_access_service.dart';
import '../../../../core/services/issue_support_service.dart';
import 'report_issue_screen.dart';

class AdminIssueReportsScreen extends StatelessWidget {
  const AdminIssueReportsScreen({super.key});
  bool get _allowed { final a=AdminAccessService.instance; return a.isDemoSuperAdmin||a.isSuperAdmin||a.can('manage_reports'); }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Issue Reports')),body:!_allowed?const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('You do not have permission to manage issue reports. Ask the Super Admin to assign Manage Reports permission.',textAlign:TextAlign.center))):StreamBuilder<List<Map<String,dynamic>>>(stream:IssueSupportService.instance.watchAllTickets(),builder:(context,s){
    if(s.hasError)return const Center(child:Text('Could not load issue reports. Check report-management permissions.'));
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final tickets=s.data!;final open=tickets.where((t)=>!{'resolved','closed'}.contains(t['status'])).length;final resolved=tickets.where((t)=>t['status']=='resolved').length;
    return Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(12,12,12,4),child:Row(children:[Expanded(child:_metric('Total',tickets.length.toString(),Icons.confirmation_number_outlined)),Expanded(child:_metric('Open',open.toString(),Icons.mark_email_unread_outlined)),Expanded(child:_metric('Resolved',resolved.toString(),Icons.check_circle_outline))])),
      Expanded(child:tickets.isEmpty?const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('No issue reports have been submitted yet.',textAlign:TextAlign.center))):ListView.separated(padding:const EdgeInsets.all(12),itemCount:tickets.length,separatorBuilder:(_,__)=>const SizedBox(height:6),itemBuilder:(context,i){
        final t=tickets[i];final status=(t['status']??'open').toString();
        return Card(child:ListTile(leading:CircleAvatar(backgroundColor:AppColors.softGreen,child:Icon(Icons.flag_outlined,color:AppColors.darkGreen)),title:Text((t['title']??'Issue').toString(),maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text((t['ticketNumber']??t['id']).toString()+' • '+(t['reporterName']??t['reporterId']).toString()+'\n'+(t['category']??'Other').toString()+' • '+statusLabel(status)+' • '+(t['priority']??'Medium').toString()),isThreeLine:true,trailing:const Icon(Icons.chevron_right_rounded),onTap:()=>context.push('/admin/reports/'+t['id'].toString())));
      })),
    ]);
  }));
  Widget _metric(String label,String value,IconData icon)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:AppColors.primaryGreen),const SizedBox(height:7),Text(value,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:22)),Text(label,style:const TextStyle(color:AppColors.mutedText))])));
}
