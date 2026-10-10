import 'package:flutter/material.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/user_profile_repository.dart';
import '../../../../core/widgets/user_identity.dart';

class ProfileEditor extends StatefulWidget {
  final UserProfile profile;
  const ProfileEditor({super.key, required this.profile});
  @override State<ProfileEditor> createState() => _ProfileEditorState();
}
class _ProfileEditorState extends State<ProfileEditor> {
  final form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> fields;
  late String photoUrl;
  bool saving = false, picking = false, changed = false, checkingId = false;
  String? idMessage;
  List<String> suggestions = [];
  Future<void> _checkId() async {
    final requested = fields[ProfileFields.username]!.text;
    setState(() { checkingId = true; idMessage = null; suggestions = []; });
    try {
      final normalized = UserProfileRepository.normalizeUsername(requested);
      if (!UserProfileRepository.validUsername(normalized)) {
        if (mounted) setState(() => idMessage = 'Use 3–24 letters, numbers or underscores; start with a letter.');
        return;
      }
      final available = await UserProfileRepository.instance.usernameAvailable(normalized);
      final choices = available ? <String>[] : await UserProfileRepository.instance.usernameSuggestions(normalized);
      if (mounted && fields[ProfileFields.username]!.text == requested) setState(() {
        idMessage = available ? 'This User ID is available.' : 'This User ID is already taken. Choose another.';
        suggestions = choices;
      });
    } catch (_) { if (mounted) setState(() => idMessage = 'Could not check availability. Please retry.'); }
    finally { if (mounted) setState(() => checkingId = false); }
  }
  @override void initState() {
    super.initState(); final p = widget.profile; photoUrl = p.photoUrl;
    fields = {
      ProfileFields.username: TextEditingController(text: p.username),
      ProfileFields.name: TextEditingController(text: p.name),
      ProfileFields.city: TextEditingController(text: p.city),
      ProfileFields.bio: TextEditingController(text: p.bio),
      ProfileFields.skills: TextEditingController(text: p.skills.join(', ')),
      ProfileFields.portfolioUrl: TextEditingController(text: p.portfolioUrl),
    };
    for (final controller in fields.values) { controller.addListener(() { if (mounted) setState(() => changed = true); }); }
  }
  @override void dispose() { for (final controller in fields.values) { controller.dispose(); } super.dispose(); }
  Future<void> _photo() async {
    setState(() => picking = true);
    try {
      final result = await UserProfileRepository.instance.pickPhoto(widget.profile.uid);
      if (mounted && result != null) setState(() { photoUrl = result; changed = true; });
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load photo. Try another image.'))); }
    finally { if (mounted) setState(() => picking = false); }
  }
  Future<void> _save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    String value(String key) => fields[key]!.text.trim();
    try {
      await UserProfileRepository.instance.save(UserProfile(uid: widget.profile.uid, username: value(ProfileFields.username),
        name: value(ProfileFields.name), city: value(ProfileFields.city),
        bio: value(ProfileFields.bio),
        portfolioUrl: value(ProfileFields.portfolioUrl), photoUrl: photoUrl,
        skills: value(ProfileFields.skills).split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet().take(12).toList()));
      if (mounted) Navigator.pop(context, true);
    } on UsernameTaken {
      await _checkId();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save profile. Check your connection and retry.')));
    } finally { if (mounted) setState(() => saving = false); }
  }
  Widget _field(String key, String label, {int lines = 1, int? maxLength, String? Function(String?)? validate}) =>
    Padding(padding: const EdgeInsets.only(bottom: 14), child: TextFormField(controller: fields[key],
      enabled: !saving, maxLines: lines, maxLength: maxLength, validator: validate,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));
  @override Widget build(BuildContext context) => PopScope(canPop: !saving, child: Scaffold(
    appBar: AppBar(title: const Text('Edit profile')),
    body: Form(key: form, child: ListView(padding: const EdgeInsets.all(20), children: [
      UserIdLabel(uid: widget.profile.uid),
      Center(child: ProfileAvatar(name: fields[ProfileFields.name]!.text, photoUrl: photoUrl, radius: 44)),
      Wrap(alignment: WrapAlignment.center, spacing: 12, children: [
        TextButton.icon(onPressed: picking || saving ? null : _photo, icon: const Icon(Icons.photo_camera_outlined), label: Text(picking ? 'Loading photo…' : 'Change photo')),
        if (photoUrl.isNotEmpty) TextButton(onPressed: saving ? null : () => setState(() { photoUrl = ''; changed = true; }), child: const Text('Remove photo')),
      ]),
      _field(ProfileFields.name, 'Name', maxLength: 80, validate: (value) => value == null || value.trim().isEmpty ? 'Enter your name.' : null),
      _field(ProfileFields.username, 'User ID', maxLength: 24, validate: (value) =>
        UserProfileRepository.validUsername(UserProfileRepository.normalizeUsername(value ?? '')) ? null : 'Use 3–24 letters, numbers or underscores; start with a letter.'),
      Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: saving || checkingId ? null : _checkId,
        child: Text(checkingId ? 'Checking…' : 'Check availability'))),
      if (idMessage != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(idMessage!)),
      if (suggestions.isNotEmpty) Wrap(spacing: 8, children: suggestions.map((id) => ActionChip(label: Text(id),
        onPressed: saving ? null : () { fields[ProfileFields.username]!.text = id; _checkId(); })).toList()),
      _field(ProfileFields.bio, 'About me', lines: 3, maxLength: 300),
      _field(ProfileFields.city, 'City', maxLength: 100),
      _field(ProfileFields.skills, 'Skills / interests (comma separated)', maxLength: 240),
      _field(ProfileFields.portfolioUrl, 'Portfolio / project link (optional)', validate: (value) {
        if (value == null || value.trim().isEmpty) return null;
        final uri = Uri.tryParse(value.trim());
        return uri == null || !['https', 'http'].contains(uri.scheme) || uri.host.isEmpty ? 'Enter a complete https:// link.' : null;
      }),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Cancel'))),
        const SizedBox(width: 12),
        Expanded(child: FilledButton(onPressed: !changed || saving || picking ? null : _save, child: Text(saving ? 'Saving…' : 'Save profile'))),
      ]),
    ])),
  ));
}
