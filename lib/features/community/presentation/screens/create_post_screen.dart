import '../../../../core/models/user_profile.dart';
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
import '../../../models/institute.dart';
import '../../../institutes/data/institute_repository.dart';
import '../../timeline_topics.dart';

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
  final Set<String> _selectedTags={};
  final Set<String> _selectedInstituteIds={};
  static final categories=TimelineTopics.all;

  @override void initState(){
    super.initState();
    final p=widget.post;
    if(p!=null){
      _controller.text=p.text;
      category=TimelineTopics.byName(p.category)!=null?p.category:'General';
      _selectedTags..clear()..addAll(p.tags);
      _selectedInstituteIds..clear()..addAll(p.instituteIds.isNotEmpty?p.instituteIds:(p.instituteId==null?const []:[p.instituteId!]));
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
          if(mounted)setState(()=>_attachments.add({'type':type,ProfileFields.name:fileName,'url':url}));
          return;
        }catch(error){_showError(error);return;}
      }
    }
    if(mounted)setState(()=>_attachments.add({'type':type,ProfileFields.name:fileName,'url':localPath??''}));
  }
  Future<void> _addLink()async{
    final c=TextEditingController();
    final url=await showDialog<String>(context:context,builder:(d)=>AlertDialog(
      title:const Text('Add link'),content:TextField(controller:c,keyboardType:TextInputType.url,autofocus:true,decoration:const InputDecoration(hintText:'https://example.com')),
      actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(d,c.text.trim()),child:const Text('Add'))],
    ));
    c.dispose();if(url==null||url.isEmpty)return;
    final normalized=url.startsWith('http://')||url.startsWith('https://')?url:'https://$url';
    setState(()=>_attachments.add({'type':'link',ProfileFields.name:normalized,'url':normalized}));
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
    final postTags=_selectedTags.toSet();
    final instituteIds=_selectedInstituteIds.toList();
    final primaryInstituteId=instituteIds.isNotEmpty?instituteIds.first:widget.instituteId;
    final options=_isPoll?_pollOptions.map((c)=>c.text.trim()).where((x)=>x.isNotEmpty).take(5).toList():<String>[];
    if(_isPoll&&options.length<2){_showError(ArgumentError('Add at least 2 poll options.'));return;}
    setState(()=>_saving=true);
    try{
      final authorId=identity.resolveUid(user?.uid??'');
      final name=identity.effectiveName ?? (user?.displayName?.trim().isNotEmpty==true?user!.displayName!.trim():(user?.email??'Student'));
      if(widget.post==null){
        final postId=await _db.createPost(text:text,authorId:authorId,authorName:name,category:category,isQuestion:_isQuestion,pollOptions:options,instituteId:primaryInstituteId,attachments:_attachments,tags:postTags.toList(),instituteIds:instituteIds);
        if(!demoActive&&user!=null){try{await _db.notifyMentions(text:text,fromId:user.uid,postId:postId);}catch(error){debugPrint('Mention notification failed: $error');}}
      }else{
        await _db.updatePost(postId:widget.post!.id,text:text,category:category,isQuestion:_isQuestion,pollOptions:options,instituteId:widget.post!.instituteId??primaryInstituteId,attachments:_attachments,tags:postTags.toList(),instituteIds:instituteIds);
      }
      if(mounted)context.pop(true);
    }catch(error){_showError(error);}finally{if(mounted)setState(()=>_saving=false);}
  }

  Future<void> _pickTopics() async {
    final temp = Set<String>.from(_selectedTags);
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .78,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Text('Tag Topics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
                  ),
                  Expanded(
                    child: ListView(
                      children: TimelineTopics.all.map((topic) {
                        return CheckboxListTile(
                          value: temp.contains(topic.name),
                          title: Text(topic.emoji + '  ' + topic.name),
                          activeColor: AppColors.primaryGreen,
                          onChanged: (value) {
                            setSheet(() {
                              if (value == true) { temp.add(topic.name); } else { temp.remove(topic.name); }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton(onPressed: () => Navigator.pop(sheet, temp), child: const Text('Done')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (result != null) {
      setState(() { _selectedTags..clear()..addAll(result); });
    }
  }

  Future<void> _pickInstitutes() async {
    await InstituteRepository.instance.load();
    final temp = Set<String>.from(_selectedInstituteIds);

    String typeFilter = 'All';
    String? provinceFilter;
    String? cityFilter;
    String? townFilter;

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, setSheet) {
          final all = InstituteRepository.instance.items;
          final provinces = all.map((i) => i.province.trim()).where((v) => v.isNotEmpty).toSet().toList()..sort();
          final cities = all
              .where((i) => provinceFilter == null || i.province == provinceFilter)
              .map((i) => i.city.trim()).where((v) => v.isNotEmpty).toSet().toList()..sort();
          final towns = all
              .where((i) => (provinceFilter == null || i.province == provinceFilter) &&
                  (cityFilter == null || i.city == cityFilter))
              .map((i) => i.town.trim()).where((v) => v.isNotEmpty).toSet().toList()..sort();

          final list = all.where((institute) {
            final typeOk = typeFilter == 'All' || institute.type.toLowerCase() == typeFilter.toLowerCase();
            final provinceOk = provinceFilter == null || institute.province == provinceFilter;
            final cityOk = cityFilter == null || institute.city == cityFilter;
            final townOk = townFilter == null || institute.town == townFilter;
            return typeOk && provinceOk && cityOk && townOk;
          }).toList();

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .86,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Text('Tag Institutes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'universities', 'colleges', 'schools'].map((type) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(type == 'All' ? 'All' : type[0].toUpperCase() + type.substring(1)),
                            selected: typeFilter == type,
                            selectedColor: AppColors.softGreen,
                            onSelected: (_) => setSheet(() => typeFilter = type),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: provinceFilter,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Province', isDense: true),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('All')),
                              ...provinces.map((v) => DropdownMenuItem<String>(value: v, child: Text(v))),
                            ],
                            onChanged: (value) => setSheet(() {
                              provinceFilter = value;
                              cityFilter = null;
                              townFilter = null;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: cityFilter,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'City', isDense: true),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text('All')),
                              ...cities.map((v) => DropdownMenuItem<String>(value: v, child: Text(v))),
                            ],
                            onChanged: (value) => setSheet(() {
                              cityFilter = value;
                              townFilter = null;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: DropdownButtonFormField<String>(
                      value: townFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Town / Area', isDense: true),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All')),
                        ...towns.map((v) => DropdownMenuItem<String>(value: v, child: Text(v))),
                      ],
                      onChanged: (value) => setSheet(() => townFilter = value),
                    ),
                  ),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(child: Text('No institutes match these filters.'))
                        : ListView(
                            children: list.map((institute) => CheckboxListTile(
                              value: temp.contains(institute.id),
                              title: Text(institute.name),
                              subtitle: Text(institute.type + ' • ' + institute.city + ', ' + institute.province +
                                  (institute.town.trim().isEmpty ? '' : ' • ' + institute.town)),
                              activeColor: AppColors.primaryGreen,
                              onChanged: (value) => setSheet(() {
                                if (value == true) {
                                  temp.add(institute.id);
                                } else {
                                  temp.remove(institute.id);
                                }
                              }),
                            )).toList(),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton(onPressed: () => Navigator.pop(sheet, temp), child: const Text('Done')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (result != null) {
      setState(() {
        _selectedInstituteIds
          ..clear()
          ..addAll(result);
      });
    }
  }

  Widget _tagSelector() {
    final instituteNames = InstituteRepository.instance.items.where((institute) => _selectedInstituteIds.contains(institute.id)).map((institute) => institute.name).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Tags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkGreen))),
            TextButton.icon(onPressed: _saving ? null : _pickTopics, icon: const Icon(Icons.sell_outlined), label: const Text('Topics')),
            TextButton.icon(onPressed: _saving ? null : _pickInstitutes, icon: const Icon(Icons.school_outlined), label: const Text('Institutes')),
          ],
        ),
        if (_selectedTags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedTags.map((tag) {
              return InputChip(
                label: Text(tag),
                onDeleted: _saving ? null : () {
                  setState(() => _selectedTags.remove(tag));
                },
              );
            }).toList(),
          ),
        if (instituteNames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6, runSpacing: 6,
              children: instituteNames.map((name) => InputChip(
                label: Text(name),
                onDeleted: _saving ? null : () {
                  final institute = InstituteRepository.instance.items.firstWhere((item) => item.name == name);
                  setState(() => _selectedInstituteIds.remove(institute.id));
                },
              )).toList(),
            ),
          ),
        if (_selectedTags.isEmpty && _selectedInstituteIds.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('You can post without tags, or add one or more topics/institutes.', style: TextStyle(fontSize: 12, color: AppColors.homeMutedText)),
          ),
      ],
    );
  }
  Widget _attachmentPreview(){
    if(_attachments.isEmpty)return const SizedBox.shrink();
    return Padding(padding:const EdgeInsets.only(bottom:10),child:Wrap(spacing:8,runSpacing:8,children:List.generate(_attachments.length,(i){
      final a=_attachments[i];final type=a['type']??'file';final icon=type=='photo'?Icons.image_outlined:type=='link'?Icons.link:Icons.insert_drive_file_outlined;
      return InputChip(avatar:Icon(icon,size:18,color:AppColors.primaryGreen),label:SizedBox(width:150,child:Text(a[ProfileFields.name]??'Attachment',overflow:TextOverflow.ellipsis)),onDeleted:_saving?null:()=>setState(()=>_attachments.removeAt(i)));
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
      _tagSelector(),
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