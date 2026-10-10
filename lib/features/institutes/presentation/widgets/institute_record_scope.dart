import 'package:flutter/material.dart';

import '../../../../core/services/active_profile_controller.dart';
import '../../data/institute_repository.dart';
import '../../data/institute_access.dart';

/// Recreate mode-sensitive forms/streams when a different test profile is selected.
class InstituteModeScope extends StatelessWidget {
  final Widget Function() builder;
  const InstituteModeScope({super.key, required this.builder});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ActiveProfileController.instance,
    builder: (context, _) => KeyedSubtree(
      key: ValueKey('${InstituteAccess.isDemo}:${InstituteAccess.uid}'),
      child: builder(),
    ),
  );
}

/// Loads deep links before opening forms and rebuilds detail screens after edits.
class InstituteRecordScope extends StatefulWidget {
  final String id;
  final Widget Function() builder;
  const InstituteRecordScope({
    super.key,
    required this.id,
    required this.builder,
  });
  @override
  State<InstituteRecordScope> createState() => _InstituteRecordScopeState();
}

class _InstituteRecordScopeState extends State<InstituteRecordScope> {
  bool _loading = true;
  int _generation = 0;
  final _repo = InstituteRepository.instance;
  @override
  void initState() {
    super.initState();
    _repo.addListener(_changed);
    ActiveProfileController.instance.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(InstituteRecordScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _load();
  }
  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() => _loading = true);
    await _repo.loadById(widget.id);
    if (mounted && generation == _generation) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _repo.removeListener(_changed);
    ActiveProfileController.instance.removeListener(_load);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_repo.byId(widget.id) == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Institute')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _repo.error == null
                    ? 'Institute not found.'
                    : 'Could not load this institute. Please retry.',
              ),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return widget.builder();
  }
}
