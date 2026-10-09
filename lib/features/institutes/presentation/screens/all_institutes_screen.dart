import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../models/institute.dart';
import '../../data/institute_catalog.dart';
import '../../data/institute_repository.dart';

class AllInstitutesScreen extends StatefulWidget {
  const AllInstitutesScreen({super.key});

  @override
  State<AllInstitutesScreen> createState() => _AllInstitutesScreenState();
}

class _AllInstitutesScreenState extends State<AllInstitutesScreen> {
  final _catalog = InstituteCatalog.instance;
  final _repository = InstituteRepository.instance;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _catalog.addListener(_onChanged);
    _repository.addListener(_onChanged);
    _catalog.load();
    _repository.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _catalog.removeListener(_onChanged);
    _repository.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _catalog.types;
    final institutes = _repository.items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Institutes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 19),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_catalog.load(), _repository.load()]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
          children: [
            Text('Explore education', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(
              'Find schools, colleges, universities, academies and specialist training institutes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            if (_repository.loading || _catalog.loading)
              const LinearProgressIndicator(minHeight: 2),
            if (_repository.error != null)
              _InlineError(message: 'Institute data could not be refreshed. Pull down to retry.'),
            if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No institute categories are currently available.'),
              )
            else
              ...categories.map((category) {
                final count = institutes.where((item) => item.type == category.id).length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InstituteCategoryCard(
                    title: category.label,
                    count: count,
                    icon: category.icon,
                    onTap: () => context.push('/institutes/${category.id}'),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_expanded) ...[
            _MiniAction(
              label: 'Find Institute',
              icon: Icons.search,
              onTap: () => context.push('/find'),
            ),
            const SizedBox(height: 9),
            _MiniAction(
              label: 'Add Institute',
              icon: Icons.add_business_outlined,
              onTap: () => context.push('/add-institute/all'),
            ),
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
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  const _InstituteCategoryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.primaryGreen,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 132,
        child: Stack(
          children: [
            Positioned(
              right: 18,
              bottom: 10,
              child: Icon(icon, size: 82, color: AppColors.white.withOpacity(.18)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  )),
                  Row(children: [
                    Text('$count listed', style: const TextStyle(color: AppColors.white70)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.white, size: 22),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MiniAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.white,
    elevation: 3,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 19, color: AppColors.darkGreen),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(
            color: AppColors.darkGreen,
            fontWeight: FontWeight.w600,
          )),
        ]),
      ),
    ),
  );
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
  );
}
