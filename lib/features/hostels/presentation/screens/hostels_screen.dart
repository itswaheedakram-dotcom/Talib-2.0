import 'package:flutter/material.dart';

class Hostel {
  final String name;
  final String city;
  final String area;
  final String type;
  final String gender;
  final String distance;
  final String price;
  final String facilities;
  final String description;

  const Hostel({
    required this.name,
    required this.city,
    required this.area,
    required this.type,
    required this.gender,
    required this.distance,
    required this.price,
    required this.facilities,
    required this.description,
  });
}

class HostelsScreen extends StatefulWidget {
  const HostelsScreen({super.key});

  @override
  State<HostelsScreen> createState() => _HostelsScreenState();
}

class _HostelsScreenState extends State<HostelsScreen> {
  final _searchController = TextEditingController();
  String _city = 'All';
  String _gender = 'All';
  String _type = 'All';

  static const _hostels = <Hostel>[
    Hostel(name: 'Student Residency Lahore', city: 'Lahore', area: 'Johar Town', type: 'Private', gender: 'Male', distance: '1.2 km from university area', price: 'PKR 18,000 / month', facilities: 'Wi-Fi • Mess • Laundry • Security', description: 'A student-focused residence with furnished rooms and convenient access to major educational institutions.'),
    Hostel(name: 'Girls Campus Hostel', city: 'Lahore', area: 'Gulberg', type: 'Private', gender: 'Female', distance: '0.8 km from campus', price: 'PKR 20,000 / month', facilities: 'Wi-Fi • Mess • CCTV • Study room', description: 'A secure residence designed for female students, with study spaces and essential daily facilities.'),
    Hostel(name: 'Punjab University Hostel', city: 'Lahore', area: 'New Campus', type: 'University', gender: 'Male', distance: 'On campus', price: 'PKR 8,500 / month', facilities: 'Mess • Library access • Sports • Security', description: 'University accommodation option for eligible students, subject to institutional admission and hostel policies.'),
    Hostel(name: 'Bahawalpur Student House', city: 'Bahawalpur', area: 'University Chowk', type: 'Private', gender: 'Male', distance: '2.0 km from university area', price: 'PKR 12,000 / month', facilities: 'Wi-Fi • Mess • Parking • Security', description: 'Affordable student accommodation near the main university area with shared and private room options.'),
    Hostel(name: 'IUB Girls Residence', city: 'Bahawalpur', area: 'Baghdad-ul-Jadeed', type: 'University', gender: 'Female', distance: 'On campus', price: 'PKR 9,000 / month', facilities: 'Mess • Study area • Security • Laundry', description: 'Campus residence for female students at the university, subject to availability and eligibility.'),
    Hostel(name: 'Multan Scholars Hostel', city: 'Multan', area: 'Bosan Road', type: 'Private', gender: 'Male', distance: '1.5 km from campus', price: 'PKR 14,000 / month', facilities: 'Wi-Fi • Mess • Generator • CCTV', description: 'A practical residence for students studying around Bosan Road and nearby educational institutions.'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Hostel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _hostels.where((item) {
      final text = (item.name + ' ' + item.city + ' ' + item.area + ' ' + item.facilities).toLowerCase();
      return (query.isEmpty || text.contains(query)) &&
          (_city == 'All' || item.city == _city) &&
          (_gender == 'All' || item.gender == _gender) &&
          (_type == 'All' || item.type == _type);
    }).toList();
  }

  void _showDetails(Hostel hostel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hostel.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                Chip(label: Text(hostel.type)),
                Chip(label: Text(hostel.gender)),
              ]),
              const SizedBox(height: 12),
              _row(Icons.location_on_outlined, hostel.area + ', ' + hostel.city),
              _row(Icons.near_me_outlined, hostel.distance),
              _row(Icons.payments_outlined, hostel.price),
              _row(Icons.apartment_outlined, hostel.facilities),
              const SizedBox(height: 14),
              Text('About this hostel', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(hostel.description),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Contact Hostel'),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(value)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('Hostels')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search hostels, cities, areas...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.clear)),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ),
          _chips('City', ['All', 'Lahore', 'Bahawalpur', 'Multan'], _city, (v) => setState(() => _city = v)),
          _chips('Gender', ['All', 'Male', 'Female'], _gender, (v) => setState(() => _gender = v)),
          _chips('Type', ['All', 'Private', 'University'], _type, (v) => setState(() => _type = v)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Row(children: [
              Text(items.length.toString() + ' hostels', style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              if (_city != 'All' || _gender != 'All' || _type != 'All')
                TextButton(onPressed: () => setState(() { _city = 'All'; _gender = 'All'; _type = 'All'; }), child: const Text('Clear filters')),
            ]),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.hotel_outlined, size: 56),
                    SizedBox(height: 12),
                    Text('No hostels found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Text('Try another search or filter.'),
                  ]))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final hostel = items[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showDetails(hostel),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(hostel.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                                const Icon(Icons.chevron_right),
                              ]),
                              const SizedBox(height: 8),
                              Text(hostel.area + ', ' + hostel.city),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                Chip(label: Text(hostel.type)),
                                Chip(label: Text(hostel.gender)),
                              ]),
                              const SizedBox(height: 6),
                              _row(Icons.payments_outlined, hostel.price),
                              _row(Icons.apartment_outlined, hostel.facilities),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chips(String label, List<String> values, String selected, ValueChanged<String> onChanged) {
    return SizedBox(
      height: 50,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: values.map((value) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(value),
            selected: selected == value,
            onSelected: (_) => onChanged(value),
          ),
        )).toList(),
      ),
    );
  }
}