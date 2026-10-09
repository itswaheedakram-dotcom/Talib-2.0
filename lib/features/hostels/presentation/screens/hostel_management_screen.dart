import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../models/hostel.dart';
import '../../data/hostel_manager.dart';
import '../../data/hostel_repository.dart';
import '../../data/hostel_room.dart';

class HostelManagementScreen extends StatefulWidget {
  final String hostelId;
  final Hostel? initialHostel;

  const HostelManagementScreen({
    super.key,
    required this.hostelId,
    this.initialHostel,
  });

  @override
  State<HostelManagementScreen> createState() => _HostelManagementScreenState();
}

class _HostelManagementScreenState extends State<HostelManagementScreen> {
  Hostel? _hostel;
  HostelManager? _manager;
  bool _loading = true;
  bool _saving = false;
  HostelRepository? _repo;
  final Map<String, TextEditingController> _c = {};
  final List<_RoomDraft> _rooms = [];

  String? get _uid {
    final active = ActiveProfileController.instance.active;
    if (active != null) return active.id;
    if (!FirebaseService.initialized) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  bool get _isOwner => _hostel != null && _uid != null && _uid == _hostel!.ownerId;

  bool _can(String permission) =>
      _isOwner || (_manager?.status == 'active' && _manager!.can(permission));

  TextEditingController _field(String key, String value) =>
      _c.putIfAbsent(key, () => TextEditingController(text: value));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _c.values) {
      controller.dispose();
    }
    for (final room in _rooms) {
      room.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    Hostel? hostel = widget.initialHostel;

    // When the detail screen already has the hostel object, use it directly. This keeps the management
    // screen usable before Firebase is connected/deployed.
    for (final item in HostelRepository.demoHostels) {
      if (item.id == widget.hostelId) {
        hostel = item;
        break;
      }
    }

    // Only query Firestore for a hostel that is not a local demo record.
    if (hostel == null && FirebaseService.initialized) {
      try {
        _repo ??= HostelRepository();
        hostel = await _repo!.getHostel(widget.hostelId);
      } catch (_) {
        // Keep the screen alive and show the explicit not-found state below.
      }
    }

    HostelManager? manager;
    final uid = _uid;
    if (hostel != null && uid != null && uid != hostel.ownerId) {
      try {
        _repo ??= HostelRepository();
        manager = await _repo!.getManager(hostel.id, uid);
      } catch (_) {
        // Manager access is optional; never let it blank/crash this screen.
      }
    }

    if (hostel != null) {
      // Seed controllers before the first non-loading build so TextFields
      // never receive null controllers.
      _seedFields(hostel);
    }

    if (!mounted) return;
    setState(() {
      _hostel = hostel;
      _manager = manager;
      _loading = false;
    });
  }

  void _seedFields(Hostel h) {
    _field('name', h.name);
    _field('type', h.type);
    _field('gender', h.gender);
    _field('description', h.description);
    _field('city', h.city);
    _field('area', h.area);
    _field('distance', h.distance);
    _field('address', h.address);
    _field('price', h.price);
    _field('securityFee', h.securityFee);
    _field('roomType', h.roomType);
    _field('availability', h.availability);
    _field('meals', h.meals);
    _field('phone', h.phone);
    _field('website', h.website);
    _field('facilities', h.facilities.join('\n'));
    _field('rules', h.rules.join('\n'));
    _field('imageUrl', h.imageUrl);
    _field('imageUrls', h.imageUrls.join('\n'));
    for (final room in h.rooms) {
      _rooms.add(_RoomDraft.fromRoom(room));
    }
  }

  Future<void> _saveSection(String permission, Map<String, dynamic> changes) async {
    final h = _hostel;
    final uid = _uid;
    if (h == null || uid == null || changes.isEmpty) return;
    setState(() => _saving = true);
    try {
      _repo ??= HostelRepository();
      await _repo!.updateHostelSectionSafe(
        hostel: h,
        userId: uid,
        permission: permission,
        changes: changes,
      );
      if (!mounted) return;
      setState(() {
        _hostel = _applyLocalChanges(h, changes);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${HostelManagerPermissions.labels[permission] ?? 'Section'} updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save this section: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Hostel _applyLocalChanges(Hostel h, Map<String, dynamic> x) {
    return Hostel(
      id: h.id, name: (x['name'] ?? h.name).toString(),
      city: (x['city'] ?? h.city).toString(), area: (x['area'] ?? h.area).toString(),
      type: (x['type'] ?? h.type).toString(), gender: (x['gender'] ?? h.gender).toString(),
      distance: (x['distance'] ?? h.distance).toString(), price: (x['price'] ?? h.price).toString(),
      securityFee: (x['securityFee'] ?? h.securityFee).toString(), roomType: (x['roomType'] ?? h.roomType).toString(),
      availability: (x['availability'] ?? h.availability).toString(), meals: (x['meals'] ?? h.meals).toString(),
      ac: x['ac'] is bool ? x['ac'] as bool : h.ac,
      facilities: x['facilities'] is List ? List<String>.from(x['facilities']) : h.facilities,
      imageUrls: x['imageUrls'] is List ? List<String>.from(x['imageUrls']) : h.imageUrls,
      description: (x['description'] ?? h.description).toString(),
      phone: (x['phone'] ?? h.phone).toString(), website: (x['website'] ?? h.website).toString(),
      imageUrl: (x['imageUrl'] ?? h.imageUrl).toString(), address: (x['address'] ?? h.address).toString(),
      ownerId: h.ownerId, ownerName: h.ownerName, status: h.status, isVerified: h.isVerified, isDemo: h.isDemo,
      rating: h.rating, reviewCount: h.reviewCount, ratingTotal: h.ratingTotal,
      rooms: x['rooms'] is List ? List<HostelRoom>.from(x['rooms']) : h.rooms,
      rules: x['rules'] is List ? List<String>.from(x['rules']) : h.rules,
    );
  }

  Future<void> _saveBasic() => _saveSection(HostelManagerPermissions.basicInfo, {
    'name': _c['name']!.text.trim(),
    'type': _c['type']!.text.trim(),
    'gender': _c['gender']!.text.trim(),
    'description': _c['description']!.text.trim(),
  });

  Future<void> _saveLocation() => _saveSection(HostelManagerPermissions.location, {
    'city': _c['city']!.text.trim(),
    'area': _c['area']!.text.trim(),
    'distance': _c['distance']!.text.trim(),
    'address': _c['address']!.text.trim(),
  });

  Future<void> _savePricing() => _saveSection(HostelManagerPermissions.pricing, {
    'price': _c['price']!.text.trim(),
    'securityFee': _c['securityFee']!.text.trim(),
    'roomType': _c['roomType']!.text.trim(),
  });

  Future<void> _saveAvailability() => _saveSection(HostelManagerPermissions.availability, {
    'availability': _c['availability']!.text.trim(),
  });

  Future<void> _saveFacilities() => _saveSection(HostelManagerPermissions.facilities, {
    'facilities': _lines(_c['facilities']!.text),
    'meals': _c['meals']!.text.trim(),
    'ac': _hostel?.ac ?? false,
  });

  Future<void> _pickGalleryPhotos() async {
    final hostel = _hostel;
    if (hostel == null || !_can(HostelManagerPermissions.photos) || _saving) return;

    try {
      final selected = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (selected.isEmpty || !mounted) return;

      setState(() => _saving = true);
      final urls = _lines(_c['imageUrls']!.text).toSet();
      final isDemo = hostel.isDemo || !FirebaseService.initialized;

      for (final image in selected) {
        if (isDemo) {
          // Demo mode keeps local paths in the in-memory demo hostel only.
          urls.add(image.path);
        } else {
          final safeName = image.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
          final objectName = DateTime.now().microsecondsSinceEpoch.toString() + '_' + safeName;
          final ref = FirebaseStorage.instance
              .ref()
              .child('hostels/' + hostel.id + '/gallery/' + objectName);
          await ref.putData(
            await image.readAsBytes(),
            SettableMetadata(contentType: image.mimeType ?? 'image/jpeg'),
          );
          urls.add(await ref.getDownloadURL());
        }
      }

      if (!mounted) return;
      final gallery = urls.toList();
      setState(() {
        _c['imageUrls']!.text = gallery.join('\n');
        if (_c['imageUrl']!.text.trim().isEmpty && gallery.isNotEmpty) {
          _c['imageUrl']!.text = gallery.first;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDemo
                ? selected.length.toString() + ' photo(s) selected for this demo session. Tap Save section.'
                : selected.length.toString() + ' photo(s) uploaded. Tap Save section to update the listing.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photos could not be added. Check gallery permission and Firebase Storage setup.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePhotos() => _saveSection(HostelManagerPermissions.photos, {
    'imageUrl': _c['imageUrl']!.text.trim(),
    'imageUrls': _lines(_c['imageUrls']!.text),
  });

  Future<void> _saveRules() => _saveSection(HostelManagerPermissions.rules, {
    'rules': _lines(_c['rules']!.text),
  });

  Future<void> _saveContact() => _saveSection(HostelManagerPermissions.contact, {
    'phone': _c['phone']!.text.trim(),
    'website': _c['website']!.text.trim(),
  });

  Future<void> _saveRooms() async {
    final rooms = _rooms.map((r) => r.toRoom()).toList();
    await _saveSection(HostelManagerPermissions.rooms, {'rooms': rooms});
  }

  List<String> _lines(String value) => value
      .split(RegExp(r'\r?\n'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: const OutlineInputBorder(),
  );

  Widget _fieldWidget(String key, String label, {int maxLines = 1, String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _c[key],
          maxLines: maxLines,
          decoration: _dec(label, hint: hint),
        ),
      );

  Widget _section(String title, String permission, List<Widget> children, VoidCallback save, {String? helper, IconData icon = Icons.edit_outlined}) {
    if (!_can(permission)) return const SizedBox.shrink();
    return Card(
      color: AppColors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children:[Icon(icon,color:AppColors.primaryGreen),const SizedBox(width:8),Expanded(child:Text(title, style: const TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w800)))]),
            if(helper!=null) ...[const SizedBox(height:4),Text(helper,style:const TextStyle(color:AppColors.mutedText))],
            const SizedBox(height: 12),
            ...children,
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save section'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get _completion {
    final h=_hostel; if(h==null)return 0;
    final checks=[h.name.isNotEmpty,h.city.isNotEmpty,h.address.isNotEmpty,h.price.isNotEmpty,h.rooms.isNotEmpty,h.facilities.isNotEmpty,h.rules.isNotEmpty,h.phone.isNotEmpty,h.imageUrls.isNotEmpty||h.imageUrl.isNotEmpty];
    return ((checks.where((x)=>x).length/checks.length)*100).round();
  }

  Widget _roomsSection() {
    if (!_can(HostelManagerPermissions.rooms)) return const SizedBox.shrink();
    return Card(
      color: AppColors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rooms & pricing', style: TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...List.generate(_rooms.length, (i) => _roomCard(i)),
            OutlinedButton.icon(
              onPressed: () => setState(() => _rooms.add(_RoomDraft.empty())),
              icon: const Icon(Icons.add),
              label: const Text('Add room'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveRooms,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save rooms'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _duplicateRoom(int index) { final r=_rooms[index]; setState(()=>_rooms.insert(index+1,_RoomDraft(type:TextEditingController(text:r.type.text),rent:TextEditingController(text:r.rent.text),security:TextEditingController(text:r.security.text),totalBeds:TextEditingController(text:r.totalBeds.text),availableBeds:TextEditingController(text:r.availableBeds.text),notes:TextEditingController(text:r.notes.text),ac:r.ac))); }

  Widget _roomCard(int index) {
    final r = _rooms[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: Text('Room ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen))),
            IconButton(tooltip:'Duplicate room',onPressed: () => _duplicateRoom(index), icon: const Icon(Icons.copy_outlined)),
            IconButton(onPressed: () => setState(() { r.dispose(); _rooms.removeAt(index); }), icon: const Icon(Icons.delete_outline)),
          ]),
          _roomField(r.type, 'Room type', r.setType),
          _roomField(r.rent, 'Rent', r.setRent),
          _roomField(r.security, 'Security fee', r.setSecurity),
          Row(children: [
            Expanded(child: _roomField(r.totalBeds, 'Total beds', r.setTotalBeds)),
            const SizedBox(width: 10),
            Expanded(child: _roomField(r.availableBeds, 'Available beds', r.setAvailableBeds)),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('AC room'),
            value: r.ac,
            onChanged: (v) => setState(() => r.ac = v),
          ),
          _roomField(r.notes, 'Notes', r.setNotes, maxLines: 2),
        ],
      ),
    );
  }

  Widget _roomField(TextEditingController controller, String label, ValueChanged<String> onChanged, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: _dec(label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    try {
      return _buildScreen(context);
    } catch (error) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Manage Hostel')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Manage Hostel could not be loaded.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedText),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildScreen(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }
    final h = _hostel;
    if (h == null) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: Text('Hostel not found.', style: TextStyle(color: AppColors.mutedText))),
      );
    }
    if (!_isOwner && _manager == null) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('You do not have management access to this hostel.', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final completion=_completion;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Manage Hostel'),
        actions: [
          if (_isOwner)
            IconButton(
              tooltip: 'Manage managers',
              onPressed: () => context.push('/hostel/${Uri.encodeComponent(h.id)}/managers'),
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Card(color:AppColors.white,elevation:0,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[const Expanded(child:Text('Hostel setup',style:TextStyle(color:AppColors.darkGreen,fontSize:19,fontWeight:FontWeight.w800))),Text('\$completion%',style:const TextStyle(color:AppColors.primaryGreen,fontSize:20,fontWeight:FontWeight.w800))]),
            const SizedBox(height:6),Text(completion==100?'Profile complete — ready to show students.':'Complete the missing sections to make your listing stronger.',style:const TextStyle(color:AppColors.mutedText)),
            const SizedBox(height:10),LinearProgressIndicator(value:completion/100,minHeight:8,borderRadius:BorderRadius.circular(8)),
          ])),),
          const SizedBox(height:12),
          Text(h.name, style: const TextStyle(color: AppColors.darkGreen, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(_isOwner ? 'Owner — full hostel access' : 'Manager — assigned sections only', style: const TextStyle(color: AppColors.mutedText)),
          if (!_isOwner) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: HostelManagerPermissions.labels.entries
                  .where((e) => _manager!.can(e.key))
                  .map((e) => Chip(label: Text(e.value)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          _section('Basic information', HostelManagerPermissions.basicInfo, [
            _fieldWidget('name', 'Hostel name'),
            _fieldWidget('type', 'Hostel type'),
            _fieldWidget('gender', 'For'),
            _fieldWidget('description', 'Description', maxLines: 4),
          ], _saveBasic),
          _section('Location', HostelManagerPermissions.location, [
            _fieldWidget('city', 'City'),
            _fieldWidget('area', 'Area'),
            _fieldWidget('distance', 'Distance'),
            _fieldWidget('address', 'Full address', maxLines: 2),
          ], _saveLocation),
          _section('Pricing', HostelManagerPermissions.pricing, [
            _fieldWidget('price', 'Monthly rent'),
            _fieldWidget('securityFee', 'Security fee'),
            _fieldWidget('roomType', 'Default room type'),
          ], _savePricing),
          _roomsSection(),
          _section('Availability', HostelManagerPermissions.availability, [
            _fieldWidget('availability', 'Availability', hint: 'e.g. 6 beds available'),
          ], _saveAvailability),
          _section('Photos', HostelManagerPermissions.photos, [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _pickGalleryPhotos,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Choose photos from gallery'),
              ),
            ),
            const SizedBox(height: 6),
            _fieldWidget('imageUrl', 'Main image URL or selected photo path'),
            _fieldWidget('imageUrls', 'Gallery image URLs / demo photo paths', maxLines: 4, hint: 'One URL or demo path per line'),
            const Text(
              'Real listings upload to Firebase Storage. Demo photos stay available in the current app session. Tap Save section after selecting photos.',
              style: TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.35),
            ),
          ], _savePhotos),
          _section('Facilities & meals', HostelManagerPermissions.facilities, [
            _fieldWidget('facilities', 'Facilities', maxLines: 5, hint: 'One facility per line'),
            _fieldWidget('meals', 'Meals / mess'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Air conditioning'),
              value: h.ac,
              onChanged: (v) => setState(() => _hostel = _applyLocalChanges(h, {'ac': v})),
            ),
          ], _saveFacilities),
          _section('Rules', HostelManagerPermissions.rules, [
            _fieldWidget('rules', 'Hostel rules', maxLines: 6, hint: 'One rule per line'),
          ], _saveRules),
          _section('Contact information', HostelManagerPermissions.contact, [
            _fieldWidget('phone', 'Phone'),
            _fieldWidget('website', 'Website'),
          ], _saveContact),
          if (_isOwner) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => context.push('/hostel/${Uri.encodeComponent(h.id)}/managers'),
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Manage managers & permissions'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoomDraft {
  final TextEditingController type;
  final TextEditingController rent;
  final TextEditingController security;
  final TextEditingController totalBeds;
  final TextEditingController availableBeds;
  final TextEditingController notes;
  bool ac;

  _RoomDraft({
    required this.type,
    required this.rent,
    required this.security,
    required this.totalBeds,
    required this.availableBeds,
    required this.notes,
    this.ac = false,
  });

  factory _RoomDraft.empty() => _RoomDraft(
    type: TextEditingController(),
    rent: TextEditingController(),
    security: TextEditingController(),
    totalBeds: TextEditingController(text: '0'),
    availableBeds: TextEditingController(text: '0'),
    notes: TextEditingController(),
  );

  factory _RoomDraft.fromRoom(HostelRoom room) => _RoomDraft(
    type: TextEditingController(text: room.type),
    rent: TextEditingController(text: room.rent),
    security: TextEditingController(text: room.securityFee),
    totalBeds: TextEditingController(text: room.totalBeds.toString()),
    availableBeds: TextEditingController(text: room.availableBeds.toString()),
    notes: TextEditingController(text: room.notes),
    ac: room.ac,
  );

  void setType(String v) {}
  void setRent(String v) {}
  void setSecurity(String v) {}
  void setTotalBeds(String v) {}
  void setAvailableBeds(String v) {}
  void setNotes(String v) {}

  HostelRoom toRoom() => HostelRoom(
    id: type.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
    type: type.text.trim(),
    rent: rent.text.trim(),
    securityFee: security.text.trim(),
    totalBeds: int.tryParse(totalBeds.text.trim()) ?? 0,
    availableBeds: int.tryParse(availableBeds.text.trim()) ?? 0,
    ac: ac,
    notes: notes.text.trim(),
  );

  void dispose() {
    type.dispose(); rent.dispose(); security.dispose(); totalBeds.dispose();
    availableBeds.dispose(); notes.dispose();
  }
}
