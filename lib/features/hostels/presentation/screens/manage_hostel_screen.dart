import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../models/hostel.dart';
import '../../data/hostel_repository.dart';

class ManageHostelScreen extends StatefulWidget {
  final Hostel hostel;
  const ManageHostelScreen({super.key, required this.hostel});
  @override
  State<ManageHostelScreen> createState() => _ManageHostelScreenState();
}

class _ManageHostelScreenState extends State<ManageHostelScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _city, _area, _address, _description, _rules,
      _price, _security, _room, _availability, _meals, _phone, _website, _photos;
  late String _gender, _type;
  late bool _ac;
  late Set<String> _facilities;
  late List<Map<String, dynamic>> _rooms;
  bool _saving = false;
  bool _saved = false;

  static const _facilityOptions = <String>[
    'Wi-Fi','Electricity backup','Parking','Laundry','CCTV','Security',
    'Study room','Common room','Water','Generator/UPS','Mess','Library',
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.hostel;
    _name = TextEditingController(text: h.name);
    _city = TextEditingController(text: h.city);
    _area = TextEditingController(text: h.area);
    _address = TextEditingController(text: h.address);
    _description = TextEditingController(text: h.description);
    _rules = TextEditingController(text: h.rules);
    _price = TextEditingController(text: h.price);
    _security = TextEditingController(text: h.securityFee);
    _room = TextEditingController(text: h.roomType);
    _availability = TextEditingController(text: h.availability);
    _meals = TextEditingController(text: h.meals);
    _phone = TextEditingController(text: h.phone);
    _website = TextEditingController(text: h.website);
    _photos = TextEditingController(text: <String>{...h.imageUrls, if (h.imageUrl.isNotEmpty) h.imageUrl}.join('\n'));
    _gender = h.gender == 'Female' ? 'Girls Hostel' : h.gender == 'Both' ? 'Boys & Girls' : 'Boys Hostel';
    _type = h.type;
    _ac = h.ac;
    _facilities = h.facilities.toSet();
    _rooms = h.rooms.map((room) => Map<String, dynamic>.from(room)).toList();
  }

  @override
  void dispose() {
    for (final c in [_name,_city,_area,_address,_description,_rules,_price,_security,
      _room,_availability,_meals,_phone,_website,_photos]) { c.dispose(); }
    super.dispose();
  }

  int get _completed {
    final checks = <bool>[
      _name.text.trim().isNotEmpty, _city.text.trim().isNotEmpty,
      _address.text.trim().isNotEmpty, _price.text.trim().isNotEmpty,
      _room.text.trim().isNotEmpty, _phone.text.trim().isNotEmpty,
      _description.text.trim().isNotEmpty, _rules.text.trim().isNotEmpty, _photos.text.trim().isNotEmpty,
      _facilities.isNotEmpty, _availability.text.trim().isNotEmpty,
      _rooms.isNotEmpty,
    ];
    return ((checks.where((v) => v).length / checks.length) * 100).round();
  }

  Future<void> _save({bool publish = false}) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the highlighted required fields.')),
      );
      return;
    }
    setState(() { _saving = true; _saved = false; });
    final old = widget.hostel;
    final photoList = _photos.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    final updated = Hostel(
      id: old.id, name: _name.text.trim(), city: _city.text.trim(),
      area: _area.text.trim(), address: _address.text.trim(), type: _type,
      gender: _gender == 'Girls Hostel' ? 'Female' : _gender == 'Boys & Girls' ? 'Both' : 'Male',
      price: _price.text.trim(), securityFee: _security.text.trim(),
      roomType: _room.text.trim(), availability: _availability.text.trim(),
      meals: _meals.text.trim(), ac: _ac, facilities: _facilities.toList(),
      imageUrl: photoList.isEmpty ? '' : photoList.first, imageUrls: photoList,
      rooms: _rooms.map((room) => Map<String, dynamic>.from(room)).toList(),
      description: _description.text.trim(), rules: _rules.text.trim(), phone: _phone.text.trim(),
      website: _website.text.trim(), ownerId: old.ownerId, ownerName: old.ownerName,
      status: publish ? 'pending' : old.status, isVerified: publish ? false : old.isVerified,
      isDemo: old.isDemo, rating: old.rating, reviewCount: old.reviewCount,
      ratingTotal: old.ratingTotal,
    );
    try {
      await HostelRepository.saveHostel(updated);
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(publish ? 'Listing submitted for review.' : 'Changes saved.'),
      ));
      if (publish) context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save changes. Check your connection and try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hostel;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Manage Hostel'), actions: [
        IconButton(tooltip: 'Preview listing', onPressed: () => context.push('/hostel/${h.id}', extra: h), icon: const Icon(Icons.visibility_outlined)),
      ]),
      body: Form(key: _formKey, child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _overview(h),
          const SizedBox(height: 12),
          _quickActions(h),
          const SizedBox(height: 14),
          _section('Basic Information', Icons.home_work_outlined, [
            _field(_name, 'Hostel name', required: true, hint: 'e.g. Student Residency'),
            _dropdown('Hostel type', _type, const ['Private','University','Family','Student Residence'], (v) => setState(() => _type = v)),
            _dropdown('Who can stay here?', _gender, const ['Boys Hostel','Girls Hostel','Boys & Girls'], (v) => setState(() => _gender = v)),
            _field(_description, 'Short description', maxLines: 3, hint: 'Peaceful hostel near universities...'),
          ]),
          _section('Location', Icons.location_on_outlined, [
            Row(children: [Expanded(child: _field(_city, 'City', required: true)), const SizedBox(width: 10), Expanded(child: _field(_area, 'Area'))]),
            _field(_address, 'Complete address', required: true, maxLines: 2),
            const Text('Tip: add a nearby landmark so students can find you easily.', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
          ]),
          _section('Rooms & Pricing', Icons.bed_outlined, [
            _dropdown('Common room setup', _room.text.isEmpty ? '2-Seater' : _room.text, const ['Single','2-Seater','3-Seater','4-Seater','Shared'], (v) { _room.text = v; setState(() {}); }),
            _field(_price, 'Monthly rent (Rs.)', required: true, keyboard: TextInputType.number, hint: '18000'),
            _field(_security, 'Security deposit (Rs.)', keyboard: TextInputType.number, hint: '18000'),
            _field(_availability, 'Available beds', hint: 'e.g. 4 beds available'),
            SwitchListTile(contentPadding: EdgeInsets.zero, activeColor: AppColors.primaryGreen, title: const Text('Air conditioning available'), value: _ac, onChanged: (v) => setState(() => _ac = v)),
            _roomInventory(),
          ]),
          _section('Photos', Icons.photo_library_outlined, [
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _saving ? null : _pickAndUploadPhotos, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Choose photos from gallery'))),
            _field(_photos, 'Photo links (one per line)', maxLines: 3, hint: 'Paste image links here'),
            const Text('This version accepts image links. Direct gallery upload needs Firebase Storage integration.', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
          ]),
          _section('Facilities', Icons.wifi_outlined, [
            Wrap(spacing: 8, runSpacing: 8, children: _facilityOptions.map((item) => FilterChip(
              label: Text(item), selected: _facilities.contains(item),
              onSelected: (yes) => setState(() { yes ? _facilities.add(item) : _facilities.remove(item); }),
              selectedColor: AppColors.guidanceBubble, checkmarkColor: AppColors.darkGreen,
            )).toList()),
          ]),
          _section('Meals', Icons.restaurant_outlined, [
            _field(_meals, 'Meal plan and timings', hint: 'Breakfast, lunch, dinner / separate charges'),
          ]),
          _section('Rules & Contact', Icons.rule_outlined, [
            _field(_phone, 'Phone / WhatsApp', required: true, keyboard: TextInputType.phone),
            _field(_website, 'Website (optional)', keyboard: TextInputType.url),
            _field(_rules, 'Hostel rules', maxLines: 4, hint: 'Visitors, curfew, cooking, smoking, quiet hours...'),
          ]),
          const SizedBox(height: 10),
          Row(children: [if (_saved) const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 18), if (_saved) const SizedBox(width: 6), Text(_saved ? 'Saved' : 'Changes are saved when you tap Save Draft', style: const TextStyle(color: AppColors.mutedText, fontSize: 12))]),
          const SizedBox(height: 10),
          SizedBox(height: 50, child: OutlinedButton.icon(onPressed: _saving ? null : () => _save(), icon: const Icon(Icons.save_outlined), label: const Text('Save Draft'))),
          const SizedBox(height: 8),
          SizedBox(height: 50, child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: AppColors.white),
            onPressed: _saving ? null : () => _save(publish: true),
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Icon(Icons.publish_outlined),
            label: Text(_saving ? 'Saving...' : 'Save & Publish'),
          )),
        ],
      )),
    );
  }

  Widget _overview(Hostel h) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_name.text.isEmpty ? h.name : _name.text, style: const TextStyle(color: AppColors.darkGreen, fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        _pill(h.status.toUpperCase(), h.status == 'approved' ? AppColors.softGreen : AppColors.guidanceBubble),
        _pill('★ ${h.rating.toStringAsFixed(1)}', AppColors.cream),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _metric('Completion', '$_completed%')),
        Expanded(child: _metric('Rooms', _rooms.length.toString())),
        Expanded(child: _metric('Managers', '—')),
      ]),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _completed / 100, minHeight: 7, color: AppColors.primaryGreen, backgroundColor: AppColors.softGreen)),
      const SizedBox(height: 8),
      Text(_completed >= 90 ? 'Great! Your listing has most of the important details.' : 'Add a few more details to make your hostel more attractive.', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
    ]),
  );

  Widget _quickActions(Hostel h) => Wrap(spacing: 8, runSpacing: 8, children: [
    _action('Rooms & Prices', Icons.bed_outlined, () => _scrollToSection()),
    _action('Add Photos', Icons.add_a_photo_outlined, () => _scrollToSection()),
    _action('Managers', Icons.people_outline, () => context.push('/hostel/${h.id}/managers', extra: h)),
    _action('View Hostel', Icons.visibility_outlined, () => context.push('/hostel/${h.id}', extra: h)),
  ]);

  Future<void> _pickAndUploadPhotos() async {
    final hostel = widget.hostel;
    if (hostel.isDemo || hostel.id.startsWith('example_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery upload needs a real Firebase hostel listing. Demo hostels can use image links for now.')),
      );
      return;
    }

    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (files.isEmpty || !mounted) return;
      setState(() => _saving = true);
      final urls = _photos.text.split('\n').map((value) => value.trim()).where((value) => value.isNotEmpty).toSet();
      for (final file in files) {
        final objectName = DateTime.now().microsecondsSinceEpoch.toString() + '_' + file.name;
        final reference = FirebaseStorage.instance.ref().child('hostels/' + hostel.id + '/gallery/' + objectName);
        await reference.putData(await file.readAsBytes());
        urls.add(await reference.getDownloadURL());
      }
      if (!mounted) return;
      setState(() {
        _photos.text = urls.join('\n');
        _saved = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(files.length.toString() + ' photo(s) uploaded. Tap Save Draft to keep the listing changes.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photos could not be uploaded. Check Firebase Storage setup and try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _roomInventory() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        const Expanded(child: Text('Room inventory', style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700))),
        TextButton.icon(onPressed: () => _editRoom(), icon: const Icon(Icons.add, size: 18), label: const Text('Add room')),
      ]),
      if (_rooms.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
          child: const Text('Abhi room add nahi kiya. Add Room dabayein aur room number, beds aur rent enter karein.', style: TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.4)),
        ),
      ..._rooms.asMap().entries.map((entry) {
        final index = entry.key;
        final room = entry.value;
        final roomName = 'Room ' + ((room['number'] ?? '').toString().trim().isEmpty ? (index + 101).toString() : room['number'].toString());
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.bed_outlined, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Expanded(child: Text(roomName, style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w800))),
              PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') _editRoom(room: room, index: index);
                  if (action == 'duplicate') _duplicateRoom(room);
                  if (action == 'delete') setState(() { _rooms.removeAt(index); _saved = false; });
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit room')),
                  PopupMenuItem(value: 'duplicate', child: Text('Duplicate room')),
                  PopupMenuItem(value: 'delete', child: Text('Remove room')),
                ],
              ),
            ]),
            Text((room['beds'] ?? 1).toString() + ' beds · Rs. ' + (room['price'] ?? '0').toString() + '/month · ' + (room['available'] ?? room['beds'] ?? 1).toString() + ' available', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
            if (room['ac'] == true)
              const Padding(padding: EdgeInsets.only(top: 4), child: Text('Air conditioning', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12))),
          ]),
        );
      }),
      const SizedBox(height: 4),
      const Text('Room details are saved with this hostel listing. Duplicate is useful when several rooms have the same setup.', style: TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.35)),
    ],
  );

  Future<void> _editRoom({Map<String, dynamic>? room, int? index}) async {
    final number = TextEditingController(text: room?['number']?.toString() ?? 'Room ' + (101 + _rooms.length).toString());
    final beds = TextEditingController(text: room?['beds']?.toString() ?? '2');
    final price = TextEditingController(text: room?['price']?.toString() ?? _price.text.trim());
    final available = TextEditingController(text: room?['available']?.toString() ?? '2');
    var hasAc = room?['ac'] == true;
    final formKey = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(room == null ? 'Add room' : 'Edit room'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: number, decoration: const InputDecoration(labelText: 'Room number / name'), validator: (v) => v == null || v.trim().isEmpty ? 'Room name is required' : null),
              TextFormField(controller: beds, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total beds'), validator: (v) => int.tryParse(v ?? '') == null || int.parse(v!) < 1 ? 'Enter at least 1 bed' : null),
              TextFormField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly rent (Rs.)'), validator: (v) => double.tryParse(v ?? '') == null || double.parse(v!) < 0 ? 'Enter a valid rent' : null),
              TextFormField(controller: available, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Available beds'), validator: (v) => int.tryParse(v ?? '') == null || int.parse(v!) < 0 || int.parse(v!) > (int.tryParse(beds.text) ?? 0) ? 'Available beds must be between 0 and total beds' : null),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Air conditioning'), value: hasAc, onChanged: (v) => setDialogState(() => hasAc = v)),
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () { if (formKey.currentState?.validate() == true) Navigator.pop(dialogContext, true); }, child: const Text('Save room')),
          ],
        ),
      ),
    );
    if (accepted == true && mounted) {
      final value = <String, dynamic>{
        'number': number.text.trim(),
        'beds': int.parse(beds.text.trim()),
        'price': price.text.trim(),
        'available': int.parse(available.text.trim()),
        'ac': hasAc,
      };
      setState(() {
        if (index == null) { _rooms.add(value); } else { _rooms[index] = value; }
        _saved = false;
      });
    }
    number.dispose(); beds.dispose(); price.dispose(); available.dispose();
  }

  void _duplicateRoom(Map<String, dynamic> room) {
    final copy = Map<String, dynamic>.from(room);
    final current = (room['number'] ?? '').toString();
    final numeric = int.tryParse(current);
    copy['number'] = numeric == null ? current + ' copy' : (numeric + 1).toString();
    setState(() { _rooms.add(copy); _saved = false; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room duplicated. Update its number and details if needed, then Save Draft.')));
  }

  void _scrollToSection() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit the relevant section below.')));
  }

  Widget _action(String label, IconData icon, VoidCallback tap) => ActionChip(avatar: Icon(icon, size: 18, color: AppColors.primaryGreen), label: Text(label), onPressed: tap, backgroundColor: AppColors.white);
  Widget _pill(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30)), child: Text(label, style: const TextStyle(color: AppColors.darkGreen, fontSize: 11, fontWeight: FontWeight.w700)));
  Widget _metric(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w800, fontSize: 15)), Text(label, style: const TextStyle(color: AppColors.mutedText, fontSize: 11))]);
  Widget _section(String title, IconData icon, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: AppColors.primaryGreen), const SizedBox(width: 9), Expanded(child: Text(title, style: const TextStyle(color: AppColors.darkGreen, fontSize: 16, fontWeight: FontWeight.w800)))]),
      const SizedBox(height: 13), ...children.map((w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w)),
    ]),
  );
  Widget _field(TextEditingController c, String label, {bool required = false, int maxLines = 1, TextInputType? keyboard, String? hint}) => TextFormField(
    controller: c, maxLines: maxLines, keyboardType: keyboard,
    onChanged: (_) { if (mounted) setState(() {}); },
    decoration: InputDecoration(labelText: label, hintText: hint, suffixIcon: label == 'Security deposit (Rs.)' ? IconButton(tooltip: 'Security deposit is a refundable amount collected at move-in.', icon: const Icon(Icons.info_outline), onPressed: () => _help('Security deposit', 'This is the amount collected as a deposit when a student moves in.')) : null),
    validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Please enter $label' : null : null,
  );
  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String> onChanged) => DropdownButtonFormField<String>(
    value: options.contains(value) ? value : options.first,
    decoration: InputDecoration(labelText: label),
    items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
    onChanged: (v) { if (v != null) onChanged(v); },
  );
  void _help(String title, String message) => showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))]));
}
