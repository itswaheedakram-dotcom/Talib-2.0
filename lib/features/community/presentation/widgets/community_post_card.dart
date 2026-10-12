import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/user_identity.dart';
import '../../../models/post.dart';
import '../../../institutes/data/institute_repository.dart';
import '../../domain/community_reaction.dart';
import '../../domain/post_templates.dart';

String postAge(DateTime time) {
  final elapsed = DateTime.now().difference(time);
  if (elapsed.inSeconds < 60) return 'Just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}

class CommunityPostCard extends StatelessWidget {
  final Post post;
  final String uid;
  final bool saved, full, preview;
  final VoidCallback? onOpen, onAuthor, onSave;
  final Future<void> Function(String?)? onReact;
  final Future<void> Function(int)? onPoll;
  final Map<String, VoidCallback> menu;
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.uid,
    this.saved = false,
    this.full = false,
    this.preview = false,
    this.onOpen,
    this.onAuthor,
    this.onSave,
    this.onReact,
    this.onPoll,
    this.menu = const {},
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme,
        template = PostTemplates.byId(post.postType);
    final instituteNames =
        (post.instituteIds.isEmpty
                ? [if (post.instituteId != null) post.instituteId!]
                : post.instituteIds)
            .map((id) => InstituteRepository.instance.byId(id)?.name)
            .whereType<String>()
            .toList();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onAuthor,
                      child: UserIdentity(
                        uid: post.authorId,
                        name: post.authorName,
                        showUsername: false,
                      ),
                    ),
                  ),
                  if (menu.isNotEmpty)
                    PopupMenuButton<String>(
                      tooltip: 'Post options',
                      onSelected: (v) => menu[v]?.call(),
                      itemBuilder: (_) => menu.keys
                          .map((v) => PopupMenuItem(value: v, child: Text(v)))
                          .toList(),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  '${postAge(post.createdAt)}${post.updatedAt == null ? '' : ' • Edited'}${preview ? ' • Preview' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (post.postType != 'general' ||
                  post.isQuestion ||
                  instituteNames.isNotEmpty ||
                  post.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (post.postType != 'general')
                        _chip(context, '${template.emoji} ${template.label}'),
                      if (post.isQuestion)
                        _chip(
                          context,
                          post.bestAnswerId != null &&
                                  post.bestAnswerId!.isNotEmpty
                              ? '✓ Best answer selected'
                              : post.commentsCount > 0
                              ? 'Has replies'
                              : 'Unanswered',
                        ),
                      ...instituteNames
                          .take(full ? 10 : 1)
                          .map((v) => _chip(context, v)),
                      ...post.tags
                          .where(
                            (tag) =>
                                tag.trim().isNotEmpty && tag != template.topic,
                          )
                          .take(full ? 10 : 1)
                          .map((v) => _chip(context, v)),
                    ],
                  ),
                ),
              Text(
                post.text,
                maxLines: full ? null : 5,
                overflow: full ? null : TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),
              if (!full &&
                  (post.text.length > 230 || post.text.split('\n').length > 5))
                TextButton(
                  onPressed: onOpen,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Read more'),
                ),
              if (post.educationalData.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final field
                          in template.fields
                              .where(
                                (f) =>
                                    (post.educationalData[f.key] ?? '')
                                        .isNotEmpty &&
                                    (full || f.key != 'eligibility'),
                              )
                              .take(full ? 20 : 4))
                        if (field.kind == 'url')
                          _urlTile(
                            context,
                            post.educationalData[field.key]!,
                            field.label,
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '${field.label}: ${post.educationalData[field.key]}',
                              maxLines: full ? null : 2,
                              overflow: full ? null : TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              if (template.communityAnnouncement)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Community shared • Verify details with the official institute.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              if (post.attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: CommunityAttachments(
                    attachments: post.attachments,
                    full: full,
                  ),
                ),
              if (post.pollOptions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.pollClosed
                            ? 'Poll closed'
                            : 'Poll${post.pollClosesAt == null ? '' : ' • closes ${post.pollClosesAt!.day}/${post.pollClosesAt!.month}/${post.pollClosesAt!.year}'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      for (var i = 0; i < post.pollOptions.length; i++)
                        _pollOption(context, i),
                      Text(
                        '${post.pollVotes.values.fold<int>(0, (a, b) => a + b)} votes',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              ReactionBar(
                post: post,
                uid: uid,
                onReact: onReact,
                onComment: onOpen,
                onSave: onSave,
                saved: saved,
                onShare: preview ? null : () => _share(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pollOption(BuildContext context, int index) {
    final colors = Theme.of(context).colorScheme,
        total = post.pollVotes.values.fold<int>(0, (a, b) => a + b),
        votes = post.pollVotes[index.toString()] ?? 0;
    final ratio = total == 0 ? 0.0 : votes / total;
    final selected = post.pollVoters[uid] == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onPoll == null || post.pollClosed ? null : () => onPoll!(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (selected)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.check_circle, size: 16),
                    ),
                  Expanded(
                    child: Text(
                      post.pollOptions[index],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '${(ratio * 100).round()}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: ratio, minHeight: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    ),
  );
  Future<void> _share(BuildContext context) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text:
              '${post.authorName} on Talib\n\n${post.text}\n${post.educationalData.entries.map((e) => '${PostTemplates.labelFor(e.key)}: ${e.value}').join('\n')}\n${post.attachments.where((a) => PostTemplates.validUrl(a['url'] ?? '')).map((a) => a['url']).join('\n')}',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing could not be opened. Please try again.'),
          ),
        );
    }
  }
}

Widget _urlTile(BuildContext context, String url, String label) => ListTile(
  dense: true,
  contentPadding: EdgeInsets.zero,
  leading: const Icon(Icons.link),
  title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
  subtitle: Text(
    Uri.tryParse(url)?.host ?? url,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
  trailing: const Icon(Icons.open_in_new, size: 18),
  onTap: () => _openUrl(context, url),
);
Future<void> _openUrl(BuildContext context, String url) async {
  if (!PostTemplates.validUrl(url)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This attachment is a local Demo preview.')),
    );
    return;
  }
  try {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication))
      throw StateError('Unavailable');
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open this attachment. Please retry.'),
        ),
      );
  }
}

class CommunityAttachments extends StatelessWidget {
  final List<Map<String, String>> attachments;
  final bool full;
  const CommunityAttachments({
    super.key,
    required this.attachments,
    this.full = false,
  });
  ImageProvider? _image(String url) {
    try {
      if (url.startsWith('data:image/'))
        return MemoryImage(base64Decode(url.split(',').last));
      if (PostTemplates.validUrl(url)) return NetworkImage(url);
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final photos = attachments.where((a) => a['type'] == 'photo').toList(),
        documents = attachments.where((a) => a['type'] != 'photo').toList();
    return Column(
      children: [
        if (photos.isNotEmpty)
          SizedBox(
            height: full ? 260 : 200,
            child: PageView.builder(
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index], image = _image(photo['url'] ?? '');
                return Stack(
                  children: [
                    Positioned.fill(
                      child: InkWell(
                        onTap: image == null
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (dialog) => Dialog(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: IconButton(
                                          tooltip: 'Close photo',
                                          onPressed: () =>
                                              Navigator.pop(dialog),
                                          icon: const Icon(Icons.close),
                                        ),
                                      ),
                                      Flexible(
                                        child: InteractiveViewer(
                                          child: Image(
                                            image: image,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const Padding(
                                                  padding: EdgeInsets.all(32),
                                                  child: Icon(
                                                    Icons.broken_image_outlined,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: image == null
                              ? const Center(child: Icon(Icons.image_outlined))
                              : Image(
                                  image: image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                  loadingBuilder: (context, child, event) =>
                                      event == null
                                      ? child
                                      : const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                ),
                        ),
                      ),
                    ),
                    if (photos.length > 1)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Chip(
                          label: Text(
                            '${index + 1}/${photos.length} • Swipe',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        for (final a in documents)
          _urlTile(
            context,
            a['url'] ?? '',
            a['name'] ?? (a['type'] == 'link' ? 'Website link' : 'Document'),
          ),
      ],
    );
  }
}

class ReactionBar extends StatefulWidget {
  final Post post;
  final String uid;
  final bool saved;
  final Future<void> Function(String?)? onReact;
  final VoidCallback? onComment, onSave, onShare;
  const ReactionBar({
    super.key,
    required this.post,
    required this.uid,
    this.saved = false,
    this.onReact,
    this.onComment,
    this.onSave,
    this.onShare,
  });
  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  bool _busy = false;
  Future<void> _react(String? value) async {
    if (_busy || widget.onReact == null) return;
    setState(() => _busy = true);
    try {
      await widget.onReact!(value);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reaction could not be saved. Please retry.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _picker() async {
    final selected = widget.post.reactionBy(widget.uid);
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose your reaction',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in CommunityReaction.all)
                    ChoiceChip(
                      label: Text('${r.emoji} ${r.label}'),
                      selected: selected == r.id,
                      onSelected: (_) => Navigator.pop(sheet, r.id),
                    ),
                ],
              ),
              if (selected != null)
                TextButton(
                  onPressed: () => Navigator.pop(sheet, 'remove'),
                  child: const Text('Remove reaction'),
                ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted)
      await _react(result == 'remove' ? null : result);
  }

  void _actors() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) {
        String filter = 'all';
        return StatefulBuilder(
          builder: (context, update) => SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * .65,
              child: Column(
                children: [
                  const Text(
                    'Reactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final r in [
                          const CommunityReaction('all', 'All', ''),
                          ...CommunityReaction.all,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text('${r.emoji} ${r.label}'),
                              selected: filter == r.id,
                              onSelected: (_) => update(() => filter = r.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final e in widget.post.reactors.entries.where(
                          (e) => filter == 'all' || e.value == filter,
                        ))
                          ListTile(
                            title: UserIdentity(
                              uid: e.key,
                              name: 'Community member',
                              showUsername: false,
                            ),
                            trailing: Text(
                              CommunityReaction.byId(e.value).emoji,
                            ),
                            onTap: () {
                              Navigator.pop(sheet);
                              this.context.push('/profile/${e.key}');
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.post.reactionBy(widget.uid),
        reaction = CommunityReaction.byId(selected ?? 'like');
    final counts =
        widget.post.reactionCounts.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    Widget action(IconData icon, String label, VoidCallback? callback) =>
        Expanded(
          child: InkWell(
            onTap: callback,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 21),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
    return Column(
      children: [
        if (widget.post.reactionsCount > 0 || widget.post.commentsCount > 0)
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.post.reactionsCount == 0 ? null : _actors,
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  child: Text(
                    '${counts.take(3).map((e) => CommunityReaction.byId(e.key).emoji).join(' ')} ${widget.post.reactionsCount} reactions',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              if (widget.post.commentsCount > 0)
                TextButton(
                  onPressed: widget.onComment,
                  child: Text(
                    '${widget.post.commentsCount} comments',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
        const Divider(height: 1),
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _busy || widget.onReact == null
                          ? null
                          : () => _react(selected == 'like' ? null : 'like'),
                      onLongPress: _busy || widget.onReact == null
                          ? null
                          : _picker,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reaction.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            Text(
                              _busy ? 'Saving…' : reaction.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: selected == null
                                    ? null
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Choose reaction',
                    onPressed: _busy || widget.onReact == null ? null : _picker,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 44,
                    ),
                    icon: const Icon(Icons.arrow_drop_down, size: 18),
                  ),
                ],
              ),
            ),
            action(Icons.chat_bubble_outline, 'Comment', widget.onComment),
            action(Icons.share_outlined, 'Share', widget.onShare),
            action(
              widget.saved ? Icons.bookmark : Icons.bookmark_border,
              widget.saved ? 'Saved' : 'Save',
              widget.onSave,
            ),
          ],
        ),
      ],
    );
  }
}
