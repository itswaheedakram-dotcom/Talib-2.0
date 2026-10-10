import '../../../../core/widgets/user_identity.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/active_profile_controller.dart';
import '../../../models/institute.dart';
import '../../../models/institute_review.dart';
import '../../data/institute_access.dart';
import '../../data/institute_review_repository.dart';
import 'institute_detail_components.dart';

class InstituteReviewsSection extends StatefulWidget {
  final Institute institute;
  const InstituteReviewsSection({super.key, required this.institute});
  @override
  State<InstituteReviewsSection> createState() => _InstituteReviewsSectionState();
}
class _InstituteReviewsSectionState extends State<InstituteReviewsSection> {
  final _repo = InstituteReviewRepository.instance;
  bool _loading = true;
  String? _error;
  String? _rankError;
  int _generation = 0;
  int _visible = 5;
  @override
  void initState() {
    super.initState();
    _repo.addListener(_changed);
    ActiveProfileController.instance.addListener(_reload);
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _reload(); });
  }
  @override
  void didUpdateWidget(InstituteReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.institute.id != widget.institute.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _reload(); });
    }
  }
  void _changed() { if (mounted) setState(() {}); }
  Future<void> _reload() async {
    if (!mounted) return;
    final generation = ++_generation;
    setState(() { _loading = true; _error = null; _rankError = null; _visible = 5; });
    try { await _repo.load(widget.institute.id); }
    catch (_) { if (mounted && generation == _generation) setState(() => _error = 'Reviews could not be loaded. Please retry.'); }
    if (!mounted || generation != _generation) return;
    setState(() => _loading = false);
    try { await _repo.loadRankings(); }
    catch (_) { if (mounted && generation == _generation) setState(() => _rankError = 'Community ranking is unavailable.'); }
    if (mounted && generation == _generation) setState(() {});
  }
  @override
  void dispose() {
    _repo.removeListener(_changed);
    ActiveProfileController.instance.removeListener(_reload);
    super.dispose();
  }
  Future<void> _edit(InstituteReview? existing) => showModalBottomSheet<void>(
    context: context, isScrollControlled: true, useSafeArea: true,
    builder: (_) => _ReviewComposer(institute: widget.institute, existing: existing),
  );
  @override
  Widget build(BuildContext context) {
    final items = _repo.forInstitute(widget.institute.id).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final summary = _repo.summary(widget.institute.id);
    final rank = _rankError == null && _error == null ? _repo.rank(widget.institute) : null;
    final ranked = _repo.ranked(widget.institute.type);
    final uid = InstituteAccess.uid;
    InstituteReview? mine;
    for (final review in items) { if (review.userId == uid) mine = review; }
    final own = mine;
    return InstituteDetailSection(title: 'Ratings & reviews', icon: Icons.star_outline,
      trailing: IconButton(tooltip: 'Refresh reviews', onPressed: _loading ? null : _reload, icon: const Icon(Icons.refresh)),
      children: [
        if (InstituteAccess.isDemo) const Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Demo ratings and reviews — sample data for testing.')),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[Text(_error!), TextButton(onPressed: _reload, child: const Text('Retry reviews'))]
        else ...[
          Wrap(spacing: 16, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(summary.count == 0 ? 'No ratings yet' : '${summary.average.toStringAsFixed(1)} / 5', style: Theme.of(context).textTheme.headlineSmall),
            Text('${summary.count} ${summary.count == 1 ? 'rating' : 'ratings'}'),
          ]),
          const SizedBox(height: 12),
          for (var stars = 5; stars >= 1; stars--) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
            Text('$stars'), const SizedBox(width: 5), Icon(Icons.star, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10), Expanded(child: LinearProgressIndicator(value: summary.count == 0 ? 0 : (summary.distribution[stars] ?? 0) / summary.count)),
            const SizedBox(width: 10), SizedBox(width: 32, child: Text('${summary.distribution[stars] ?? 0}')),
          ])),
          const SizedBox(height: 12),
          if (_rankError != null) ...[Text(_rankError!), TextButton(onPressed: _reload, child: const Text('Retry ranking'))]
          else if (rank != null) InstituteDetailBadge(label: 'Community rank #$rank of ${ranked.length}', icon: Icons.leaderboard_outlined)
          else Text(summary.eligibleForRank ? 'Community rank is loading.' : 'At least 3 ratings are needed for a community rank.'),
          const SizedBox(height: 8),
          const Text('Compared with reviewed institutes of the same category in this app. This is community feedback, not an official academic ranking.', style: TextStyle(fontSize: 12)),
          ExpansionTile(tilePadding: EdgeInsets.zero, title: const Text('How is the rank calculated?'), children: const [
            Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Each signed-in account has one rating. Ranking uses (total stars + 15) ÷ (number of ratings + 5). The extra weight is equivalent to five neutral 3-star ratings, so a very small number of reviews has less influence. Equal scores share the same rank.')),
          ]),
          if (uid == null || uid.isEmpty) const Text('Sign in to share your rating and review.')
          else Align(alignment: Alignment.centerLeft, child: FilledButton.icon(
            onPressed: _loading ? null : () => _edit(own), icon: const Icon(Icons.rate_review_outlined),
            label: Text(own == null ? 'Rate this institute' : 'Edit your review'))),
          const SizedBox(height: 12),
          if (items.isEmpty && !_loading) const Text('Be the first to share your experience.'),
          for (final review in items.take(_visible)) Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              UserIdentity(uid: review.userId, name: review.authorName),
              const SizedBox(height: 6), Text('${review.rating} / 5 stars · ${review.updatedAt.toLocal().toIso8601String().split('T').first}'),
              if (review.text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(review.text)),
            ]))),
          if (items.length > _visible) TextButton(onPressed: () => setState(() => _visible += 5), child: const Text('Show more reviews')),
        ],
      ]);
  }
}

class _ReviewComposer extends StatefulWidget {
  final Institute institute;
  final InstituteReview? existing;
  const _ReviewComposer({required this.institute, this.existing});
  @override
  State<_ReviewComposer> createState() => _ReviewComposerState();
}
class _ReviewComposerState extends State<_ReviewComposer> {
  late final _text = TextEditingController(text: widget.existing?.text ?? '');
  late int _rating = widget.existing?.rating ?? 0;
  final _uid = InstituteAccess.uid;
  bool _busy = false;
  String? _error;
  @override
  void dispose() { _text.dispose(); super.dispose(); }
  Future<void> _save({bool delete = false}) async {
    if (_busy) return;
    if (_uid == null || _uid != InstituteAccess.uid) { setState(() => _error = 'Your profile changed. Reopen the form.'); return; }
    if (!delete && _rating == 0) { setState(() => _error = 'Choose a star rating first.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      if (delete) { await InstituteReviewRepository.instance.delete(widget.institute.id); }
      else { await InstituteReviewRepository.instance.save(widget.institute.id, _rating, _text.text); }
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) setState(() { _busy = false; _error = 'Could not save your change: $e'; }); }
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_busy, child: SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Text('Your rating & review', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8), Text(widget.institute.name),
      const SizedBox(height: 16), const Text('Choose 1–5 stars'),
      Row(children: [for (var star = 1; star <= 5; star++) Expanded(child: IconButton(
        tooltip: '$star ${star == 1 ? 'star' : 'stars'}', icon: Icon(star <= _rating ? Icons.star : Icons.star_outline),
        color: Theme.of(context).colorScheme.primary,
        onPressed: _busy ? null : () => setState(() => _rating = star))),]),
      Text(_rating == 0 ? 'No rating selected' : '$_rating / 5 stars'),
      const SizedBox(height: 16), const Text('Your experience (optional)'), const SizedBox(height: 8),
      TextField(key: const ValueKey('institute-review-text'), controller: _text, enabled: !_busy,
        minLines: 3, maxLines: 5, maxLength: 1000,
        decoration: const InputDecoration(hintText: 'What was helpful? What could improve?')),
      const Text('Your name, rating and review will be public. Share your own experience.'),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      const SizedBox(height: 16), Wrap(spacing: 12, runSpacing: 8, alignment: WrapAlignment.end, children: [
        if (widget.existing != null) TextButton(onPressed: _busy ? null : () => _save(delete: true), child: const Text('Delete your review')),
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Saving…' : 'Publish review')),
      ]),
    ]),
  ));
}
