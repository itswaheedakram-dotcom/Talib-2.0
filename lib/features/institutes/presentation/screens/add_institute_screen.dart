import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddInstituteScreen extends StatefulWidget {
  final String type;
  const AddInstituteScreen({super.key, required this.type});
  @override State<AddInstituteScreen> createState() => _AddInstituteScreenState();
}

class _AddInstituteScreenState extends State<AddInstituteScreen> {
  final _name = TextEditingController();
  final _campus = TextEditingController();
  final _city = TextEditingController();
  final _province = TextEditingController();
  final _description = TextEditingController();
  final _website = TextEditingController();
  String _sector = 'Private';
  String _submission = 'Online';

  String get title => switch (widget.type) {
    'schools' => 'Add School',
    'colleges' => 'Add College',
    'universities' => 'Add University',
    _ => 'Add Institute',
  };

  @override void dispose() {
    for (final c in [_name, _campus, _city, _province, _description, _website]) c.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty || _city.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter institute name and city.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Institute submitted for admin approval.')));
    context.pop();
  }

  @override Widget build(BuildContext context) {
    const green = Color(0xFF00A66A);
    const darkGreen = Color(0xFF00543D);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.pop()),
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          const Text('Institute Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkGreen)),
          const SizedBox(height: 12),
          _field(_name, 'Institute Name', Icons.account_balance_outlined),
          _field(_campus, 'Campus', Icons.location_city_outlined),
          Row(children: [
            Expanded(child: _field(_province, 'Province', Icons.map_outlined)),
            const SizedBox(width: 10),
            Expanded(child: _field(_city, 'City', Icons.location_on_outlined)),
          ]),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: _sector,
            decoration: const InputDecoration(labelText: 'Sector', prefixIcon: Icon(Icons.business_outlined)),
            items: const ['Private', 'Government', 'Semi-government'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _sector = v ?? _sector),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _submission,
            decoration: const InputDecoration(labelText: 'Application Submission', prefixIcon: Icon(Icons.link_outlined)),
            items: const ['Online', 'Physical'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _submission = v ?? _submission),
          ),
          const SizedBox(height: 12),
          _field(_website, 'Website', Icons.language_outlined),
          _field(_description, 'Description', Icons.description_outlined, maxLines: 4),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEAF8F2), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: green),
              SizedBox(width: 9),
              Expanded(child: Text('Your institute will be reviewed by an admin before it appears publicly.')),
            ]),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 50, child: FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(backgroundColor: green),
            child: const Text('Submit Institute'),
          )),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: controller, maxLines: maxLines, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon))),
    );
  }
}
