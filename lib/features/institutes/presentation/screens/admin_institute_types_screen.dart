import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../data/institute_catalog.dart';

class AdminInstituteTypesScreen extends StatefulWidget {
  const AdminInstituteTypesScreen({super.key});

  @override
  State<AdminInstituteTypesScreen> createState() => _AdminInstituteTypesScreenState();
}

class _AdminInstituteTypesScreenState extends State<AdminInstituteTypesScreen> {
  final _catalog = InstituteCatalog.instance;

  @override
  void initState() {
    super.initState();
    _catalog.addListener(_onChanged);
    _catalog.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _catalog.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _editType({InstituteTypeOption? existing}) async {
    final name = TextEditingController(text: existing?.label ?? '');
    final id = TextEditingController(text: existing?.id ?? '');
    final subcategories = TextEditingController(text: existing?.subcategories.join(', ') ?? '');
    final programLabel = TextEditingController(text: existing?.programLabel ?? 'Programs / courses');
    final eligibilityLabel = TextEditingController(text: existing?.eligibilityLabel ?? 'Eligibility criteria');
    final featuredProgramLabel = TextEditingController(text: existing?.featuredProgramLabel ?? 'Featured / next program');
    final order = TextEditingController(text: (existing?.sortOrder ?? (_catalog.allTypes.length + 1) * 10).toString());
    var iconKey = existing?.iconKey ?? 'school';
    var showMinimumScore = existing?.showMinimumScore ?? true;
    var enabled = existing?.enabled ?? true;
    var idWasEdited = existing != null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add institute category' : 'Edit institute category'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  onChanged: (value) {
                    if (!idWasEdited) {
                      id.text = _slug(value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: id,
                  readOnly: existing != null,
                  decoration: const InputDecoration(labelText: 'Unique category ID'),
                  onChanged: (_) => idWasEdited = true,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: iconKey,
                  decoration: const InputDecoration(labelText: 'Category icon'),
                  items: const [
                    DropdownMenuItem(value: 'school', child: Text('School')),
                    DropdownMenuItem(value: 'college', child: Text('College / Institute')),
                    DropdownMenuItem(value: 'university', child: Text('University')),
                    DropdownMenuItem(value: 'academy', child: Text('Academy / Books')),
                    DropdownMenuItem(value: 'technical', child: Text('Technical / Vocational')),
                    DropdownMenuItem(value: 'medical', child: Text('Medical')),
                    DropdownMenuItem(value: 'training', child: Text('Professional Training')),
                    DropdownMenuItem(value: 'religious', child: Text('Religious Education')),
                  ],
                  onChanged: (value) => setDialogState(() => iconKey = value ?? iconKey),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: subcategories,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Subcategories (comma separated)',
                    hintText: 'Entry Test, Tuition, MDCAT',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: programLabel,
                  decoration: const InputDecoration(
                    labelText: 'Programs field label',
                    hintText: 'Classes / levels, Degrees / programs, Deeni courses',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: eligibilityLabel,
                  decoration: const InputDecoration(labelText: 'Eligibility field label'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: featuredProgramLabel,
                  decoration: const InputDecoration(labelText: 'Featured program field label'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show minimum percentage / CGPA field'),
                  value: showMinimumScore,
                  onChanged: (value) => setDialogState(() => showMinimumScore = value),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: order,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Display order'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enabled in app'),
                  value: enabled,
                  onChanged: (value) => setDialogState(() => enabled = value),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save category'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) {
      name.dispose();
      id.dispose();
      subcategories.dispose();
      programLabel.dispose();
      eligibilityLabel.dispose();
      featuredProgramLabel.dispose();
      order.dispose();
      return;
    }

    final typeId = id.text.trim().toLowerCase();
    final label = name.text.trim();
    if (typeId.isEmpty || label.isEmpty || !RegExp(r'^[a-z0-9_]+$').hasMatch(typeId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name and a valid unique ID (letters, numbers and underscores).')),
      );
    } else if (existing == null && _catalog.byId(typeId) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That category ID already exists. Choose another ID or edit the existing category.')),
      );
    } else {
      try {
        await _catalog.saveType(InstituteTypeOption(
          id: typeId,
          label: label,
          iconKey: iconKey,
          subcategories: subcategories.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList(),
          programLabel: programLabel.text.trim().isEmpty
              ? 'Programs / courses'
              : programLabel.text.trim(),
          eligibilityLabel: eligibilityLabel.text.trim().isEmpty
              ? 'Eligibility criteria'
              : eligibilityLabel.text.trim(),
          featuredProgramLabel: featuredProgramLabel.text.trim().isEmpty
              ? 'Featured / next program'
              : featuredProgramLabel.text.trim(),
          showMinimumScore: showMinimumScore,
          enabled: enabled,
          sortOrder: int.tryParse(order.text.trim()) ?? 100,
        ));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Institute category saved.')),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save category: $error')),
          );
        }
      }
    }
    name.dispose();
    id.dispose();
    subcategories.dispose();
    programLabel.dispose();
    eligibilityLabel.dispose();
    featuredProgramLabel.dispose();
    order.dispose();
  }

  String _slug(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  @override
  Widget build(BuildContext context) {
    final types = _catalog.allTypes;
    return Scaffold(
      appBar: AppBar(title: const Text('Institute Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editType(),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      body: RefreshIndicator(
        onRefresh: _catalog.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            Text('One central category catalogue', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'New categories and subcategories flow into institute browsing, filters and submission forms. Demo changes stay local; real changes are saved to the protected instituteTypes collection.',
            ),
            const SizedBox(height: 14),
            if (_catalog.loading) const LinearProgressIndicator(minHeight: 2),
            if (_catalog.error != null)
              Text('Could not refresh remote categories: ${_catalog.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ...types.map((type) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.softGreen,
                  child: Icon(type.icon, color: AppColors.darkGreen),
                ),
                title: Text(type.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(type.subcategories.isEmpty
                    ? type.id
                    : '${type.id} • ${type.programLabel} • ${type.eligibilityLabel} • ${type.subcategories.join(', ')}'),
                isThreeLine: type.subcategories.length > 3,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (!type.enabled)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.visibility_off_outlined, size: 18),
                    ),
                  IconButton(
                    tooltip: 'Edit category',
                    onPressed: () => _editType(existing: type),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ]),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
