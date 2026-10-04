import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PublicProfileScreen extends StatefulWidget {
  final String id;
  const PublicProfileScreen({super.key, required this.id});
  @override State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  User? get me => FirebaseAuth.instance.currentUser;

  Future<void> _review(String name) async {
    final current = me;
    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to leave a review.')));
      return;
    }
    var rating = 5;
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text('Review ' + name),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
              onPressed: () => setDialogState(() => rating = i + 1),
              icon: Icon(i < rating ? Icons.star : Icons.star_border),
            ))),
            TextField(controller: controller, maxLines: 4, maxLength: 300, decoration: const InputDecoration(
              labelText: 'Your review', hintText: 'How did this person help you?',
            )),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Publish')),
          ],
        ),
      ),
    );
    final text = controller.text.trim();
    if (result == true && text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(widget.id).collection('reviews').doc(current.uid).set({
        'reviewerId': current.uid,
        'reviewerName': current.displayName?.trim().isNotEmpty == true ? current.displayName!.trim() : 'Student',
        'rating': rating, 'text': text, 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review published')));
    }
    controller.dispose();
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.id).snapshots(),
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (profileSnapshot.hasError || !profileSnapshot.hasData || !profileSnapshot.data!.exists) return const Center(child: Text('User profile not found.'));
        final data = profileSnapshot.data!.data() ?? {};
        final rawName = (data['name'] ?? 'Student').toString().trim();
        final name = rawName.isEmpty ? 'Student' : rawName;
        final city = (data['city'] ?? '').toString();
        final institute = (data['institute'] ?? '').toString();
        final program = (data['program'] ?? '').toString();
        final level = (data['educationLevel'] ?? '').toString();
        final verified = data['verified'] == true;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.id).collection('reviews').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, reviewsSnapshot) {
            final docs = reviewsSnapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            var total = 0; var sum = 0;
            for (final doc in docs) {
              final value = (doc.data()['rating'] as num?)?.toInt() ?? 0;
              if (value >= 1 && value <= 5) { total++; sum += value; }
            }
            final average = total == 0 ? 0.0 : sum / total;
            final eligible = !verified && average >= 4.5 && total >= 10;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Center(child: Column(children: [
                CircleAvatar(radius: 42, backgroundColor: const Color(0xFFE8F5E9), child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 30, color: Color(0xFF2E7D32)))),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  if (verified) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified, size: 20, color: Color(0xFF2E7D32))),
                ]),
                if (city.isNotEmpty) Text(city, style: const TextStyle(color: Colors.grey)),
              ])),
              const SizedBox(height: 18),
              Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _Stat(value: total == 0 ? '—' : average.toStringAsFixed(1), label: 'Rating'),
                _Stat(value: total.toString(), label: 'Reviews'),
                _Stat(value: verified ? 'Verified' : eligible ? 'Eligible' : 'Community', label: 'Status'),
              ]))),
              if (eligible) const Padding(padding: EdgeInsets.only(top: 8), child: Text(
                'This profile meets the current community reputation threshold for verification review.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12),
              )),
              if (institute.isNotEmpty || program.isNotEmpty || level.isNotEmpty) ...[
                const SizedBox(height: 14), const Text('Education', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                if (level.isNotEmpty) _InfoTile(Icons.school_outlined, 'Education level', level),
                if (institute.isNotEmpty) _InfoTile(Icons.account_balance_outlined, 'Institute', institute),
                if (program.isNotEmpty) _InfoTile(Icons.menu_book_outlined, 'Program / Degree', program),
              ],
              if (me != null && me!.uid != widget.id) ...[
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _review(name), icon: const Icon(Icons.star_outline), label: const Text('Write a Review'))),
              ],
              const SizedBox(height: 18), const Text('Public Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 6),
              if (docs.isEmpty) const Text('No reviews yet. Be the first to share useful feedback.', style: TextStyle(color: Colors.grey)),
              ...docs.map((doc) {
                final d = doc.data(); final reviewer = (d['reviewerName'] ?? 'Student').toString(); final stars = (d['rating'] as num?)?.toInt() ?? 0;
                return Card(margin: const EdgeInsets.only(top: 8), child: ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFFE8F5E9), child: Text(reviewer.isEmpty ? '?' : reviewer[0].toUpperCase())),
                  title: Row(children: [Expanded(child: Text(reviewer, style: const TextStyle(fontWeight: FontWeight.w600))), Text(stars.toString() + '/5', style: const TextStyle(fontSize: 12, color: Colors.grey))]),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text((d['text'] ?? '').toString())),
                ));
              }),
            ]);
          },
        );
      },
    ),
  );

  Widget _InfoTile(IconData icon, String label, String value) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon, color: const Color(0xFF4CAF50)), title: Text(value), subtitle: Text(label));
}

class _Stat extends StatelessWidget {
  final String value; final String label;
  const _Stat({required this.value, required this.label});
  @override Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
    const SizedBox(height: 3), Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
  ]);
}