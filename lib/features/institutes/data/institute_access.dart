import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/active_profile_controller.dart';
import '../../../core/services/admin_access_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../models/institute.dart';

/// Shared identity and authorization for both institute backends.
abstract final class InstituteAccess {
  static bool get isDemo =>
      ActiveProfileController.instance.isDemo || !FirebaseService.initialized;
  static String? get uid => isDemo
      ? ActiveProfileController.instance.effectiveUid
      : FirebaseAuth.instance.currentUser?.uid;

  static bool get canReviewClaims => isDemo
      ? ActiveProfileController.instance.effectiveUid == 'demo-user-6'
      : AdminAccessService.instance.can('ownership_claim_review');
  static bool get canModerate => isDemo
      ? ActiveProfileController.instance.effectiveUid == 'demo-user-6'
      : AdminAccessService.instance.can('manage_institutes');

  static bool canManage(Institute institute) =>
      canManageAs(institute, uid: uid, moderator: canModerate);

  static bool canManageAs(
    Institute institute, {
    required String? uid,
    bool moderator = false,
  }) =>
      uid != null && uid.isNotEmpty && (moderator || institute.ownerId == uid);
}
