import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/institute_repository.dart';
import '../../data/institute_claim_repository.dart';
import '../../data/institute_access.dart';

class ClaimInstituteScreen extends StatefulWidget {
  final String instituteId;
  final String instituteName;
  const ClaimInstituteScreen({super.key, required this.instituteId, required this.instituteName});
  @override State<ClaimInstituteScreen> createState() => _ClaimInstituteScreenState();
}

class _ClaimInstituteScreenState extends State<ClaimInstituteScreen> {
  final _designation = TextEditingController();
  final _details = TextEditingController();
  String _method = 'Official email';
  bool _busy = false;
  final _methods = const ['Official email', 'Official phone', 'Document / authorization letter'];

  @override void dispose() { _designation.dispose(); _details.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (InstituteAccess.uid == null) { context.push('/signin'); return; }
    if (_designation.text.trim().isEmpty || _details.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all verification details.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final institute = InstituteRepository.instance.byId(widget.instituteId);
      if (institute == null) throw StateError('Institute not found.');
      await InstituteClaimRepository.instance.submit(institute,
        designation: _designation.text, method: _method, details: _details.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim submitted for admin verification.')));
        context.pop();
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit claim: $error')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Claim Institute')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(InstituteRepository.instance.byId(widget.instituteId)?.name ?? widget.instituteName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Create/Use your Talib account and submit proof that you represent this institute. Your claim will be reviewed by Talib admin.'),
      const SizedBox(height: 22),
      TextField(controller: _designation, decoration: const InputDecoration(labelText: 'Your designation', hintText: 'Principal, Director, Admin, etc.')),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: _method,
        decoration: const InputDecoration(labelText: 'Verification method'),
        items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
        onChanged: (v) => setState(() => _method = v ?? _method),
      ),
      const SizedBox(height: 14),
      TextField(controller: _details, maxLines: 4, decoration: const InputDecoration(labelText: 'Verification details', hintText: 'Official email, phone number, or document/reference details')),
      const SizedBox(height: 22),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: _busy ? null : _submit,
        icon: _busy ? const SizedBox(width: 18,height: 18,child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.verified_outlined),
        label: Text(_busy ? 'Submitting...' : 'Submit Claim'),
      )),
    ]),
  );
}
