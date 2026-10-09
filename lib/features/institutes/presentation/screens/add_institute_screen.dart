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
  final _country = TextEditingController(text: 'Pakistan');
  final _province = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _board = TextEditingController();
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
  final Set<String> _customPrograms = {};
  final Set<String> _customFacilities = {};

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
      _name, _campus, _country, _province, _district, _city, _area, _board, _town, _address, _description,
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
    Set<String> customItems,
  ) {
    final value = custom.text.trim();
    if (value.isEmpty) return;
    setState(() {
      selected.add(value);
      customItems.add(value);
      output.text = selected.join(', ');
      custom.clear();
    });
  }

  void _removeCustomItem(
    Set<String> selected,
    Set<String> customItems,
    TextEditingController output,
    String item,
  ) {
    setState(() {
      selected.remove(item);
      customItems.remove(item);
      output.text = selected.join(', ');
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
            '${picked.year.toString().padLeft(4, "0")}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}';
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
      country: _country.text.trim().isEmpty ? 'Pakistan' : _country.text.trim(),
      province: _province.text.trim(),
      district: _district.text.trim(),
      city: _city.text.trim(),
      area: _area.text.trim(),
      board: _board.text.trim(),
      town: _town.text.trim().isEmpty ? _area.text.trim() : _town.text.trim(),
      sector: _sector,
      address: _address.text.trim().isEmpty
          ? [_area.text.trim(), _city.text.trim(), _district.text.trim(), _province.text.trim(), _country.text.trim()].where((part) => part.isNotEmpty).join(', ')
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
            _locationAutocomplete(
              controller: _country,
              label: 'Country',
              options: const ['Pakistan', 'United Arab Emirates', 'Saudi Arabia', 'Qatar', 'Oman', 'Bahrain', 'Kuwait', 'United Kingdom', 'United States', 'Canada', 'Australia', 'Malaysia', 'Turkey'],
              required: true,
              onSelected: (_) {
                _province.clear();
                _district.clear();
                _city.clear();
                _area.clear();
                setState(() {});
              },
            ),
            Row(children: [
              Expanded(
                child: _locationAutocomplete(
                  controller: _province,
                  label: 'Province / State / Region',
                  options: _country.text.trim().toLowerCase() == 'pakistan'
                      ? const ['Punjab', 'Sindh', 'Khyber Pakhtunkhwa', 'Balochistan', 'Islamabad Capital Territory', 'Azad Jammu & Kashmir', 'Gilgit-Baltistan']
                      : const [],
                  required: true,
                  onSelected: (_) {
                    _district.clear();
                    _city.clear();
                    _area.clear();
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _locationAutocomplete(
                  controller: _district,
                  label: 'District / County (optional)',
                  options: _districtsForProvince(_province.text),
                  required: false,
                  onSelected: (_) {
                    _city.clear();
                    _area.clear();
                    setState(() {});
                  },
                ),
              ),
            ]),
            Row(children: [
              Expanded(
                child: _locationAutocomplete(
                  controller: _city,
                  label: 'City / Town',
                  options: _citiesForProvince(_province.text),
                  required: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _locationAutocomplete(
                  controller: _area,
                  label: 'Area / Locality (optional)',
                  options: const [],
                  required: false,
                ),
              ),
            ]),
            if (_type == 'schools' || _type == 'colleges')
              _locationAutocomplete(
                controller: _board,
                label: 'Education board / examining authority',
                options: const [
                  'BISE Lahore', 'BISE Rawalpindi', 'BISE Faisalabad', 'BISE Multan',
                  'BISE Bahawalpur', 'BISE Sargodha', 'BISE Gujranwala', 'BISE Sahiwal',
                  'BISE Dera Ghazi Khan', 'FBISE', 'Sindh Boards', 'KPK Boards',
                  'Balochistan Board', 'Aga Khan University Examination Board', 'Cambridge International',
                ],
                required: false,
              ),
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
              suggestions: _catalog.programSuggestionsFor(_type),
              selected: _selectedPrograms,
              output: _programs,
              custom: _customProgram,
              customItems: _customPrograms,
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
              suggestions: _catalog.facilitySuggestionsFor(_type),
              selected: _selectedFacilities,
              output: _facilities,
              custom: _customFacility,
              customItems: _customFacilities,
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

  List<String> _citiesForProvince(String province) {
    final key = province.trim().toLowerCase();
    if (key == 'punjab') {
      return const ['Lahore', 'Faisalabad', 'Rawalpindi', 'Multan', 'Gujranwala', 'Bahawalpur', 'Sargodha', 'Sialkot', 'Rahim Yar Khan', 'Dera Ghazi Khan', 'Layyah', 'Taxila', 'Gujrat', 'Jhelum', 'Kasur', 'Okara', 'Sahiwal', 'Mianwali', 'Attock', 'Chakwal'];
    }
    if (key == 'sindh') {
      return const ['Karachi', 'Hyderabad', 'Sukkur', 'Larkana', 'Mirpur Khas', 'Nawabshah', 'Jacobabad', 'Thatta'];
    }
    if (key == 'khyber pakhtunkhwa' || key == 'kpk') {
      return const ['Peshawar', 'Mardan', 'Abbottabad', 'Swat', 'Kohat', 'Bannu', 'Dera Ismail Khan', 'Charsadda', 'Mansehra'];
    }
    if (key == 'balochistan') {
      return const ['Quetta', 'Gwadar', 'Turbat', 'Khuzdar', 'Chaman', 'Sibi', 'Zhob'];
    }
    if (key == 'islamabad capital territory' || key == 'islamabad') {
      return const ['Islamabad'];
    }
    if (key == 'azad jammu & kashmir' || key == 'ajk') {
      return const ['Muzaffarabad', 'Mirpur', 'Kotli', 'Rawalakot', 'Bhimber'];
    }
    if (key == 'gilgit-baltistan') {
      return const ['Gilgit', 'Skardu', 'Hunza', 'Ghanche', 'Ghizer'];
    }
    return const ['Lahore', 'Karachi', 'Islamabad', 'Peshawar', 'Quetta', 'Multan', 'Faisalabad', 'Hyderabad'];
  }

  List<String> _districtsForProvince(String province) {
    final key = province.trim().toLowerCase();
    if (key == 'punjab') {
      return const ['Attock', 'Bahawalnagar', 'Bahawalpur', 'Bhakkar', 'Chakwal', 'Chiniot', 'Dera Ghazi Khan', 'Faisalabad', 'Gujranwala', 'Gujrat', 'Hafizabad', 'Jhang', 'Jhelum', 'Kasur', 'Khanewal', 'Khushab', 'Kot Addu', 'Lahore', 'Layyah', 'Lodhran', 'Mandi Bahauddin', 'Mianwali', 'Multan', 'Murree', 'Muzaffargarh', 'Narowal', 'Nankana Sahib', 'Okara', 'Pakpattan', 'Rahim Yar Khan', 'Rajanpur', 'Rawalpindi', 'Sahiwal', 'Sargodha', 'Sheikhupura', 'Sialkot', 'Talagang', 'Taunsa', 'Toba Tek Singh', 'Vehari', 'Wazirabad'];
    }
    if (key == 'sindh') {
      return const ['Badin', 'Dadu', 'Ghotki', 'Hyderabad', 'Jacobabad', 'Jamshoro', 'Karachi Central', 'Karachi East', 'Karachi South', 'Karachi West', 'Kashmore', 'Khairpur', 'Larkana', 'Malir', 'Mirpur Khas', 'Naushahro Feroze', 'Sanghar', 'Shaheed Benazirabad', 'Shikarpur', 'Sukkur', 'Thatta', 'Tharparkar', 'Umerkot'];
    }
    if (key == 'khyber pakhtunkhwa' || key == 'kpk') {
      return const ['Abbottabad', 'Bajaur', 'Bannu', 'Charsadda', 'Dera Ismail Khan', 'Hangu', 'Haripur', 'Karak', 'Khyber', 'Kohat', 'Kurram', 'Lakki Marwat', 'Lower Dir', 'Malakand', 'Mansehra', 'Mardan', 'Mohmand', 'North Waziristan', 'Nowshera', 'Orakzai', 'Peshawar', 'Shangla', 'Swabi', 'Swat', 'Tank', 'Upper Dir'];
    }
    if (key == 'balochistan') {
      return const ['Awaran', 'Barkhan', 'Chagai', 'Chaman', 'Dera Bugti', 'Gwadar', 'Hub', 'Jafarabad', 'Kalat', 'Kech', 'Khuzdar', 'Killa Abdullah', 'Killa Saifullah', 'Kohlu', 'Lasbela', 'Loralai', 'Mastung', 'Musakhel', 'Naseerabad', 'Nushki', 'Panjgur', 'Pishin', 'Quetta', 'Sherani', 'Sibi', 'Sohbatpur', 'Washuk', 'Zhob', 'Ziarat'];
    }
    if (key == 'islamabad capital territory' || key == 'islamabad') return const ['Islamabad'];
    if (key == 'azad jammu & kashmir' || key == 'ajk') return const ['Bagh', 'Bhimber', 'Haveli', 'Kotli', 'Mirpur', 'Muzaffarabad', 'Neelum', 'Poonch', 'Sudhanoti'];
    if (key == 'gilgit-baltistan') return const ['Astore', 'Diamer', 'Ghanche', 'Ghizer', 'Gilgit', 'Hunza', 'Kharmang', 'Shigar', 'Skardu'];
    return const [];
  }

  Widget _locationAutocomplete({
    required TextEditingController controller,
    required String label,
    required List<String> options,
    required bool required,
    ValueChanged<String>? onSelected,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Autocomplete<String>(
      key: ValueKey("${label}-${label == 'City' ? _province.text : 'province'}"),
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return options;
        return options.where((option) => option.toLowerCase().contains(query));
      },
      onSelected: (value) {
        controller.text = value;
        onSelected?.call(value);
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        if (fieldController.text.isEmpty && controller.text.isNotEmpty) {
          fieldController.text = controller.text;
        }
        return TextFormField(
          controller: fieldController,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) => controller.text = value,
          validator: required
              ? (value) => value == null || value.trim().isEmpty ? 'This field is required' : null
              : null,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(label == 'City' ? Icons.location_on_outlined : Icons.map_outlined),
          ),
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
    ),
  );

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
    required Set<String> customItems,
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
          children: [
            ...suggestions.map((item) => FilterChip(
              label: Text(item),
              selected: selected.contains(item),
              onSelected: _saving ? null : (_) => _toggleItem(selected, output, item),
            )),
            ...customItems.where((item) => !suggestions.contains(item)).map((item) => InputChip(
              label: Text(item),
              selected: selected.contains(item),
              showCheckmark: true,
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: _saving ? null : () => _removeCustomItem(selected, customItems, output, item),
              onSelected: _saving ? null : (_) => _toggleItem(selected, output, item),
            )),
          ],
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
                onSubmitted: (_) => _addCustomItem(selected, output, custom, customItems),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Add item',
              onPressed: _saving ? null : () => _addCustomItem(selected, output, custom, customItems),
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
