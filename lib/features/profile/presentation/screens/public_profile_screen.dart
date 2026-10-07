import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/database_service.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/services/active_profile_controller.dart';
import '../../../../core/services/demo_data_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String id;
  const PublicProfileScreen({super.key, required this.id});
  @override State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  User? get me => FirebaseAuth.instance.currentUser;

  Future<void> _review(String name) async {
    final current = me;
    final identity = ActiveProfileController.instance;
    if (identity.isDemo) {
      var rating = 5;
      final controller = TextEditingController();
      final result = await showDialog<bool>(context: context,builder: (dialogContext) => StatefulBuilder(builder: (_, setDialogState) => AlertDialog(title: Text('Review ' + name),content: Column(mainAxisSize: MainAxisSize.min,children:[Row(mainAxisAlignment: MainAxisAlignment.center,children: List.generate(5,(i)=>IconButton(onPressed:()=>setDialogState(()=>rating=i+1),icon:Icon(i<rating?Icons.star:Icons.star_border)))),TextField(controller:controller,maxLines:4,maxLength:300,decoration:const InputDecoration(labelText:'Your review'))]),actions:[TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),child:const Text('Publish'))])));
      final text=controller.text.trim();
      if(result==true&&text.isNotEmpty){await DatabaseService().addDemoReview(widget.id,identity.effectiveUid!,identity.effectiveName??'Student',rating,text);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Review published')));}
      controller.dispose();
      return;
    }
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

  @override Widget build(BuildContext context) {
    if (!FirebaseService.initialized || widget.id.startsWith('demo-user-')) {
      final demo={'demo-user-1':{'name':'Ayesha Khan','city':'Lahore, Punjab','level':'BS Computer Science','institute':'University of the Punjab','program':'Computer Science'},'demo-user-2':{'name':'Ali Raza','city':'Multan, Punjab','level':'BS Software Engineering','institute':'BZU Multan','program':'Software Engineering'},'demo-user-3':{'name':'Hira Ahmed','city':'Islamabad','level':'MS Education','institute':'NUST Islamabad','program':'Education'},'demo-user-4':{'name':'Usman Malik','city':'Faisalabad, Punjab','level':'BS Business Administration','institute':'University of Agriculture Faisalabad','program':'Business Administration'}}[widget.id]??{'name':'Student','city':'Pakistan','level':'Community Member','institute':'','program':''};
      final name=demo['name']!;
      return Scaffold(appBar:AppBar(title:const Text('Profile')),body:ListView(padding:const EdgeInsets.all(16),children:[
        Center(child:CircleAvatar(radius:44,backgroundColor:const Color(0xFFE8F5E9),child:Text(name[0],style:const TextStyle(fontSize:32,color:Color(0xFF2E7D32))))),
        const SizedBox(height:10),Row(mainAxisAlignment:MainAxisAlignment.center,children:[Text(name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w600)),const SizedBox(width:6),const Icon(Icons.verified,size:20,color:AppColors.primaryGreen)]),Center(child:Text(demo['city']!,style:const TextStyle(color:Colors.grey))),
        const SizedBox(height:12),
        AnimatedBuilder(
          animation: ActiveProfileController.instance,
          builder: (context, _) {
            final controller = ActiveProfileController.instance;
            final active = controller.active?.id == widget.id;
            final currentId = controller.effectiveUid;
            final following = currentId != null &&
                DemoDataService.instance.isFollowing(currentId, widget.id);
            return Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: active
                        ? null
                        : () {
                            final profile = temporaryProfiles.firstWhere(
                              (p) => p.id == widget.id,
                            );
                            controller.activate(profile);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  profile.name +
                                      ' is now the active test profile.',
                                ),
                              ),
                            );
                          },
                    icon: Icon(
                      active
                          ? Icons.check_circle
                          : Icons.play_circle_outline,
                    ),
                    label: Text(
                      active ? 'Active Profile' : 'Activate This Profile',
                    ),
                  ),
                ),
                if (currentId != null && currentId != widget.id) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              DemoDataService.instance.toggleFollow(
                            currentId,
                            widget.id,
                            !following,
                          ),
                          icon: Icon(
                            following
                                ? Icons.person_remove_outlined
                                : Icons.person_add_outlined,
                          ),
                          label: Text(
                            following ? 'Following' : 'Follow',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/chat/' +
                                DemoDataService.instance.conversationId(
                                  currentId,
                                  widget.id,
                                ) +
                                '?uid=' +
                                widget.id +
                                '&name=' +
                                Uri.encodeComponent(name),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Message'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height:18),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Profile Information',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),const SizedBox(height:10),_InfoTile(Icons.school_outlined,'Education level',demo['level']!),if(demo['institute']!.isNotEmpty)_InfoTile(Icons.account_balance_outlined,'Institute',demo['institute']!),if(demo['program']!.isNotEmpty)_InfoTile(Icons.menu_book_outlined,'Program / Degree',demo['program']!)
        ]))),const SizedBox(height:12),const Card(child:Padding(padding:EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Community Activity',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),SizedBox(height:8),Text('This profile is participating in the Talib community.',style:TextStyle(color:Colors.grey))])))
      ]));
    }
    return Scaffold(
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
        final isOwner = me?.uid == widget.id;
        final isPrivate = data['privateProfile'] == true;
        if (isPrivate && !isOwner) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 52, color: AppColors.primaryGreen),
                  SizedBox(height: 12),
                  Text('Private profile', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('This user has limited profile visibility.', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
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
                if (widget.id.startsWith('demo-user-'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: AnimatedBuilder(
                      animation: ActiveProfileController.instance,
                      builder: (context, _) {
                        final active = ActiveProfileController.instance.active?.id == widget.id;
                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: active ? null : () {
                              final profile = temporaryProfiles.firstWhere((p) => p.id == widget.id);
                              ActiveProfileController.instance.activate(profile);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(profile.name + ' is now the active test profile.')),
                              );
                            },
                            icon: Icon(active ? Icons.check_circle : Icons.play_circle_outline),
                            label: Text(active ? 'Active Profile' : 'Activate This Profile'),
                          ),
                        );
                      },
                    ),
                  ),
                if (me != null && me!.uid != widget.id) ...[
                  const SizedBox(height: 10),
                  StreamBuilder<bool>(
                    stream: DatabaseService().followingStream(me!.uid, widget.id),
                    builder: (context, followSnapshot) {
                      final following = followSnapshot.data == true;
                      return StreamBuilder<bool>(
                        stream: DatabaseService().followingStream(widget.id, me!.uid),
                        builder: (context, reverseFollowSnapshot) {
                          final mutual = following && reverseFollowSnapshot.data == true;
                          return Row(mainAxisAlignment: MainAxisAlignment.center, children:[
                            FilledButton.icon(
                              onPressed:()=>DatabaseService().toggleFollow(me!.uid, widget.id, !following),
                              icon:Icon(following?Icons.person_remove_outlined:Icons.person_add_outlined),
                              label:Text(following?'Following':'Follow'),
                            ),
                            if (mutual) ...[
                              const SizedBox(width:8),
                              OutlinedButton.icon(
                                onPressed:()=>context.push('/chat/${DatabaseService().conversationId(me!.uid, widget.id)}?uid=${widget.id}&name=${Uri.encodeComponent(name)}'),
                                icon:const Icon(Icons.chat_bubble_outline),
                                label:const Text('Message'),
                              ),
                            ],
                            const SizedBox(width:8),
                            OutlinedButton.icon(onPressed:()=>_reportUser(name),icon:const Icon(Icons.flag_outlined),label:const Text('Report')),
                            const SizedBox(width:8),
                            OutlinedButton.icon(onPressed:()=>_blockUser(name),icon:const Icon(Icons.block_outlined),label:const Text('Block')),
                          ]);
                        },
                      );
                    },
                  ),
                ],
              ])),
              const SizedBox(height: 18),
              Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _Stat(value: total == 0 ? '—' : average.toStringAsFixed(1), label: 'Rating'),
                _Stat(value: total.toString(), label: 'Reviews'),
                _Stat(value: verified ? 'Verified' : eligible ? 'Eligible' : 'Community', label: 'Status'),
                if (me != null) StreamBuilder<int>(stream: DatabaseService().followerCountStream(widget.id), builder: (_, s) => _Stat(value: (s.data ?? 0).toString(), label: 'Followers')),
              ]))),
              if (eligible) const Padding(padding: EdgeInsets.only(top: 8), child: Text(
                'This profile meets the current community reputation threshold for verification review.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12),
              )),
              const SizedBox(height: 12),
              FutureBuilder<Map<String,dynamic>>(
                future: DatabaseService().reputation(widget.id),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
                  final d=snap.data??{};
                  final badges=List<String>.from(d['badges']??const []);
                  return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    const Text('Community Reputation',style:TextStyle(fontSize:18,fontWeight:FontWeight.w600)),
                    const SizedBox(height:8),
                    Row(children:[
                      const Icon(Icons.emoji_events_outlined,color:Color(0xFF2E7D32),size:28),
                      const SizedBox(width:8),
                      Expanded(child:Text('${d['score']??0} Reputation • ${d['posts']??0} posts • ${d['comments']??0} comments',style:const TextStyle(fontWeight:FontWeight.w600))),
                    ]),
                    if(badges.isNotEmpty) ...[
                      const SizedBox(height:10),
                      Wrap(spacing:6,runSpacing:6,children:badges.map((b)=>Chip(avatar:const Icon(Icons.military_tech_outlined,size:16),label:Text(b))).toList()),
                    ],
                  ])));
                },
              ),
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
  }

  Future<void> _reportUser(String name) async {
    final u=me;if(u==null)return;
    final reason=await showDialog<String>(context:context,builder:(_)=>SimpleDialog(title:Text('Report '+name),children:['Spam','Harassment','Fake information','Inappropriate','Scam','Other'].map((x)=>SimpleDialogOption(onPressed:()=>Navigator.pop(context,x),child:Text(x))).toList()));
    if(reason!=null){await DatabaseService().report(reporterId:u.uid,targetId:widget.id,targetType:'user',reason:reason);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Report submitted.')));}
  }
  Future<void> _blockUser(String name) async {
    final u=me;if(u==null)return;
    final yes=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:Text('Block '+name+'?'),content:const Text('You will no longer see this user in your community feed.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Block'))]));
    if(yes==true){await DatabaseService().blockUser(u.uid,widget.id);if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('User blocked.')));context.pop();}}
  }
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