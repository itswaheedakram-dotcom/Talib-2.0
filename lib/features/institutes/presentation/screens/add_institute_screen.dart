import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../models/institute.dart';
import '../../data/institute_catalog.dart';
import '../../data/institute_repository.dart';
import '../widgets/institute_image_field.dart';

class AddInstituteScreen extends StatefulWidget {
  final String type;
  const AddInstituteScreen({super.key, required this.type});

  @override
  State<AddInstituteScreen> createState() => _AddInstituteScreenState();
}

class _AddInstituteScreenState extends State<AddInstituteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _campus = TextEditingController();
  final _province = TextEditingController();
  final _city = TextEditingController();
  final _town = TextEditingController();
  final _address = TextEditingController();
  final _description = TextEditingController();
  final _website = TextEditingController();
  final _applicationUrl = TextEditingController();
  final _contact = TextEditingController();
  final _eligibility = TextEditingController();
  final _minScore = TextEditingController();
  final _nextProgram = TextEditingController();
  final _programs = TextEditingController();
  final _deadline = TextEditingController();
  final _fee = TextEditingController();
  final _facilities = TextEditingController();
  final _imageUrl = TextEditingController();
  final _customSubcategory = TextEditingController();
  final _customProgram = TextEditingController();
  final _customFacility = TextEditingController();
  final Set<String> _selectedPrograms = {};
  final Set<String> _selectedFacilities = {};

  final _catalog = InstituteCatalog.instance;
  final _repository = InstituteRepository.instance;
  String _type = '';
  String _subcategory = '';
  String _sector = 'Private';
  String _submission = 'Online';
  String _admissionStatus = 'Not announced';
  bool _entryTest = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.type == 'all' ? '' : widget.type;
    _catalog.addListener(_onCatalogChanged);
    _catalog.load().then((_) {
      if (!mounted) return;
      if (_type.isEmpty || _catalog.byId(_type) == null) {
        setState(() => _type = _catalog.types.isEmpty ? '' : _catalog.types.first.id);
      }
    });
  }

  void _onCatalogChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _catalog.removeListener(_onCatalogChanged);
    for (final controller in [
      _name, _campus, _province, _city, _town, _address, _description,
      _website, _applicationUrl, _contact, _eligibility, _minScore, _nextProgram, _programs,
      _deadline, _fee, _facilities, _imageUrl, _customSubcategory,
      _customProgram, _customFacility,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _title => _type.isEmpty
      ? 'Suggest an Institute'
      : 'Add ${_catalog.labelFor(_type)}';

  List<String> _split(String value) => value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toSet()
      .toList();

  List<String> _programSuggestions(String type) => switch (type) {
    'schools' => ['Montessori', 'Primary', 'Middle', 'Matric', 'O-Level', 'A-Level'],
    'colleges' => ['FA', 'FSc Pre-Medical', 'FSc Pre-Engineering', 'ICS', 'ICom', 'ADP', 'BS'],
    'universities' => ['Undergraduate', 'Graduate', 'PhD', 'Computer Science', 'Business', 'Engineering'],
    'academies' => ['Entry Test', 'MDCAT', 'ECAT', 'CSS / PMS', 'Tuition', 'Languages'],
    'technical_vocational' => ['IT & Programming', 'Electrical', 'Plumbing', 'Welding', 'Auto Mechanics'],
    'professional_training' => ['Freelancing', 'Digital Marketing', 'Graphic Design', 'Certification'],
    'medical_allied_health' => ['Nursing', 'Pharmacy', 'Medical Lab', 'Radiology', 'Physiotherapy'],
    'madaris' => ['Hifz-ul-Quran', 'Nazra Quran', 'Tajweed', 'Dars-e-Nizami', 'Islamic Studies'],
    'special_education' => ['Learning Support', 'Speech & Language', 'Inclusive Education'],
    'research_institutes' => ['Science & Technology', 'Educational Research', 'Policy Research'],
    _ => ['General Studies', 'Professional Course'],
  };

  List<String> _facilitySuggestions(String type) => [
    'Library',
    'Computer Lab',
    'Science Lab',
    'Transport',
    'Hostel',
    'Sports',
    'Cafeteria',
    if (type == 'schools' || type == 'colleges') 'Playground',
    if (type == 'universities' || type == 'medical_allied_health') 'Research Lab',
    if (type == 'madaris') 'Residential Facility',
  ];

  void _toggleItem(Set<String> selected, TextEditingController controller, String item) {
    setState(() {
      if (selected.contains(item)) {
        selected.remove(item);
      } else {
        selected.add(item);
      }
      controller.text = selected.join(', ');
    });
  }

  void _addCustomItem(
    Set<String> selected,
    TextEditingController output,
    TextEditingController custom,
  ) {
    final value = custom.text.trim();
    if (value.isEmpty) return;
    setState(() {
      selected.add(value);
      output.text = selected.join(', ');
      custom.clear();
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: 'Select admission deadline',
    );
    if (picked != null && mounted) {
      setState(() {
        _deadline.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type.isEmpty || _catalog.byId(_type) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an institute category.')),
      );
      return;
    }
    setState(() => _saving = true);
    final subcategory = _subcategory == '__other__'
        ? _customSubcategory.text.trim()
        : _subcategory;
    final institute = Institute(
      id: '',
      name: _name.text.trim(),
      type: _type,
      subcategory: subcategory,
      createdBy: ActiveProfileController.instance.effectiveUid ?? '',
      campus: _campus.text.trim(),
      province: _province.text.trim(),
      city: _city.text.trim(),
      town: _town.text.trim(),
      sector: _sector,
      address: _address.text.trim().isEmpty
          ? '${_city.text.trim()}, ${_province.text.trim()}'.trim()
          : _address.text.trim(),
      description: _description.text.trim(),
      website: _website.text.trim(),
      applicationUrl: _applicationUrl.text.trim(),
      contact: _contact.text.trim(),
      submissionMode: _submission,
      eligibility: _eligibility.text.trim(),
      programs: _split(_programs.text),
      minScore: double.tryParse(_minScore.text.trim()) ?? 0,
      nextProgram: _nextProgram.text.trim(),
      admissionStatus: _admissionStatus,
      admissionDeadline: _deadline.text.trim(),
      feeRange: _fee.text.trim(),
      entryTestRequired: _entryTest,
      imageUrl: _imageUrl.text.trim(),
      facilities: _split(_facilities.text),
      status: 'pending',
    );
    final saved = await _repository.add(institute);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      final message = _repository.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          message == null || message.isEmpty
              ? 'Institute could not be submitted. Please try again.'
              : 'Institute could not be submitted: $message',
        )),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Institute submitted for review. It will appear publicly after approval.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final types = _catalog.types;
    final selectedType = _catalog.byId(_type);
    final subcategories = _catalog.subcategoriesFor(_type);
    if (_type.isNotEmpty && !types.any((type) => type.id == _type) && types.isNotEmpty) {
      _type = types.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(_title),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            Text('Institute profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(
              'Enter what you know. Required details are marked. Optional information can be completed later by the approved institute representative.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: types.any((item) => item.id == _type) ? _type : null,
              decoration: const InputDecoration(labelText: 'Institute category'),
              items: types.map((item) => DropdownMenuItem(
                value: item.id,
                child: Text(item.label, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: _saving ? null : (value) => setState(() {
                _type = value ?? '';
                _subcategory = '';
                _customSubcategory.clear();
              }),
              validator: (value) => value == null || value.isEmpty ? 'Choose a category' : null,
            ),
            const SizedBox(height: 12),
            if (subcategories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _subcategory.isNotEmpty && (_subcategory == '__other__' || subcategories.contains(_subcategory))
                    ? _subcategory
                    : null,
                decoration: const InputDecoration(labelText: 'Subcategory (optional)'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Not specified')),
                  ...subcategories.map((item) => DropdownMenuItem(value: item, child: Text(item))),
                  const DropdownMenuItem(value: '__other__', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _subcategory = value ?? ''),
              ),
            if (_subcategory == '__other__') ...[
              const SizedBox(height: 12),
              _field(_customSubcategory, 'Custom subcategory', Icons.category_outlined),
            ],
            const SizedBox(height: 12),
            _field(_name, 'Institute name', Icons.account_balance_outlined, required: true),
            Row(children: [
              Expanded(child: _field(_province, 'Province / Region', Icons.map_outlined, required: true,
                  textCapitalization: TextCapitalization.words)),
              const SizedBox(width: 10),
              Expanded(child: _field(_city, 'City', Icons.location_on_outlined, required: true,
                  textCapitalization: TextCapitalization.words)),
            ]),
            _choiceSection(
              label: 'Ownership / sector',
              values: InstituteCatalog.sectors,
              selected: _sector,
              onSelected: (value) => setState(() => _sector = value),
            ),
            const SizedBox(height: 16),
            Text('${_catalog.labelFor(_type)} details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _selectableItemsSection(
              title: selectedType?.programLabel ?? 'Programs / courses',
              suggestions: _programSuggestions(_type),
              selected: _selectedPrograms,
              output: _programs,
              custom: _customProgram,
              hint: 'Add another program or course',
            ),
            _field(_nextProgram, selectedType?.featuredProgramLabel ?? 'Featured / next program', Icons.school_outlined),
            _field(_eligibility, selectedType?.eligibilityLabel ?? 'Eligibility criteria', Icons.rule_outlined, maxLines: 3),
            if (selectedType?.showMinimumScore ?? true)
              _field(_minScore, 'Minimum percentage / CGPA (optional)', Icons.percent,
                  keyboard: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 8),
            Text('Admissions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _choiceSection(
              label: 'Admission status',
              values: InstituteCatalog.admissionStatuses,
              selected: _admissionStatus,
              onSelected: (value) => setState(() => _admissionStatus = value),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: _deadline,
                readOnly: true,
                onTap: _saving ? null : _pickDeadline,
                decoration: const InputDecoration(
                  labelText: 'Admission deadline (optional)',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                  suffixIcon: Icon(Icons.event_outlined),
                ),
              ),
            ),
            _field(_fee, 'Fee range / fee notes (optional)', Icons.payments_outlined),
            _choiceSection(
              label: 'Application submission mode',
              values: InstituteCatalog.submissionModes,
              selected: _submission,
              onSelected: (value) => setState(() => _submission = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Entry test required'),
              value: _entryTest,
              onChanged: (value) => setState(() => _entryTest = value),
            ),
            const SizedBox(height: 8),
            Text('Contact & facilities', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _field(_contact, 'Contact phone or email', Icons.phone_outlined,
                keyboard: TextInputType.text),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: const Text('Website and application links (optional)'),
              subtitle: const Text('Open only if you have these details'),
              children: [
                _field(_website, 'Official website URL', Icons.language_outlined, keyboard: TextInputType.url),
                _field(_applicationUrl, 'Direct admission / application URL', Icons.open_in_new_outlined, keyboard: TextInputType.url),
              ],
            ),
            InstituteImageField(
              controller: _imageUrl,
              fallbackIcon: _catalog.iconFor(_type),
              label: _type.isEmpty ? 'Institute cover image' : _catalog.labelFor(_type),
              height: 150,
            ),
            _selectableItemsSection(
              title: 'Facilities (optional)',
              suggestions: _facilitySuggestions(_type),
              selected: _selectedFacilities,
              output: _facilities,
              custom: _customFacility,
              hint: 'Add another facility',
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: const Text('More institute information (optional)'),
              subtitle: const Text('Description and other details'),
              children: [
                _field(_description, 'About this institute', Icons.notes_outlined, maxLines: 4),
                _field(_town, 'Town / Area', Icons.place_outlined),
                _field(_campus, 'Campus / Branch', Icons.location_city_outlined),
                _field(_address, 'Full address', Icons.pin_drop_outlined, maxLines: 2),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: AppColors.primaryGreen),
                SizedBox(width: 9),
                Expanded(child: Text(
                  'This listing stays private until an admin approves it. The submitter can later request to claim the institute profile after verification. Demo submissions stay isolated from Firebase.',
                )),
              ]),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: _saving
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Text('Submit for Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceSection({
    required String label,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onSelected,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: values.map((value) => ChoiceChip(
            label: Text(value),
            selected: selected == value,
            onSelected: _saving ? null : (_) => onSelected(value),
          )).toList(),
        ),
      ],
    ),
  );

  Widget _selectableItemsSection({
    required String title,
    required List<String> suggestions,
    required Set<String> selected,
    required TextEditingController output,
    required TextEditingController custom,
    required String hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: suggestions.map((item) => FilterChip(
            label: Text(item),
            selected: selected.contains(item),
            onSelected: _saving ? null : (_) => _toggleItem(selected, output, item),
          )).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: custom,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: hint,
                  prefixIcon: const Icon(Icons.add_circle_outline),
                ),
                onSubmitted: (_) => _addCustomItem(selected, output, custom),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Add item',
              onPressed: _saving ? null : () => _addCustomItem(selected, output, custom),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '${selected.length} selected',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      textCapitalization: textCapitalization,
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'This field is required' : null
          : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    ),
  );
}
