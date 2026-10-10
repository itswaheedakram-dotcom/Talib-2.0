import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/active_profile_controller.dart';
import '../../../models/institute.dart';
import '../../../models/institute_opportunity.dart';
import '../../data/institute_access.dart';
import '../../data/institute_opportunity_repository.dart';
import 'institute_opportunity_card.dart';
import 'institute_detail_components.dart';
import 'institute_program_groups.dart';

/// Displays all offerings in the institute's existing detail-page scroll.
class InstituteDetailListings extends StatefulWidget {
  final Institute institute;
  final Map<String, Key> sectionKeys;
  final Widget? admissionOverview;
  const InstituteDetailListings({
    super.key,
    required this.institute,
    this.sectionKeys = const {},
    this.admissionOverview,
  });

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
    final admissions = items.where((item) => item.hasActiveAdmissions).toList();
    admissions.sort((a, b) {
      final priority = (a.displayStatus == 'Open' ? 0 : 1).compareTo(
        b.displayStatus == 'Open' ? 0 : 1,
      );
      if (priority != 0) return priority;
      final aDate = DateTime.tryParse(a.openingDate) ?? DateTime(9999);
      final bDate = DateTime.tryParse(b.openingDate) ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
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
          items: courses.where((item) => item.programKeys.isEmpty).toList(),
          emptyMessage: 'No programs or courses listed yet.',
          programs: widget.institute.programCategories,
        ),
        const SizedBox(height: 10),
        _section(
          context,
          title: 'Admissions',
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
  }) => InstituteDetailSection(
    key: widget.sectionKeys[kind],
    title: title,
    icon: switch (kind) {
      'course' => Icons.school_outlined,
      'scholarship' => Icons.workspace_premium_outlined,
      _ => Icons.calendar_month_outlined,
    },
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InstituteDetailBadge(
          label:
              '${(kind == 'course' && widget.institute.programGroups.isNotEmpty ? widget.institute.programGroups.values.fold<int>(0, (count, names) => count + names.length) : programs.length) + items.length}',
        ),
        if (InstituteAccess.canManage(widget.institute))
          IconButton(
            tooltip: 'Manage $title',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(
              kind == 'course'
                  ? '/institute/${widget.institute.id}/programs'
                  : '/institute/${widget.institute.id}/opportunities?kind=$kind',
            ),
          ),
      ],
    ),
    children: [
      if (kind == 'admission') ...[
        const Text('Open and upcoming intakes'),
        const SizedBox(height: 8),
        if (widget.admissionOverview != null) widget.admissionOverview!,
      ],
      if (programs.isNotEmpty) ...[
        InstituteProgramGroups(institute: widget.institute),
        if (items.isNotEmpty) const SizedBox(height: 12),
      ],
      for (final item in items)
        InstituteOpportunityCard(
          key: ValueKey('${item.kind}:${item.id}'),
          item: item,
        ),
      if (items.isEmpty && programs.isEmpty && !_loading && _error == null)
        Text(emptyMessage),
    ],
  );
}
