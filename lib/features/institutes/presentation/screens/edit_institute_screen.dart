import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/institute_repository.dart';
import '../../../models/institute.dart';
import '../../../../app/theme.dart';
import '../../data/institute_catalog.dart';

class EditInstituteScreen extends StatefulWidget {
  final String id;
  const EditInstituteScreen({super.key, required this.id});
  @override State<EditInstituteScreen> createState() => _EditInstituteScreenState();
}

class _EditInstituteScreenState extends State<EditInstituteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name=TextEditingController(), _campus=TextEditingController(), _subcategory=TextEditingController(), _province=TextEditingController(),
      _city=TextEditingController(), _town=TextEditingController(), _address=TextEditingController(), _description=TextEditingController(),
      _website=TextEditingController(), _applicationUrl=TextEditingController(), _eligibility=TextEditingController(), _minScore=TextEditingController(),
      _nextProgram=TextEditingController(), _deadline=TextEditingController(), _fee=TextEditingController(),
      _contact=TextEditingController(), _programs=TextEditingController(), _facilities=TextEditingController(),
      _imageUrl=TextEditingController();
  String _sector='Private', _submission='Online', _admissionStatus='Open';
  bool _entryTest=false, _saving=false;

  @override void initState() {
    super.initState();
    final i=InstituteRepository.instance.byId(widget.id);
    if(i==null) return;
    _name.text=i.name; _campus.text=i.campus; _subcategory.text=i.subcategory; _province.text=i.province; _city.text=i.city; _town.text=i.town;
    _address.text=i.address; _description.text=i.description; _website.text=i.website; _applicationUrl.text=i.applicationUrl;
    _eligibility.text=i.eligibility; _minScore.text=i.minScore == 0 ? '' : i.minScore.toString();
    _nextProgram.text=i.nextProgram; _deadline.text=i.admissionDeadline; _fee.text=i.feeRange;
    _contact.text=i.contact; _programs.text=i.programs.join(', '); _facilities.text=i.facilities.join(', ');
    _imageUrl.text=i.imageUrl; _sector=i.sector; _submission=i.submissionMode;
    _admissionStatus=i.admissionStatus; _entryTest=i.entryTestRequired;
  }

  @override void dispose() {
    for(final c in [_name,_campus,_subcategory,_province,_city,_town,_address,_description,_website,_applicationUrl,_eligibility,_minScore,
      _nextProgram,_deadline,_fee,_contact,_programs,_facilities,_imageUrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if(!_formKey.currentState!.validate()) return;
    final old=InstituteRepository.instance.byId(widget.id);
    if(old==null) return;
    setState(()=>_saving=true);
    final updated=Institute(
      id: old.id, name:_name.text.trim(), type:old.type, subcategory:_subcategory.text.trim(), ownerId:old.ownerId, representativeId:old.representativeId, createdBy:old.createdBy, campus:_campus.text.trim(),
      province:_province.text.trim(), city:_city.text.trim(), town:_town.text.trim(), sector:_sector,
      address:_address.text.trim(), description:_description.text.trim(), website:_website.text.trim(), applicationUrl:_applicationUrl.text.trim(),
      submissionMode:_submission, eligibility:_eligibility.text.trim(),
      programs:_split(_programs.text), contact:_contact.text.trim(), status:old.status,
      minScore:double.tryParse(_minScore.text.trim())??0, nextProgram:_nextProgram.text.trim(),
      admissionStatus:_admissionStatus, admissionDeadline:_deadline.text.trim(), feeRange:_fee.text.trim(),
      entryTestRequired:_entryTest, imageUrl:_imageUrl.text.trim(), facilities:_split(_facilities.text),
    );
    final ok=await InstituteRepository.instance.update(updated);
    if(!mounted) return;
    setState(()=>_saving=false);
    if(ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Institute updated successfully.')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Institute could not be updated.')));
    }
  }

  List<String> _split(String value)=>value.split(',').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toSet().toList();

  @override Widget build(BuildContext context) {
    const green=AppColors.primaryGreen, dark=AppColors.darkGreen;
    final i=InstituteRepository.instance.byId(widget.id);
    if(i==null) return const Scaffold(body:Center(child:Text('Institute not found')));
    return Scaffold(
      appBar:AppBar(leading:IconButton(icon:const Icon(Icons.arrow_back_ios_new,size:18),onPressed:()=>context.pop()),title:const Text('Edit Institute')),
      body:Form(key:_formKey,child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,30),children:[
        Text('Basic Information',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:dark)),
        const SizedBox(height:12),
        _field(_name,'Institute Name',Icons.account_balance_outlined,required:true),
        _field(_campus,'Campus',Icons.location_city_outlined),
        _field(_subcategory,'Subcategory',Icons.category_outlined),
        Row(children:[Expanded(child:_field(_province,'Province',Icons.map_outlined,required:true)),const SizedBox(width:10),Expanded(child:_field(_city,'City',Icons.location_on_outlined,required:true))]),
        _field(_town,'Town / Area',Icons.place_outlined),
        _field(_address,'Full Address',Icons.place_outlined),
        _dropdown('Sector',_sector,InstituteCatalog.sectors,(v)=>setState(()=>_sector=v)),
        _field(_contact,'Contact',Icons.phone_outlined),
        _field(_website,'Website',Icons.language_outlined,keyboard:TextInputType.url),
        _field(_applicationUrl,'Direct Admission / Application URL',Icons.open_in_new_outlined,keyboard:TextInputType.url),
        _field(_imageUrl,'Image URL',Icons.image_outlined,keyboard:TextInputType.url),
        _field(_description,'Description',Icons.description_outlined,maxLines:4),
        const SizedBox(height:8),
        Text('Academic Information',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:dark)),
        const SizedBox(height:12),
        _field(_programs,'Programs (comma separated)',Icons.menu_book_outlined,maxLines:2),
        _field(_nextProgram,'Next Education Program',Icons.school_outlined),
        _field(_eligibility,'Eligibility Criteria',Icons.rule_outlined,maxLines:4),
        _field(_minScore,'Minimum Percentage / CGPA',Icons.percent,keyboard:const TextInputType.numberWithOptions(decimal:true)),
        const SizedBox(height:8),
        Text('Admissions',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:dark)),
        const SizedBox(height:12),
        _dropdown('Admission Status',_admissionStatus,InstituteCatalog.admissionStatuses,(v)=>setState(()=>_admissionStatus=v)),
        _field(_deadline,'Admission Deadline',Icons.calendar_month_outlined),
        _field(_fee,'Fee Range',Icons.payments_outlined),
        _dropdown('Submission Mode',_submission,InstituteCatalog.submissionModes,(v)=>setState(()=>_submission=v)),
        SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Entry Test Required'),value:_entryTest,onChanged:(v)=>setState(()=>_entryTest=v)),
        const SizedBox(height:8),
        Text('Facilities & Display',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:dark)),
        const SizedBox(height:12),
        _field(_facilities,'Facilities (comma separated)',Icons.business_outlined,maxLines:3),
        const SizedBox(height:18),
        SizedBox(height:50,child:FilledButton(onPressed:_saving?null:_save,style:FilledButton.styleFrom(backgroundColor:green),child:_saving?const SizedBox(height:22,width:22,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Text('Save Changes'))),
      ])),
    );
  }

  Widget _field(TextEditingController c,String label,IconData icon,{bool required=false,int maxLines=1,TextInputType? keyboard}) =>
      Padding(padding:const EdgeInsets.only(bottom:12),child:TextFormField(controller:c,maxLines:maxLines,keyboardType:keyboard,validator:required?(v)=>v==null||v.trim().isEmpty?'Required':null:null,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon),border:const OutlineInputBorder())));
  Widget _dropdown(String label,String value,List<String> items,void Function(String) onChanged)=>Padding(padding:const EdgeInsets.only(bottom:12),child:DropdownButtonFormField<String>(initialValue:items.contains(value)?value:items.first,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder()),items:items.map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v){if(v!=null)onChanged(v);}));
}
