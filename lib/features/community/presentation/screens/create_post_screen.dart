import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../models/post.dart';

class CreatePostScreen extends StatefulWidget {
  final Post? post;
  final String? instituteId;
  final String? instituteName;
  const CreatePostScreen({super.key,this.post,this.instituteId,this.instituteName});
  @override State<CreatePostScreen> createState()=>_CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller=TextEditingController();
  final _pollController=TextEditingController();
  final _db=DatabaseService();
  bool _saving=false;
  String category='General';
  bool isQuestion=false;
  bool isPoll=false;

  static const categories=[
    'General','Admission Help','Career','Scholarships','Study Help',
    'Institute Reviews','Jobs/Internships','Announcements'
  ];

  @override void initState(){
    super.initState();
    final p=widget.post;
    if(p!=null){
      _controller.text=p.text;
      category=p.category;
      isQuestion=p.isQuestion;
      isPoll=p.pollOptions.isNotEmpty;
      _pollController.text=p.pollOptions.join('\n');
    }
  }

  @override void dispose(){_controller.dispose();_pollController.dispose();super.dispose();}

  List<String> _options()=>isPoll
      ? _pollController.text.split('\n').map((x)=>x.trim()).where((x)=>x.isNotEmpty).toList()
      : <String>[];

  void _error(Object e){
    final msg=e.toString().replaceFirst('Exception: ','').trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:AppColors.darkGreen,
        content:Text(msg.isEmpty?'Could not save the post.':msg,style:const TextStyle(color:AppColors.white)),
      ),
    );
  }

  Future<void> _publish() async {
    final text=_controller.text.trim();
    if(text.isEmpty){_error('Write something before publishing.');return;}
    final options=_options();
    if(isPoll&&options.length<2){_error('Add at least 2 poll options.');return;}
    if(isPoll&&options.length>5){_error('A poll can have maximum 5 options.');return;}
    if(isPoll&&options.toSet().length!=options.length){_error('Poll options must be unique.');return;}

    final firebaseOn=FirebaseService.initialized;
    final user=FirebaseAuth.instance.currentUser;
    if(firebaseOn&&user==null){
      _error('Please sign in first. Firebase is enabled but no user is signed in.');
      return;
    }

    setState(()=>_saving=true);
    try{
      final uid=user?.uid??'demo-current-user';
      final name=user?.displayName?.trim().isNotEmpty==true
          ? user!.displayName!.trim()
          : (user?.email??'Demo Student');

      if(widget.post==null){
        final id=await _db.createPost(
          text:text,authorId:uid,authorName:name,category:category,
          isQuestion:isQuestion,pollOptions:options,
          instituteId:widget.instituteId?.trim().isEmpty==true?null:widget.instituteId,
        );
        await _db.notifyMentions(text:text,fromId:uid,postId:id);
      }else{
        await _db.updatePost(
          postId:widget.post!.id,text:text,category:category,
          isQuestion:isQuestion,pollOptions:options,
        );
      }
      if(mounted)context.pop(true);
    }catch(e){
      if(mounted)_error(e);
    }finally{
      if(mounted)setState(()=>_saving=false);
    }
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(
      title:Text(widget.post==null
          ? (widget.instituteName==null?'Create post':'Post in ${widget.instituteName}')
          :'Edit post'),
      actions:[
        TextButton(
          onPressed:_saving?null:_publish,
          child:Text(_saving?'...':'Post',style:const TextStyle(color:AppColors.white,fontWeight:FontWeight.w800)),
        )
      ],
    ),
    body:ListView(
      padding:const EdgeInsets.fromLTRB(14,10,14,24),
      children:[
        Row(children:[
          const CircleAvatar(radius:21,backgroundColor:AppColors.softGreen,child:Icon(Icons.person,color:AppColors.primaryGreen)),
          const SizedBox(width:10),
          Expanded(child:Text(widget.post==null?'Share with the community':'Update your post',
            style:const TextStyle(color:AppColors.darkGreen,fontWeight:FontWeight.w700)))
        ]),
        const SizedBox(height:14),
        DropdownButtonFormField<String>(
          value:category,
          decoration:const InputDecoration(labelText:'Category'),
          items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
          onChanged:_saving?null:(v)=>setState(()=>category=v??category),
        ),
        const SizedBox(height:12),
        SwitchListTile(
          contentPadding:EdgeInsets.zero,
          title:const Text('Ask a question'),
          subtitle:const Text('Let other students answer and mark the best answer.'),
          value:isQuestion,onChanged:_saving?null:(v)=>setState(()=>isQuestion=v),
        ),
        SwitchListTile(
          contentPadding:EdgeInsets.zero,
          title:const Text('Add a poll'),
          subtitle:const Text('Add 2–5 options for the community to vote on.'),
          value:isPoll,onChanged:_saving?null:(v)=>setState(()=>isPoll=v),
        ),
        if(isPoll)Padding(
          padding:const EdgeInsets.only(bottom:12),
          child:TextField(
            controller:_pollController,maxLines:5,enabled:!_saving,
            decoration:const InputDecoration(labelText:'Poll options',hintText:'One option per line'),
          ),
        ),
        TextField(
          controller:_controller,maxLines:8,maxLength:1000,enabled:!_saving,
          decoration:const InputDecoration(hintText:'What do you want to share?'),
        ),
      ],
    ),
  );
}
