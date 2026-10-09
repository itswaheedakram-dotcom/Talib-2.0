import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/active_profile_controller.dart';
import '../../models/institute.dart';

class InstituteRepository extends ChangeNotifier {
  InstituteRepository._() : _demoItems = List<Institute>.of(_seedItems);
  static final instance = InstituteRepository._();

  static const List<Institute> _seedItems = [
    const Institute(id:'school-1',name:'The Educators',type:'schools',city:'Lahore',province:'Punjab',sector:'Private',address:'Lahore, Punjab',description:'A school offering foundational and secondary education.',programs:['Primary','Middle','Matric']),
    const Institute(id:'school-2',name:'Beaconhouse School System',type:'schools',city:'Lahore',province:'Punjab',sector:'Private',address:'Lahore, Punjab',description:'A private school network providing education from early years through secondary levels.',programs:['Early Years','Primary','Secondary']),
    const Institute(id:'college-1',name:'Government College Lahore',type:'colleges',city:'Lahore',province:'Punjab',sector:'Government',address:'Lahore, Punjab',description:'A historic public college offering intermediate and degree programs.',programs:['FA','FSc','ICS','BS']),
    const Institute(id:'college-2',name:'Government College of Science',type:'colleges',city:'Lahore',province:'Punjab',sector:'Government',address:'Lahore, Punjab',description:'A public institution focused on science and degree education.',programs:['FSc','BS']),
    const Institute(id:'university-1',name:'University of the Punjab',type:'universities',city:'Lahore',province:'Punjab',sector:'Government',address:'Quaid-e-Azam Campus, Lahore',description:'A major public university with a broad range of academic disciplines.',programs:['Undergraduate','Graduate','PhD']),
    const Institute(id:'university-2',name:'Islamia University Bahawalpur',type:'universities',city:'Bahawalpur',province:'Punjab',sector:'Government',address:'Bahawalpur, Punjab',description:'A public-sector university serving students across multiple disciplines.',programs:['Undergraduate','Graduate','PhD']),
    const Institute(id:'university-3',name:'University of Engineering and Technology, Lahore',type:'universities',city:'Lahore',province:'Punjab',sector:'Government',address:'Lahore, Punjab',description:'Public engineering university.',programs:['Engineering','Computer Science','Architecture']),
    const Institute(id:'university-4',name:'Government College University Lahore',type:'universities',city:'Lahore',province:'Punjab',sector:'Government',address:'Lahore, Punjab',description:'Public university in Lahore.',programs:['Undergraduate','Graduate','PhD']),
    const Institute(id:'university-5',name:'Lahore College for Women University',type:'universities',city:'Lahore',province:'Punjab',sector:'Government',address:'Lahore, Punjab',description:'Public women university.',programs:['Undergraduate','Graduate','PhD']),
    const Institute(id:'university-6',name:'University of Education Lahore',type:'universities',city:'Lahore',province:'Punjab',sector:'Government',address:'Lahore, Punjab',description:'Public university focused on education and related disciplines.',programs:['Undergraduate','Graduate','PhD']),
    const Institute(id:'university-7',name:'University of Veterinary and Animal Sciences',type:'universities',city:'Lahore',province:'Punjab',sector:'Government',address:'Lahore, Punjab',description:'Public veterinary and animal sciences university.',programs:['Veterinary Sciences','Animal Sciences','Life Sciences']),
    const Institute(id:'university-8',name:'University of Central Punjab',type:'universities',city:'Lahore',province:'Punjab',sector:'Private',address:'Lahore, Punjab',description:'Private university in Lahore.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-9',name:'Lahore University of Management Sciences',type:'universities',city:'Lahore',province:'Punjab',sector:'Private',address:'Lahore, Punjab',description:'Private university in Lahore.',programs:['Business','Computer Science','Engineering','Social Sciences']),
    const Institute(id:'university-10',name:'University of Management and Technology',type:'universities',city:'Lahore',province:'Punjab',sector:'Private',address:'Lahore, Punjab',description:'Private university in Lahore.',programs:['Business','Computing','Engineering','Social Sciences']),
    const Institute(id:'university-11',name:'Forman Christian College',type:'universities',city:'Lahore',province:'Punjab',sector:'Private',address:'Lahore, Punjab',description:'Chartered university in Lahore.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-12',name:'Beaconhouse National University',type:'universities',city:'Lahore',province:'Punjab',sector:'Private',address:'Lahore, Punjab',description:'Private university focused on art, design, architecture and social sciences.',programs:['Art','Design','Architecture','Social Sciences']),
    const Institute(id:'university-13',name:'National College of Arts',type:'universities',city:'Lahore',province:'Punjab',sector:'Government',address:'Lahore, Punjab',description:'Public arts and design institution.',programs:['Fine Arts','Design','Architecture']),
    const Institute(id:'university-14',name:'University of Agriculture Faisalabad',type:'universities',city:'Faisalabad',province:'Punjab',sector:'Government',address:'Faisalabad, Punjab',description:'Public agriculture university.',programs:['Agriculture','Veterinary Sciences','Food Sciences','Engineering']),
    const Institute(id:'university-15',name:'National Textile University',type:'universities',city:'Faisalabad',province:'Punjab',sector:'Government',address:'Faisalabad, Punjab',description:'Public university specializing in textile and related disciplines.',programs:['Textile Engineering','Engineering','Business','Computing']),
    const Institute(id:'university-16',name:'Government College University Faisalabad',type:'universities',city:'Faisalabad',province:'Punjab',sector:'Government',address:'Faisalabad, Punjab',description:'Public university in Faisalabad.',programs:['Undergraduate','Graduate','PhD']),
    const Institute(id:'university-17',name:'Government College Women University Faisalabad',type:'universities',city:'Faisalabad',province:'Punjab',sector:'Government',address:'Faisalabad, Punjab',description:'Public women university.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-18',name:'Bahauddin Zakariya University',type:'universities',city:'Multan',province:'Punjab',sector:'Government',address:'Multan, Punjab',description:'Public university in Multan.',programs:['Undergraduate','Graduate','PhD']),
    const Institute(id:'university-19',name:'Muhammad Nawaz Sharif University of Engineering and Technology',type:'universities',city:'Multan',province:'Punjab',sector:'Government',address:'Multan, Punjab',description:'Public engineering university.',programs:['Engineering','Computing','Technology']),
    const Institute(id:'university-20',name:'Muhammad Nawaz Shareef University of Agriculture',type:'universities',city:'Multan',province:'Punjab',sector:'Government',address:'Multan, Punjab',description:'Public agriculture university.',programs:['Agriculture','Food Sciences','Life Sciences']),
    const Institute(id:'university-21',name:'Emerson University Multan',type:'universities',city:'Multan',province:'Punjab',sector:'Government',address:'Multan, Punjab',description:'Public university in Multan.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-22',name:'University of Sargodha',type:'universities',city:'Sargodha',province:'Punjab',sector:'Government',address:'Sargodha, Punjab',description:'Public university in Sargodha.',programs:['Undergraduate','Graduate','PhD']),
    const Institute(id:'university-23',name:'University of Gujrat',type:'universities',city:'Gujrat',province:'Punjab',sector:'Government',address:'Gujrat, Punjab',description:'Public university in Gujrat.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-24',name:'University of Sialkot',type:'universities',city:'Sialkot',province:'Punjab',sector:'Private',address:'Sialkot, Punjab',description:'University in Sialkot.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-25',name:'Government College Women University Sialkot',type:'universities',city:'Sialkot',province:'Punjab',sector:'Government',address:'Sialkot, Punjab',description:'Public women university.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-26',name:'University of Narowal',type:'universities',city:'Narowal',province:'Punjab',sector:'Government',address:'Narowal, Punjab',description:'Public university in Narowal.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-27',name:'University of Engineering and Technology, Taxila',type:'universities',city:'Taxila',province:'Punjab',sector:'Government',address:'Taxila, Punjab',description:'Public engineering university.',programs:['Engineering','Computing','Technology']),
    const Institute(id:'university-28',name:'Fatima Jinnah Women University',type:'universities',city:'Rawalpindi',province:'Punjab',sector:'Government',address:'Rawalpindi, Punjab',description:'Public women university.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-29',name:'Rawalpindi Medical University',type:'universities',city:'Rawalpindi',province:'Punjab',sector:'Government',address:'Rawalpindi, Punjab',description:'Public medical university.',programs:['Medicine','Nursing','Allied Health Sciences']),
    const Institute(id:'university-30',name:'Rawalpindi Women University',type:'universities',city:'Rawalpindi',province:'Punjab',sector:'Government',address:'Rawalpindi, Punjab',description:'Public women university.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-31',name:'Pir Mehr Ali Shah Arid Agriculture University',type:'universities',city:'Rawalpindi',province:'Punjab',sector:'Government',address:'Rawalpindi, Punjab',description:'Public agriculture university.',programs:['Agriculture','Veterinary Sciences','Computing']),
    const Institute(id:'university-32',name:'Ghazi University',type:'universities',city:'Dera Ghazi Khan',province:'Punjab',sector:'Government',address:'Dera Ghazi Khan, Punjab',description:'Public university in Dera Ghazi Khan.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-33',name:'Khawaja Fareed University of Engineering and Information Technology',type:'universities',city:'Rahim Yar Khan',province:'Punjab',sector:'Government',address:'Rahim Yar Khan, Punjab',description:'Public engineering and technology university.',programs:['Engineering','Computing','Technology']),
    const Institute(id:'university-34',name:'Cholistan University of Veterinary and Animal Sciences',type:'universities',city:'Bahawalpur',province:'Punjab',sector:'Government',address:'Bahawalpur, Punjab',description:'Public veterinary and animal sciences university.',programs:['Veterinary Sciences','Animal Sciences']),
    const Institute(id:'university-35',name:'Government Sadiq College Women University',type:'universities',city:'Bahawalpur',province:'Punjab',sector:'Government',address:'Bahawalpur, Punjab',description:'Public women university.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-36',name:'University of Layyah',type:'universities',city:'Layyah',province:'Punjab',sector:'Government',address:'Layyah, Punjab',description:'Public university in Layyah.',programs:['Undergraduate','Graduate']),
    const Institute(id:'university-37',name:'University of Education, DG Khan Campus',type:'universities',city:'Dera Ghazi Khan',province:'Punjab',sector:'Government',address:'Dera Ghazi Khan, Punjab',description:'Public university campus.',programs:['Education','Undergraduate','Graduate']),
  ];

  final List<Institute> _demoItems;
  final List<Institute> _realItems = [];
  bool loading = false;
  String? error;

  /// Demo and production records are kept in separate collections in memory.
  /// Only approved institutes are exposed to public browsing screens.
  bool get isDemoMode =>
      ActiveProfileController.instance.isDemo || !FirebaseService.initialized;

  List<Institute> get items {
    final records = <String, Institute>{
      if (!isDemoMode)
        for (final item in _seedItems)
          if (item.status.toLowerCase() == 'approved') item.id: item,
      for (final item in (isDemoMode ? _demoItems : _realItems))
        if (item.status.toLowerCase() == 'approved') item.id: item,
    };
    return List.unmodifiable(records.values);
  }

  /// All records for the selected mode, including pending submissions.
  List<Institute> get moderationItems =>
      List.unmodifiable(isDemoMode ? _demoItems : _realItems);

  Institute? byId(String id) {
    final source = isDemoMode ? _demoItems : _realItems;
    for (final item in source) {
      if (item.id == id) return item;
    }
    if (!isDemoMode) {
      for (final item in _seedItems) {
        if (item.id == id) return item;
      }
    }
    return null;
  }

  Future<void> load() async {
    if (isDemoMode) {
      loading = false;
      error = null;
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('institutes')
          .where('status', isEqualTo: 'approved')
          .get();
      final loaded = snapshot.docs
          .map((doc) => Institute.fromMap(doc.id, doc.data()))
          .where((item) => item.status.toLowerCase() == 'approved')
          .toList();
      _realItems
        ..clear()
        ..addAll(loaded);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> update(Institute institute) async {
    error = null;
    try {
      if (isDemoMode) {
        final index = _demoItems.indexWhere((item) => item.id == institute.id);
        if (index < 0) {
          error = 'Institute was not found in demo data.';
          return false;
        }
        _demoItems[index] = institute;
        notifyListeners();
        return true;
      }

      // Moderation status is deliberately not editable through the normal form.
      final data = institute.toMap()..remove('status');
      await FirebaseFirestore.instance
          .collection('institutes')
          .doc(institute.id)
          .update(data);
      final index = _realItems.indexWhere((item) => item.id == institute.id);
      if (index >= 0) _realItems[index] = institute;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Institute?> add(Institute institute) async {
    error = null;
    try {
      final pending = Institute.fromMap(
        institute.id.isEmpty
            ? 'demo-institute-${DateTime.now().millisecondsSinceEpoch}'
            : institute.id,
        {...institute.toMap(), 'status': 'pending'},
      );
      if (isDemoMode) {
        _demoItems.add(pending);
        notifyListeners();
        return pending;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        error = 'Sign in is required to submit a real institute listing.';
        notifyListeners();
        return null;
      }
      final ref = await FirebaseFirestore.instance
          .collection('institutes')
          .add({...institute.toMap(), 'createdBy': user.uid, 'status': 'pending'});
      final saved = Institute.fromMap(
        ref.id,
        {...institute.toMap(), 'createdBy': user.uid, 'status': 'pending'},
      );
      // Pending submissions are intentionally excluded from public browse lists.
      _realItems.add(saved);
      notifyListeners();
      return saved;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> setSubmissionStatus(String instituteId, String status) async {
    if (!const {'approved', 'pending', 'rejected'}.contains(status)) {
      error = 'Unsupported institute status.';
      return false;
    }
    try {
      if (isDemoMode) {
        final index = _demoItems.indexWhere((item) => item.id == instituteId);
        if (index < 0) return false;
        final current = _demoItems[index];
        _demoItems[index] = Institute.fromMap(
          current.id,
          {...current.toMap(), 'status': status},
        );
      } else {
        await FirebaseFirestore.instance
            .collection('institutes')
            .doc(instituteId)
            .update({'status': status});
        _realItems.removeWhere((item) => item.id == instituteId);
        if (status == 'approved') {
          final doc = await FirebaseFirestore.instance
              .collection('institutes')
              .doc(instituteId)
              .get();
          if (doc.exists) _realItems.add(Institute.fromMap(doc.id, doc.data()!));
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
