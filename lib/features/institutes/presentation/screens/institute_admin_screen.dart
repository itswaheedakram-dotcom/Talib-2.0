import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

class InstituteAdminScreen extends StatefulWidget {
  final String claimId;
  const InstituteAdminScreen({super.key, required this.claimId});

  @override
  State<InstituteAdminScreen> createState() => _InstituteAdminScreenState();
}

class _InstituteAdminScreenState extends State<InstituteAdminScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _description = TextEditingController();
  bool _busy = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndSave();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _contact.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadAndSave({bool save = false}) async {
    if (save) {
      if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Institute name and address are required.')),
        );
        return;
      }
      setState(() {
        _saving = true;
        _error = null;
      });
    } else {
      setState(() {
        _busy = true;
        _error = null;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Please sign in with the approved representative account.');
      final claimRef = FirebaseFirestore.instance.collection('instituteClaims').doc(widget.claimId);
      final claim = await claimRef.get();
      final data = claim.data() ?? <String, dynamic>{};
      if (!claim.exists ||
          data['representativeId'] != user.uid ||
          data['status'] != 'approved') {
        throw StateError('This approved institute claim is not assigned to your account.');
      }
      final instituteId = (data['instituteId'] ?? '').toString();
      if (instituteId.isEmpty) throw StateError('The claim is missing its institute ID.');
      final instituteRef = FirebaseFirestore.instance.collection('institutes').doc(instituteId);

      if (save) {
        await instituteRef.update({
          'name': _name.text.trim(),
          'address': _address.text.trim(),
          'contact': _contact.text.trim(),
          'description': _description.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Institute profile updated.')),
          );
        }
      } else {
        final doc = await instituteRef.get();
        final data = doc.data() ?? <String, dynamic>{};
        _name.text = (data['name'] ?? claim.data()?['instituteName'] ?? '').toString();
        _address.text = (data['address'] ?? '').toString();
        _contact.text = (data['contact'] ?? data['phone'] ?? '').toString();
        _description.text = (data['description'] ?? '').toString();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Scaffold(
        appBar: AppBar(title: Text('Manage Institute')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _name.text.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Institute')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.primaryGreen),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton(onPressed: () => _loadAndSave(), child: const Text('Retry')),
          ]),
        )),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Institute')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Basic information', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Institute name')),
        const SizedBox(height: 12),
        TextField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'Address')),
        const SizedBox(height: 12),
        TextField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact phone or email')),
        const SizedBox(height: 12),
        TextField(controller: _description, maxLines: 4, decoration: const InputDecoration(labelText: 'About institute')),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _saving ? null : () => _loadAndSave(save: true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                : const Text('Save Changes'),
          ),
        ),
      ]),
    );
  }
}
