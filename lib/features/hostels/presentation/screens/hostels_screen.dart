import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/hostel_repository.dart';
import '../../data/hostel_registry.dart';
import '../../data/hostel_seed_data.dart';
import '../../../models/hostel.dart';

class HostelsScreen extends StatefulWidget {
  const HostelsScreen({super.key});

  @override
  State<HostelsScreen> createState() => _HostelsScreenState();
}

class _HostelsScreenState extends State<HostelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  HostelRepository? _repository;
  StreamSubscription<List<Hostel>>? _hostelSubscription;

  List<Hostel> _hostels = List<Hostel>.from(exampleHostels);
  String _city = 'All';
  String _gender = 'All';
  String _type = 'All';
  String _roomType = 'All';
  String _sort = 'Recommended';
  bool _acOnly = false;
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _connectToFirestore();
  }

  Future<void> _connectToFirestore() async {
    try {
      if (!FirebaseService.initialized) return;
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
      // Keep local demo data visible if Firebase is unavailable.
    }
  }

  @override
  void dispose() {
    _hostelSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Hostel> _filteredHostels() {
    final repository = _repository;
    if (repository == null) return _localDiscover(_hostels);
    return repository.discover(
      _hostels,
      query: _searchController.text.trim(),
      city: _city,
      gender: _gender,
      type: _type,
      roomType: _roomType,
      acOnly: _acOnly,
      sort: _sort,
    );
  }

  List<Hostel> _localDiscover(List<Hostel> source) {
    final normalizedQuery = _searchController.text.trim().toLowerCase();
    final result = source.where((hostel) {
      if (hostel.status.toLowerCase() != 'approved') return false;
      if (_city != 'All' && hostel.city != _city) return false;
      if (_gender != 'All' && hostel.gender != _gender) return false;
      if (_type != 'All' && hostel.type != _type) return false;
      if (_roomType != 'All' && hostel.roomType != _roomType && !hostel.rooms.any((room) => room.type == _roomType)) return false;
      if (_acOnly && !hostel.ac && !hostel.rooms.any((room) => room.ac)) return false;
      if (normalizedQuery.isEmpty) return true;
      final haystack = <String>[hostel.name, hostel.city, hostel.area, hostel.type, hostel.gender, hostel.price, hostel.roomType, hostel.availability, hostel.meals, hostel.description, hostel.address, hostel.website, ...hostel.facilities, ...hostel.rules, ...hostel.rooms.map((room) => room.type)].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
    if (_sort == 'Top Rated') result.sort((a, b) => b.rating.compareTo(a.rating));
    else if (_sort == 'Price Low') result.sort((a, b) => _numberValue(a.price).compareTo(_numberValue(b.price)));
    else if (_sort == 'Price High') result.sort((a, b) => _numberValue(b.price).compareTo(_numberValue(a.price)));
    else if (_sort == 'Nearest') result.sort((a, b) => _numberValue(a.distance).compareTo(_numberValue(b.distance)));
    else result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  double _numberValue(String value) {
    final match = RegExp(r'[-+]?\\d+(?:\\.\\d+)?').firstMatch(value.replaceAll(',', ''));
    return match == null ? double.infinity : double.tryParse(match.group(0)!) ?? double.infinity;
  }

  List<String> _values(
    List<Hostel> hostels,
    String Function(Hostel) getter,
  ) {
    final values = hostels
        .map(getter)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return <String>['All', ...values];
  }

  bool get _hasActiveFilters {
    return _city != 'All' ||
        _gender != 'All' ||
        _type != 'All' ||
        _roomType != 'All' ||
        _acOnly ||
        _sort != 'Recommended';
  }

  void _clearFilters() {
    setState(() {
      _city = 'All';
      _gender = 'All';
      _type = 'All';
      _roomType = 'All';
      _sort = 'Recommended';
      _acOnly = false;
    });
  }

  Future<void> _showFilters() async {
    final cities = _values(_hostels, (hostel) => hostel.city);
    final genders = _values(_hostels, (hostel) => hostel.gender);
    final types = _values(_hostels, (hostel) => hostel.type);
    final rooms = <String>['All', ...HostelRegistry.roomTypes];

    String city = _city;
    String gender = _gender;
    String type = _type;
    String roomType = _roomType;
    String sort = _sort;
    bool acOnly = _acOnly;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
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
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              city = 'All';
                              gender = 'All';
                              type = 'All';
                              roomType = 'All';
                              sort = 'Recommended';
                              acOnly = false;
                            });
                          },
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
                      'Hostel type',
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
                      onSelected: (value) {
                        setSheetState(() => acOnly = value);
                      },
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
                      children: <String>[
                        'Recommended',
                        'Price Low',
                        'Nearest',
                        'Price High',
                        'Top Rated',
                      ].map((value) {
                        return ChoiceChip(
                          label: Text(value),
                          selected: sort == value,
                          onSelected: (_) {
                            setSheetState(() => sort = value);
                          },
                        );
                      }).toList(),
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
                            _sort = sort;
                            _acOnly = acOnly;
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Apply filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
        children: <Widget>[
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
            children: values.map((value) {
              return ChoiceChip(
                label: Text(value),
                selected: selected == value,
                onSelected: (_) => onChanged(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHostels();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Hostels'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Search',
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) _searchController.clear();
              });
            },
            icon: Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Filters',
            onPressed: _showFilters,
            icon: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                const Icon(Icons.tune_rounded),
                if (_hasActiveFilters)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'List your hostel',
            onPressed: () => context.push('/hostels/list'),
            icon: const Icon(Icons.add_business_outlined),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '${filtered.length}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search hostels, cities, areas...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryGreen,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
              ),
            ),
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear filters'),
                ),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _hostelCard(filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            Icon(
              Icons.hotel_outlined,
              size: 54,
              color: AppColors.primaryGreen,
            ),
            SizedBox(height: 12),
            Text(
              'No hostels found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try changing your search or filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hostelCard(Hostel hostel) {
    return Card(
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/hostel/${Uri.encodeComponent(hostel.id)}', extra: hostel),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _hostelImage(hostel),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            hostel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (hostel.isVerified)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _verifiedBadge(),
                          ),
                        if (hostel.reviewCount > 0) ...<Widget>[
                          const SizedBox(width: 2),
                          _rating(hostel.rating, hostel.reviewCount),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      <String>[hostel.area, hostel.city]
                          .where((value) => value.isNotEmpty)
                          .join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: <Widget>[
                        _tag(hostel.type),
                        _tag(hostel.gender),
                        if (hostel.roomType.isNotEmpty) _tag(hostel.roomType),
                        if (hostel.ac) _tag('AC'),
                      ],
                    ),
                    if (hostel.price.isNotEmpty ||
                        hostel.availability.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          if (hostel.price.isNotEmpty)
                            Expanded(
                              child: Text(
                                hostel.price,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (hostel.availability.isNotEmpty)
                            Text(
                              hostel.availability,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (hostel.facilities.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 7),
                      Text(
                        hostel.facilities.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.verified_rounded, size: 13, color: AppColors.primaryGreen),
          SizedBox(width: 3),
          Text('Verified', style: TextStyle(color: AppColors.darkGreen, fontSize: 9, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _hostelImage(Hostel hostel) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: hostel.imageUrl.trim().isEmpty
          ? const Icon(
              Icons.hotel_rounded,
              color: AppColors.primaryGreen,
              size: 34,
            )
          : Image.network(
              hostel.imageUrl.trim(),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => const Icon(
                Icons.hotel_rounded,
                color: AppColors.primaryGreen,
                size: 34,
              ),
            ),
    );
  }

  Widget _tag(String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _rating(double rating, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.star_rounded,
          color: AppColors.primaryGreen,
          size: 16,
        ),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          ' ($count)',
          style: const TextStyle(
            color: AppColors.mutedText,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
