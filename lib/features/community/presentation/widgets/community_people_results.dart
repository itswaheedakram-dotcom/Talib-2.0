import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/user_profile_repository.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/widgets/user_identity.dart';
import 'community_shimmer.dart';

class CommunityPeopleResults extends StatefulWidget {
  final String query, uid;
  final bool demo;
  const CommunityPeopleResults({
    super.key,
    required this.query,
    required this.uid,
    required this.demo,
  });
  @override
  State<CommunityPeopleResults> createState() => _CommunityPeopleResultsState();
}

class _CommunityPeopleResultsState extends State<CommunityPeopleResults> {
  final List<UserProfile> _people = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = true, _more = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.demo) {
        _people.clear();
        _people.addAll(
          temporaryProfiles
              .map((p) => UserProfileRepository.instance.demoProfile(p.id))
              .where((p) => !p.privateProfile),
        );
        _more = false;
      } else {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection('users')
            .where('privateProfile', isEqualTo: false)
            .orderBy(FieldPath.documentId)
            .limit(100);
        if (_cursor != null) query = query.startAfterDocument(_cursor!);
        final docs = await query.get();
        if (!mounted) return;
        _people.addAll(
          docs.docs.map((d) => UserProfile.fromMap(d.id, d.data())),
        );
        _cursor = docs.docs.lastOrNull;
        _more = docs.docs.length == 100;
      }
    } catch (_) {
      _error = 'People could not be loaded. Please retry.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _people.isEmpty) return const CommunityShimmer();
    final query = widget.query.toLowerCase(),
        people = _people
            .where(
              (p) =>
                  p.uid != widget.uid &&
                  '${p.name} ${p.username} ${p.course} ${p.instituteName} ${p.city}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_error != null) Text(_error!),
        if (people.isEmpty && !_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'No matching public profiles.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final p in people)
          ListTile(
            title: UserIdentity(uid: p.uid, name: p.name, showUsername: false),
            subtitle: Text(
              [
                if (p.username.isNotEmpty) '@${p.username}',
                p.course,
                p.instituteName,
              ].where((v) => v.isNotEmpty).join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/${p.uid}'),
          ),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_more || _error != null)
          TextButton(
            onPressed: _load,
            child: Text(_error == null ? 'Search more people' : 'Retry'),
          ),
      ],
    );
  }
}
