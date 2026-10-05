import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../data/hostel_repository.dart';
import '../../data/hostel_seed_data.dart';
import '../../../models/hostel.dart';

class HostelsScreen extends StatefulWidget {
  const HostelsScreen({super.key});
  @override
  State<HostelsScreen> createState() => _HostelsScreenState();
}

class _HostelsScreenState extends State<HostelsScreen> {
  final _searchController = TextEditingController();
  HostelRepository? _repository;
  StreamSubscription<List<Hostel>>? _hostelSubscription;
  List<Hostel> _hostels = List<Hostel>.from(exampleHostels);
  String _city = 'All';
  String _gender = 'All';
  String _type = 'All';
  String _roomType = 'All';
  String _sort = 'Recommended';
  bool _acOnly = false;

  @override
  void initState() {
    super.initState();
    _connectToFirestore();
  }

  Future<void> _connectToFirestore() async {
    try {
      final repository = HostelRepository();
      _repository = repository;
      await repository.seedDemoDataIfEmpty();
      _hostelSubscription = repository.watchHostels().listen(
        (hostels) {
          if (!mounted) return;
          setState(() {
            _hostels = hostels.isEmpty
                ? List<Hostel>.from(exampleHostels)
                : hostels;
          });
        },
        onError: (_) {},
      );
    } catch (_) {
      // Keep bundled examples visible if Firebase is unavailable.
    }
  }

  @override
  void dispose() {
    _hostelSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Hostel> _filter(List<Hostel> hostels) {
    final query = _searchController.text.trim().toLowerCase();
    final result = hostels.where((item) {
      final text = [
        item.name, item.city, item.area, item.type, item.gender,
        item.price, item.roomType, item.availability, item.meals, item.description, item.address, ...item.facilities,
      ].join(' ').toLowerCase();
      return (query.isEmpty || text.contains(query)) &&
          (_city == 'All' || item.city == _city) &&
          (_gender == 'All' || item.gender == _gender) &&
          (_type == 'All' || item.type == _type) &&
          (_roomType == 'All' || item.roomType == _roomType) &&
          (!_acOnly || item.ac);
    }).toList();
    if (_sort == 'Price: Low') result.sort((a, b) => _price(a.price).compareTo(_price(b.price)));
    if (_sort == 'Nearest') result.sort((a, b) => _distance(a.distance).compareTo(_distance(b.distance)));
    return result;
  }

  int _price(String value) => int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999999999;
  double _distance(String value) => double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 999999;

  List<String> _values(List<Hostel> hostels, String Function(Hostel) value) {
    final values = hostels.map(value).where((v) => v.trim().isNotEmpty).toSet().toList()..sort();
    return ['All', ...values];
  }

  bool get _hasActiveFilters =>
      _city != 'All' ||
      _gender != 'All' ||
      _type != 'All' ||
      _roomType != 'All' ||
      _acOnly ||
      _sort != 'Recommended';

  void _clearFilters() {
    setState(() {
      _city = 'All';
      _gender = 'All';
      _type = 'All';
      _roomType = 'All';
      _acOnly = false;
      _sort = 'Recommended';
    });
  }

  void _showFilters({
    required List<String> cities,
    required List<String> genders,
    required List<String> types,
    required List<String> rooms,
  }) {
    var city = _city;
    var gender = _gender;
    var type = _type;
    var roomType = _roomType;
    var acOnly = _acOnly;
    var sort = _sort;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filters',
                        style: TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (city != 'All' ||
                        gender != 'All' ||
                        type != 'All' ||
                        roomType != 'All' ||
                        acOnly ||
                        sort != 'Recommended')
                      TextButton(
                        onPressed: () => setSheetState(() {
                          city = 'All';
                          gender = 'All';
                          type = 'All';
                          roomType = 'All';
                          acOnly = false;
                          sort = 'Recommended';
                        }),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _filterSection(
                  'City',
                  cities,
                  city,
                  (value) => setSheetState(() => city = value),
                ),
                _filterSection(
                  'Gender',
                  genders,
                  gender,
                  (value) => setSheetState(() => gender = value),
                ),
                _filterSection(
                  'Type',
                  types,
                  type,
                  (value) => setSheetState(() => type = value),
                ),
                _filterSection(
                  'Room type',
                  rooms,
                  roomType,
                  (value) => setSheetState(() => roomType = value),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Other',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                FilterChip(
                  label: const Text('AC only'),
                  selected: acOnly,
                  onSelected: (value) =>
                      setSheetState(() => acOnly = value),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sort by',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: ['Recommended', 'Price: Low', 'Nearest']
                      .map(
                        (value) => ChoiceChip(
                          label: Text(value),
                          selected: sort == value,
                          onSelected: (_) =>
                              setSheetState(() => sort = value),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _city = city;
                        _gender = gender;
                        _type = type;
                        _roomType = roomType;
                        _acOnly = acOnly;
                        _sort = sort;
                      });
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Apply filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterSection(
    String title,
    List<String> values,
    String selected,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: selected == value,
                    onSelected: (_) => onChanged(value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showDetails(Hostel hostel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hostel.name, style: const TextStyle(color: AppColors.darkGreen, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [_tag(hostel.type), _tag(hostel.gender)]),
            const SizedBox(height: 14),
            _row(Icons.location_on_outlined, hostel.address.isNotEmpty ? hostel.address : '${hostel.area}, ${hostel.city}'),
            if (hostel.distance.isNotEmpty) _row(Icons.near_me_outlined, hostel.distance),
            if (hostel.price.isNotEmpty) _row(Icons.payments_outlined, hostel.price),
            if (hostel.facilities.isNotEmpty) _row(Icons.apartment_outlined, hostel.facilities.join(' • ')),
            if (hostel.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('About this hostel', style: TextStyle(color: AppColors.darkGreen, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(hostel.description, style: const TextStyle(color: AppColors.mutedText, height: 1.4)),
            ],
            if (hostel.phone.isNotEmpty) ...[
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: AppColors.white),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: hostel.phone));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Hostel contact copied')));
                  }
                },
                icon: const Icon(Icons.phone_outlined),
                label: Text('Copy ${hostel.phone}'),
              )),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _tag(String value) => Chip(
    label: Text(value),
    backgroundColor: AppColors.softGreen,
    labelStyle: const TextStyle(color: AppColors.darkGreen, fontSize: 12),
    side: BorderSide.none,
  );

  Widget _row(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: AppColors.primaryGreen),
      const SizedBox(width: 10),
      Expanded(child: Text(value, style: const TextStyle(color: AppColors.darkGreen, height: 1.3))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final allHostels = _hostels;
    final cities = _values(allHostels, (h) => h.city);
    final genders = _values(allHostels, (h) => h.gender);
    final types = _values(allHostels, (h) => h.type);
    final rooms = _values(allHostels, (h) => h.roomType);
    final filtered = _filter(allHostels);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Hostels'),
        actions: [
          IconButton(
            tooltip: 'List your hostel',
            onPressed: () => context.push('/hostels/list'),
            icon: const Icon(Icons.add_business_outlined, color: AppColors.white),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${filtered.length}',
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search hostels, cities, areas...',
              leading: const Icon(Icons.search_rounded, color: AppColors.primaryGreen),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear_rounded),
                  ),
                IconButton(
                  tooltip: 'Filters',
                  onPressed: () => _showFilters(
                    cities: cities,
                    genders: genders,
                    types: types,
                    rooms: rooms,
                  ),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.tune_rounded, color: AppColors.primaryGreen),
                      if (_hasActiveFilters)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.brightGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Filters stay hidden until the user opens them from the search area.

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} hostels',
                  style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (_hasActiveFilters)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _state(
                    Icons.hotel_outlined,
                    allHostels.isEmpty ? 'No hostels available' : 'No hostels found',
                    allHostels.isEmpty
                        ? 'Hostel listings will appear here when they are added.'
                        : 'Try another search or filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _card(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(Hostel hostel) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/hostel/${hostel.id}', extra: hostel),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(14)),
              child: hostel.imageUrl.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(hostel.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.hotel_rounded, color: AppColors.primaryGreen, size: 32)))
                  : const Icon(Icons.hotel_rounded, color: AppColors.primaryGreen, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hostel.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.darkGreen, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${hostel.area}, ${hostel.city}', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
              const SizedBox(height: 7),
              Wrap(spacing: 6, runSpacing: 4, children: [
                _smallTag(hostel.type), _smallTag(hostel.gender),
                if (hostel.roomType.isNotEmpty) _smallTag(hostel.roomType),
                if (hostel.ac) _smallTag('AC'),
              ]),
              if (hostel.price.isNotEmpty || hostel.availability.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  if (hostel.price.isNotEmpty) Expanded(child: Text(hostel.price, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.w700))),
                  if (hostel.availability.isNotEmpty) Text(hostel.availability, style: const TextStyle(color: AppColors.mutedText, fontSize: 10)),
                ]),
              ],
              if (hostel.facilities.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(hostel.facilities.join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 11)),
              ],
            ])),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
          ]),
        ),
      ),
    );
  }

  Widget _smallTag(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(10)),
    child: Text(value, style: const TextStyle(color: AppColors.darkGreen, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  Widget _state(IconData icon, String title, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 54, color: AppColors.primaryGreen),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
      ]),
    ),
  );
}
