import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { context.push('/signin'); return; }
    if (_designation.text.trim().isEmpty || _details.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all verification details.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final db = FirebaseFirestore.instance;
      final existing = await db.collection('instituteClaims')
          .where('instituteId', isEqualTo: widget.instituteId)
          .where('representativeId', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'approved']).limit(1).get();
      if (existing.docs.isNotEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You already have a claim for this institute.')));
        return;
      }
      await db.collection('instituteClaims').add({
        'instituteId': widget.instituteId,
        'instituteName': widget.instituteName,
        'representativeId': user.uid,
        'representativeName': user.displayName?.trim().isNotEmpty == true ? user.displayName!.trim() : 'Representative',
        'representativeEmail': user.email ?? '',
        'designation': _designation.text.trim(),
        'verificationMethod': _method,
        'verificationDetails': _details.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim submitted for admin verification.')));
        context.pop();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not submit the claim. Please try again.')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Claim Institute')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(widget.instituteName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
