import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_service.dart';
import '../../models/institute.dart';

class InstituteRepository extends ChangeNotifier {
  InstituteRepository._();
  static final instance = InstituteRepository._();

  final List<Institute> _items = [
    const Institute(id:'school-1',name:'The Educators',type:'schools',city:'Lahore',province:'Punjab',sector:'Private',address:'Lahore, Punjab',description:'A school offering foundational and secondary education.',programs:['Primary','Middle','Matric']),
    const Institute(id:'school-2',name:'Beaconhouse School System',type:'schools',city:'Lahore',province:'Punjab',sector:'Private',address:'Lahore, Punjab',description:'A private school network providing education from early years through secondary levels.',programs:['Early Years','Primary','Secondary']),
    const Institute(id:'college-1',name:'Government College Lahore',type:'colleges',city:'Lahore',province:'Punjab',sector:'Government',address:'Lahore, Punjab',description:'A historic public college offering intermediate and degree programs.',programs:['FA','FSc','ICS','BS']),
    const Institute(id:'college-2',name:'Government College of Science',type:'colleges',city:'Lahore',province:'Punjab',sector:'Government',address:'Lahore, Punjab',description:'A public institution focused on science and degree education.',programs:['FSc','BS']),
    const Institute(id:'university-1',name:'University of the Punjab',type:'universities',city:'Lahore',province:'Punjab',sector:'Government',address:'Quaid-e-Azam Campus, Lahore',description:'A major public university with a broad range of academic disciplines.',programs:['Undergraduate','Graduate','PhD']),
    const Institute(id:'university-2',name:'Islamia University Bahawalpur',type:'universities',city:'Bahawalpur',province:'Punjab',sector:'Government',address:'Bahawalpur, Punjab',description:'A public-sector university serving students across multiple disciplines.',programs:['Undergraduate','Graduate','PhD']),
  ];

  List<Institute> get items => List.unmodifiable(_items);
  bool loading = false;
  String? error;

  Institute? byId(String id) {
    for (final item in _items) { if (item.id == id) return item; }
    return null;
  }

  Future<void> load() async {
    if (!FirebaseService.initialized) return;
    loading = true; error = null; notifyListeners();
    try {
      final snap = await FirebaseFirestore.instance.collection('institutes').get();
      for (final doc in snap.docs) {
        final item = Institute.fromMap(doc.id, doc.data());
        if (item.status == 'approved' && !_items.any((e) => e.id == item.id)) _items.add(item);
      }
    } catch (e) {
      error = 'Could not load institutes. Showing available local data.';
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<Institute?> add(Institute institute) async {
    error = null;
    try {
      if (FirebaseService.initialized) {
        final ref = await FirebaseFirestore.instance.collection('institutes').add(institute.toMap());
        final saved = Institute.fromMap(ref.id, {...institute.toMap(), 'status':'pending'});
        _items.add(saved);
        notifyListeners();
        return saved;
      }
      final local = Institute.fromMap('local-${DateTime.now().millisecondsSinceEpoch}', {...institute.toMap(), 'status':'pending'});
      _items.add(local);
      notifyListeners();
      return local;
    } catch (e) {
      error = 'Institute could not be saved. Please try again.';
      notifyListeners();
      return null;
    }
  }
}
