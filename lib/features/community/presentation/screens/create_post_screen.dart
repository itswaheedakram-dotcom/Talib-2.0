import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/database_service.dart';
import '../../../models/post.dart';

class CreatePostScreen extends StatefulWidget{
  final Post? post;final String? instituteId;final String? instituteName;
  const CreatePostScreen({super.key,this.post,this.instituteId,this.instituteName});
  @override State<CreatePostScreen> createState()=>_CreatePostScreenState();
}
class _CreatePostScreenState extends State<CreatePostScreen>{
  final _controller=TextEditingController();final _pollController=TextEditingController();final _db=DatabaseService();bool _saving=false;String category='General';bool isQuestion=false;bool isPoll=false;
  static const categories=['General','Admission Help','Career','Scholarships','Study Help','Institute Reviews','Jobs/Internships','Announcements'];
  @override void initState(){super.initState();final p=widget.post;if(p!=null){_controller.text=p.text;category=p.category;isQuestion=p.isQuestion;isPoll=p.pollOptions.isNotEmpty;_pollController.text=p.pollOptions.join('\n');}}
  @override void dispose(){_controller.dispose();_pollController.dispose();super.dispose();}
  Future<void> _publish()async{
    final user=FirebaseAuth.instance.currentUser;final text=_controller.text.trim();
    if(user==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please sign in first.')));return;}
    if(text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Write something before publishing.')));return;}
    setState(()=>_saving=true);try{final name=user.displayName?.trim().isNotEmpty==true?user.displayName!.trim():(user.email??'Student');if(widget.post==null){await _db.createPost(text:text,authorId:user.uid,authorName:name,category:category,isQuestion:isQuestion,pollOptions:isPoll?_pollController.text.split('\n').map((x)=>x.trim()).where((x)=>x.isNotEmpty).take(5).toList():const <String>[],instituteId:widget.instituteId);}else{await _db.updatePost(postId:widget.post!.id,text:text,category:category,isQuestion:isQuestion);}if(mounted)context.pop();}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not save the post.')));}finally{if(mounted)setState(()=>_saving=false);}}
  @override Widget build(BuildContext context){const green=Color(0xFF00A66A);return Scaffold(appBar:AppBar(title:Text(widget.post==null?(widget.instituteName==null?'Create post':'Post in '+widget.instituteName!):'Edit post'),actions:[TextButton(onPressed:_saving?null:_publish,child:Text(_saving?'...':'Post',style:const TextStyle(color:green,fontWeight:FontWeight.w800)))]),body:ListView(padding:const EdgeInsets.fromLTRB(14,10,14,24),children:[
    Row(children:[const CircleAvatar(radius:21,backgroundColor:Color(0xFFEAF8F2),child:Icon(Icons.person,color:green)),const SizedBox(width:10),Expanded(child:Text(widget.post==null?'Share with the community':'Update your post',style:const TextStyle(fontWeight:FontWeight.w700)))]),const SizedBox(height:14),
    DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'Category',border:OutlineInputBorder()),items:categories.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>category=v??category)),
    const SizedBox(height:12),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Ask a question'),subtitle:const Text('Let other students answer and mark the best answer.'),value:isQuestion,onChanged:(v)=>setState(()=>isQuestion=v)),SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Add a poll'),subtitle:const Text('Add 2–5 options for the community to vote on.'),value:isPoll,onChanged:(v)=>setState(()=>isPoll=v)),if(isPoll)Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:_pollController,maxLines:5,decoration:const InputDecoration(labelText:'Poll options',hintText:'One option per line',border:OutlineInputBorder())),
    TextField(controller:_controller,maxLines:8,maxLength:1000,decoration:const InputDecoration(hintText:'What do you want to share?',border:OutlineInputBorder())),
  ]));}
}