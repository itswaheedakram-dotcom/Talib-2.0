import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'active_profile_controller.dart';
import 'firebase_service.dart';
import 'admin_access_service.dart';

class IssueSupportService extends ChangeNotifier {
  IssueSupportService._();
  static final instance = IssueSupportService._();
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;
  final StreamController<void> _demoChanges = StreamController<void>.broadcast();
  final List<Map<String, dynamic>> _demoTickets = [];
  final Map<String, Map<String, dynamic>> _demoFaqOverrides = {};
  int _sequence = 0;
  bool get isDemo => ActiveProfileController.instance.isDemo;

  static const List<Map<String, dynamic>> defaultFaqs = [
    {'id':'account_signin','question':'How do I create or access my Talib account?','answer':'Open Sign up to create an account, or Sign in if you already have one. Use the same email address and password you registered with.','category':'Account','order':1,'isEnabled':true},
    {'id':'find_institutes','question':'How can I find an institute?','answer':'Open Search or Finding Institutes, then narrow results using institute type and location filters.','category':'Institutes','order':2,'isEnabled':true},
    {'id':'hostel_listing','question':'How can I list a hostel?','answer':'Open Hostels and use the listing option. Provide accurate location, room, price, facility and contact details.','category':'Hostels','order':3,'isEnabled':true},
    {'id':'community_posts','question':'How do I publish a Community post?','answer':'Open Community, tap Add/Create Post, enter your content and choose the relevant topics or institute tags before publishing.','category':'Community','order':4,'isEnabled':true},
    {'id':'messages','question':'Why can I not message another user?','answer':'Direct messages follow Talib’s mutual-follow and account-safety rules. Both accounts may need to follow each other.','category':'Messages & Groups','order':5,'isEnabled':true},
    {'id':'privacy','question':'How do I manage privacy or blocked users?','answer':'Open Settings to manage privacy preferences and Blocked Users. Only share personal contact details with people you trust.','category':'Privacy & Safety','order':6,'isEnabled':true},
    {'id':'report_issue','question':'How do I report a problem in Talib?','answer':'Open Report an Issue, select a category and priority, describe the problem, and attach a screenshot if useful. Save the ticket number to track progress.','category':'Reports & Support','order':7,'isEnabled':true},
    {'id':'ticket_tracking','question':'Where can I track my support ticket?','answer':'Open Report an Issue and choose My Reports. Each ticket shows its number, current status, support reply and history.','category':'Reports & Support','order':8,'isEnabled':true},
    {'id':'faq_contact','question':'What if I cannot find my answer here?','answer':'Use Report an Issue and include the screen or feature name and the steps that led to the issue.','category':'Reports & Support','order':9,'isEnabled':true},
  ];

  List<Map<String, dynamic>> _mergeFaqs({List<Map<String, dynamic>> remote = const [], bool includeDisabled = false}) {
    final merged = <String, Map<String, dynamic>>{for (final f in defaultFaqs) f['id'] as String: Map<String,dynamic>.from(f)};
    if (isDemo) for (final e in _demoFaqOverrides.entries) { merged[e.key] = Map<String,dynamic>.from(e.value); }
    for (final f in remote) { final id = f['id']?.toString() ?? ''; if (id.isNotEmpty) merged[id] = Map<String,dynamic>.from(f); }
    return merged.values.where((f) => includeDisabled || f['isEnabled'] != false).toList()..sort((a,b) {
      final c = (a['category'] ?? '').toString().compareTo((b['category'] ?? '').toString());
      return c != 0 ? c : ((a['order'] as num?)?.toInt() ?? 999).compareTo(((b['order'] as num?)?.toInt() ?? 999));
    });
  }

  Stream<List<Map<String,dynamic>>> watchFaqs({bool includeDisabled = false}) {
    if (isDemo || !FirebaseService.initialized) return Stream<List<Map<String,dynamic>>>.multi((c) {
      c.add(_mergeFaqs(includeDisabled: includeDisabled)); final sub = _demoChanges.stream.listen((_) => c.add(_mergeFaqs(includeDisabled: includeDisabled))); c.onCancel = sub.cancel;
    });
    return Stream<List<Map<String,dynamic>>>.multi((c) {
      c.add(_mergeFaqs(includeDisabled: includeDisabled));
      final sub = _db.collection('helpFaqs').snapshots().listen((s) => c.add(_mergeFaqs(remote: s.docs.map((d) => {'id':d.id,...d.data()}).toList(), includeDisabled: includeDisabled)), onError: (_) => c.add(_mergeFaqs(includeDisabled: includeDisabled)));
      final ds = _demoChanges.stream.listen((_) => c.add(_mergeFaqs(includeDisabled: includeDisabled)));
      c.onCancel = () async { await sub.cancel(); await ds.cancel(); };
    });
  }

  Future<void> saveFaq({String? id, required String question, required String answer, required String category, required int order, required bool enabled}) async {
    final q = question.trim(), a = answer.trim(), cat = category.trim();
    if (q.isEmpty || a.isEmpty || cat.isEmpty) throw ArgumentError('Question, answer and category are required.');
    final access = AdminAccessService.instance;
    if (isDemo && !access.isDemoSuperAdmin) throw StateError('Only Demo Super Admin can manage Demo FAQs.');
    if (!isDemo && !(access.isSuperAdmin || access.can('manage_faqs'))) throw StateError('You do not have permission to manage FAQs.');
    if (q.length > 240 || a.length > 4000 || cat.length > 80) throw ArgumentError('Please shorten the FAQ fields and try again.');
    final faqId = id?.trim().isNotEmpty == true ? id!.trim() : 'faq_${DateTime.now().microsecondsSinceEpoch}';
    final data = <String,dynamic>{'id':faqId,'question':q,'answer':a,'category':cat,'order':order,'isEnabled':enabled,'updatedAt':DateTime.now()};
    if (isDemo) { _demoFaqOverrides[faqId] = data; _demoChanges.add(null); notifyListeners(); return; }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please sign in with an authorized admin account.');
    await _db.collection('helpFaqs').doc(faqId).set({...data,'updatedAt':FieldValue.serverTimestamp(),'updatedBy':user.uid}, SetOptions(merge:true));
  }

  Stream<List<Map<String,dynamic>>> watchMyTickets(String uid) {
    if (isDemo) return Stream<List<Map<String,dynamic>>>.multi((c) {
      List<Map<String,dynamic>> items() => _sorted(_demoTickets.where((t) => t['reporterId'] == uid).map((t) => Map<String,dynamic>.from(t)).toList());
      c.add(items()); final s = _demoChanges.stream.listen((_) => c.add(items())); c.onCancel = s.cancel;
    });
    return _db.collection('issueTickets').where('reporterId',isEqualTo:uid).snapshots().map((s) => _sorted(s.docs.map((d) => {'id':d.id,...d.data()}).toList()));
  }

  Stream<List<Map<String,dynamic>>> watchAllTickets() {
    if (isDemo) return Stream<List<Map<String,dynamic>>>.multi((c) {
      List<Map<String,dynamic>> items() => _sorted(_demoTickets.map((t) => Map<String,dynamic>.from(t)).toList());
      c.add(items()); final s = _demoChanges.stream.listen((_) => c.add(items())); c.onCancel = s.cancel;
    });
    return _db.collection('issueTickets').snapshots().map((s) => _sorted(s.docs.map((d) => {'id':d.id,...d.data()}).toList()));
  }

  Stream<Map<String,dynamic>?> watchTicket(String id) {
    if (isDemo) return Stream<Map<String,dynamic>?>.multi((c) {
      void emit() { final found = _demoTickets.where((t) => t['id'] == id); c.add(found.isEmpty ? null : Map<String,dynamic>.from(found.first)); }
      emit(); final s = _demoChanges.stream.listen((_) => emit()); c.onCancel = s.cancel;
    });
    return _db.collection('issueTickets').doc(id).snapshots().map((d) => d.exists ? {'id':d.id,...d.data()!} : null);
  }

  Stream<List<Map<String,dynamic>>> watchHistory(String id) {
    if (isDemo) return Stream<List<Map<String,dynamic>>>.multi((c) {
      void emit() { final found = _demoTickets.where((t) => t['id'] == id); c.add(found.isEmpty ? <Map<String,dynamic>>[] : _sorted(List<Map<String,dynamic>>.from(found.first['history'] as List? ?? const []))); }
      emit(); final s = _demoChanges.stream.listen((_) => emit()); c.onCancel = s.cancel;
    });
    return _db.collection('issueTickets').doc(id).collection('history').snapshots().map((s) => _sorted(s.docs.map((d) => {'id':d.id,...d.data()}).toList()));
  }

  Future<String> createTicket({required String reporterId, required String reporterName, required String category, required String title, required String description, required String priority, XFile? screenshot}) async {
    final t = title.trim(), d = description.trim();
    if (t.isEmpty || d.isEmpty) throw ArgumentError('Enter a title and describe the issue.');
    if (t.length > 120 || d.length > 5000) throw ArgumentError('Title or description is too long.');
    if (!{'Low','Medium','High'}.contains(priority)) throw ArgumentError('Choose a valid priority.');
    if (isDemo) {
      final seq = ++_sequence, id = 'demo-ticket-$_sequence', now = DateTime.now(), number = 'TAL-DEMO-${seq.toString().padLeft(4,'0')}';
      _demoTickets.insert(0, {'id':id,'ticketNumber':number,'reporterId':reporterId,'reporterName':reporterName,'category':category,'title':t,'description':d,'priority':priority,'status':'open','screenshotUrl':screenshot?.path ?? '','latestReply':'','latestReplyBy':'','createdAt':now,'updatedAt':now,'history':[{'id':'event-created-$seq','eventType':'created','message':'Issue submitted','actorUid':reporterId,'actorName':reporterName,'status':'open','createdAt':now}]});
      _demoChanges.add(null); notifyListeners(); return number;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != reporterId) throw StateError('Please sign in again before submitting a report.');
    final ref = _db.collection('issueTickets').doc();
    var url = '';
    if (screenshot != null) {
      final bytes = await screenshot.readAsBytes();
      final upload = _storage.ref('issueAttachments/$reporterId/${ref.id}/screenshot.jpg');
      await upload.putData(bytes, SettableMetadata(contentType:'image/jpeg'));
      url = await upload.getDownloadURL();
    }
    final number = 'TAL-${DateTime.now().toUtc().year}-${ref.id.substring(0,7).toUpperCase()}';
    final batch = _db.batch();
    batch.set(ref, {'ticketNumber':number,'reporterId':reporterId,'reporterName':reporterName,'category':category,'title':t,'description':d,'priority':priority,'status':'open','screenshotUrl':url,'latestReply':'','latestReplyBy':'','createdAt':FieldValue.serverTimestamp(),'updatedAt':FieldValue.serverTimestamp(),'lastActorUid':reporterId});
    batch.set(ref.collection('history').doc(), {'eventType':'created','message':'Issue submitted','actorUid':reporterId,'actorName':reporterName,'status':'open','createdAt':FieldValue.serverTimestamp()});
    await batch.commit(); return number;
  }

  Future<void> updateTicket({required String ticketId, required String actorUid, required String actorName, String? status, String? reply}) async {
    if (status != null && !{'open','in_progress','resolved','closed'}.contains(status)) throw ArgumentError('Invalid ticket status.');
    final r = (reply ?? '').trim(); if (r.length > 2000) throw ArgumentError('Reply must be 2000 characters or fewer.');
    if (isDemo) {
      final access = AdminAccessService.instance;
      if (!(access.isDemoSuperAdmin || access.isSuperAdmin || access.can('manage_reports'))) throw StateError('You do not have permission to manage issue reports.');
      final i = _demoTickets.indexWhere((t) => t['id'] == ticketId); if (i < 0) throw StateError('Ticket not found.');
      final ticket = _demoTickets[i], old = (ticket['status'] ?? 'open').toString(), next = status ?? old, now = DateTime.now();
      ticket['status'] = next; ticket['updatedAt'] = now; if (r.isNotEmpty) {ticket['latestReply'] = r; ticket['latestReplyBy'] = actorName;}
      final history = List<Map<String,dynamic>>.from(ticket['history'] as List? ?? const []);
      if (status != null && status != old) history.add({'id':'event-${++_sequence}','eventType':'status_changed','message':'Status changed from $old to $next','oldStatus':old,'status':next,'actorUid':actorUid,'actorName':actorName,'createdAt':now});
      if (r.isNotEmpty) history.add({'id':'event-${++_sequence}','eventType':'reply','message':r,'actorUid':actorUid,'actorName':actorName,'status':next,'createdAt':now});
      ticket['history'] = history; _demoChanges.add(null); notifyListeners(); return;
    }
    final user = FirebaseAuth.instance.currentUser; if (user == null || user.uid != actorUid) throw StateError('Please sign in again.');
    final ref = _db.collection('issueTickets').doc(ticketId), snap = await ref.get();
    if (!snap.exists) throw StateError('Ticket not found.');
    final old = (snap.data()?['status'] ?? 'open').toString(), next = status ?? old, batch = _db.batch();
    final update = <String,dynamic>{'status':next,'updatedAt':FieldValue.serverTimestamp(),'lastActorUid':actorUid};
    if (r.isNotEmpty) {update['latestReply'] = r; update['latestReplyBy'] = actorName;}
    batch.update(ref, update);
    if (status != null && status != old) batch.set(ref.collection('history').doc(), {'eventType':'status_changed','message':'Status changed from $old to $next','oldStatus':old,'status':next,'actorUid':actorUid,'actorName':actorName,'createdAt':FieldValue.serverTimestamp()});
    if (r.isNotEmpty) batch.set(ref.collection('history').doc(), {'eventType':'reply','message':r,'actorUid':actorUid,'actorName':actorName,'status':next,'createdAt':FieldValue.serverTimestamp()});
    await batch.commit();
  }

  List<Map<String,dynamic>> _sorted(List<Map<String,dynamic>> items) {
    DateTime dateOf(Map<String,dynamic> item) { final v = item['createdAt'] ?? item['updatedAt']; if (v is DateTime) return v; if (v is Timestamp) return v.toDate(); return DateTime.fromMillisecondsSinceEpoch(0); }
    items.sort((a,b) => dateOf(b).compareTo(dateOf(a))); return items;
  }
}
