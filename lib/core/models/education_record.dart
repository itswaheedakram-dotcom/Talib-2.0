import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared schema for both profile history and institute enrollment mirrors.
abstract final class EducationFields {
  static const collection = 'educationRecords',
      memberships = 'educationMemberships';
  static String programKey(String instituteId, String program) =>
      program.isEmpty
      ? ''
      : '$instituteId:${base64Url.encode(utf8.encode(program.trim().toLowerCase()))}';
  static const id = 'educationRecordId', userId = 'userId';
  static const instituteId = 'instituteId', instituteName = 'instituteName';
  static const programId = 'programId', program = 'program';
  static const levelId = 'educationLevelId', status = 'educationStatus';
  static const verification = 'verificationStatus', primary = 'isPrimary';
  static const startDate = 'startDate', completionDate = 'completionDate';
  static const createdAt = 'createdAt', updatedAt = 'updatedAt';
}

abstract final class EducationStatus {
  static const current = 'current', completed = 'completed', left = 'left';
  static const values = [current, completed, left];
}

abstract final class EducationVerification {
  static const notRequested = 'not_requested',
      pending = 'pending',
      approved = 'approved',
      rejected = 'rejected';
}

abstract final class EducationLevels {
  static const labels = <String, String>{
    'school': 'School',
    'college': 'College / intermediate',
    'diploma': 'Diploma',
    'bachelors': 'Bachelor’s degree',
    'masters': 'Master’s degree',
    'doctorate': 'Doctorate',
    'other': 'Other',
  };
}

class EducationRecord {
  final String id,
      userId,
      instituteId,
      instituteName,
      programId,
      program,
      levelId;
  final String status, verification;
  final bool primary;
  final DateTime? startDate, completionDate;
  const EducationRecord({
    required this.id,
    required this.userId,
    required this.instituteId,
    required this.instituteName,
    this.programId = '',
    this.program = '',
    this.levelId = '',
    this.status = EducationStatus.current,
    this.verification = EducationVerification.notRequested,
    this.primary = false,
    this.startDate,
    this.completionDate,
  });
  bool get isAlumni => status == EducationStatus.completed;
  bool get isVerifiedCurrent =>
      status == EducationStatus.current &&
      verification == EducationVerification.approved;
  static DateTime? date(dynamic value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : null;
  factory EducationRecord.fromMap(Map<String, dynamic> data) => EducationRecord(
    id: data[EducationFields.id] as String,
    userId: data[EducationFields.userId] as String,
    instituteId: data[EducationFields.instituteId] as String,
    instituteName: (data[EducationFields.instituteName] ?? '').toString(),
    programId: (data[EducationFields.programId] ?? '').toString(),
    program: (data[EducationFields.program] ?? '').toString(),
    levelId: (data[EducationFields.levelId] ?? '').toString(),
    status: (data[EducationFields.status] ?? EducationStatus.current)
        .toString(),
    verification:
        (data[EducationFields.verification] ??
                EducationVerification.notRequested)
            .toString(),
    primary: data[EducationFields.primary] == true,
    startDate: date(data[EducationFields.startDate]),
    completionDate: date(data[EducationFields.completionDate]),
  );
  Map<String, dynamic> toMap() => {
    EducationFields.id: id,
    EducationFields.userId: userId,
    EducationFields.instituteId: instituteId,
    EducationFields.instituteName: instituteName,
    EducationFields.programId: programId,
    EducationFields.program: program,
    EducationFields.levelId: levelId,
    EducationFields.status: status,
    EducationFields.verification: verification,
    EducationFields.primary: primary,
    EducationFields.startDate: startDate,
    EducationFields.completionDate: completionDate,
  };
  Map<String, dynamic> get membership => {
    EducationFields.id: id,
    EducationFields.userId: userId,
    EducationFields.instituteId: instituteId,
    EducationFields.status: status,
    EducationFields.verification: verification,
  };
  static List<EducationRecord> sorted(Iterable<EducationRecord> records) =>
      records.toList()..sort((a, b) {
        if (a.primary != b.primary) return a.primary ? -1 : 1;
        if ((a.status == EducationStatus.current) !=
            (b.status == EducationStatus.current)) {
          return a.status == EducationStatus.current ? -1 : 1;
        }
        return (b.startDate ?? DateTime(1900)).compareTo(
          a.startDate ?? DateTime(1900),
        );
      });
}
