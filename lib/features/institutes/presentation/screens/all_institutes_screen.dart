import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AllInstitutesScreen extends StatelessWidget {
  const AllInstitutesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = const [
      ('Schools', 'Primary, middle & high schools', Icons.school_rounded, 'schools'),
      ('Colleges', 'Intermediate & degree colleges', Icons.account_balance_rounded, 'colleges'),
      ('Universities', 'Universities & higher education', Icons.castle_rounded, 'universities'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('All Institutes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text('Find an institute', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Choose an institute category to browse available institutions.'),
          const SizedBox(height: 20),
          ...categories.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.push('/institutes/' + item.$4),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Container(width: 52, height: 52, decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(15)), child: Icon(item.$3, color: scheme.primary)),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.$1, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(item.$2, style: const TextStyle(color: Colors.black54)),
                    ])),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
