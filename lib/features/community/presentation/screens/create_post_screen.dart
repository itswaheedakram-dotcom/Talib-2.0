import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final _pollController=TextEditingController();
  final _db=DatabaseService();
  bool _saving=false;
  String category='General';
  bool isQuestion=false;
  bool isPoll=false;
  static const categories=['General','Admission Help','Career','Scholarships','Study Help','Institute Reviews','Jobs/Internships','Announcements'];

  @override void initState(){
    super.initState();
    final p=widget.post;
    if(p!=null){
      _controller.text=p.text;
      category=categories.contains(p.category)?p.category:'General';
      isQuestion=p.isQuestion;
      isPoll=p.pollOptions.isNotEmpty;
      _pollController.text=p.pollOptions.join('\n');
    }
  }
  @override void dispose(){_controller.dispose();_pollController.dispose();super.dispose();}

  String _errorText(Object error){
    final raw=error.toString().trim();
    if(raw.isEmpty)return 'Unknown error.';
    return raw.replaceFirst(RegExp(r'^Exception:\s*'),'');
  }
  void _showError(Object error){
    if(!mounted)return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:Text(_errorText(error)),duration:const Duration(seconds:5),
    ));
  }

  Future<void> _publish()async{
    if(_saving)return;
    final identity=ActiveProfileController.instance;
    final demoActive=identity.isDemoActive;
    User? user;
    try{user=FirebaseService.initialized?FirebaseAuth.instance.currentUser:null;}
    catch(error){_showError(error);return;}

    final text=_controller.text.trim();
    if(user==null&&!demoActive){
      _showError(StateError('Please sign in first. Firebase authentication has no active user.'));
      return;
    }
    if(text.isEmpty){_showError(ArgumentError('Write something before publishing.'));return;}

    final options=isPoll
      ?_pollController.text.split('\n').map((x)=>x.trim()).where((x)=>x.isNotEmpty).take(5).toList()
      :<String>[];
    if(isPoll&&options.length<2){_showError(ArgumentError('Add at least 2 poll options.'));return;}

    setState(()=>_saving=true);
    try{
      final authorId=identity.resolveUid(user?.uid??'');
      final name=identity.effectiveName ??
        (user?.displayName?.trim().isNotEmpty==true
          ?user!.displayName!.trim():(user?.email??'Student'));

      if(widget.post==null){
        final postId=await _db.createPost(
          text:text,authorId:authorId,authorName:name,category:category,
          isQuestion:isQuestion,pollOptions:options,instituteId:widget.instituteId,
        );
        if(!demoActive&&user!=null){
          try{await _db.notifyMentions(text:text,fromId:user.uid,postId:postId);}
          catch(error){debugPrint('Mention notification failed: $error');}
        }
      }else{
        await _db.updatePost(
          postId:widget.post!.id,text:text,category:category,isQuestion:isQuestion,
          pollOptions:options,instituteId:widget.post!.instituteId??widget.instituteId,
        );
      }
      if(mounted)context.pop(true);
    }catch(error){_showError(error);}
    finally{if(mounted)setState(()=>_saving=false);}
  }

  @override Widget build(BuildContext context){
    final editing=widget.post!=null;
    return Scaffold(
      appBar:AppBar(
        title:Text(editing?'Edit post':
          (widget.instituteName==null?'Create post':'Post in ${widget.instituteName}')),
        actions:[TextButton(
          onPressed:_saving?null:_publish,
          child:Text(_saving?'Posting…':'Post',
            style:const TextStyle(color:AppColors.white,fontWeight:FontWeight.w800)),
        )],
      ),
      body:ListView(
        padding:const EdgeInsets.fromLTRB(14,10,14,24),
        children:[
          Row(children:[
            const CircleAvatar(radius:21,backgroundColor:AppColors.softGreen,
              child:Icon(Icons.person,color:AppColors.primaryGreen)),
            const SizedBox(width:10),
            Expanded(child:Text(
              editing?'Update your post':
              (widget.instituteName==null?'Share with the community':'Share with this institute community'),
              style:const TextStyle(color:AppColors.darkGreen,fontWeight:FontWeight.w700),
            )),
          ]),
          const SizedBox(height:14),
          DropdownButtonFormField<String>(
            value:category,decoration:const InputDecoration(labelText:'Category'),
            items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
            onChanged:_saving?null:(v)=>setState(()=>category=v??category),
          ),
          const SizedBox(height:12),
          SwitchListTile(contentPadding:EdgeInsets.zero,activeColor:AppColors.primaryGreen,
            title:const Text('Ask a question'),
            subtitle:const Text('Let other students answer and mark the best answer.'),
            value:isQuestion,onChanged:_saving?null:(v)=>setState(()=>isQuestion=v)),
          SwitchListTile(contentPadding:EdgeInsets.zero,activeColor:AppColors.primaryGreen,
            title:const Text('Add a poll'),
            subtitle:const Text('Add 2–5 options for the community to vote on.'),
            value:isPoll,onChanged:_saving?null:(v)=>setState(()=>isPoll=v)),
          if(isPoll)Padding(
            padding:const EdgeInsets.only(bottom:12),
            child:TextField(controller:_pollController,maxLines:5,
              decoration:const InputDecoration(labelText:'Poll options',hintText:'One option per line')),
          ),
          TextField(controller:_controller,maxLines:8,maxLength:1000,
            decoration:const InputDecoration(hintText:'What do you want to share?')),
        ],
      ),
    );
  }
}
