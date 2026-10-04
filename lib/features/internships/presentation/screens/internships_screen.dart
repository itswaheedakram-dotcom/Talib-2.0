import 'package:flutter/material.dart';

class Internship {
  final String title, company, location, field, mode, stipend, duration, deadline, description;
  final List<String> requirements;
  const Internship({required this.title, required this.company, required this.location, required this.field, required this.mode, required this.stipend, required this.duration, required this.deadline, required this.description, required this.requirements});
}

class InternshipsScreen extends StatefulWidget {
  const InternshipsScreen({super.key});
  @override State<InternshipsScreen> createState() => _InternshipsScreenState();
}

class _InternshipsScreenState extends State<InternshipsScreen> {
  final _search = TextEditingController();
  String _field = 'All';
  String _mode = 'All';
  bool _paidOnly = false;

  final List<Internship> _items = const [
    Internship(title: 'Flutter Developer Intern', company: 'TechNova Solutions', location: 'Lahore', field: 'Software', mode: 'Hybrid', stipend: 'Rs. 25,000/month', duration: '3 months', deadline: '30 Nov 2026', description: 'Work with a development team to build and improve Flutter applications.', requirements: ['Basic Flutter and Dart', 'Git fundamentals', 'Problem-solving skills']),
    Internship(title: 'UI/UX Design Intern', company: 'PixelCraft Studio', location: 'Lahore', field: 'Design', mode: 'On-site', stipend: 'Rs. 20,000/month', duration: '3 months', deadline: '15 Dec 2026', description: 'Assist designers with mobile and web product experiences and design systems.', requirements: ['Figma basics', 'UI design fundamentals', 'Portfolio preferred']),
    Internship(title: 'Digital Marketing Intern', company: 'GrowthHub', location: 'Remote', field: 'Marketing', mode: 'Remote', stipend: 'Paid', duration: '2 months', deadline: '10 Dec 2026', description: 'Support social media, content, SEO and digital campaign activities.', requirements: ['Communication skills', 'Social media knowledge', 'Content writing basics']),
    Internship(title: 'Finance Intern', company: 'Prime Advisory', location: 'Islamabad', field: 'Finance', mode: 'On-site', stipend: 'Unpaid', duration: '6 weeks', deadline: '05 Dec 2026', description: 'Gain practical exposure to financial analysis, reporting and business research.', requirements: ['B.Com/BBA/Finance student', 'Excel basics', 'Analytical mindset']),
    Internship(title: 'Electrical Engineering Intern', company: 'PowerTech Industries', location: 'Multan', field: 'Engineering', mode: 'On-site', stipend: 'Rs. 30,000/month', duration: '4 months', deadline: '20 Dec 2026', description: 'Learn practical engineering workflows through supervised industrial projects.', requirements: ['Engineering student', 'Basic technical knowledge', 'Safety awareness']),
    Internship(title: 'Backend Developer Intern', company: 'CodeWorks', location: 'Remote', field: 'Software', mode: 'Remote', stipend: 'Rs. 25,000/month', duration: '3 months', deadline: '25 Nov 2026', description: 'Help develop APIs and backend services while learning production development practices.', requirements: ['Node.js or similar', 'REST API basics', 'Database fundamentals']),
  ];

  List<Internship> get _filtered {
    final q=_search.text.trim().toLowerCase();
    return _items.where((x) => (q.isEmpty || '${x.title} ${x.company} ${x.location} ${x.field}'.toLowerCase().contains(q)) && (_field=='All' || x.field==_field) && (_mode=='All' || x.mode==_mode) && (!_paidOnly || x.stipend != 'Unpaid')).toList();
  }

  void _details(Internship x) {
    showModalBottomSheet(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(x.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6), Text(x.company, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16), Wrap(spacing: 8, runSpacing: 8, children: [_chip(Icons.location_on_outlined,x.location), _chip(Icons.laptop_mac_outlined,x.mode), _chip(Icons.payments_outlined,x.stipend), _chip(Icons.schedule_outlined,x.duration)]),
      const SizedBox(height: 20), Text('About the internship', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(x.description),
      const SizedBox(height: 18), Text('Requirements', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), ...x.requirements.map((r)=>ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle_outline), title: Text(r))),
      const SizedBox(height: 8), Text('Application deadline: ${x.deadline}', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 16), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.send_outlined), label: const Text('Apply Now'))),
    ])))));
  }

  Widget _chip(IconData icon,String text) => Chip(avatar: Icon(icon,size:17),label: Text(text));

  @override Widget build(BuildContext context) {
    final data=_filtered;
    return Scaffold(appBar: AppBar(title: const Text('Internships'), actions: [IconButton(onPressed: () => _showFilters(), icon: const Icon(Icons.tune))]), body: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: TextField(controller: _search, onChanged: (_)=>setState((){}), decoration: InputDecoration(hintText: 'Search internships, companies...', prefixIcon: const Icon(Icons.search), suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: ()=>setState(()=>_search.clear()), icon: const Icon(Icons.clear)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))))),
      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: ['All','Software','Design','Marketing','Finance','Engineering'].map((v)=>Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(v), selected: _field==v, onSelected: (_)=>setState(()=>_field=v)))).toList())),
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Row(children: [Text('${data.length} opportunities', style: const TextStyle(fontWeight: FontWeight.w600)), const Spacer(), if (_mode!='All' || _paidOnly) TextButton(onPressed: ()=>setState((){_mode='All';_paidOnly=false;}), child: const Text('Clear filters'))])),
      Expanded(child: data.isEmpty ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.work_off_outlined,size:56), SizedBox(height:12), Text('No internships found'), SizedBox(height:4), Text('Try changing your search or filters.')])) : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), itemCount: data.length, itemBuilder: (_,i){final x=data[i]; return Card(margin: const EdgeInsets.only(bottom: 12), child: InkWell(borderRadius: BorderRadius.circular(16), onTap: ()=>_details(x), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(x.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))), const Icon(Icons.chevron_right)]), const SizedBox(height: 5), Text(x.company), const SizedBox(height: 12), Wrap(spacing: 6, runSpacing: 6, children: [Chip(label: Text(x.field)), Chip(label: Text(x.mode)), Chip(label: Text(x.stipend))]), const SizedBox(height: 6), Row(children: [const Icon(Icons.location_on_outlined,size:17), const SizedBox(width:4), Text(x.location), const Spacer(), Text('Due ${x.deadline}', style: Theme.of(context).textTheme.bodySmall)])]))));}) )
    ]));
  }

  void _showFilters() {
    showModalBottomSheet(context: context, showDragHandle: true, builder: (_) => StatefulBuilder(builder: (context,setSheet) => Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Filter internships', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16), Text('Work mode', style: Theme.of(context).textTheme.titleMedium),
      Wrap(spacing: 8, children: ['All','Remote','Hybrid','On-site'].map((v)=>ChoiceChip(label: Text(v), selected: _mode==v, onSelected: (_){setSheet((){});setState(()=>_mode=v);})).toList()),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Paid internships only'), value: _paidOnly, onChanged: (v){setSheet((){});setState(()=>_paidOnly=v);}),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: ()=>Navigator.pop(context), child: const Text('Apply Filters'))),
    ]))));
  }
}