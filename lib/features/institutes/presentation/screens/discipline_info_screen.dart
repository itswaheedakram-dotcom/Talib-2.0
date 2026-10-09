import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../models/institute.dart';
import '../../data/institute_repository.dart';

class DisciplineInfoScreen extends StatefulWidget {
  final String instituteId;
  const DisciplineInfoScreen({super.key, required this.instituteId});

  @override
  State<DisciplineInfoScreen> createState() => _DisciplineInfoScreenState();
}

class _DisciplineInfoScreenState extends State<DisciplineInfoScreen> {
  final _subject = TextEditingController();
  final _repository = InstituteRepository.instance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onChanged);
    _repository.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repository.removeListener(_onChanged);
    _subject.dispose();
    super.dispose();
  }

  bool _canEdit(Institute institute) {
    if (ActiveProfileController.instance.isDemo) return true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid.isNotEmpty && institute.ownerId == uid;
  }

  Future<void> _addProgram(Institute institute) async {
    final name = _subject.text.trim();
    if (name.isEmpty) return;
    if (institute.programs.any((program) => program.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This program is already listed.')),
      );
      return;
    }
    setState(() => _saving = true);
    final updated = Institute.fromMap(
      institute.id,
      {...institute.toMap(), 'programs': [...institute.programs, name]},
    );
    final success = await _repository.update(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      _subject.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program added to the institute profile.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_repository.error ?? 'Could not add this program.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final institute = _repository.byId(widget.instituteId);
    if (institute == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Programs')),
        body: const Center(child: Text('Institute not found. Refresh and try again.')),
      );
    }
    final canEdit = _canEdit(institute);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Programs & Courses'),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Edit institute details',
              onPressed: () => context.push('/institute/${institute.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(institute.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          Text('Programs currently listed by this institute. Additions update the same shared institute record.'),
          const SizedBox(height: 16),
          if (institute.programs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(children: [
                  Icon(Icons.menu_book_outlined, size: 42, color: AppColors.primaryGreen),
                  SizedBox(height: 8),
                  Text('No programs listed yet', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('The verified representative can add programs to this profile.', textAlign: TextAlign.center),
                ]),
              ),
            )
          else
            ...institute.programs.map((program) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.softGreen,
                  child: Icon(Icons.menu_book_outlined, color: AppColors.darkGreen),
                ),
                title: Text(program, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(institute.subcategory.isEmpty
                    ? institute.name
                    : institute.subcategory),
              ),
            )),
          if (canEdit) ...[
            const SizedBox(height: 12),
            Text('Add a program', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextField(
                  controller: _subject,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. BS Computer Science',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  onSubmitted: (_) { if (!_saving) _addProgram(institute); },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : () => _addProgram(institute),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  child: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const Icon(Icons.add),
                ),
              ),
            ]),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Only the verified institute representative can add programs. Use Edit Institute to update multiple programs at once.',
                style: TextStyle(color: AppColors.mutedText),
              ),
            ),
        ],
      ),
    );
  }
}
