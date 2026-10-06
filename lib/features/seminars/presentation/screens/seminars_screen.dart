import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/database_service.dart';

class Seminar {
  final String title;
  final String category;
  final String date;
  final String time;
  final String location;
  final String mode;
  final String speaker;
  final String description;

  const Seminar({required this.title, required this.category, required this.date, required this.time, required this.location, required this.mode, required this.speaker, required this.description});
}

class SeminarsScreen extends StatefulWidget {
  const SeminarsScreen({super.key});
  @override State<SeminarsScreen> createState() => _SeminarsScreenState();
}

class _SeminarsScreenState extends State<SeminarsScreen> {
  final _searchController = TextEditingController();
  String _category = 'All';
  String _mode = 'All';

  static const _seminars = <Seminar>[
    Seminar(title: 'Future of Artificial Intelligence', category: 'Technology', date: '18 Oct 2026', time: '11:00 AM', location: 'Lahore', mode: 'Online', speaker: 'Dr. Ali Raza', description: 'Explore practical AI trends, careers, and the skills students need for the next generation of technology.'),
    Seminar(title: 'Career Planning After Graduation', category: 'Career', date: '22 Oct 2026', time: '2:00 PM', location: 'Bahawalpur', mode: 'In-person', speaker: 'Ayesha Khan', description: 'A practical session on choosing career paths, building a strong CV, networking, and preparing for interviews.'),
    Seminar(title: 'University Admissions Guide', category: 'Admissions', date: '25 Oct 2026', time: '4:00 PM', location: 'Online', mode: 'Online', speaker: 'Admissions Experts', description: 'Learn about admission requirements, application planning, scholarships, and common mistakes to avoid.'),
    Seminar(title: 'Freelancing Skills for Students', category: 'Skills', date: '29 Oct 2026', time: '12:30 PM', location: 'Multan', mode: 'In-person', speaker: 'Usman Ahmed', description: 'Learn how students can build digital skills, find clients, and start freelancing responsibly.'),
    Seminar(title: 'Entrepreneurship & Business Basics', category: 'Business', date: '02 Nov 2026', time: '6:00 PM', location: 'Lahore', mode: 'Online', speaker: 'Hamza Malik', description: 'An introduction to business ideas, validation, customer discovery, and building a sustainable startup.'),
    Seminar(title: 'Web Development Masterclass', category: 'Technology', date: '07 Nov 2026', time: '10:00 AM', location: 'Lahore', mode: 'In-person', speaker: 'Software Engineering Panel', description: 'A beginner-friendly masterclass covering modern web development and a roadmap from learning to employment.'),
  ];

  @override void dispose() { _searchController.dispose(); super.dispose(); }

  List<Seminar> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _seminars.where((item) {
      final matchesQuery = query.isEmpty || item.title.toLowerCase().contains(query) || item.category.toLowerCase().contains(query) || item.speaker.toLowerCase().contains(query) || item.location.toLowerCase().contains(query);
      return matchesQuery && (_category == 'All' || item.category == _category) && (_mode == 'All' || item.mode == _mode);
    }).toList();
  }

  void _showDetails(Seminar seminar) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (context) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(seminar.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [Chip(label: Text(seminar.category)), Chip(label: Text(seminar.mode))]),
      const SizedBox(height: 12),
      _detailRow(Icons.calendar_month_outlined, seminar.date), _detailRow(Icons.schedule_outlined, seminar.time), _detailRow(Icons.location_on_outlined, seminar.location), _detailRow(Icons.person_outline, seminar.speaker),
      const SizedBox(height: 14),
      Text('About this seminar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6), Text(seminar.description), const SizedBox(height: 20),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _registerInterest(seminar), icon: const Icon(Icons.how_to_reg_outlined), label: const Text('Register Interest'))),
    ]))));
  }

  Future<void> _registerInterest(Seminar seminar) async { Navigator.pop(context); final user=AuthService().currentUser; if(user==null){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please sign in to register.')));return;} final id=seminar.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'),'_'); await DatabaseService().saveInterest(seminarId:id,title:seminar.title,userId:user.uid,userName:user.displayName??user.email??'Student'); if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Interest registered successfully.'))); }

  Widget _detailRow(IconData icon, String text) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20), const SizedBox(width: 10), Expanded(child: Text(text))]));

  @override Widget build(BuildContext context) {
    final items = _filtered;
    final categories = ['All', 'Technology', 'Career', 'Admissions', 'Skills', 'Business'];
    return Scaffold(appBar: AppBar(title: const Text('Seminars')), body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 6), child: SearchBar(controller: _searchController, hintText: 'Search seminars, topics, speakers...', leading: const Icon(Icons.search), trailing: [if (_searchController.text.isNotEmpty) IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.clear))], onChanged: (_) => setState(() {}))),
      SizedBox(height: 54, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), scrollDirection: Axis.horizontal, itemCount: categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (context, index) { final value = categories[index]; return ChoiceChip(label: Text(value), selected: _category == value, onSelected: (_) => setState(() => _category = value)); })),
      SizedBox(height: 50, child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, children: ['All', 'Online', 'In-person'].map((value) => Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(value), selected: _mode == value, onSelected: (_) => setState(() => _mode = value)))).toList())),
      Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), child: Row(children: [Text(items.length.toString() + ' seminars', style: Theme.of(context).textTheme.labelLarge), const Spacer(), if (_category != 'All' || _mode != 'All') TextButton(onPressed: () => setState(() { _category = 'All'; _mode = 'All'; }), child: const Text('Clear filters'))])),
      Expanded(child: items.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.event_busy_outlined, size: 56), SizedBox(height: 12), Text('No seminars found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), SizedBox(height: 6), Text('Try another search or filter.')]))) : ListView.separated(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) { final seminar = items[index]; return Card(child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => _showDetails(seminar), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(seminar.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))), const SizedBox(width: 8), Icon(seminar.mode == 'Online' ? Icons.wifi : Icons.location_city_outlined)]),
        const SizedBox(height: 10), Wrap(spacing: 8, children: [Chip(label: Text(seminar.category)), Chip(label: Text(seminar.mode))]),
        const SizedBox(height: 8), _detailRow(Icons.calendar_today_outlined, seminar.date + ' • ' + seminar.time), _detailRow(Icons.location_on_outlined, seminar.location), _detailRow(Icons.person_outline, seminar.speaker),
      ])))); })),
    ]));
  }
}