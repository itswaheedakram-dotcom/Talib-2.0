import '../../../../core/models/user_profile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/admin_access_service.dart';
import '../../data/location_catalog.dart';

class AdminLocationCatalogScreen extends StatefulWidget {
  const AdminLocationCatalogScreen({super.key});

  @override
  State<AdminLocationCatalogScreen> createState() => _AdminLocationCatalogScreenState();
}

class _AdminLocationCatalogScreenState extends State<AdminLocationCatalogScreen> {
  final _access = AdminAccessService.instance;
  final _catalog = LocationCatalog.instance;
  String _filter = 'all';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _catalog.addListener(_refresh);
    _catalog.load(force: true);
  }

  @override
  void dispose() {
    _catalog.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _access,
      builder: (context, _) {
        if (_access.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!_access.canOpenPanel ||
            (!_access.isSuperAdmin && !_access.isDemoSuperAdmin && !_access.can('manage_institutes'))) {
          return const Scaffold(body: Center(child: Text('Admin access is required.')));
        }
        final entries = _catalog.entries.where((entry) =>
          _filter == 'all' || entry['type'] == _filter).toList()
          ..sort((a, b) {
            final typeCompare = (a['type'] ?? '').compareTo(b['type'] ?? '');
            return typeCompare != 0 ? typeCompare : (a[ProfileFields.name] ?? '').compareTo(b[ProfileFields.name] ?? '');
          });
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
            title: const Text('Location Catalog'),
            actions: [
              IconButton(tooltip: 'Import CSV', onPressed: _busy ? null : _importCsv, icon: const Icon(Icons.upload_file_outlined)),
              IconButton(tooltip: 'Add location', onPressed: _busy ? null : _addEntry, icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Maintain searchable locations for Pakistan and overseas institutes. Add parent locations first, then their child locations.'),
                  const SizedBox(height: 8),
                  const Text('CSV columns: type,name,parentName,country. Allowed types: country,region,district,city,area.',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final value in const ['all', 'country', 'region', 'district', ProfileFields.city, 'area'])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(value == 'all' ? 'All' : _label(value)),
                            selected: _filter == value,
                            onSelected: (_) => setState(() => _filter = value),
                          ),
                        ),
                    ]),
                  ),
                ]),
              ),
              if (_busy || _catalog.loading) const LinearProgressIndicator(minHeight: 2),
              if (_catalog.error != null)
                Padding(padding: const EdgeInsets.all(10), child: Text(_catalog.error!, style: const TextStyle(color: AppColors.darkGreen))),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No custom catalog records yet. Use Add or Import CSV to maintain the list.', textAlign: TextAlign.center),
                      ))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return Card(child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.softGreen,
                              child: Icon(_icon(entry['type'] ?? ''), color: AppColors.darkGreen),
                            ),
                            title: Text(entry[ProfileFields.name] ?? ''),
                            subtitle: Text([
                              _label(entry['type'] ?? ''),
                              if ((entry['parentName'] ?? '').isNotEmpty) 'Parent: ${entry['parentName']}',
                              if ((entry['country'] ?? '').isNotEmpty && entry['type'] != 'country') entry['country']!,
                            ].join(' • ')),
                            trailing: IconButton(
                              tooltip: 'Remove catalog entry',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: _busy ? null : () => _deleteEntry(entry),
                            ),
                          ));
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _busy ? null : _addEntry,
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add location'),
          ),
        );
      },
    );
  }

  Future<void> _addEntry() async {
    final name = TextEditingController();
    final parent = TextEditingController();
    final country = TextEditingController(text: 'Pakistan');
    final formKey = GlobalKey<FormState>();
    String type = 'region';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add location'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Location level'),
                  items: const ['country', 'region', 'district', ProfileFields.city, 'area']
                      .map((value) => DropdownMenuItem(value: value, child: Text(_label(value)))).toList(),
                  onChanged: (value) => setDialogState(() {
                    type = value ?? 'region';
                    if (type == 'country') {
                      country.text = name.text.trim();
                      parent.clear();
                    }
                  }),
                ),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Location name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                  onChanged: (value) { if (type == 'country') country.text = value; },
                ),
                if (type != 'country')
                  TextFormField(
                    controller: country,
                    decoration: const InputDecoration(labelText: 'Country'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Country is required' : null,
                  ),
                if (type != 'country')
                  TextFormField(
                    controller: parent,
                    decoration: InputDecoration(labelText: switch (type) {
                      'region' => 'Parent country name',
                      'district' => 'Parent province / region name',
                      ProfileFields.city => 'Parent district or region name',
                      'area' => 'Parent city / town name',
                      _ => 'Parent location',
                    }),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Parent location is required' : null,
                  ),
              ]),
            )),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() => _busy = true);
      final ok = await _catalog.addEntry(
        name: name.text,
        type: type,
        parentName: parent.text,
        country: country.text,
      );
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Location added to catalog.' : 'Could not add location: ${_catalog.error ?? 'Please retry.'}'),
        ));
      }
    }
    name.dispose();
    parent.dispose();
    country.dispose();
  }

  Future<void> _deleteEntry(Map<String, String> entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove location?'),
        content: Text('Remove "${entry[ProfileFields.name]}" from suggestions? Existing institute records will not be changed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final ok = await _catalog.deleteEntry(entry['id'] ?? '');
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Location removed.' : 'Could not remove location: ${_catalog.error ?? 'Please retry.'}'),
      ));
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final raw = String.fromCharCodes(result.files.first.bytes!);
    final rows = raw.split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty).toList();
    if (rows.isEmpty) return;
    final first = rows.first.toLowerCase().replaceAll(' ', '');
    final start = first.startsWith('type,name,parentname,country') ? 1 : 0;
    var imported = 0;
    setState(() => _busy = true);
    for (final row in rows.skip(start)) {
      final columns = row.split(',');
      if (columns.length < 4) continue;
      final ok = await _catalog.addEntry(
        type: columns[0].trim(),
        name: columns[1].trim(),
        parentName: columns[2].trim(),
        country: columns.sublist(3).join(',').trim(),
      );
      if (ok) imported++;
    }
    if (mounted) {
      setState(() => _busy = false);
      await _catalog.load(force: true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Imported $imported location records.'),
      ));
    }
  }

  static String _label(String type) => switch (type) {
    'country' => 'Country',
    'region' => 'Province / State / Region',
    'district' => 'District / County',
    ProfileFields.city => 'City / Town',
    'area' => 'Area / Locality',
    _ => type,
  };

  static IconData _icon(String type) => switch (type) {
    'country' => Icons.public_outlined,
    'region' => Icons.map_outlined,
    'district' => Icons.account_balance_outlined,
    ProfileFields.city => Icons.location_city_outlined,
    'area' => Icons.place_outlined,
    _ => Icons.place_outlined,
  };
}
