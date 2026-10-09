import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../models/hostel.dart';
import '../../data/hostel_manager.dart';
import '../../data/hostel_repository.dart';

class HostelManagersScreen extends StatefulWidget {
  final String hostelId;
  const HostelManagersScreen({super.key, required this.hostelId});
  @override State<HostelManagersScreen> createState() => _HostelManagersScreenState();
}

class _HostelManagersScreenState extends State<HostelManagersScreen> {
  Hostel? _hostel;
  HostelRepository? _repository;
  bool _loading=true, _saving=false;
  final _uid=TextEditingController(), _name=TextEditingController();
  final Map<String,bool> _permissions={for(final k in HostelManagerPermissions.labels.keys) k:true};
  HostelRepository get repo=>_repository ??= HostelRepository();

  String? get currentUid {
    final a=ActiveProfileController.instance.active;
    if(a!=null) return a.id;
    if(!FirebaseService.initialized) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }
  bool get isOwner=>_hostel!=null && currentUid!=null && _hostel!.ownerId==currentUid;

  @override void initState(){super.initState(); _load();}
  @override void dispose(){_uid.dispose();_name.dispose();super.dispose();}

  Future<void> _load() async {
    Hostel? h;
    try {
      for(final item in HostelRepository.demoHostels){
        if(item.id==widget.hostelId){h=item;break;}
      }
      if(h==null && FirebaseService.initialized){
        _repository ??= HostelRepository();
        h=await _repository!.getHostel(widget.hostelId);
      }
    } catch (_) {}
    if(mounted)setState(() { _hostel=h; _loading=false; });
  }

  void _pick(ActiveDemoProfile p){_uid.text=p.id;_name.text=p.name;}

  Future<void> _add() async {
    final id=_uid.text.trim();
    if(id.isEmpty){_msg('Pehle manager select karein ya User ID likhein.');return;}
    if(id==currentUid){_msg('Owner ko manager banane ki zaroorat nahi.');return;}
    setState(()=>_saving=true);
    try{
      await repo.addManager(hostelId:widget.hostelId,userId:id,userName:_name.text.trim(),permissions:_permissions);
      _uid.clear();_name.clear();
      _msg('Manager access add ho gaya.');
      if(mounted)setState((){});
    }catch(e){_msg('Manager add nahi ho saka.');}
    finally{if(mounted)setState(()=>_saving=false);}
  }

  void _msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}

  Future<void> _remove(String id) async {
    try{await repo.removeManager(widget.hostelId,id);if(mounted)setState((){});}catch(_){_msg('Access remove nahi ho saka.');}
  }

  Future<void> _edit(HostelManager m) async {
    final values=Map<String,bool>.from(m.permissions);
    final ok=await showDialog<bool>(context:context,builder:(c)=>StatefulBuilder(
      builder:(c,setD)=>AlertDialog(
        title:Text('Access: ${m.userName}'),
        content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:
          HostelManagerPermissions.labels.entries.map((e)=>SwitchListTile(
            contentPadding:EdgeInsets.zero,title:Text(e.value),value:values[e.key]==true,
            onChanged:(v)=>setD(()=>values[e.key]=v))).toList())),
        actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),
          FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Save'))],
      )));
    if(ok!=true)return;
    try{await repo.updateManagerPermissions(hostelId:widget.hostelId,userId:m.userId,permissions:values);if(mounted)setState((){});}
    catch(_){_msg('Permissions update nahi ho sakin.');}
  }

  Widget _permissionsBox(){
    final count=_permissions.values.where((v)=>v).length;
    return Card(color:AppColors.white,elevation:0,child:Padding(padding:const EdgeInsets.all(16),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[const Expanded(child:Text('Manager kya manage kar sakta hai?',style:TextStyle(color:AppColors.darkGreen,fontSize:17,fontWeight:FontWeight.w800))),Text('$count/${_permissions.length}',style:const TextStyle(color:AppColors.primaryGreen,fontWeight:FontWeight.w800))]),
        const SizedBox(height:5),const Text('Sirf woh cheezen select karein jo manager ko change karni hain.',style:TextStyle(color:AppColors.mutedText)),
        Wrap(spacing:8,children:[
          ActionChip(label:const Text('Select all'),onPressed:()=>setState((){for(final k in _permissions.keys)_permissions[k]=true;})),
          ActionChip(label:const Text('Clear all'),onPressed:()=>setState((){for(final k in _permissions.keys)_permissions[k]=false;})),
        ]),
        ...HostelManagerPermissions.labels.entries.map((e)=>CheckboxListTile(contentPadding:EdgeInsets.zero,title:Text(e.value),value:_permissions[e.key]==true,onChanged:(v)=>setState(()=>_permissions[e.key]=v==true))),
      ])));
  }

  @override Widget build(BuildContext context) {
    try {
      return _buildScreen(context);
    } catch (error) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Manage Managers')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Manage Managers could not be loaded.\\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildScreen(BuildContext context) {
    if(_loading)return const Scaffold(backgroundColor:AppColors.cream,body:Center(child:CircularProgressIndicator(color:AppColors.primaryGreen)));
    if(_hostel==null)return Scaffold(backgroundColor:AppColors.cream,appBar:AppBar(title:const Text('Manage Managers')),body:const Center(child:Text('Hostel nahi mila.')));
    if(!isOwner)return Scaffold(backgroundColor:AppColors.cream,appBar:AppBar(title:const Text('Manage Managers')),body:const Center(child:Padding(padding:EdgeInsets.all(24),child:Text('Sirf hostel owner managers ko manage kar sakta hai.',textAlign:TextAlign.center))));
    return Scaffold(backgroundColor:AppColors.cream,appBar:AppBar(title:const Text('Manage Managers')),body:StreamBuilder<List<HostelManager>>(
      stream:repo.watchManagers(widget.hostelId),builder:(context,s){
        if(s.hasError)return Center(child:Text('Managers load nahi ho sake.\n${s.error}',textAlign:TextAlign.center));
        final list=s.data??const <HostelManager>[];
        return ListView(padding:const EdgeInsets.fromLTRB(16,16,16,40),children:[
          Text(_hostel!.name,style:const TextStyle(color:AppColors.darkGreen,fontSize:24,fontWeight:FontWeight.w800)),
          const SizedBox(height:4),const Text('Trusted person ko limited access dein. Ownership hamesha aapke paas rahegi.',style:TextStyle(color:AppColors.mutedText)),
          const SizedBox(height:16),
          Card(color:AppColors.white,elevation:0,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Add a manager',style:TextStyle(color:AppColors.darkGreen,fontSize:18,fontWeight:FontWeight.w800)),
            const SizedBox(height:6),const Text('Demo user ke liye naam par tap karein; real user ke liye Firebase UID use karein.',style:TextStyle(color:AppColors.mutedText)),
            const SizedBox(height:10),
            Wrap(spacing:8,runSpacing:8,children:temporaryProfiles.where((p)=>p.id!=currentUid).map((p)=>ActionChip(avatar:const Icon(Icons.person_outline,size:18),label:Text(p.name),onPressed:()=>_pick(p))).toList()),
            const SizedBox(height:12),
            TextField(controller:_name,decoration:const InputDecoration(labelText:'Manager name',prefixIcon:Icon(Icons.badge_outlined))),
            const SizedBox(height:10),TextField(controller:_uid,decoration:const InputDecoration(labelText:'User ID',hintText:'Demo ID ya Firebase UID',prefixIcon:Icon(Icons.fingerprint))),
          ]))),
          const SizedBox(height:12),_permissionsBox(),const SizedBox(height:12),
          FilledButton.icon(onPressed:_saving?null:_add,icon:_saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:AppColors.white)):const Icon(Icons.person_add_alt_1),label:Text(_saving?'Adding...':'Add manager')),
          const SizedBox(height:24),Row(children:[const Expanded(child:Text('Current managers',style:TextStyle(color:AppColors.darkGreen,fontSize:19,fontWeight:FontWeight.w800))),Text('${list.length}')]),
          const SizedBox(height:8),
          if(list.isEmpty)Card(color:AppColors.white,elevation:0,child:const Padding(padding:EdgeInsets.all(20),child:Column(children:[Icon(Icons.manage_accounts_outlined,size:42,color:AppColors.mutedText),SizedBox(height:8),Text('Abhi koi manager nahi hai.',style:TextStyle(fontWeight:FontWeight.w700)),SizedBox(height:4),Text('Upar se pehla manager add karein.',style:TextStyle(color:AppColors.mutedText))])))
          else ...list.map((m)=>Card(color:AppColors.white,elevation:0,margin:const EdgeInsets.only(bottom:10),child:ListTile(
            leading:CircleAvatar(backgroundColor:AppColors.softGreen,child:const Icon(Icons.person_outline,color:AppColors.darkGreen)),
            title:Text(m.userName,style:const TextStyle(fontWeight:FontWeight.w700)),
            subtitle:Text('${m.userId}\n${m.permissions.values.where((v)=>v).length} permissions enabled'),isThreeLine:true,
            trailing:PopupMenuButton<String>(onSelected:(v){if(v=='edit')_edit(m);if(v=='remove')_remove(m.userId);},itemBuilder:(_)=>const[
              PopupMenuItem(value:'edit',child:Text('Edit permissions')),PopupMenuItem(value:'remove',child:Text('Remove access'))])))),
        ]);
      }));
  }
}
