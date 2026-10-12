import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/user_profile_repository.dart';
import '../../../../core/models/user_profile.dart';
import '../../../models/post.dart';
import '../../../institutes/data/institute_repository.dart';
import '../../timeline_topics.dart';
import '../../domain/post_templates.dart';
import '../widgets/community_post_card.dart';

class CreatePostScreen extends StatefulWidget {
  final Post? post;
  final String? instituteId, instituteName, initialType;
  const CreatePostScreen({
    super.key,
    this.post,
    this.instituteId,
    this.instituteName,
    this.initialType,
  });
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _body = TextEditingController();
  final Map<String, TextEditingController> _fields = {
    for (final field in PostTemplates.all.expand((t) => t.fields))
      field.key: TextEditingController(),
  };
  final List<TextEditingController> _options = [];
  final List<Map<String, String>> _attachments = [];
  final Set<String> _tags = {}, _institutes = {};
  final _db = DatabaseService();
  Timer? _draftTimer;
  StreamSubscription<User?>? _auth;
  String _scope = '', _uid = '';
  String? _type;
  UserProfile? _profile;
  bool _loadingDraft = true,
      _saving = false,
      _uploading = false,
      _ready = false,
      _draftDialog = false;
  bool _previewing = false;
  double _progress = 0;
  String? _error;
  bool get _demo => ActiveProfileController.instance.isDemo;
  String get _currentUid => _demo
      ? (ActiveProfileController.instance.effectiveUid ?? '')
      : (FirebaseService.initialized
            ? FirebaseAuth.instance.currentUser?.uid ?? ''
            : '');
  String get _currentScope => '${_demo ? 'demo' : 'real'}:$_currentUid';
  String get _draftKey =>
      'talib.community.draft.$_scope.${widget.post?.id ?? 'new'}';
  bool get _voteLocked =>
      widget.post?.pollVotes.values.any((v) => v > 0) == true;
  bool get _canEdit => widget.post == null || widget.post!.authorId == _uid;
  PostTemplate get _template => PostTemplates.byId(_type ?? 'general');
  Map<String, String> get _values => {
    for (final field in _template.fields)
      if (_fields[field.key]!.text.trim().isNotEmpty)
        field.key: _fields[field.key]!.text.trim(),
  };
  @override
  void initState() {
    super.initState();
    _body.addListener(_scheduleDraft);
    for (final field in _fields.values) {
      field.addListener(_scheduleDraft);
    }
    ActiveProfileController.instance.addListener(_identityChanged);
    if (FirebaseService.initialized)
      _auth = FirebaseAuth.instance.authStateChanges().listen(
        (_) => _identityChanged(),
      );
    _bind();
  }

  void _identityChanged() {
    if (_scope != _currentScope) {
      if (_ready && _uid.isNotEmpty) _persist(_draftKey, _snapshot());
      if (_draftDialog || _previewing) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _bind();
    }
  }

  void _bind() {
    _ready = false;
    _draftTimer?.cancel();
    _scope = _currentScope;
    _uid = _currentUid;
    _loadingDraft = true;
    _error = null;
    _profile = null;
    _saving = false;
    _uploading = false;
    _body.text = widget.post?.text ?? '';
    for (final c in _fields.values) {
      c.clear();
    }
    _attachments
      ..clear()
      ..addAll(
        widget.post?.attachments.map((a) => Map<String, String>.from(a)) ?? [],
      );
    _tags
      ..clear()
      ..addAll(widget.post?.tags ?? []);
    _institutes
      ..clear()
      ..addAll(widget.post?.instituteIds ?? []);
    if (widget.post?.instituteId != null)
      _institutes.add(widget.post!.instituteId!);
    if (widget.instituteId?.isNotEmpty == true)
      _institutes.add(widget.instituteId!);
    _type = widget.post == null
        ? (PostTemplates.all.any((t) => t.id == widget.initialType)
              ? widget.initialType
              : null)
        : (widget.post!.pollOptions.isNotEmpty
              ? 'poll'
              : widget.post!.postType);
    for (final entry
        in widget.post?.educationalData.entries ??
            <MapEntry<String, String>>[]) {
      _fields[entry.key]?.text = entry.value;
    }
    for (final c in _options) {
      c.dispose();
    }
    _options.clear();
    for (final option in widget.post?.pollOptions ?? <String>[]) {
      _addOption(option);
    }
    if (_type == 'poll' && _options.length < 2) {
      _addOption();
      _addOption();
    }
    if (_fields['duration']!.text.isEmpty) _fields['duration']!.text = '3 days';
    _restore();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _auth?.cancel();
    ActiveProfileController.instance.removeListener(_identityChanged);
    if (_ready && _uid.isNotEmpty && !_saving) _persist(_draftKey, _snapshot());
    _body.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    for (final c in _options) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _addOption([String value = '']) {
    final c = TextEditingController(text: value)..addListener(_scheduleDraft);
    _options.add(c);
  }

  void _selectType(String id) {
    final previous = _type;
    setState(() {
      _type = id;
      if (id == 'study_group' && _fields['mode']!.text.isEmpty)
        _fields['mode']!.text = 'Online';
      if (id == 'career' && _fields['purpose']!.text.isEmpty)
        _fields['purpose']!.text = 'Career advice';
      if (previous != null) _tags.remove(PostTemplates.byId(previous).topic);
      _tags.add(_template.topic);
      if (id == 'poll' && _options.length < 2) {
        _addOption();
        _addOption();
      }
      _error = null;
    });
    _scheduleDraft();
  }

  Map<String, dynamic> _snapshot() => {
    'type': _type,
    'body': _body.text,
    'fields': {for (final e in _fields.entries) e.key: e.value.text},
    'tags': _tags.toList(),
    'institutes': _institutes.toList(),
    'options': _options.map((c) => c.text).toList(),
    'attachments': _attachments
        .map(
          (a) => {
            ...a,
            if ((a['url'] ?? '').startsWith('data:')) 'url': '',
            if ((a['url'] ?? '').startsWith('data:')) 'reattach': 'true',
          },
        )
        .toList(),
  };
  Future<void> _persist(String key, Map<String, dynamic> value) async {
    if (value['type'] == null &&
        (value['body'] ?? '').toString().isEmpty &&
        (value['attachments'] as List).isEmpty)
      return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(value));
    } catch (_) {
      /* Publishing does not depend on local draft storage. */
    }
  }

  void _scheduleDraft() {
    if (!_ready || _saving || _uid.isEmpty) return;
    _draftTimer?.cancel();
    final key = _draftKey, value = _snapshot();
    _draftTimer = Timer(
      const Duration(milliseconds: 500),
      () => _persist(key, value),
    );
  }

  Future<void> _restore() async {
    final scope = _scope, key = _draftKey;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || scope != _currentScope) return;
    final raw = prefs.getString(key);
    if (raw != null && _canEdit) {
      setState(() => _loadingDraft = false);
      _draftDialog = true;
      final restore = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Restore your draft?'),
          content: const Text(
            'Continue the post you were writing on this account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      _draftDialog = false;
      if (!mounted || scope != _currentScope) return;
      if (restore == true) {
        try {
          final d = jsonDecode(raw) as Map<String, dynamic>;
          _type = d['type'] as String?;
          _body.text = (d['body'] ?? '').toString();
          for (final e in (d['fields'] as Map? ?? {}).entries) {
            _fields[e.key]?.text = e.value.toString();
          }
          _tags
            ..clear()
            ..addAll(List<String>.from(d['tags'] ?? []));
          _institutes
            ..clear()
            ..addAll(List<String>.from(d['institutes'] ?? []));
          for (final c in _options) {
            c.dispose();
          }
          _options.clear();
          for (final option in List<String>.from(d['options'] ?? [])) {
            _addOption(option);
          }
          _attachments
            ..clear()
            ..addAll(
              (d['attachments'] as List? ?? []).map(
                (a) => Map<String, String>.from(a),
              ),
            );
        } catch (_) {
          _error =
              'The saved draft could not be restored. Please start a new post.';
        }
      } else if (restore == false) {
        await prefs.remove(key);
      }
    }
    await InstituteRepository.instance.load();
    if (!mounted || scope != _currentScope) return;
    if (_uid.isNotEmpty) {
      try {
        _profile = await UserProfileRepository.instance.watch(_uid).first;
        if (!mounted || scope != _currentScope) return;
        if (widget.post == null) {
          for (final subject in PostTemplates.subjects) {
            if (_profile!.course.toLowerCase().contains(
                  subject.toLowerCase(),
                ) &&
                _fields['subject']!.text.isEmpty)
              _fields['subject']!.text = subject;
          }
          if (_fields['program']!.text.isEmpty)
            _fields['program']!.text = _profile!.course;
          if (_fields['semester']!.text.isEmpty)
            _fields['semester']!.text = _profile!.semester;
        }
      } catch (_) {}
    }
    if (mounted && scope == _currentScope)
      setState(() {
        _loadingDraft = false;
        _ready = true;
      });
  }

  void _message(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPhoto() async {
    try {
      final scope = _scope;
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (image == null || !mounted || scope != _currentScope) return;
      await _attach(await image.readAsBytes(), image.name, 'photo', scope);
    } catch (_) {
      _message('Photo could not be attached. Please retry.');
    }
  }

  Future<void> _pickFile() async {
    try {
      final scope = _scope;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx', 'ppt', 'pptx'],
        withData: true,
      );
      if (result == null || !mounted || scope != _currentScope) return;
      final file = result.files.single;
      if (file.bytes == null) {
        _message('The file could not be read. Try another file.');
        return;
      }
      await _attach(file.bytes!, file.name, 'file', scope);
    } catch (_) {
      _message('Document could not be attached. Please retry.');
    }
  }

  Future<void> _attach(
    Uint8List bytes,
    String name,
    String type,
    String scope,
  ) async {
    if (_attachments.length >= 8) {
      _message('You can attach up to 8 items.');
      return;
    }
    if (bytes.length > 10 * 1024 * 1024) {
      _message('Choose a file smaller than 10 MB.');
      return;
    }
    setState(() {
      _uploading = true;
      _progress = 0;
    });
    try {
      String url;
      if (_demo) {
        url = type == 'photo'
            ? 'data:image/${name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg'};base64,${base64Encode(bytes)}'
            : '';
      } else {
        url = await _db.uploadCommunityAttachment(
          bytes: bytes,
          fileName: name,
          type: type,
          onProgress: (value) {
            if (mounted && scope == _currentScope)
              setState(() => _progress = value);
          },
        );
      }
      if (!mounted || scope != _currentScope) return;
      setState(
        () => _attachments.add({'type': type, 'name': name, 'url': url}),
      );
      _scheduleDraft();
    } catch (_) {
      if (mounted && scope == _currentScope)
        _message(
          'Upload failed. Your post is still saved as a draft. Try again.',
        );
    } finally {
      if (mounted && scope == _currentScope) setState(() => _uploading = false);
    }
  }

  Future<void> _link() async {
    final c = TextEditingController();
    final scope = _scope;
    final result = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Add website link'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://example.com'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (PostTemplates.validUrl(c.text))
                Navigator.pop(dialog, c.text.trim());
              else
                _message('Enter a valid http or https website link.');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    c.dispose();
    if (result != null && mounted && scope == _currentScope) {
      if (_attachments.length >= 8) {
        _message('You can attach up to 8 items.');
        return;
      }
      setState(
        () => _attachments.add({
          'type': 'link',
          'name': Uri.parse(result).host,
          'url': result,
        }),
      );
      _scheduleDraft();
    }
  }

  Future<void> _date(PostField field) async {
    final now = DateTime.now(), scope = _scope;
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_fields[field.key]!.text) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null && mounted && scope == _currentScope)
      setState(
        () => _fields[field.key]!.text =
            '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}',
      );
  }

  Future<void> _time(PostField field) async {
    final scope = _scope,
        selected = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
    if (selected != null && mounted && scope == _currentScope)
      setState(() => _fields[field.key]!.text = selected.format(context));
  }

  DateTime? get _closesAt => _voteLocked
      ? widget.post?.pollClosesAt
      : _type == 'poll'
      ? DateTime.now().add(
          Duration(
            days: _fields['duration']!.text == '1 day'
                ? 1
                : _fields['duration']!.text == '7 days'
                ? 7
                : 3,
          ),
        )
      : null;
  Map<String, String> get _publishValues {
    final values = _values;
    if (_voteLocked) {
      if (widget.post?.educationalData['duration'] == null) {
        values.remove('duration');
      } else {
        values['duration'] = widget.post!.educationalData['duration']!;
      }
    }
    return values;
  }

  List<String> get _pollOptions =>
      _type == 'poll' ? _options.map((c) => c.text.trim()).toList() : [];
  String? _validate() => PostTemplates.validate(
    type: _type ?? 'general',
    values: _values,
    body: _body.text,
    attachments: _attachments.length,
    institutes: _institutes.length,
    options: _pollOptions,
  );
  Future<void> _preview() async {
    FocusScope.of(context).unfocus();
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final post = Post(
      id: 'preview',
      text: PostTemplates.compose(_type!, _values, _body.text),
      authorId: _uid,
      authorName:
          _profile?.name ??
          ActiveProfileController.instance.effectiveName ??
          'Student',
      createdAt: widget.post?.createdAt ?? DateTime.now(),
      postType: _type!,
      educationalData: _publishValues,
      isQuestion:
          _template.question ||
          (_type == 'career' && _values['purpose'] == 'Career advice'),
      attachments: _attachments,
      tags: _tags.toList(),
      instituteIds: _institutes.toList(),
      pollOptions: _pollOptions,
      pollClosesAt: _closesAt,
    );
    _previewing = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .8,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Public community preview',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              CommunityPostCard(
                post: post,
                uid: _uid,
                full: true,
                preview: true,
              ),
              FilledButton(
                onPressed: () => Navigator.pop(sheet),
                child: const Text('Back to editing'),
              ),
            ],
          ),
        ),
      ),
    );
    _previewing = false;
  }

  Future<void> _publish() async {
    if (_saving || _uploading || _type == null || !_canEdit || _uid.isEmpty)
      return;
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_tags.length > 12) {
      setState(() => _error = 'Choose up to 12 topics.');
      return;
    }
    if (!_demo &&
        _attachments.any((a) => !PostTemplates.validUrl(a['url'] ?? ''))) {
      setState(
        () =>
            _error = 'Remove or reattach files that do not have a valid link.',
      );
      return;
    }
    if (_attachments.any((a) => a['reattach'] == 'true')) {
      setState(
        () =>
            _error = 'Reattach the local Demo photos restored from your draft.',
      );
      return;
    }
    final scope = _scope, key = _draftKey, uid = _uid;
    final text = PostTemplates.compose(_type!, _values, _body.text),
        values = _publishValues,
        options = _pollOptions,
        close = _closesAt;
    final authorName =
        _profile?.name ??
        ActiveProfileController.instance.effectiveName ??
        'Student';
    final type = _voteLocked ? widget.post!.postType : _type!;
    final tags = {..._tags, _template.topic}.toList();
    _draftTimer?.cancel();
    await _persist(key, _snapshot());
    if (!mounted || scope != _currentScope) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.post == null) {
        final id = await _db.createPost(
          text: text,
          authorId: uid,
          authorName: authorName,
          category: _template.topic,
          isQuestion:
              _template.question ||
              (_type == 'career' && _values['purpose'] == 'Career advice'),
          pollOptions: options,
          instituteId: _institutes.firstOrNull,
          attachments: _attachments
              .map((a) => {...a}..remove('reattach'))
              .toList(),
          tags: tags,
          instituteIds: _institutes.toList(),
          postType: type,
          educationalData: values,
          pollClosesAt: close,
        );
        if (!_demo && scope == _currentScope) {
          try {
            await _db.notifyMentions(text: text, fromId: uid, postId: id);
          } catch (_) {}
        }
      } else {
        await _db.updatePost(
          postId: widget.post!.id,
          text: text,
          category: _template.topic,
          isQuestion:
              _template.question ||
              (widget.post!.postType == 'general' && widget.post!.isQuestion),
          pollOptions: options,
          instituteId: _institutes.firstOrNull,
          attachments: _attachments,
          tags: tags,
          instituteIds: _institutes.toList(),
          postType: type,
          educationalData: values,
          pollClosesAt: close,
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      if (mounted && scope == _currentScope) {
        _ready = false;
        context.pop(true);
      }
    } catch (_) {
      if (mounted && scope == _currentScope)
        setState(
          () => _error =
              'Publishing failed. Your draft is safe—check your connection and retry.',
        );
    } finally {
      if (mounted && scope == _currentScope) setState(() => _saving = false);
    }
  }

  final Map<String, FocusNode> _focus = {};
  Widget _field(PostField field) {
    final controller = _fields[field.key]!,
        label = '${field.label}${field.required ? ' *' : ''}',
        locked = _voteLocked && field.key == 'duration';
    if (field.kind == 'days') {
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final selected = controller.text
          .split(', ')
          .where((v) => v.isNotEmpty)
          .toSet();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final day in days)
                  FilterChip(
                    label: Text(day.substring(0, 3)),
                    selected: selected.contains(day),
                    onSelected: _saving
                        ? null
                        : (v) {
                            if (v)
                              selected.add(day);
                            else
                              selected.remove(day);
                            setState(
                              () => controller.text = days
                                  .where(selected.contains)
                                  .join(', '),
                            );
                          },
                  ),
              ],
            ),
          ],
        ),
      );
    }
    if (field.kind == 'date' || field.kind == 'time')
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          readOnly: true,
          onTap: _saving
              ? null
              : () => field.kind == 'date' ? _date(field) : _time(field),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.text.isNotEmpty && !field.required)
                  IconButton(
                    tooltip: 'Clear date',
                    onPressed: () => setState(controller.clear),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                Icon(
                  field.kind == 'date'
                      ? Icons.calendar_today_outlined
                      : Icons.schedule,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
    if (const ['mode', 'purpose', 'milestone', 'duration'].contains(field.key))
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: field.choices.contains(controller.text)
              ? controller.text
              : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            helperText: locked
                ? 'Poll duration stays unchanged after voting starts.'
                : null,
          ),
          items: field.choices
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: _saving || locked
              ? null
              : (v) => setState(() => controller.text = v ?? ''),
        ),
      );
    if (field.choices.isNotEmpty) {
      final choices = {
        ...field.choices,
        if (field.key == 'program')
          ...InstituteRepository.instance.items
              .where((i) => _institutes.contains(i.id))
              .expand(
                (i) => [
                  ...i.programs,
                  ...i.programGroups.values.expand((v) => v),
                ],
              ),
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: RawAutocomplete<String>(
          textEditingController: controller,
          focusNode: _focus.putIfAbsent(field.key, FocusNode.new),
          optionsBuilder: (value) => choices.where(
            (option) => option.toLowerCase().contains(value.text.toLowerCase()),
          ),
          onSelected: (_) => setState(() {}),
          fieldViewBuilder: (context, text, focus, submit) => TextField(
            controller: text,
            focusNode: focus,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: label,
              helperText: 'Choose a suggestion or type your own.',
            ),
          ),
          optionsViewBuilder: (context, select, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 200,
                  maxWidth: 300,
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final value in options)
                      ListTile(title: Text(value), onTap: () => select(value)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: !_saving,
        maxLines: field.key == 'eligibility' ? 3 : 1,
        maxLength: 600,
        keyboardType: field.kind == 'url'
            ? TextInputType.url
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          hintText: field.kind == 'url' ? 'https://…' : null,
        ),
      ),
    );
  }

  Future<void> _topics() async {
    final selected = {..._tags}, scope = _scope;
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .7,
            child: Column(
              children: [
                const Text(
                  'Choose topics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final topic in TimelineTopics.all)
                        CheckboxListTile(
                          title: Text('${topic.emoji} ${topic.name}'),
                          value: selected.contains(topic.name),
                          onChanged: (v) => update(() {
                            if (v == true)
                              selected.add(topic.name);
                            else
                              selected.remove(topic.name);
                          }),
                        ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(sheet, selected),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted && scope == _currentScope) {
      setState(() {
        _tags
          ..clear()
          ..addAll(result);
      });
      _scheduleDraft();
    }
  }

  Future<void> _chooseInstitutes() async {
    await InstituteRepository.instance.load();
    if (!mounted) return;
    final scope = _scope, selected = {..._institutes};
    String query = '';
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .72,
            child: Column(
              children: [
                const Text(
                  'Choose institutes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search institute or city',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => update(() => query = v.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final i in InstituteRepository.instance.items.where(
                        (i) =>
                            '${i.name} ${i.city}'.toLowerCase().contains(query),
                      ))
                        CheckboxListTile(
                          title: Text(i.name),
                          subtitle: Text(i.city),
                          value: selected.contains(i.id),
                          onChanged: (v) => update(() {
                            if (v == true)
                              selected.add(i.id);
                            else
                              selected.remove(i.id);
                          }),
                        ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(sheet, selected),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted && scope == _currentScope) {
      setState(() {
        _institutes
          ..clear()
          ..addAll(result);
      });
      _scheduleDraft();
    }
  }

  Widget _institutePicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              _template.communityAnnouncement
                  ? 'Institute *'
                  : 'Related institute',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          TextButton.icon(
            onPressed: _saving ? null : _chooseInstitutes,
            icon: const Icon(Icons.school_outlined, size: 18),
            label: const Text('Choose'),
          ),
        ],
      ),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final id in _institutes)
            InputChip(
              label: Text(
                InstituteRepository.instance.byId(id)?.name ??
                    widget.instituteName ??
                    'Selected institute',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onDeleted: _saving
                  ? null
                  : () {
                      setState(() => _institutes.remove(id));
                      _scheduleDraft();
                    },
            ),
        ],
      ),
      if (_institutes.isEmpty && _profile != null)
        Wrap(
          children: [
            for (final i
                in InstituteRepository.instance.items
                    .where(
                      (i) =>
                          i.id == _profile!.instituteId ||
                          i.name.toLowerCase() ==
                              _profile!.instituteName.toLowerCase(),
                    )
                    .take(1))
              ActionChip(
                label: Text('Use ${i.name}'),
                onPressed: () {
                  setState(() => _institutes.add(i.id));
                  _scheduleDraft();
                },
              ),
          ],
        ),
      const SizedBox(height: 10),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final template = _template;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post == null ? 'Create post' : 'Edit post'),
        actions: [
          if (_type != null)
            TextButton(
              onPressed: _saving || _uploading || _loadingDraft
                  ? null
                  : _preview,
              child: const Text('Preview'),
            ),
        ],
      ),
      body: _loadingDraft
          ? const Center(child: CircularProgressIndicator())
          : !_canEdit
          ? const Center(child: Text('You can only edit your own posts.'))
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              children: [
                const Row(
                  children: [
                    Icon(Icons.public, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Public Talib community',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_type == null) ...[
                  Text(
                    'What would you like to share?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose a ready format. We will guide you through the details.',
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, size) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in PostTemplates.all)
                          SizedBox(
                            width: (size.maxWidth - 8) / 2,
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: InkWell(
                                onTap: () => _selectType(t.id),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.emoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        t.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Text(
                        template.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          template.label,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (widget.post == null)
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _type = null),
                          child: const Text('Change'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (template.communityAnnouncement)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Community shared. A green account tick does not verify this announcement. Include the official source.',
                      ),
                    ),
                  if (template.communityAnnouncement || _type == 'achievement')
                    _institutePicker(),
                  for (final field in template.fields)
                    if (_type != 'career' ||
                        _fields['purpose']!.text != 'Career advice' ||
                        !const [
                          'organization',
                          'deadline',
                          'sourceUrl',
                        ].contains(field.key))
                      _field(field),
                  TextField(
                    controller: _body,
                    enabled: !_saving,
                    minLines: 4,
                    maxLines: 9,
                    maxLength: 10000,
                    decoration: InputDecoration(
                      labelText: template.question
                          ? 'Your question *'
                          : _type == 'poll'
                          ? 'Poll question *'
                          : _type == 'general'
                          ? 'Your post *'
                          : 'Caption / details',
                      hintText: template.prompt,
                      border: const OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_type == 'poll') ...[
                    const Text(
                      'Poll options',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (_voteLocked)
                      const Text(
                        'Options stay unchanged after voting starts.',
                        style: TextStyle(fontSize: 12),
                      ),
                    for (var i = 0; i < _options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _options[i],
                                enabled: !_saving && !_voteLocked,
                                maxLength: 120,
                                decoration: InputDecoration(
                                  labelText: 'Option ${i + 1}',
                                  counterText: '',
                                ),
                              ),
                            ),
                            if (_options.length > 2 && !_voteLocked)
                              IconButton(
                                tooltip: 'Remove option',
                                onPressed: () {
                                  final c = _options.removeAt(i);
                                  c.dispose();
                                  setState(() {});
                                  _scheduleDraft();
                                },
                                icon: const Icon(Icons.close),
                              ),
                          ],
                        ),
                      ),
                    if (_options.length < 5 && !_voteLocked)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _addOption());
                          _scheduleDraft();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add option'),
                      ),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving || _uploading ? null : _pickPhoto,
                        icon: const Icon(Icons.photo_outlined),
                        label: const Text('Photo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _saving || _uploading ? null : _pickFile,
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Document'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _saving || _uploading ? null : _link,
                        icon: const Icon(Icons.link),
                        label: const Text('Link'),
                      ),
                    ],
                  ),
                  if (_uploading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: _progress > 0 ? _progress : null,
                          ),
                          Text(
                            'Uploading ${(_progress * 100).round()}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  for (var i = 0; i < _attachments.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _attachments[i]['type'] == 'photo'
                            ? Icons.photo
                            : Icons.description_outlined,
                      ),
                      title: Text(
                        _attachments[i]['name'] ?? 'Attachment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: _attachments[i]['reattach'] == 'true'
                          ? const Text('Reattach this local Demo photo')
                          : null,
                      trailing: IconButton(
                        tooltip: 'Remove attachment',
                        onPressed: _saving
                            ? null
                            : () {
                                setState(() => _attachments.removeAt(i));
                                _scheduleDraft();
                              },
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('More options'),
                    children: [
                      if (!template.communityAnnouncement &&
                          _type != 'achievement')
                        _institutePicker(),
                      if (_type == 'career' &&
                          _fields['purpose']!.text == 'Career advice')
                        ...template.fields
                            .where(
                              (f) => const [
                                'organization',
                                'deadline',
                                'sourceUrl',
                              ].contains(f.key),
                            )
                            .map(_field),
                      Row(
                        children: [
                          const Expanded(child: Text('Topics')),
                          TextButton(
                            onPressed: _saving ? null : _topics,
                            child: const Text('Choose'),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final tag in _tags)
                            InputChip(
                              label: Text(tag),
                              onDeleted: _saving
                                  ? null
                                  : () {
                                      setState(() => _tags.remove(tag));
                                      _scheduleDraft();
                                    },
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving || _uploading || _uid.isEmpty
                          ? null
                          : _publish,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(
                        _saving
                            ? 'Publishing…'
                            : widget.post == null
                            ? 'Publish post'
                            : 'Save changes',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _uid.isEmpty
                        ? 'Sign in to publish.'
                        : 'Your draft is saved automatically on this device.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ],
            ),
    );
  }
}
