import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DisciplineInfoScreen extends StatefulWidget {
  final String instituteId;
  const DisciplineInfoScreen({super.key, required this.instituteId});
  @override State<DisciplineInfoScreen> createState() => _DisciplineInfoScreenState();
}

class _DisciplineInfoScreenState extends State<DisciplineInfoScreen> {
  final _subject = TextEditingController();
  final List<Map<String, String>> _programs = [
    {'name': 'BS Computer Science', 'duration': '4 year', 'fee': 'Rs. 65,000 / semester'},
    {'name': 'BS Software Engineering', 'duration': '4 year', 'fee': 'Rs. 62,000 / semester'},
    {'name': 'BS Information Technology', 'duration': '4 year', 'fee': 'Rs. 58,000 / semester'},
  ];

  @override void dispose() { _subject.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    const green = Color(0xFF00A66A);
    const darkGreen = Color(0xFF00543D);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
        title: const Text('Add Programs'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: const [
            Text('Details', style: TextStyle(color: darkGreen, fontWeight: FontWeight.w600)),
            SizedBox(width: 8),
            Switch(value: true, onChanged: null),
          ]),
          ..._programs.map((p) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Container(width: 8, height: 58, decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(8))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.w700, color: darkGreen)),
                  const SizedBox(height: 5),
                  Text((p['duration'] ?? '') + '  •  ' + (p['fee'] ?? ''), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ])),
                const Icon(Icons.chevron_right, color: green),
              ]),
            ),
          )),
          Row(children: [
            Expanded(child: TextField(controller: _subject, decoration: const InputDecoration(hintText: 'Discipline / Area of Study', prefixIcon: Icon(Icons.menu_book_outlined)))),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'add_program',
              backgroundColor: green,
              foregroundColor: Colors.white,
              onPressed: () {
                if (_subject.text.trim().isEmpty) return;
                setState(() {
                  _programs.add({'name': _subject.text.trim(), 'duration': '4 year', 'fee': 'Fee per semester'});
                  _subject.clear();
                });
              },
              child: const Icon(Icons.add),
            ),
          ]),
        ],
      ),
    );
  }
}
