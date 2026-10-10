import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../models/institute.dart';
import '../../../models/institute_opportunity.dart';
import '../../data/institute_access.dart';
import '../../data/institute_opportunity_repository.dart';
import 'institute_opportunity_card.dart';

/// Displays all offerings in the institute's existing detail-page scroll.
class InstituteDetailListings extends StatefulWidget {
  final Institute institute;
  const InstituteDetailListings({super.key, required this.institute});

  @override
  State<InstituteDetailListings> createState() =>
      _InstituteDetailListingsState();
}

class _InstituteDetailListingsState extends State<InstituteDetailListings> {
  final _repository = InstituteOpportunityRepository.instance;
  bool _loading = true;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_changed);
    ActiveProfileController.instance.addListener(_reload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  void didUpdateWidget(InstituteDetailListings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.institute.id != widget.institute.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reload();
      });
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _repository.load(widget.institute.id);
    if (!mounted || generation != _generation) return;
    setState(() {
      _loading = false;
      _error = _repository.error;
    });
  }

  @override
  void dispose() {
    _repository.removeListener(_changed);
    ActiveProfileController.instance.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _repository.forInstitute(widget.institute.id);
    final courses = items.where((item) => item.kind == 'course').toList();
    final admissions = items
        .where(
          (item) =>
              item.kind == 'admission' &&
              const {
                'open',
                'upcoming',
              }.contains(item.status.trim().toLowerCase()),
        )
        .toList();
    final scholarships = items
        .where((item) => item.kind == 'scholarship')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Could not load institute listings. Please retry.',
                  ),
                  TextButton(onPressed: _reload, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        _section(
          context,
          title: 'Programs / Courses',
          kind: 'course',
          items: courses,
          emptyMessage: 'No programs or courses listed yet.',
          programs: widget.institute.programs,
        ),
        const SizedBox(height: 10),
        _section(
          context,
          title: 'Admissions — Open & Upcoming',
          kind: 'admission',
          items: admissions,
          emptyMessage: 'No open or upcoming admissions listed yet.',
        ),
        const SizedBox(height: 10),
        _section(
          context,
          title: 'Scholarships',
          kind: 'scholarship',
          items: scholarships,
          emptyMessage: 'No scholarships listed yet.',
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required String kind,
    required List<InstituteOpportunity> items,
    required String emptyMessage,
    List<String> programs = const [],
  }) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (InstituteAccess.canManage(widget.institute))
                IconButton(
                  tooltip: 'Manage $title',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push(
                    '/institute/${widget.institute.id}/opportunities?kind=$kind',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          if (programs.isNotEmpty) ...[
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: programs
                  .map(
                    (program) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softGreen,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        program,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (items.isNotEmpty) const SizedBox(height: 8),
          ],
          for (final item in items) InstituteOpportunityCard(item: item),
          if (items.isEmpty && programs.isEmpty && !_loading && _error == null)
            Text(emptyMessage),
        ],
      ),
    ),
  );
}
