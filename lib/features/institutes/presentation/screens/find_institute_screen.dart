import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FindInstituteScreen extends StatefulWidget {
  const FindInstituteScreen({super.key});
  @override State<FindInstituteScreen> createState() => _FindInstituteScreenState();
}

class _FindInstituteScreenState extends State<FindInstituteScreen> {
  final _searchController = TextEditingController();
  String _type = 'All', _city = 'All cities', _program = 'All programs';

  static const _institutes = [
    _Item('school-1', 'The Educators', 'School', 'Lahore', ['Matric', 'Intermediate']),
    _Item('school-2', 'Beaconhouse School System', 'School', 'Lahore', ['Matric', 'Intermediate']),
    _Item('college-1', 'Government College Lahore', 'College', 'Lahore', ['ICS', 'I.Com', 'FA', 'FSc']),
    _Item('college-2', 'Government College of Science', 'College', 'Lahore', ['FSc', 'ICS']),
    _Item('university-1', 'University of the Punjab', 'University', 'Lahore', ['BS', 'MS', 'MPhil', 'PhD']),
    _Item('university-2', 'Islamia University Bahawalpur', 'University', 'Bahawalpur', ['BS', 'MS', 'MPhil', 'PhD']),
  ];

  List<_Item> get _results {
    final q = _searchController.text.trim().toLowerCase();
    return _institutes.where((i) {
      final search = q.isEmpty || i.name.toLowerCase().contains(q) ||
          i.city.toLowerCase().contains(q) ||
          i.programs.any((p) => p.toLowerCase().contains(q));
      return search && (_type == 'All' || i.type == _type) &&
          (_city == 'All cities' || i.city == _city) &&
          (_program == 'All programs' || i.programs.contains(_program));
    }).toList();
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      builder: (context) => StatefulBuilder(builder: (context, sheetSet) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Wrap(runSpacing: 18, children: [
          Text('Filters', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          _Group('Institute type', const ['All', 'School', 'College', 'University'], _type, (v) => sheetSet(() => _type = v)),
          _Group('City', const ['All cities', 'Lahore', 'Multan', 'Bahawalpur', 'Islamabad'], _city, (v) => sheetSet(() => _city = v)),
          _Group('Program', const ['All programs', 'Matric', 'Intermediate', 'ICS', 'I.Com', 'FA', 'FSc', 'BS', 'MS', 'MPhil', 'PhD'], _program, (v) => sheetSet(() => _program = v)),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () {
              setState(() { _type = 'All'; _city = 'All cities'; _program = 'All programs'; });
              Navigator.pop(context);
            }, child: const Text('Clear all'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () { setState(() {}); Navigator.pop(context); }, child: const Text('Show results'))),
          ]),
        ]),
      )),
    );
  }

  @override void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: const Text('Find Institute'), actions: [
        IconButton(onPressed: _showFilters, icon: const Icon(Icons.tune), tooltip: 'Filters'),
      ]),
      body: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: SliverList(delegate: SliverChildListDelegate([
            Text('Find the right institute', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Search by name, city or program, then narrow the results with filters.'),
            const SizedBox(height: 18),
            SearchBar(
              controller: _searchController,
              hintText: 'Search institute, city or program',
              leading: const Icon(Icons.search),
              trailing: [if (_searchController.text.isNotEmpty) IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.clear))],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('Type: $_type', _type != 'All'),
              _chip('City: $_city', _city != 'All cities'),
              _chip('Program: $_program', _program != 'All programs'),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Text('${results.length} institutes found', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton.icon(onPressed: _showFilters, icon: const Icon(Icons.tune, size: 18), label: const Text('Filters')),
            ]),
          ])),
        ),
        if (results.isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search_off_rounded, size: 52), SizedBox(height: 12),
              Text('No matching institutes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 6), Text('Try another search or clear one of the filters.', textAlign: TextAlign.center),
            ]),
          )))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final i = results[index];
                return Padding(padding: const EdgeInsets.only(bottom: 12), child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/institute/${i.id}'),
                    child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CircleAvatar(radius: 25, child: Icon(_icon(i.type))),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(i.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text('${i.type} • ${i.city}'),
                        const SizedBox(height: 9),
                        Wrap(spacing: 6, runSpacing: 6, children: i.programs.take(3).map((p) => Chip(label: Text(p), visualDensity: VisualDensity.compact)).toList()),
                      ])),
                      const Icon(Icons.chevron_right),
                    ])),
                  ),
                ));
              },
            ),
          ),
      ]),
    );
  }

  Widget _chip(String label, bool active) => Chip(
    avatar: Icon(active ? Icons.check : Icons.filter_alt_outlined, size: 16),
    label: Text(label),
  );

  IconData _icon(String type) => switch (type) {
    'School' => Icons.school_outlined,
    'College' => Icons.account_balance_outlined,
    _ => Icons.account_balance,
  };
}

class _Group extends StatelessWidget {
  final String title, selected;
  final List<String> values;
  final ValueChanged<String> onChanged;
  const _Group(this.title, this.values, this.selected, this.onChanged);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    Wrap(spacing: 8, runSpacing: 8, children: values.map((v) => ChoiceChip(label: Text(v), selected: selected == v, onSelected: (_) => onChanged(v))).toList()),
  ]);
}

class _Item {
  final String id, name, type, city;
  final List<String> programs;
  const _Item(this.id, this.name, this.type, this.city, this.programs);
}
