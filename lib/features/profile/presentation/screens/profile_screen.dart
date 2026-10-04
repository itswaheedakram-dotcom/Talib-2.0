import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final name=TextEditingController(), level=TextEditingController(), institute=TextEditingController(), program=TextEditingController(), city=TextEditingController();
  bool loading=true, saving=false;
  User? get user=>FirebaseAuth.instance.currentUser;

  @override void initState(){super.initState(); _load();}
  Future<void> _load() async {
    final u=user;
    if(u==null){if(mounted)setState(()=>loading=false);return;}
    name.text=u.displayName??'';
    final d=(await FirebaseFirestore.instance.collection('users').doc(u.uid).get()).data()??{};
    name.text=(d['name']??name.text).toString();
    level.text=(d['educationLevel']??'').toString();
    institute.text=(d['institute']??'').toString();
    program.text=(d['program']??'').toString();
    city.text=(d['city']??'').toString();
    if(mounted)setState(()=>loading=false);
  }
  Future<void> _save() async {
    final u=user;if(u==null)return;setState(()=>saving=true);
    await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
      'name':name.text.trim(),'email':u.email??'','educationLevel':level.text.trim(),
      'institute':institute.text.trim(),'program':program.text.trim(),'city':city.text.trim(),
      'updatedAt':FieldValue.serverTimestamp()
    },SetOptions(merge:true));
    await u.updateDisplayName(name.text.trim().isEmpty?null:name.text.trim());
    if(mounted){setState(()=>saving=false);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Profile updated')));}
  }
  @override void dispose(){for(final c in [name,level,institute,program,city])c.dispose();super.dispose();}

  @override Widget build(BuildContext context){
    final u=user;
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    if(u==null)return Scaffold(appBar:AppBar(title:const Text('Profile')),body:Center(child:Padding(
      padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Icon(Icons.person_outline,size:72),const SizedBox(height:12),
        const Text('Sign in to create and manage your profile.',textAlign:TextAlign.center),const SizedBox(height:18),
        SizedBox(width:double.infinity,child:FilledButton(onPressed:()=>context.push('/signin'),child:const Text('Sign In'))),
        TextButton(onPressed:()=>context.push('/register'),child:const Text('Create an account'))
      ])));
    final display=name.text.trim().isEmpty?'Student':name.text.trim();
    return Scaffold(appBar:AppBar(title:const Text('Profile'),actions:[IconButton(onPressed:saving?null:_save,icon:const Icon(Icons.save_outlined))]),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        Center(child:Column(children:[CircleAvatar(radius:42,child:Text(display.substring(0,1).toUpperCase(),style:const TextStyle(fontSize:30))),
          const SizedBox(height:10),Text(display,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w600)),const SizedBox(height:4),Text(u.email??'',style:TextStyle(color:Colors.grey))])),
        const SizedBox(height:24),const Text('Profile Information',style:TextStyle(fontSize:18,fontWeight:FontWeight.w600)),const SizedBox(height:10),
        _field(name,'Name',Icons.person_outline),_field(level,'Education level',Icons.school_outlined),_field(institute,'Institute',Icons.account_balance_outlined),
        _field(program,'Program / Degree',Icons.menu_book_outlined),_field(city,'City',Icons.location_on_outlined),
        SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:saving?null:_save,icon:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.save_outlined),label:Text(saving?'Saving...':'Save Profile'))),
        const SizedBox(height:24),const Text('My Activity',style:TextStyle(fontSize:18,fontWeight:FontWeight.w600)),
        _action(Icons.article_outlined,'My Posts','View posts you have created',()=>context.push('/community')),
        _action(Icons.bookmark_outline,'Saved Items','Open your saved posts and resources',()=>context.push('/bookmarks')),
        const SizedBox(height:16),const Text('Account',style:TextStyle(fontSize:18,fontWeight:FontWeight.w600)),
        _action(Icons.lock_reset,'Change Password','Send a password reset email',()async{if(u.email!=null){await FirebaseAuth.instance.sendPasswordResetEmail(email:u.email!);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Password reset email sent')));}}),
        _action(Icons.logout,'Log Out','Sign out of this account',()async{await FirebaseAuth.instance.signOut();if(mounted)context.go('/');})
      ]));
  }
  Widget _field(TextEditingController c,String label,IconData icon)=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon))));
  Widget _action(IconData icon,String title,String subtitle,VoidCallback tap)=>ListTile(contentPadding:EdgeInsets.zero,leading:Icon(icon),title:Text(title),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right),onTap:tap);
}