import '../../../../core/models/user_profile.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../data/institute_access.dart';
import '../../data/institute_claim_repository.dart';
import '../../data/institute_repository.dart';
import '../../../models/institute.dart';

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
      final data = await InstituteClaimRepository.instance.get(widget.claimId);
      if (data == null || data['representativeId'] != InstituteAccess.uid || data['status'] != 'approved') {
        throw StateError('This approved claim is not assigned to your account.');
      }
      final instituteId = (data['instituteId'] ?? '').toString();
      final institute = await InstituteRepository.instance.loadById(instituteId);
      if (!mounted) return;
      if (institute == null || !InstituteAccess.canManage(institute)) throw StateError('Institute management access required.');

      if (save) {
        final ok = await InstituteRepository.instance.update(Institute.fromMap(institute.id, {
          ...institute.toMap(), ProfileFields.name: _name.text.trim(), 'address': _address.text.trim(),
          'contact': _contact.text.trim(), 'description': _description.text.trim(),
        }));
        if (!ok) throw StateError(InstituteRepository.instance.error ?? 'Could not save institute.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Institute profile updated.')),
          );
        }
      } else {
        _name.text = institute.name;
        _address.text = institute.address;
        _contact.text = institute.contact;
        _description.text = institute.description;
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
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Institute')),
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
