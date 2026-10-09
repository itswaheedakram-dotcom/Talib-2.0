import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../institutes/data/institute_catalog.dart';
import '../../../institutes/data/institute_repository.dart';
import '../../../models/post.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demo = ActiveProfileController.instance.isDemo;
    if (!demo && !FirebaseService.initialized) {
      return const Scaffold(
        appBar: AppBar(title: Text('Bookmarks')),
        body: _EmptyState(
          icon: Icons.cloud_off,
          title: 'Bookmarks unavailable',
          message: 'Firebase is not configured yet. Activate a demo profile to test bookmarks locally.',
        ),
      );
    }
    final uid = demo
        ? ActiveProfileController.instance.effectiveUid
        : FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bookmarks')),
        body: const _EmptyState(
          icon: Icons.bookmark_border,
          title: 'Sign in to view bookmarks',
          message: 'Save useful posts and institutes to keep them here for later.',
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookmarks'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.forum_outlined), text: 'Posts'),
              Tab(icon: Icon(Icons.school_outlined), text: 'Institutes'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _PostBookmarksTab(uid: uid),
          _InstituteBookmarksTab(uid: uid),
        ]),
      ),
    );
  }
}

class _PostBookmarksTab extends StatelessWidget {
  final String uid;
  const _PostBookmarksTab({required this.uid});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Post>>(
    stream: DatabaseService().bookmarkedPostsStream(uid),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load post bookmarks',
          message: 'Please retry in a moment.',
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      final posts = snapshot.data ?? const <Post>[];
      if (posts.isEmpty) {
        return const _EmptyState(
          icon: Icons.bookmark_border,
          title: 'No saved posts',
          message: 'Tap the bookmark icon on a community post to save it here.',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final post = posts[index];
          return _PostBookmarkCard(
            post: post,
            onOpen: () => context.push('/community/post/${post.id}'),
            onRemove: () => DatabaseService().toggleBookmark(post.id, uid, false),
          );
        },
      );
    },
  );
}

class _InstituteBookmarksTab extends StatefulWidget {
  final String uid;
  const _InstituteBookmarksTab({required this.uid});

  @override
  State<_InstituteBookmarksTab> createState() => _InstituteBookmarksTabState();
}

class _InstituteBookmarksTabState extends State<_InstituteBookmarksTab> {
  final _repository = InstituteRepository.instance;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Set<String>>(
    stream: DatabaseService().instituteBookmarkIdsStream(widget.uid),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const _EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load institute bookmarks',
          message: 'Please retry in a moment.',
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final ids = snapshot.data ?? const <String>{};
      if (ids.isEmpty) {
        return const _EmptyState(
          icon: Icons.school_outlined,
          title: 'No saved institutes',
          message: 'Save an institute from its details page to find it here.',
        );
      }
      final institutes = ids
          .map(_repository.byId)
          .whereType<Institute>()
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (institutes.isEmpty && _repository.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (institutes.isEmpty) {
        return const _EmptyState(
          icon: Icons.school_outlined,
          title: 'Saved institutes not available',
          message: 'Refresh institute data and try again.',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: institutes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final institute = institutes[index];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.softGreen,
                child: Icon(InstituteCatalog.instance.iconFor(institute.type), color: AppColors.darkGreen),
              ),
              title: Text(institute.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text([
                InstituteCatalog.instance.labelFor(institute.type),
                if (institute.city.isNotEmpty) institute.city,
              ].join(' • ')),
              onTap: () => context.push('/institute/${institute.id}'),
              trailing: IconButton(
                tooltip: 'Remove bookmark',
                onPressed: () async {
                  try {
                    await DatabaseService().toggleInstituteBookmark(widget.uid, institute.id, false);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not remove bookmark: $error')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.bookmark, color: AppColors.primaryGreen),
              ),
            ),
          );
        },
      );
    },
  );
}

class _PostBookmarkCard extends StatelessWidget {
  final Post post;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  const _PostBookmarkCard({required this.post, required this.onOpen, required this.onRemove});

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: AppColors.softGreen,
              child: Text(
                post.authorName.isEmpty ? '?' : post.authorName[0].toUpperCase(),
                style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w600))),
            IconButton(onPressed: onRemove, tooltip: 'Remove bookmark', icon: const Icon(Icons.bookmark)),
          ]),
          const SizedBox(height: 8),
          Text(post.text, maxLines: 4, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Text('${post.likesCount} likes • ${post.commentsCount} comments',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
        ]),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _EmptyState({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: AppColors.primaryGreen),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
        const SizedBox(height: 18),
        SizedBox(width: 150, child: FilledButton(
          onPressed: () => context.push('/signin'),
          child: const Text('Sign In'),
        )),
      ]),
    ),
  );
}
