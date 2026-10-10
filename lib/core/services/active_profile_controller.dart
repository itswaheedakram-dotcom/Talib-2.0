import 'package:flutter/foundation.dart';

class ActiveDemoProfile {
  final String id;
  final String name;
  final String username;
  final String city;
  final String level;
  final String institute;
  final String program;
  const ActiveDemoProfile({required this.id,required this.name,this.username='',required this.city,required this.level,required this.institute,required this.program});
}

class ActiveProfileController extends ChangeNotifier {
  ActiveProfileController._();
  static final instance=ActiveProfileController._();
  ActiveDemoProfile? _active;
  ActiveDemoProfile? get active=>_active;
  bool get isDemoActive=>_active!=null;
  bool get isDemo=>_active!=null;
  String? get effectiveUid => _active?.id;
  String? get effectiveName => _active?.name;
  String? get effectiveCity => _active?.city;
  String? get effectiveLevel => _active?.level;
  String? get effectiveInstitute => _active?.institute;
  String? get effectiveProgram => _active?.program;
  String resolveUid(String realUid) => _active?.id ?? realUid;
  String resolveName(String realName) => _active?.name ?? realName;
  void activate(ActiveDemoProfile profile){_active=profile;notifyListeners();}
  void clear(){if(_active==null)return;_active=null;notifyListeners();}
}

const temporaryProfiles=<ActiveDemoProfile>[
  ActiveDemoProfile(id:'demo-user-1',name:'Ayesha Khan',city:'Lahore, Punjab',level:'BS Computer Science',institute:'University of the Punjab',program:'Computer Science'),
  ActiveDemoProfile(id:'demo-user-2',name:'Ali Raza',city:'Multan, Punjab',level:'BS Software Engineering',institute:'BZU Multan',program:'Software Engineering'),
  ActiveDemoProfile(id:'demo-user-3',name:'Hira Ahmed',city:'Islamabad',level:'MS Education',institute:'NUST Islamabad',program:'Education'),
  ActiveDemoProfile(id:'demo-user-4',name:'Usman Malik',city:'Faisalabad, Punjab',level:'BS Agriculture',institute:'University of Agriculture Faisalabad',program:'Agriculture'),
  ActiveDemoProfile(id:'demo-user-5',name:'Ahtasham Malik',city:'Lahore, Punjab',level:'BS Business Administration',institute:'University of the Punjab',program:'Business Administration'),
  ActiveDemoProfile(id:'demo-user-6',name:'Waheed Akram',username:'waheed',city:'Pakistan',level:'Community Member',institute:'',program:''),
];
