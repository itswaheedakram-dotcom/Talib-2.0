import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../models/institute.dart';
import '../../data/institute_catalog.dart';
import '../../data/institute_repository.dart';
import '../../data/institute_image_service.dart';
import '../widgets/institute_image_preview.dart';

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

  final _catalog = InstituteCatalog.instance;
  final _repository = InstituteRepository.instance;
  String _type = '';
  String _subcategory = '';
  String _sector = 'Private';
  String _submission = 'Online';
  String _admissionStatus = 'Not announced';
  bool _entryTest = false;
  bool _saving = false;
  bool _uploadingImage = false;

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

  Future<void> _chooseImage() async {
    setState(() => _uploadingImage = true);
    try {
      final source = await InstituteImageService.instance.pickAndUpload();
      if (source != null && mounted) setState(() => _imageUrl.text = source);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select/upload image: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
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
              'Enter what you know. Optional details can be completed later by the verified institute representative.',
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
              Expanded(child: _field(_province, 'Province / Region', Icons.map_outlined, required: true)),
              const SizedBox(width: 10),
              Expanded(child: _field(_city, 'City', Icons.location_on_outlined, required: true)),
            ]),
            _field(_town, 'Town / Area', Icons.place_outlined),
            _field(_campus, 'Campus / Branch', Icons.location_city_outlined),
            _field(_address, 'Full address', Icons.pin_drop_outlined, maxLines: 2),
            DropdownButtonFormField<String>(
              value: _sector,
              decoration: const InputDecoration(labelText: 'Sector'),
              items: InstituteCatalog.sectors
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _sector = value ?? _sector),
            ),
            const SizedBox(height: 16),
            Text('Programs & eligibility', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _field(_programs, 'Programs / courses (comma separated)', Icons.menu_book_outlined, maxLines: 2),
            _field(_nextProgram, 'Featured / next program', Icons.school_outlined),
            _field(_eligibility, 'Eligibility criteria', Icons.rule_outlined, maxLines: 3),
            _field(_minScore, 'Minimum percentage / CGPA', Icons.percent,
                keyboard: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 8),
            Text('Admissions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _admissionStatus,
              decoration: const InputDecoration(labelText: 'Admission status'),
              items: InstituteCatalog.admissionStatuses
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _admissionStatus = value ?? _admissionStatus),
            ),
            const SizedBox(height: 12),
            _field(_deadline, 'Admission deadline', Icons.calendar_month_outlined),
            _field(_fee, 'Fee range / fee notes', Icons.payments_outlined),
            DropdownButtonFormField<String>(
              value: _submission,
              decoration: const InputDecoration(labelText: 'Application submission mode'),
              items: InstituteCatalog.submissionModes
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _submission = value ?? _submission),
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
            _field(_contact, 'Contact phone / email', Icons.phone_outlined),
            _field(_website, 'Official website URL', Icons.language_outlined, keyboard: TextInputType.url),
            _field(_applicationUrl, 'Direct admission / application URL', Icons.open_in_new_outlined, keyboard: TextInputType.url),
            Text('Cover image', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            InstituteImagePreview(
              source: _imageUrl.text,
              fallbackIcon: _catalog.iconFor(_type),
              label: _type.isEmpty ? 'Institute image' : _catalog.labelFor(_type),
              height: 150,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _uploadingImage || _saving ? null : _chooseImage,
              icon: _uploadingImage
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.photo_library_outlined),
              label: Text(_uploadingImage ? 'Uploading image...' : 'Choose image from gallery'),
            ),
            _field(_imageUrl, 'Or paste an image URL', Icons.image_outlined, keyboard: TextInputType.url),
            _field(_facilities, 'Facilities (comma separated)', Icons.checklist_outlined, maxLines: 2),
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
                  'This suggestion stays private until it is approved. Demo submissions stay in Demo mode and never write to Firebase.',
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

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      onChanged: controller == _imageUrl ? (_) => setState(() {}) : null,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'This field is required' : null
          : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    ),
  );
}
