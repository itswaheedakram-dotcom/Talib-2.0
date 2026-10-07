import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../models/post.dart';

class CreatePostScreen extends StatefulWidget{
  final Post? post;
  final String? instituteId;
  final String? instituteName;
  const CreatePostScreen({super.key,this.post,this.instituteId,this.instituteName});
  @override State<CreatePostScreen> createState()=>_CreatePostScreenState();
}
class _CreatePostScreenState extends State<CreatePostScreen>{
  final _controller=TextEditingController();
  final _db=DatabaseService();
  final _picker=ImagePicker();
  final _pollOptions=<TextEditingController>[];
  final _attachments=<Map<String,String>>[];
  bool _saving=false,_isQuestion=false,_isPoll=false;
  String category='General';
  static const categories=['General','Admission Help','Career','Scholarships','Study Help','Institute Reviews','Jobs/Internships','Announcements'];

  @override void initState(){
    super.initState();
    final p=widget.post;
    if(p!=null){
      _controller.text=p.text;
      category=categories.contains(p.category)?p.category:'General';
      _isQuestion=p.isQuestion;_isPoll=p.pollOptions.isNotEmpty;
      for(final option in p.pollOptions)_addPollOption(option);
      _attachments.addAll(p.attachments.map((x)=>Map<String,String>.from(x)));
    }
  }
  void _addPollOption([String value='']){
    if(_pollOptions.length>=5)return;
    final c=TextEditingController(text:value);
    _pollOptions.add(c);
    if(mounted)setState((){});
  }
  void _removePollOption(int index){
    if(_pollOptions.length<=2)return;
    final c=_pollOptions.removeAt(index);c.dispose();setState((){});
  }
  @override void dispose(){_controller.dispose();for(final c in _pollOptions)c.dispose();super.dispose();}

  String _errorText(Object error){final raw=error.toString().trim();if(raw.isEmpty)return 'Unknown error.';return raw.replaceFirst(RegExp(r'^Exception:\s*'),'');}
  void _showError(Object error){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_errorText(error)),duration:const Duration(seconds:5)));}

  Future<void> _showAttachmentMenu()async{
    await showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(sheet)=>SafeArea(child:Padding(
      padding:const EdgeInsets.fromLTRB(18,8,18,22),child:Wrap(children:[
        ListTile(leading:const Icon(Icons.photo_outlined,color:AppColors.primaryGreen),title:const Text('Photo'),subtitle:const Text('Add a picture to your post'),onTap:(){Navigator.pop(sheet);_pickPhoto();}),
        ListTile(leading:const Icon(Icons.insert_drive_file_outlined,color:AppColors.primaryGreen),title:const Text('File'),subtitle:const Text('Attach a document or file'),onTap:(){Navigator.pop(sheet);_pickFile();}),
        ListTile(leading:const Icon(Icons.link,color:AppColors.primaryGreen),title:const Text('Link'),subtitle:const Text('Add a web link'),onTap:(){Navigator.pop(sheet);_addLink();}),
        ListTile(leading:const Icon(Icons.poll_outlined,color:AppColors.primaryGreen),title:const Text('Poll'),subtitle:const Text('Create a poll with 2–5 options'),onTap:(){Navigator.pop(sheet);_enablePoll();}),
      ]),
    )));
  }

  Future<void> _pickPhoto()async{
    try{
      final x=await _picker.pickImage(source:ImageSource.gallery,imageQuality:85,maxWidth:1800);
      if(x==null)return;
      await _stageAttachment(bytes:await x.readAsBytes(),fileName:x.name,type:'photo',localPath:x.path);
    }catch(error){_showError(error);}
  }
  Future<void> _pickFile()async{
    try{
      final result=await FilePicker.platform.pickFiles(withData:true);
      if(result==null||result.files.isEmpty)return;
      final f=result.files.single;
      if(f.bytes==null){_showError(StateError('Could not read the selected file.'));return;}
      await _stageAttachment(bytes:f.bytes!,fileName:f.name,type:'file');
    }catch(error){_showError(error);}
  }
  Future<void> _stageAttachment({required Uint8List bytes,required String fileName,required String type,String? localPath})async{
    if(FirebaseService.initialized){
      final user=FirebaseAuth.instance.currentUser;
      if(user!=null){
        try{
          final url=await _db.uploadCommunityAttachment(bytes:bytes,fileName:fileName,type:type);
          if(mounted)setState(()=>_attachments.add({'type':type,'name':fileName,'url':url}));
          return;
        }catch(error){_showError(error);return;}
      }
    }
    if(mounted)setState(()=>_attachments.add({'type':type,'name':fileName,'url':localPath??''}));
  }
  Future<void> _addLink()async{
    final c=TextEditingController();
    final url=await showDialog<String>(context:context,builder:(d)=>AlertDialog(
      title:const Text('Add link'),content:TextField(controller:c,keyboardType:TextInputType.url,autofocus:true,decoration:const InputDecoration(hintText:'https://example.com')),
      actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(d,c.text.trim()),child:const Text('Add'))],
    ));
    c.dispose();if(url==null||url.isEmpty)return;
    final normalized=url.startsWith('http://')||url.startsWith('https://')?url:'https://$url';
    setState(()=>_attachments.add({'type':'link','name':normalized,'url':normalized}));
  }
  void _enablePoll(){
    setState(()=>_isPoll=true);
    if(_pollOptions.isEmpty){_addPollOption();_addPollOption();}else if(_pollOptions.length==1)_addPollOption();
  }

  Future<void> _publish()async{
    if(_saving)return;
    final identity=ActiveProfileController.instance;final demoActive=identity.isDemoActive;
    User? user;
    try{user=FirebaseService.initialized?FirebaseAuth.instance.currentUser:null;}catch(error){_showError(error);return;}
    if(user==null&&!demoActive){_showError(StateError('Please sign in first. Firebase authentication has no active user.'));return;}
    final text=_controller.text.trim();if(text.isEmpty){_showError(ArgumentError('Write something before publishing.'));return;}
    final options=_isPoll?_pollOptions.map((c)=>c.text.trim()).where((x)=>x.isNotEmpty).take(5).toList():<String>[];
    if(_isPoll&&options.length<2){_showError(ArgumentError('Add at least 2 poll options.'));return;}
    setState(()=>_saving=true);
    try{
      final authorId=identity.resolveUid(user?.uid??'');
      final name=identity.effectiveName ?? (user?.displayName?.trim().isNotEmpty==true?user!.displayName!.trim():(user?.email??'Student'));
      if(widget.post==null){
        final postId=await _db.createPost(text:text,authorId:authorId,authorName:name,category:category,isQuestion:_isQuestion,pollOptions:options,instituteId:widget.instituteId,attachments:_attachments);
        if(!demoActive&&user!=null){try{await _db.notifyMentions(text:text,fromId:user.uid,postId:postId);}catch(error){debugPrint('Mention notification failed: $error');}}
      }else{
        await _db.updatePost(postId:widget.post!.id,text:text,category:category,isQuestion:_isQuestion,pollOptions:options,instituteId:widget.post!.instituteId??widget.instituteId,attachments:_attachments);
      }
      if(mounted)context.pop(true);
    }catch(error){_showError(error);}finally{if(mounted)setState(()=>_saving=false);}
  }

  Widget _attachmentPreview(){
    if(_attachments.isEmpty)return const SizedBox.shrink();
    return Padding(padding:const EdgeInsets.only(bottom:10),child:Wrap(spacing:8,runSpacing:8,children:List.generate(_attachments.length,(i){
      final a=_attachments[i];final type=a['type']??'file';final icon=type=='photo'?Icons.image_outlined:type=='link'?Icons.link:Icons.insert_drive_file_outlined;
      return InputChip(avatar:Icon(icon,size:18,color:AppColors.primaryGreen),label:SizedBox(width:150,child:Text(a['name']??'Attachment',overflow:TextOverflow.ellipsis)),onDeleted:_saving?null:()=>setState(()=>_attachments.removeAt(i)));
    })));
  }
  Widget _pollEditor(){
    if(!_isPoll)return const SizedBox.shrink();
    return Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(12),
      decoration:BoxDecoration(color:AppColors.softGreen,borderRadius:BorderRadius.circular(14)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('Poll',style:TextStyle(fontWeight:FontWeight.w800,color:AppColors.darkGreen)),const SizedBox(height:8),
        ...List.generate(_pollOptions.length,(i)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Row(children:[
          Expanded(child:TextField(controller:_pollOptions[i],decoration:InputDecoration(hintText:'Option ${i+1}',filled:true,fillColor:AppColors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:BorderSide.none)))),
          if(_pollOptions.length>2)IconButton(onPressed:()=>_removePollOption(i),icon:const Icon(Icons.close)),
        ]))),
        if(_pollOptions.length<5)TextButton.icon(onPressed:_saving?null:()=>_addPollOption(),icon:const Icon(Icons.add),label:const Text('Add option')),
      ]),
    );
  }

  @override Widget build(BuildContext context){
    final editing=widget.post!=null;
    return Scaffold(appBar:AppBar(title:Text(editing?'Edit post':(widget.instituteName==null?'Create post':'Post in ${widget.instituteName}')),actions:[
      TextButton(onPressed:_saving?null:_publish,child:Text(_saving?'Posting…':'Post',style:const TextStyle(color:AppColors.white,fontWeight:FontWeight.w800))),
    ]),
    body:ListView(padding:const EdgeInsets.fromLTRB(14,10,14,24),children:[
      Row(children:[const CircleAvatar(radius:21,backgroundColor:AppColors.softGreen,child:Icon(Icons.person,color:AppColors.primaryGreen)),const SizedBox(width:10),
        Expanded(child:Text(editing?'Update your post':(widget.instituteName==null?'Share with the community':'Share with this institute community'),style:const TextStyle(color:AppColors.darkGreen,fontWeight:FontWeight.w700)))]),
      const SizedBox(height:14),
      DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Tag'),items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:_saving?null:(v)=>setState(()=>category=v??category)),
      const SizedBox(height:10),
      TextField(controller:_controller,maxLines:8,maxLength:1000,decoration:const InputDecoration(hintText:'What do you want to share?')),
      _pollEditor(),_attachmentPreview(),
      Row(children:[
        Expanded(child:Text('Add to your post',style:TextStyle(color:AppColors.homeMutedText,fontWeight:FontWeight.w600))),
        IconButton(tooltip:'Attachments',onPressed:_saving?null:_showAttachmentMenu,icon:const Icon(Icons.attach_file,color:AppColors.primaryGreen)),
        FilterChip(label:const Text('Question'),selected:_isQuestion,onSelected:_saving?null:(v)=>setState(()=>_isQuestion=v),selectedColor:AppColors.softGreen),
      ]),
      if(_isQuestion)const Padding(padding:EdgeInsets.only(top:4),child:Text('After people answer, the author can mark one answer as Best Answer.',style:TextStyle(fontSize:12,color:AppColors.homeMutedText))),
    ]));
  }
}