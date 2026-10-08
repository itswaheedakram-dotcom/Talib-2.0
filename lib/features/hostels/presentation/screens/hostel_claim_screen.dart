import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../data/hostel_repository.dart';

class HostelClaimScreen extends StatefulWidget {
  final String hostelId;
  final String hostelName;
  final bool isDemo;

  const HostelClaimScreen({
    super.key,
    required this.hostelId,
    required this.hostelName,
    this.isDemo = false,
  });

  @override
  State<HostelClaimScreen> createState() => _HostelClaimScreenState();
}

class _HostelClaimScreenState extends State<HostelClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  bool get _isDemoHostel => widget.isDemo || HostelRepository.demoHostels.any((h) => h.id == widget.hostelId);

  @override
  void initState() {
    super.initState();
    final active = ActiveProfileController.instance.active;
    if (active != null) {
      _name.text = active.name;
    } else {
      final user = FirebaseService.initialized ? FirebaseAuth.instance.currentUser : null;
      _name.text = user?.displayName?.trim() ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final active = ActiveProfileController.instance.active;
      final user = FirebaseService.initialized ? FirebaseAuth.instance.currentUser : null;
      final demoIdentity = active != null;
      final userId = active?.id ?? user?.uid;
      if (userId == null || userId.isEmpty) {
        if (mounted) context.push('/signin');
        return;
      }
      final existing = await HostelRepository().getMyClaim(widget.hostelId, userId);
      if (existing != null && (existing.status == 'pending' || existing.status == 'approved')) {
        if (!mounted) return;
        final message = existing.status == 'approved'
            ? 'You already own or have an approved claim for this hostel.'
            : 'Your claim for this hostel is already pending.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      await HostelRepository.submitClaim(
        hostelId: widget.hostelId,
        hostelName: widget.hostelName,
        userId: userId,
        userName: _name.text.trim(),
        contact: _contact.text.trim(),
        note: _note.text.trim(),
        demo: demoIdentity || _isDemoHostel || !FirebaseService.initialized,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim request submitted. Status: Pending.')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim request could not be submitted.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Claim Hostel')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: AppColors.softGreen, child: Icon(Icons.hotel_rounded, color: AppColors.primaryGreen)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(widget.hostelName, style: const TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Request ownership', style: TextStyle(color: AppColors.darkGreen, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            const Text('Submit your details. The hostel remains unchanged until the claim is approved.', style: TextStyle(color: AppColors.mutedText, height: 1.4)),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Your name', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contact,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact number', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Proof / ownership note (optional)', prefixIcon: Icon(Icons.description_outlined)),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: AppColors.white),
                icon: _saving ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Icon(Icons.send_outlined),
                label: Text(_saving ? 'Submitting...' : 'Submit Claim'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}