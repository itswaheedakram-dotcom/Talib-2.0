import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/institute.dart';

class InstituteListScreen extends StatefulWidget {
  final String type;
  const InstituteListScreen({super.key, required this.type});
  @override
  State<InstituteListScreen> createState() => _InstituteListScreenState();
}

class _InstituteListScreenState extends State<InstituteListScreen> {
  final _search = TextEditingController();
  String _city = 'All cities';
  static const _cities = ['All cities', 'Lahore', 'Multan', 'Bahawalpur', 'Islamabad'];
  static const _data = <Institute>[
    Institute(id: 'school-1', name: 'The Educators', type: 'schools', city: 'Lahore', address: 'Lahore, Punjab', description: 'A school offering foundational and secondary education.', programs: ['Primary', 'Middle', 'Matric']),
    Institute(id: 'school-2', name: 'Beaconhouse School System', type: 'schools', city: 'Lahore', address: 'Lahore, Punjab', description: 'A private school network providing education from early years through secondary levels.', programs: ['Early Years', 'Primary', 'Secondary']),
    Institute(id: 'college-1', name: 'Government College Lahore', type: 'colleges', city: 'Lahore', address: 'Lahore, Punjab', description: 'A historic public college offering intermediate and degree programs.', programs: ['FA', 'FSc', 'ICS', 'BS']),
    Institute(id: 'college-2', name: 'Government College of Science', type: 'colleges', city: 'Lahore', address: 'Lahore, Punjab', description: 'A public institution focused on science and degree education.', programs: ['FSc', 'BS']),
    Institute(id: 'university-1', name: 'University of the Punjab', type: 'universities', city: 'Lahore', address: 'Quaid-e-Azam Campus, Lahore', description: 'A major public university with a broad range of academic disciplines.', programs: ['Undergraduate', 'Graduate', 'PhD']),
    Institute(id: 'university-2', name: 'Islamia University Bahawalpur', type: 'universities', city: 'Bahawalpur', address: 'Bahawalpur, Punjab', description: 'A public-sector university serving students across multiple disciplines.', programs: ['Undergraduate', 'Graduate', 'PhD']),
  ];
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  List<Institute> get _filtered => _data.where((i) {
    final q = _search.text.trim().toLowerCase();
    return i.type == widget.type && (q.isEmpty || i.name.toLowerCase().contains(q) || i.city.toLowerCase().contains(q)) && (_city == 'All cities' || i.city == _city);
  }).toList();
  String get _title => switch (widget.type) { 'schools' => 'Schools', 'colleges' => 'Colleges', 'universities' => 'Universities', _ => 'Institutes' };
  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: 'Search ' + _title, prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded))),
          ),
        ),
        SizedBox(height: 50, child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20), scrollDirection: Axis.horizontal, itemCount: _cities.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) => ChoiceChip(label: Text(_cities[index]), selected: _city == _cities[index], onSelected: (_) => setState(() => _city = _cities[index])),
        )),
        const SizedBox(height: 8),
        Expanded(child: items.isEmpty ? const Center(child: Text('No institutes found')) : ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final institute = items[index];
            return Card(child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(child: Icon(_iconFor(widget.type))),
              title: Text(institute.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(institute.city + ' • ' + institute.programs.take(2).join(', ')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/institute/${institute.id}'),
            ));
          },
        )),
      ]),
    );
  }
  IconData _iconFor(String type) => switch (type) { 'schools' => Icons.school_rounded, 'colleges' => Icons.account_balance_rounded, _ => Icons.castle_rounded };
}
