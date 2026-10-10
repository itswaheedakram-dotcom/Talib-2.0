import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../models/institute.dart';
import '../../../models/institute_opportunity.dart';
import '../../data/institute_opportunity_repository.dart';
import '../../data/institute_repository.dart';
import '../../data/institute_access.dart';
import '../widgets/institute_opportunity_card.dart';

class InstituteOpportunitiesScreen extends StatefulWidget {
  final String instituteId;
  final String initialKind;
  const InstituteOpportunitiesScreen({
    super.key,
    required this.instituteId,
    this.initialKind = 'admission',
  });

  @override
  State<InstituteOpportunitiesScreen> createState() => _InstituteOpportunitiesScreenState();
}

class _InstituteOpportunitiesScreenState extends State<InstituteOpportunitiesScreen> {
  final _repository = InstituteOpportunityRepository.instance;
  String _kind = 'admission';
  String _yearFilter = 'All years';

  Institute? get _institute => InstituteRepository.instance.byId(widget.instituteId);

  bool get _canManage => _institute != null && InstituteAccess.canManage(_institute!);

  @override
  void initState() {
    super.initState();
    _kind = _validKind(widget.initialKind);
    _repository.addListener(_refresh);
    _repository.load(widget.instituteId);
  }

  static String _validKind(String kind) =>
      const {'course', 'admission', 'scholarship'}.contains(kind)
          ? kind
          : 'admission';

  @override
  void didUpdateWidget(InstituteOpportunitiesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialKind != widget.initialKind ||
        oldWidget.instituteId != widget.instituteId) {
      _kind = _validKind(widget.initialKind);
      _yearFilter = 'All years';
      if (oldWidget.instituteId != widget.instituteId) {
        _repository.load(widget.instituteId);
      }
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final institute = _institute;
    if (institute == null) {
      return const Scaffold(body: Center(child: Text('Institute not found')));
    }
    final items = _repository.forInstitute(widget.instituteId)
        .where((item) => item.kind == _kind).toList();
    final years = items.map((item) => item.academicYear).where((year) => year.isNotEmpty).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final yearOptions = <String>['All years', ...years];
    final visibleItems = _yearFilter == 'All years'
        ? items
        : items.where((item) => item.academicYear == _yearFilter).toList();
    final title = switch (_kind) {
      'course' => 'Programs & Courses',
      'scholarship' => 'Scholarships',
      _ => 'Admissions',
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(title),
        actions: [
          if (_canManage)
            IconButton(
              tooltip: 'Add listing',
              onPressed: () => _openEditor(context, institute, _kind),
              icon: const Icon(Icons.add_circle_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(institute.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _kindChip('course', 'Programs / Courses', Icons.school_outlined),
                _kindChip('admission', 'Admissions', Icons.calendar_month_outlined),
                _kindChip('scholarship', 'Scholarships', Icons.workspace_premium_outlined),
              ],
            ),
          ),
          if (years.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 18, color: AppColors.darkGreen),
                  const SizedBox(width: 8),
                  const Text('Academic year:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: yearOptions.contains(_yearFilter) ? _yearFilter : 'All years',
                    items: yearOptions.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
                    onChanged: (value) => setState(() => _yearFilter = value ?? 'All years'),
                  ),
                ],
              ),
            ),
          if (_repository.loading)
            const LinearProgressIndicator(minHeight: 2),
          if (_repository.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Could not load listings: ${_repository.error}',
                style: const TextStyle(color: AppColors.darkGreen),
              ),
            ),
          Expanded(
            child: visibleItems.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                    children: [
                      Icon(
                        _kind == 'scholarship'
                            ? Icons.workspace_premium_outlined
                            : _kind == 'course'
                                ? Icons.school_outlined
                                : Icons.event_note_outlined,
                        size: 54,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No ${title.toLowerCase()} listed yet',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _canManage
                            ? 'Add a listing to publish this program, admission intake, or scholarship.'
                            : 'The institute has not published any listings here yet.',
                        textAlign: TextAlign.center,
                      ),
                      if (_canManage) ...[
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () => _openEditor(context, institute, _kind),
                          icon: const Icon(Icons.add),
                          label: Text('Add ${_kindLabel(_kind)}'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: visibleItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => InstituteOpportunityCard(
                      item: visibleItems[index],
                      onEdit: _canManage
                          ? () => _openEditor(context, institute, visibleItems[index].kind, visibleItems[index])
                          : null,
                      onDelete: _canManage
                          ? () => _confirmDelete(context, visibleItems[index])
                          : null,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(context, institute, _kind),
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add),
              label: Text('Add ${_kindLabel(_kind)}'),
            )
          : null,
    );
  }

  Widget _kindChip(String value, String label, IconData icon) => ChoiceChip(
    avatar: Icon(icon, size: 17),
    label: Text(label),
    selected: _kind == value,
    onSelected: (_) => setState(() { _kind = value; _yearFilter = 'All years'; }),
  );

  Future<void> _confirmDelete(BuildContext context, InstituteOpportunity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('“${item.title}” will be removed from this institute.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _repository.delete(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Listing deleted.' : 'Listing could not be deleted: ${_repository.error ?? 'Please retry.'}'),
    ));
  }

  Future<void> _openEditor(
    BuildContext context,
    Institute institute,
    String kind, [
    InstituteOpportunity? existing,
  ]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final year = TextEditingController(text: existing?.academicYear ?? DateTime.now().year.toString());
    final intake = TextEditingController(text: existing?.intake ?? '');
    final opening = TextEditingController(text: existing?.openingDate ?? '');
    final deadline = TextEditingController(text: existing?.deadline ?? '');
    final eligibility = TextEditingController(text: existing?.eligibility ?? '');
    final fee = TextEditingController(text: existing?.feeDetails ?? '');
    final coverage = TextEditingController(text: existing?.coverage ?? '');
    final mode = TextEditingController(text: existing?.deliveryMode ?? '');
    final url = TextEditingController(text: existing?.applicationUrl ?? '');
    final description = TextEditingController(text: existing?.description ?? '');
    final provider = TextEditingController(text: existing?.provider ?? '');
    String status = existing?.status ?? 'Not announced';
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${existing == null ? 'Add' : 'Edit'} ${_kindLabel(kind)}'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: title,
                      validator: (value) => value == null || value.trim().isEmpty ? 'This field is required' : null,
                      decoration: InputDecoration(
                        labelText: kind == 'scholarship'
                            ? 'Scholarship name'
                            : kind == 'course' ? 'Program / course name' : 'Program / admission title',
                      ),
                    ),
                    TextFormField(controller: year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Academic year (e.g. 2027)')),
                    TextFormField(controller: intake, decoration: const InputDecoration(labelText: 'Intake / semester / batch (e.g. Fall, Spring, CSS Batch 3)')),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const ['Not announced', 'Upcoming', 'Open', 'Closed', 'Cancelled', 'Awarded']
                          .map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) => setDialogState(() => status = value ?? 'Not announced'),
                    ),
                    TextFormField(
                      controller: opening,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(opening.text) ?? DateTime.now(),
                          firstDate: DateTime(DateTime.now().year - 1),
                          lastDate: DateTime(DateTime.now().year + 15),
                        );
                        if (picked != null) setDialogState(() => opening.text = _dateString(picked));
                      },
                      decoration: const InputDecoration(labelText: 'Opening date (optional)', suffixIcon: Icon(Icons.calendar_month_outlined)),
                    ),
                    TextFormField(
                      controller: deadline,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(deadline.text) ?? DateTime.now(),
                          firstDate: DateTime(DateTime.now().year - 1),
                          lastDate: DateTime(DateTime.now().year + 15),
                        );
                        if (picked != null) setDialogState(() => deadline.text = _dateString(picked));
                      },
                      decoration: const InputDecoration(labelText: 'Closing / deadline (optional)', suffixIcon: Icon(Icons.event_busy_outlined)),
                    ),
                    TextFormField(controller: eligibility, maxLines: 2, decoration: const InputDecoration(labelText: 'Eligibility / requirements')),
                    TextFormField(controller: fee, decoration: InputDecoration(labelText: kind == 'scholarship' ? 'Any fees / notes' : 'Fee details / fee range')),
                    if (kind == 'scholarship') TextFormField(controller: coverage, maxLines: 2, decoration: const InputDecoration(labelText: 'Scholarship coverage (e.g. 50%, full tuition)')),
                    if (kind == 'scholarship') TextFormField(controller: provider, decoration: const InputDecoration(labelText: 'Scholarship provider')),
                    if (kind != 'scholarship') TextFormField(controller: mode, decoration: const InputDecoration(labelText: 'Study / application mode (online, on-campus, hybrid)')),
                    TextFormField(controller: url, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Official application URL')),
                    TextFormField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Additional details')),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final opportunity = InstituteOpportunity(
                  id: existing?.id ?? '',
                  instituteId: institute.id,
                  kind: kind,
                  title: title.text.trim(),
                  academicYear: year.text.trim(),
                  intake: intake.text.trim(),
                  status: status,
                  openingDate: opening.text.trim(),
                  deadline: deadline.text.trim(),
                  eligibility: eligibility.text.trim(),
                  feeDetails: fee.text.trim(),
                  coverage: coverage.text.trim(),
                  deliveryMode: mode.text.trim(),
                  applicationUrl: url.text.trim(),
                  description: description.text.trim(),
                  provider: provider.text.trim(),
                  createdBy: existing?.createdBy ?? InstituteAccess.uid ?? '',
                );
                final result = existing == null
                    ? await _repository.add(opportunity)
                    : await _repository.update(opportunity);
                if (!dialogContext.mounted) return;
                if (result == null || result == false) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                    content: Text('Listing could not be saved: ${_repository.error ?? 'Please retry.'}'),
                  ));
                  return;
                }
                Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(existing == null ? 'Listing added.' : 'Listing updated.'),
                  ));
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: const Text('Save listing'),
            ),
          ],
        ),
      ),
    );

    for (final controller in [
      title, year, intake, opening, deadline, eligibility, fee, coverage, mode, url, description, provider,
    ]) {
      controller.dispose();
    }
  }

  static String _kindLabel(String kind) => switch (kind) {
    'course' => 'Program / Course',
    'scholarship' => 'Scholarship',
    _ => 'Admission Intake',
  };

  static String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
