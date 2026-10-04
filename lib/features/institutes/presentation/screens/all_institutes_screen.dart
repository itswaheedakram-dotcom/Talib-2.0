import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AllInstitutesScreen extends StatefulWidget {
  const AllInstitutesScreen({super.key});
  @override
  State<AllInstitutesScreen> createState() => _AllInstitutesScreenState();
}

class _AllInstitutesScreenState extends State<AllInstitutesScreen> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00A66A);
    const darkGreen = Color(0xFF00543D);
    final categories = const [
      ('Schools', 'schools', Icons.school_rounded),
      ('Colleges', 'colleges', Icons.account_balance_rounded),
      ('Universities', 'universities', Icons.account_balance_rounded),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institutes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 19),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
        children: [
          const Text(
            'Institutes',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: darkGreen),
          ),
          const SizedBox(height: 5),
          const Text(
            'Explore schools, colleges and universities.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          ...categories.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _InstituteCategoryCard(
                  title: item.$1,
                  icon: item.$3,
                  onTap: () => context.push('/institutes/${item.$2}'),
                ),
              )),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_expanded) ...[
            _MiniAction(label: 'Find Institute', icon: Icons.search, onTap: () => context.push('/find')),
            const SizedBox(height: 9),
            _MiniAction(label: 'Add Institute', icon: Icons.add_business_outlined, onTap: () => context.push('/find')),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: 'institute_actions',
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Icon(_expanded ? Icons.close : Icons.add),
          ),
        ],
      ),
    );
  }
}

class _InstituteCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _InstituteCategoryCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00A66A);
    return Material(
      color: green,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 145,
          child: Stack(
            children: [
              Positioned(
                right: 18,
                bottom: 10,
                child: Icon(icon, size: 88, color: Colors.white.withOpacity(.18)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
                    Row(
                      children: const [
                        Text('Browse institutes', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Spacer(),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MiniAction({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 19, color: const Color(0xFF00543D)),
              const SizedBox(width: 7),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}
