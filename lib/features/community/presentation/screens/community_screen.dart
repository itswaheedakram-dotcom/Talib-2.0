import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../models/post.dart';
import '../../../institutes/data/institute_repository.dart';
import '../../timeline_topics.dart';
import '../../data/community_feed_controller.dart';
import '../../data/community_preferences.dart';
import '../widgets/community_shimmer.dart';
import '../widgets/community_post_card.dart';
import '../widgets/community_people_results.dart';

class CommunityScreen extends StatefulWidget {
  final String? instituteId, instituteName, authorId;
  const CommunityScreen({
    super.key,
    this.instituteId,
    this.instituteName,
    this.authorId,
  });
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _db = DatabaseService(),
      _search = TextEditingController(),
      _scroll = ScrollController();
  CommunityFeedController? _feed;
  CommunityPreferences? _preferences;
  StreamSubscription<User?>? _auth;
  String _scope = '', _uid = '', _topic = 'All', _institute = '', _query = '';
  bool _following = false, _people = false, _guide = true;
  bool _prefsOpen = false;
  bool get _demo => ActiveProfileController.instance.isDemo;
  String get _currentUid => _demo
      ? (ActiveProfileController.instance.effectiveUid ?? '')
      : (FirebaseService.initialized
            ? FirebaseAuth.instance.currentUser?.uid ?? ''
            : '');
  String get _currentScope => '${_demo ? 'demo' : 'real'}:$_currentUid';
  bool get _canInteract => _uid.isNotEmpty;
  @override
  void initState() {
    super.initState();
    ActiveProfileController.instance.addListener(_identityChanged);
    if (FirebaseService.initialized)
      _auth = FirebaseAuth.instance.authStateChanges().listen(
        (_) => _identityChanged(),
      );
    InstituteRepository.instance.addListener(_changed);
    InstituteRepository.instance.load();
    _bind();
    _scroll.addListener(_scrollChanged);
  }

  void _identityChanged() {
    if (_scope != _currentScope) {
      if (_prefsOpen) Navigator.of(context, rootNavigator: true).pop();
      _bind();
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _bind() {
    _feed?.removeListener(_changed);
    _feed?.dispose();
    _preferences?.removeListener(_changed);
    _preferences?.dispose();
    _scope = _currentScope;
    _uid = _currentUid;
    _query = '';
    _search.clear();
    _topic = 'All';
    _institute = '';
    _people = false;
    _following = false;
    _guide = true;
    _feed = CommunityFeedController(demo: _demo, uid: _uid)
      ..addListener(_changed);
    _preferences = CommunityPreferences(demo: _demo, uid: _uid)
      ..addListener(_changed);
    _preferences!.start();
    _feed!.start();
    _loadGuide();
    if (mounted) setState(() {});
  }

  Future<void> _loadGuide() async {
    final scope = _scope;
    final prefs = await SharedPreferences.getInstance();
    if (mounted && scope == _scope)
      setState(
        () =>
            _guide = !(prefs.getBool('talib.community.guide.$scope') ?? false),
      );
  }

  Future<void> _hideGuide() async {
    final scope = _scope;
    setState(() => _guide = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('talib.community.guide.$scope', true);
  }

  @override
  void dispose() {
    _feed?.removeListener(_changed);
    _feed?.dispose();
    _preferences?.removeListener(_changed);
    _preferences?.dispose();
    _auth?.cancel();
    ActiveProfileController.instance.removeListener(_identityChanged);
    InstituteRepository.instance.removeListener(_changed);
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollChanged() {
    if (!_people &&
        _scroll.hasClients &&
        _scroll.position.extentAfter < 400 &&
        _feed?.hasMore == true &&
        _feed?.loadingMore == false &&
        _feed?.error == null)
      _feed!.loadMore();
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _act(Future<void> Function() action, {String? success}) async {
    final scope = _scope;
    try {
      await action();
      if (mounted && scope == _scope && success != null) _message(success);
    } catch (_) {
      if (mounted && scope == _scope)
        _message('Could not complete this action. Please retry.');
    }
  }

  Future<void> _create([String type = '']) async {
    if (!_canInteract) {
      _message('Sign in to create a post.');
      return;
    }
    final scope = _scope;
    final result = await context.push(
      '/community/create?type=${Uri.encodeComponent(type)}&instituteId=${Uri.encodeComponent(widget.instituteId ?? '')}&instituteName=${Uri.encodeComponent(widget.instituteName ?? '')}',
    );
    if (result == true && mounted && scope == _scope) {
      await _feed!.refresh();
      _top();
    }
  }

  void _top() {
    if (_scroll.hasClients)
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
  }

  Future<void> _open(Post p) async {
    final scope = _scope;
    await context.push('/community/post/${p.id}');
    if (mounted && scope == _scope) _feed?.refreshPost(p.id);
  }

  Future<void> _react(Post p, String? value) async {
    final uid = _uid, scope = _scope;
    await _db.setReaction(p.id, uid, value);
    if (mounted && scope == _scope) await _feed?.refreshPost(p.id);
  }

  Future<void> _save(Post p) async {
    final saved = _preferences!.saved.contains(p.id);
    await _act(
      () => _db.toggleBookmark(p.id, _uid, !saved),
      success: saved ? 'Removed from saved posts' : 'Post saved',
    );
  }

  Future<void> _hide(Post p, {bool notInterested = false}) async {
    final prefs = _preferences!;
    await _act(
      () => prefs.hide(p, reason: notInterested ? 'not_interested' : 'hide'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notInterested
              ? 'We will hide this post from your feed.'
              : 'Post hidden',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _act(() => prefs.restore('hiddenPosts', p.id)),
        ),
      ),
    );
  }

  Future<void> _delete(Post p) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This permanently removes the post.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true)
      await _act(() async {
        await _db.deletePost(p.id);
        _feed?.remove(p.id);
      });
  }

  Future<void> _report(Post p) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const Text('Report post'),
        children:
            [
                  'Spam',
                  'Harassment',
                  'Fake information',
                  'Inappropriate',
                  'Scam',
                  'Other',
                ]
                .map(
                  (v) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(dialog, v),
                    child: Text(v),
                  ),
                )
                .toList(),
      ),
    );
    if (reason != null)
      await _act(
        () => _db.report(
          reporterId: _uid,
          targetId: p.id,
          targetType: 'post',
          reason: reason,
        ),
        success: 'Report submitted for review',
      );
  }

  Future<void> _feedPreferences() async {
    final prefs = _preferences!;
    _prefsOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => ListenableBuilder(
        listenable: prefs,
        builder: (context, _) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .65,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Feed preferences',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                for (final entry in {
                  'Hidden posts': ('hiddenPosts', prefs.hidden),
                  'Muted people': ('mutedAuthors', prefs.muted),
                  'Blocked people': ('blockedUsers', prefs.blocked),
                }.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (entry.value.$2.isEmpty) const Text('None'),
                  for (final item in entry.value.$2.entries)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: TextButton(
                        onPressed: () =>
                            _act(() => prefs.restore(entry.value.$1, item.key)),
                        child: const Text('Restore'),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    setState(() => _guide = true);
                  },
                  child: const Text('Show guidance shortcut'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _prefsOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feed!, prefs = _preferences!;
    final selectedInstitutes = InstituteRepository.instance.items
        .where((i) => prefs.institutes.contains(i.id))
        .toList();
    final filtered = feed.posts
        .where(
          (p) =>
              prefs.allows(p) &&
              (!_following || prefs.following.contains(p.authorId)) &&
              (widget.authorId == null || p.authorId == widget.authorId) &&
              (widget.instituteId == null ||
                  p.instituteIds.contains(widget.instituteId) ||
                  p.instituteId == widget.instituteId) &&
              (_institute.isEmpty ||
                  p.instituteIds.contains(_institute) ||
                  p.instituteId == _institute) &&
              (_topic == 'All' ||
                  (p.tags.isEmpty ? [p.category] : p.tags).any(
                    (t) => TimelineTopics.matches(_topic, t),
                  )) &&
              (_query.isEmpty ||
                  '${p.text} ${p.authorName} ${p.tags.join(' ')} ${p.educationalData.values.join(' ')}'
                      .toLowerCase()
                      .contains(_query.toLowerCase())),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.authorId != null
              ? 'My posts'
              : widget.instituteName == null
              ? 'Community'
              : '${widget.instituteName} community',
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Feed options',
            onSelected: (v) {
              if (v == 'preferences') {
                _feedPreferences();
              } else if (v == 'topics') {
                context.push('/community/add-to-timeline');
              } else {
                feed.changeSort(v);
                _top();
              }
            },
            itemBuilder: (_) => [
              for (final sort in ['Latest', 'Popular'])
                PopupMenuItem(
                  value: sort,
                  child: Text('${feed.sort == sort ? '✓ ' : ''}$sort'),
                ),
              if (_canInteract)
                const PopupMenuItem(
                  value: 'preferences',
                  child: Text('Feed preferences'),
                ),
              if (_canInteract)
                const PopupMenuItem(
                  value: 'topics',
                  child: Text('Manage topics'),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Create post'),
      ),
      body: Column(
        children: [
          if (_guide)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Need guidance?',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _create('question'),
                    child: const Text('Ask a question'),
                  ),
                  IconButton(
                    tooltip: 'Dismiss guidance',
                    onPressed: _hideGuide,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('For You'),
                  selected: !_following,
                  onSelected: (_) {
                    setState(() => _following = false);
                    _top();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Following'),
                  selected: _following,
                  onSelected: (_) {
                    setState(() => _following = true);
                    _top();
                  },
                ),

                Text(
                  feed.sort,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!_people)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('All topics'),
                      selected: _topic == 'All' && _institute.isEmpty,
                      onSelected: (_) => setState(() {
                        _topic = 'All';
                        _institute = '';
                      }),
                    ),
                  ),
                  for (final topic in prefs.topics)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(topic),
                        selected: _topic == topic,
                        onSelected: (_) => setState(() {
                          _topic = topic;
                          _institute = '';
                        }),
                      ),
                    ),
                  for (final i in selectedInstitutes)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(i.name),
                        selected: _institute == i.id,
                        onSelected: (_) => setState(() {
                          _institute = i.id;
                          _topic = 'All';
                        }),
                      ),
                    ),
                  ActionChip(
                    label: const Text('+ Topics'),
                    onPressed: _canInteract
                        ? () => context.push('/community/add-to-timeline')
                        : null,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: _people ? 'Search people' : 'Search community',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty || _people)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Posts'),
                    selected: !_people,
                    onSelected: (_) => setState(() => _people = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('People'),
                    selected: _people,
                    onSelected: (_) => setState(() => _people = true),
                  ),
                ],
              ),
            ),
          if (prefs.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      prefs.error!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(onPressed: _bind, child: const Text('Retry')),
                ],
              ),
            ),
          if (feed.pendingCount > 0 && !_people)
            TextButton.icon(
              onPressed: () {
                feed.showNewPosts();
                _top();
              },
              icon: const Icon(Icons.arrow_upward, size: 18),
              label: Text(
                '${feed.pendingCount} ${feed.sort == 'Latest' ? 'new posts' : 'feed updates'} available',
              ),
            ),
          Expanded(
            child: _people
                ? CommunityPeopleResults(
                    key: ValueKey(_scope),
                    query: _query,
                    demo: _demo,
                    uid: _uid,
                  )
                : (feed.loading || (_following && !prefs.followingReady))
                ? const CommunityShimmer()
                : feed.error != null && feed.posts.isEmpty
                ? _empty(feed.error!, retry: true)
                : RefreshIndicator(
                    onRefresh: feed.refresh,
                    child: ListView.separated(
                      key: PageStorageKey('community.$_scope'),
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                      itemCount: filtered.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        if (index == filtered.length) {
                          if (filtered.isEmpty)
                            return SizedBox(
                              height: 250,
                              child: _empty(
                                _following && prefs.following.isEmpty
                                    ? 'Follow people to see their posts.'
                                    : _query.isNotEmpty
                                    ? 'No posts match this search.'
                                    : 'No posts here yet.',
                                more: feed.hasMore,
                              ),
                            );
                          return Column(
                            children: [
                              if (feed.error != null)
                                Text(feed.error!, textAlign: TextAlign.center),
                              if (feed.loadingMore)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else if (feed.hasMore || feed.error != null)
                                TextButton(
                                  onPressed: feed.loadMore,
                                  child: const Text('Load more posts'),
                                )
                              else
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'You are all caught up',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          );
                        }
                        final post = filtered[index],
                            owner = post.authorId == _uid;
                        return CommunityPostCard(
                          key: ValueKey(post.id),
                          post: post,
                          uid: _uid,
                          saved: prefs.saved.contains(post.id),
                          onOpen: () => _open(post),
                          onAuthor: () =>
                              context.push('/profile/${post.authorId}'),
                          onReact: _canInteract
                              ? (value) => _react(post, value)
                              : null,
                          onSave: _canInteract ? () => _save(post) : null,
                          onPoll: _canInteract
                              ? (index) => _act(() async {
                                  await _db.votePoll(
                                    postId: post.id,
                                    uid: _uid,
                                    option: index,
                                  );
                                  await feed.refreshPost(post.id);
                                })
                              : null,
                          menu: {
                            if (owner)
                              'Edit': () => context
                                  .push('/community/create', extra: post)
                                  .then((_) => feed.refreshPost(post.id)),
                            if (owner) 'Delete': () => _delete(post),
                            if (_canInteract) 'Hide post': () => _hide(post),
                            if (_canInteract && !owner)
                              'Not interested': () =>
                                  _hide(post, notInterested: true),
                            if (_canInteract && !owner)
                              'Mute ${post.authorName}': () => _act(
                                () => prefs.mute(post),
                                success: 'Person muted',
                              ),
                            if (_canInteract &&
                                !owner &&
                                prefs.following.contains(post.authorId))
                              'Unfollow': () => _act(
                                () => _db.toggleFollow(
                                  _uid,
                                  post.authorId,
                                  false,
                                ),
                              ),
                            if (_canInteract && !owner)
                              'Report': () => _report(post),
                            if (_canInteract && !owner)
                              'Block': () => _act(
                                () => prefs.block(post),
                                success: 'Person blocked',
                              ),
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String message, {bool retry = false, bool more = false}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                retry ? Icons.cloud_off_outlined : Icons.forum_outlined,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  if (retry)
                    OutlinedButton(
                      onPressed: () => _feed!.refresh(),
                      child: const Text('Retry'),
                    ),
                  if (more)
                    OutlinedButton(
                      onPressed: _feed!.loadingMore ? null : _feed!.loadMore,
                      child: Text(
                        _feed!.loadingMore ? 'Loading…' : 'Search more posts',
                      ),
                    ),
                  if (!retry)
                    OutlinedButton(
                      onPressed: () => setState(() => _people = true),
                      child: const Text('Find people'),
                    ),
                  if (_canInteract && !retry)
                    FilledButton(
                      onPressed: () => _create(),
                      child: const Text('Create post'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}
