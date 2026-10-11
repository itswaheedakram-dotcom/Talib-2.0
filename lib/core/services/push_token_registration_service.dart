import '../models/user_profile.dart';
import 'package:flutter/material.dart';
import '../../app/router.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'active_profile_controller.dart';
import 'admin_access_service.dart';
import 'firebase_service.dart';

class PushTokenRegistrationService {
  PushTokenRegistrationService._();
  static final instance = PushTokenRegistrationService._();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  bool _started = false;
  // ignore: unused_field
  StreamSubscription<RemoteMessage>? _openedSubscription;
  // ignore: unused_field
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  void _openChatPush(RemoteMessage message) {
    final data=message.data;
    final user=FirebaseAuth.instance.currentUser;
    if(data['type']!='chat_message'||ActiveProfileController.instance.isDemo||user==null||data['receiverId']!=user.uid)return;
    final id=data['conversationId'],sender=data['senderId'];
    if(id==null||sender==null||id.isEmpty||sender.isEmpty)return;
    final path='/chat/'+Uri.encodeComponent(id)+'?uid='+Uri.encodeComponent(sender)+'&name='+Uri.encodeComponent(data['senderName']??'Student');
    appRouter.push(path);
  }

  void _foregroundChatPush(RemoteMessage message) {
    final data=message.data;
    final user=FirebaseAuth.instance.currentUser;
    if(data['type']!='chat_message'||ActiveProfileController.instance.isDemo||user==null||data['receiverId']!=user.uid)return;
    final id=data['conversationId'];
    if(id==null||appRouter.routeInformationProvider.value.uri.path=='/chat/'+Uri.encodeComponent(id))return;
    final context=appRouter.routerDelegate.navigatorKey.currentContext;
    if(context==null)return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
      content:Text('New message from '+(data['senderName']??'Student')),
      action:SnackBarAction(label:'Open chat',onPressed:()=>_openChatPush(message)),
    ));
  }


  void start() {
    if (_started || !FirebaseService.initialized) return;
    _started = true;
    try {
      ActiveProfileController.instance.addListener(_sync);
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) => _sync());
      _openedSubscription=FirebaseMessaging.onMessageOpenedApp.listen(_openChatPush);
      _foregroundSubscription=FirebaseMessaging.onMessage.listen(_foregroundChatPush);
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if(message!=null) WidgetsBinding.instance.addPostFrameCallback((_)=>_openChatPush(message));
      });
      _sync();
    } catch (_) {
      _started = false;
    }
  }

  Future<void> _sync() async {
    if (!FirebaseService.initialized || ActiveProfileController.instance.isDemo) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    try {
      await AdminAccessService.instance.refresh(user:user);
      await FirebaseMessaging.instance.requestPermission(alert:true,badge:true,sound:true);
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _save(user.uid, token);
      _tokenSubscription ??= FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        final current = FirebaseAuth.instance.currentUser;
        if (!ActiveProfileController.instance.isDemo && current != null && !current.isAnonymous) {
          _save(current.uid, token);
        }
      });
    } catch (_) {
      // Push registration is optional; report submission and in-app ticket history still work.
    }
  }

  Future<void> _save(String uid, String token) async {
    final access = AdminAccessService.instance;
    final adminRecipient = access.isSuperAdmin || access.can('manage_reports');
    await FirebaseFirestore.instance.collection('pushTokens').doc(uid).set({
      ProfileFields.uid:uid,
      'tokens':FieldValue.arrayUnion([token]),
      'adminRecipient':adminRecipient,
      'updatedAt':FieldValue.serverTimestamp(),
    }, SetOptions(merge:true));
  }
}
