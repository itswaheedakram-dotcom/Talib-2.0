import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical profile schema. Document id/Auth UID is the immutable user key.
/// Relation fields (authorId, senderId, userId, etc.) reference that same UID.
abstract final class ProfileFields {
  static const uid = 'uid', name = 'name', city = 'city', role = 'role';
  static const bio = 'bio', photoUrl = 'photoUrl', educationLevel = 'educationLevel';
  static const semester = 'semester', graduationYear = 'graduationYear';
  static const skills = 'skills', portfolioUrl = 'portfolioUrl', privateProfile = 'privateProfile';
  static const instituteId = 'studentInstituteId', instituteName = 'studentInstituteName';
  static const course = 'studentProgram', affiliationStatus = 'studentVerificationStatus';
  static const updatedAt = 'updatedAt', affiliationRequestedAt = 'affiliationRequestedAt';
  static const authorId = 'authorId', authorName = 'authorName';
  static const senderId = 'senderId', reviewerId = 'reviewerId', userId = 'userId', fromId = 'fromId';
}

class UserProfile {
  final String uid, name, city, role, bio, photoUrl, educationLevel;
  final String semester, graduationYear, portfolioUrl, instituteId, instituteName, course;
  final List<String> skills;
  final bool privateProfile;
  const UserProfile({required this.uid, this.name = 'Student', this.city = '',
    this.role = 'student', this.bio = '', this.photoUrl = '', this.educationLevel = '',
    this.semester = '', this.graduationYear = '', this.portfolioUrl = '',
    this.instituteId = '', this.instituteName = '', this.course = '',
    this.skills = const [], this.privateProfile = false});
  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    String value(String key) => (data[key] ?? '').toString().trim();
    final name = value(ProfileFields.name);
    final instituteId = value(ProfileFields.instituteId);
    return UserProfile(uid: uid, name: name.isEmpty ? 'Student' : name,
      city: value(ProfileFields.city), role: value(ProfileFields.role).isEmpty ? 'student' : value(ProfileFields.role),
      bio: value(ProfileFields.bio), photoUrl: value(ProfileFields.photoUrl),
      educationLevel: value(ProfileFields.educationLevel), semester: value(ProfileFields.semester),
      graduationYear: value(ProfileFields.graduationYear), portfolioUrl: value(ProfileFields.portfolioUrl),
      instituteId: instituteId, instituteName: value(ProfileFields.instituteName),
      // Legacy degree is read only when no canonical affiliation has been selected.
      course: instituteId.isEmpty ? value(ProfileFields.course).isEmpty ? value('program') : value(ProfileFields.course) : value(ProfileFields.course),
      skills: data[ProfileFields.skills] is List ? List<String>.from(data[ProfileFields.skills]).toSet().toList() : const [],
      privateProfile: data[ProfileFields.privateProfile] == true);
  }
  Map<String, dynamic> get editableFields => {
    ProfileFields.name: name, ProfileFields.city: city, ProfileFields.bio: bio,
    ProfileFields.photoUrl: photoUrl, ProfileFields.educationLevel: educationLevel,
    ProfileFields.semester: semester, ProfileFields.graduationYear: graduationYear,
    ProfileFields.skills: skills, ProfileFields.portfolioUrl: portfolioUrl,
  };
  String get roleLabel => role == 'student' ? 'Student' : 'Community Member';
}
