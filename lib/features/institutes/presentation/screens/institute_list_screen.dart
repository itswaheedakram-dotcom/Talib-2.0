import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../models/institute.dart';
import '../../data/institute_catalog.dart';
import '../../data/institute_repository.dart';

class InstituteListScreen extends StatefulWidget {
  final String type;
  const InstituteListScreen({super.key, required this.type});

  @override
  State<InstituteListScreen> createState() => _InstituteListScreenState();
}

class _InstituteListScreenState extends State<InstituteListScreen> {
  final _search = TextEditingController();
  final _catalog = InstituteCatalog.instance;
  final _repository = InstituteRepository.instance;
  String _city = 'All cities';

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
    _search.dispose();
    super.dispose();
  }

  List<Institute> get _categoryItems =>
      _repository.items.where((item) => item.type == widget.type).toList();

  List<String> get _cities {
    final values = _categoryItems
        .map((item) => item.city.trim())
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All cities', ...values];
  }

  List<Institute> get _filtered {
    final query = _search.text.trim().toLowerCase();
    return _categoryItems.where((item) {
      final searchable = [
        item.name,
        item.city,
        item.province,
        item.subcategory,
        item.town,
        item.campus,
        item.address,
        item.description,
        ...item.programs,
      ].join(' ').toLowerCase();
      return (query.isEmpty || searchable.contains(query)) &&
          (_city == 'All cities' || item.city == _city);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final type = _catalog.byId(widget.type);
    final title = type?.label ?? _catalog.labelFor(widget.type);
    final items = _filtered;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: _repository.load,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search $title by name, city or program',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _cities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final city = _cities[index];
                  return ChoiceChip(
                    label: Text(city),
                    selected: _city == city,
                    onSelected: (_) => setState(() => _city = city),
                  );
                },
              ),
            ),
            if (_repository.loading)
              const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Expanded(
                  child: Text(
                    '${items.length} institutes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/add-institute/${widget.type}'),
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Suggest institute'),
                ),
              ]),
            ),
            Expanded(
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 72),
                        Icon(Icons.school_outlined, size: 54, color: AppColors.mutedText),
                        const SizedBox(height: 12),
                        Center(child: Text(
                          _repository.error == null
                              ? 'No matching institutes found'
                              : 'Could not load institutes. Pull down to retry.',
                        )),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final institute = items[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.push('/institute/${institute.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.softGreen,
                                  child: Icon(type?.icon ?? _catalog.iconFor(institute.type),
                                      color: AppColors.darkGreen),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(institute.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text([
                                    _catalog.labelFor(institute.type),
                                    if (institute.subcategory.isNotEmpty) institute.subcategory,
                                    if (institute.city.isNotEmpty) institute.city,
                                    if (institute.sector.isNotEmpty) institute.sector,
                                  ].join(' • '), style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                                  if (institute.programs.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(institute.programs.take(3).join(' • '),
                                        maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: 7),
                                  Wrap(spacing: 6, runSpacing: 6, children: [
                                    Text('Admissions: ${institute.admissionStatus}',
                                        style: const TextStyle(color: AppColors.darkGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                                    if (institute.admissionDeadline.isNotEmpty)
                                      Text('Deadline: ${institute.admissionDeadline}',
                                          style: const TextStyle(color: AppColors.mutedText, fontSize: 11)),
                                  ]),
                                ])),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.darkGreen),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
