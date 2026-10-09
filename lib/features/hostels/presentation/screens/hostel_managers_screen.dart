import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../models/hostel.dart';

class HostelManagersScreen extends StatefulWidget {
  final Hostel hostel;
  const HostelManagersScreen({super.key, required this.hostel});
  @override
  State<HostelManagersScreen> createState() => _HostelManagersScreenState();
}

class _HostelManagersScreenState extends State<HostelManagersScreen> {
  static final Map<String, List<Map<String, dynamic>>> _demoManagers = {};
  static const _permissions = <String, String>{
    'basicInfo': 'Hostel ki information edit kar sakta hai',
    'location': 'Location aur address change kar sakta hai',
    'rooms': 'Rooms aur prices change kar sakta hai',
    'availability': 'Bed availability update kar sakta hai',
    'photos': 'Photos add/remove kar sakta hai',
    'facilities': 'Facilities update kar sakta hai',
    'rules': 'Hostel rules update kar sakta hai',
    'contact': 'Contact details change kar sakta hai',
    'meals': 'Meal details update kar sakta hai',
  };
  bool _loading = true;
  bool _failed = false;
  List<Map<String, dynamic>> _managers = [];
  final _search = TextEditingController();

  String get _hostelId => widget.hostel.id;
  bool get _demo => widget.hostel.isDemo || _hostelId.startsWith('example_');

  @override
  void initState() { super.initState(); _loadManagers(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _loadManagers() async {
    if (mounted) setState(() { _loading = true; _failed = false; });
    try {
      if (_demo) {
        _managers = List<Map<String, dynamic>>.from(_demoManagers[_hostelId] ?? [
          {'uid':'demo-ahmed','name':'Ahmed Khan','phone':'0300 1234567','active':true,'permissions':<String, bool>{'basicInfo':true,'location':true,'rooms':true,'availability':true,'photos':true,'facilities':true}},
        ]);
      } else {
        final snap = await FirebaseFirestore.instance.collection('hostels').doc(_hostelId).collection('managers').get();
        _managers = snap.docs.map((d) => <String, dynamic>{'uid':d.id, ...d.data()}).toList();
      }
    } catch (_) {
      _failed = true;
      _managers = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addManager() async {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add a manager'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: idController, decoration: const InputDecoration(labelText: 'User ID / UID', hintText: 'Enter their account UID')),
        const SizedBox(height: 10),
        TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name (for display)', hintText: 'e.g. Ahmed Khan')),
        const SizedBox(height: 8),
        const Text('Use the exact account UID so access is linked to the correct person.', style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, idController.text.trim().isNotEmpty && nameController.text.trim().isNotEmpty), child: const Text('Add'))],
    ));
    final uid = idController.text.trim(), name = nameController.text.trim();
    idController.dispose(); nameController.dispose();
    if (accepted != true || uid.isEmpty || name.isEmpty) return;
    final manager = <String, dynamic>{'uid':uid,'name':name,'phone':'','active':true,'permissions':<String, bool>{for (final key in _permissions.keys) key:false}};
    try {
      if (_demo) {
        _demoManagers[_hostelId] = [..._managers, manager];
      } else {
        await FirebaseFirestore.instance.collection('hostels').doc(_hostelId).collection('managers').doc(uid).set({
          'name':name,'active':true,'permissions':manager['permissions'],'createdBy':FirebaseAuth.instance.currentUser?.uid,
          'createdAt':FieldValue.serverTimestamp(),
        });
      }
      await _loadManagers();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manager could not be added. Check your connection and try again.')));
    }
  }

  Future<void> _savePermissions(Map<String, dynamic> manager) async {
    final uid = manager['uid'].toString();
    try {
      if (_demo) {
        _demoManagers[_hostelId] = _managers.map((m) => m['uid'] == uid ? manager : m).toList();
      } else {
        await FirebaseFirestore.instance.collection('hostels').doc(_hostelId).collection('managers').doc(uid).update({'permissions':manager['permissions']});
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions saved.')));
      await _loadManagers();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions could not be saved. Please try again.')));
    }
  }

  Future<void> _remove(Map<String, dynamic> manager) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Remove manager?'), content: Text('Remove ${manager['name']} from this hostel?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove'))],
    ));
    if (yes != true) return;
    try {
      if (_demo) {
        _demoManagers[_hostelId] = _managers.where((m) => m['uid'] != manager['uid']).toList();
      } else {
        await FirebaseFirestore.instance.collection('hostels').doc(_hostelId).collection('managers').doc(manager['uid'].toString()).delete();
      }
      await _loadManagers();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manager could not be removed. Please try again.')));
    }
  }

  Future<void> _editPermissions(Map<String, dynamic> manager) async {
    final current = Map<String, bool>.from((manager['permissions'] as Map?)?.map((k,v) => MapEntry(k.toString(), v == true)) ?? {});
    final draft = Map<String, bool>.from(current);
    final result = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, showDragHandle: true, backgroundColor: AppColors.cream, builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) => SafeArea(
      child: Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Align(alignment: Alignment.centerLeft, child: Text('Manager permissions', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.darkGreen))),
        Row(children: [TextButton(onPressed: () => setSheetState(() { for (final k in _permissions.keys) { draft[k] = true; } }), child: const Text('Select All')), TextButton(onPressed: () => setSheetState(() { for (final k in _permissions.keys) { draft[k] = false; } }), child: const Text('Clear All'))]),
        Flexible(child: ListView(shrinkWrap: true, children: _permissions.entries.map((entry) => CheckboxListTile(
          contentPadding: EdgeInsets.zero, activeColor: AppColors.primaryGreen, value: draft[entry.key] == true, title: Text(entry.value, style: const TextStyle(fontSize: 13)), onChanged: (v) => setSheetState(() => draft[entry.key] = v == true),
        )).toList())),
        const SizedBox(height: 8), SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save permissions'))),
      ])),
    )));
    if (result == true) {
      manager['permissions'] = draft;
      await _savePermissions(manager);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: const Text('Managers')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _addManager, icon: const Icon(Icons.person_add_alt_1), label: const Text('Add Manager')),
    body: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)) : RefreshIndicator(
      onRefresh: _loadManagers,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 90), children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.hostel.name, style: const TextStyle(color: AppColors.darkGreen, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Yahan se aap decide karte hain ke manager hostel mein kya kya manage kar sakta hai.', style: TextStyle(color: AppColors.mutedText, height: 1.35)),
          if (_demo) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Demo mode: changes are kept for this app session.', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12))),
        ])),
        const SizedBox(height: 14),
        if (_failed) Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)), child: Column(children: [
          const Icon(Icons.cloud_off_outlined, size: 34, color: AppColors.primaryGreen),
          const SizedBox(height: 8), const Text('Managers could not be loaded.', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700)),
          const Text('Check your connection and try again.', style: TextStyle(color: AppColors.mutedText)),
          TextButton(onPressed: _loadManagers, child: const Text('Try again')),
        ])),
        const SizedBox(height: 12),
        TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name, UID or phone')),
        const SizedBox(height: 12),
        if (!_failed && _managers.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Column(children: [Icon(Icons.people_outline, size: 42, color: AppColors.primaryGreen), SizedBox(height: 8), Text('No managers added yet', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700)), Text('Tap Add Manager to give someone access.', style: TextStyle(color: AppColors.mutedText))])),
        ..._managers.where((m) => _search.text.isEmpty || '${m['name']} ${m['uid']} ${m['phone']}'.toLowerCase().contains(_search.text.toLowerCase())).map(_managerCard),
      ]),
    ),
  );

  Widget _managerCard(Map<String, dynamic> manager) {
    final permissions = Map<String, dynamic>.from((manager['permissions'] as Map?) ?? {});
    final granted = permissions.values.where((v) => v == true).length;
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [
      Row(children: [
        const CircleAvatar(backgroundColor: AppColors.softGreen, child: Icon(Icons.person_outline, color: AppColors.primaryGreen)),
        const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(manager['name']?.toString() ?? 'Manager', style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w800)),
          Text(manager['uid']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.mutedText, fontSize: 11)),
          const SizedBox(height: 4), const Text('● Active', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12)),
        ])),
        IconButton(tooltip: 'Remove manager', onPressed: () => _remove(manager), icon: const Icon(Icons.person_remove_outlined, color: AppColors.mutedText)),
      ]),
      const Divider(height: 22),
      Row(children: [Expanded(child: Text('Permissions: $granted/${_permissions.length}', style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700))), TextButton.icon(onPressed: () => _editPermissions(manager), icon: const Icon(Icons.tune, size: 18), label: const Text('Manage'))]),
    ]));
  }
}
