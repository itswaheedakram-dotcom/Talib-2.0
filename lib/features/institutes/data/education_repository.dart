import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/education_record.dart';
import '../../models/institute.dart';
import 'institute_access.dart';
import 'student_affiliation_repository.dart';
import '../../../core/models/user_profile.dart';

/// Atomic canonical history + institute mirror. Only managers approve current enrollment.
class EducationRepository extends ChangeNotifier {
  EducationRepository._() {
    for (final record in [
      EducationRecord(
        id: 'demo-school-history-1',
        userId: 'demo-user-1',
        instituteId: 'school-1',
        instituteName: 'The Educators',
        program: 'Matric',
        programId: EducationFields.programKey('school-1', 'Matric'),
        levelId: 'school',
        status: EducationStatus.completed,
        startDate: DateTime(2017),
        completionDate: DateTime(2019),
      ),
      EducationRecord(
        id: 'demo-college-history-1',
        userId: 'demo-user-1',
        instituteId: 'college-1',
        instituteName: 'Government College Lahore',
        program: 'ICS',
        programId: EducationFields.programKey('college-1', 'ICS'),
        levelId: 'college',
        status: EducationStatus.completed,
        startDate: DateTime(2019),
        completionDate: DateTime(2021),
      ),
    ]) {
      _demo[record.id] = record;
    }
  }
  static final instance = EducationRepository._();
  final Map<String, EducationRecord> _demo = {};
  CollectionReference<Map<String, dynamic>> _history(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(EducationFields.collection);
  DocumentReference<Map<String, dynamic>> _mirror(EducationRecord record) =>
      FirebaseFirestore.instance
          .collection('institutes')
          .doc(record.instituteId)
          .collection(EducationFields.collection)
          .doc(record.id);
  DocumentReference<Map<String, dynamic>> _membership(EducationRecord record) =>
      FirebaseFirestore.instance
          .collection('institutes')
          .doc(record.instituteId)
          .collection(EducationFields.memberships)
          .doc(record.id);
  Stream<List<EducationRecord>> watch(String uid) {
    if (InstituteAccess.isDemo || uid.startsWith('demo-user-')) {
      return Stream.multi((controller) {
        void emit() => controller.add(
          EducationRecord.sorted(_demo.values.where((r) => r.userId == uid)),
        );
        emit();
        addListener(emit);
        controller.onCancel = () => removeListener(emit);
      });
    }
    return _history(uid).snapshots().map(
      (s) => EducationRecord.sorted(
        s.docs.map((d) => EducationRecord.fromMap(d.data())),
      ),
    );
  }

  Future<void> save(EducationRecord record, Institute institute) async {
    if (InstituteAccess.uid != record.userId) {
      throw StateError('Sign in to edit your education.');
    }
    if (record.instituteId != institute.id ||
        ![
          EducationStatus.current,
          EducationStatus.completed,
          EducationStatus.left,
        ].contains(record.status)) {
      throw StateError('Invalid education record.');
    }
    if (record.completionDate != null &&
        record.startDate != null &&
        record.completionDate!.isBefore(record.startDate!)) {
      throw StateError('Completion date must follow the start date.');
    }
    if (!EducationLevels.labels.containsKey(record.levelId)) {
      throw StateError('Choose an education level.');
    }
    if (record.status != EducationStatus.current && record.primary) {
      throw StateError('Only a current degree can be primary.');
    }
    record = EducationRecord.fromMap({
      ...record.toMap(),
      EducationFields.programId: EducationFields.programKey(
        record.instituteId,
        record.program,
      ),
    });
    final programs = {
      ...institute.programs,
      ...institute.programGroups.values.expand((v) => v),
    };
    if (record.program.isNotEmpty && !programs.contains(record.program)) {
      throw StateError('Choose a listed program.');
    }
    final verification =
        record.status == EducationStatus.current && record.program.isNotEmpty
        ? EducationVerification.pending
        : EducationVerification.notRequested;
    if (InstituteAccess.isDemo) {
      final old = _demo[record.id];
      final unchanged =
          old?.instituteId == record.instituteId &&
          old?.program == record.program &&
          old?.programId == record.programId &&
          old?.levelId == record.levelId &&
          old?.status == record.status &&
          old?.verification != EducationVerification.rejected;
      if (record.primary) {
        for (final entry in _demo.entries.toList()) {
          if (entry.value.userId == record.userId && entry.value.primary) {
            _demo[entry.key] = EducationRecord.fromMap({
              ...entry.value.toMap(),
              EducationFields.primary: false,
            });
          }
        }
      }
      final legacy = StudentAffiliationRepository.instance.demoProfileData(
        record.userId,
      );
      final keepLegacyApproval =
          record.id == 'legacy-${record.userId}' &&
          record.status == EducationStatus.current &&
          legacy[ProfileFields.instituteId] == record.instituteId &&
          legacy[ProfileFields.course] == record.program &&
          legacy[ProfileFields.affiliationStatus] ==
              EducationVerification.approved;
      _demo[record.id] = EducationRecord.fromMap({
        ...record.toMap(),
        EducationFields.verification: unchanged
            ? old!.verification
            : keepLegacyApproval
            ? EducationVerification.approved
            : verification,
      });
      if (record.id == 'legacy-${record.userId}') {
        StudentAffiliationRepository.instance.retireDemoAffiliation(
          record.userId,
        );
      }
    } else {
      final db = FirebaseFirestore.instance;
      await db.runTransaction((tx) async {
        final settingsRef = db
            .collection('users')
            .doc(record.userId)
            .collection('private')
            .doc('educationState');
        final settings = (await tx.get(settingsRef)).data();
        final primaryId = (settings?['primaryEducationRecordId'] ?? '')
            .toString();
        final ref = _history(record.userId).doc(record.id);
        final old = (await tx.get(ref)).data();
        final legacyUser = record.id == 'legacy-${record.userId}'
            ? (await tx.get(db.collection('users').doc(record.userId))).data()
            : null;
        final legacyInstituteId = (legacyUser?['studentInstituteId'] ?? '')
            .toString();
        final legacyRef = db
            .collection('institutes')
            .doc(
              legacyInstituteId.isEmpty
                  ? record.instituteId
                  : legacyInstituteId,
            )
            .collection('studentAffiliations')
            .doc(record.userId);
        final legacy = legacyUser != null && legacyInstituteId.isNotEmpty
            ? await tx.get(legacyRef)
            : null;
        final others = <DocumentSnapshot<Map<String, dynamic>>>[];
        if (record.primary && primaryId.isNotEmpty && primaryId != record.id) {
          others.add(await tx.get(_history(record.userId).doc(primaryId)));
        }
        // The settings document serializes simultaneous primary selections.
        if (record.primary || primaryId == record.id) {
          tx.set(settingsRef, {
            'primaryEducationRecordId': record.primary ? record.id : '',
          });
        }
        final unchanged =
            old?[EducationFields.instituteId] == record.instituteId &&
            old?[EducationFields.program] == record.program &&
            old?[EducationFields.programId] == record.programId &&
            old?[EducationFields.levelId] == record.levelId &&
            old?[EducationFields.status] == record.status &&
            old?[EducationFields.verification] !=
                EducationVerification.rejected;
        final keepLegacyApproval =
            old == null &&
            legacy?.data()?['status'] == EducationVerification.approved &&
            legacyInstituteId == record.instituteId &&
            legacyUser?[ProfileFields.course] == record.program &&
            record.status == EducationStatus.current;
        final data = {
          ...record.toMap(),
          EducationFields.verification: unchanged
              ? old![EducationFields.verification]
              : keepLegacyApproval
              ? EducationVerification.approved
              : verification,
          EducationFields.createdAt:
              old?[EducationFields.createdAt] ?? FieldValue.serverTimestamp(),
          EducationFields.updatedAt: FieldValue.serverTimestamp(),
        };
        if (old != null &&
            old[EducationFields.instituteId] != record.instituteId) {
          tx.delete(_mirror(EducationRecord.fromMap(old)));
          tx.delete(_membership(EducationRecord.fromMap(old)));
        }
        for (final doc in others) {
          if (!doc.exists) continue;
          final previous = EducationRecord.fromMap(doc.data()!);
          tx.update(doc.reference, {
            EducationFields.primary: false,
            EducationFields.updatedAt: FieldValue.serverTimestamp(),
          });
          tx.update(_mirror(previous), {
            EducationFields.primary: false,
            EducationFields.updatedAt: FieldValue.serverTimestamp(),
          });
        }
        tx.set(ref, data);
        tx.set(_mirror(record), data);
        tx.set(_membership(record), {
          ...record.membership,
          EducationFields.verification: data[EducationFields.verification],
        });
        if (data[EducationFields.verification] ==
                EducationVerification.pending &&
            !unchanged &&
            institute.ownerId.isNotEmpty) {
          tx.set(
            db
                .collection('users')
                .doc(institute.ownerId)
                .collection('notifications')
                .doc(),
            {
              'type': 'student_affiliation',
              'fromId': record.userId,
              'instituteId': record.instituteId,
              EducationFields.id: record.id,
              'text': 'A student requested current enrollment verification.',
              'createdAt': FieldValue.serverTimestamp(),
              'read': false,
            },
          );
        }
        if (legacy?.exists == true) {
          tx.delete(legacyRef);
          tx.update(db.collection('users').doc(record.userId), {
            'studentInstituteId': '',
            'studentInstituteName': '',
            'studentProgram': '',
            'studentVerificationStatus': EducationVerification.notRequested,
          });
        }
      });
    }
    notifyListeners();
  }

  String newId() => InstituteAccess.isDemo
      ? 'education-${DateTime.now().microsecondsSinceEpoch}'
      : _history(InstituteAccess.uid!).doc().id;
  Stream<List<EducationRecord>> instituteRecords(
    String instituteId, {
    bool includePending = false,
  }) {
    if (InstituteAccess.isDemo) {
      return Stream.multi((controller) {
        void emit() => controller.add(
          _demo.values.where((r) => r.instituteId == instituteId).toList(),
        );
        emit();
        addListener(emit);
        controller.onCancel = () => removeListener(emit);
      });
    }
    final collection = FirebaseFirestore.instance
        .collection('institutes')
        .doc(instituteId)
        .collection(
          includePending
              ? EducationFields.collection
              : EducationFields.memberships,
        );
    if (includePending) {
      return collection
          .where(
            EducationFields.verification,
            isEqualTo: EducationVerification.pending,
          )
          .snapshots()
          .map(
            (s) =>
                s.docs.map((d) => EducationRecord.fromMap(d.data())).toList(),
          );
    }
    return Stream.multi((controller) {
      List<EducationRecord> current = [], alumni = [];
      bool currentReady = false, alumniReady = false;
      void emit() {
        if (currentReady && alumniReady) {
          controller.add([...current, ...alumni]);
        }
      }

      final a = collection
          .where(EducationFields.status, isEqualTo: EducationStatus.current)
          .where(
            EducationFields.verification,
            isEqualTo: EducationVerification.approved,
          )
          .snapshots()
          .listen((s) {
            current = s.docs
                .map((d) => EducationRecord.fromMap(d.data()))
                .toList();
            currentReady = true;
            emit();
          }, onError: controller.addError);
      final b = collection
          .where(EducationFields.status, isEqualTo: EducationStatus.completed)
          .snapshots()
          .listen((s) {
            alumni = s.docs
                .map((d) => EducationRecord.fromMap(d.data()))
                .toList();
            alumniReady = true;
            emit();
          }, onError: controller.addError);
      controller.onCancel = () async {
        await a.cancel();
        await b.cancel();
      };
    });
  }

  Future<void> review(
    Institute institute,
    EducationRecord record,
    String status,
  ) async {
    if (!InstituteAccess.canManage(institute) ||
        record.instituteId != institute.id ||
        ![
          EducationVerification.approved,
          EducationVerification.rejected,
        ].contains(status)) {
      throw StateError('You cannot review this request.');
    }
    if (InstituteAccess.isDemo) {
      final current = _demo[record.id];
      if (current?.status != EducationStatus.current ||
          current?.verification != EducationVerification.pending) {
        throw StateError('This request has changed.');
      }
      _demo[record.id] = EducationRecord.fromMap({
        ...current!.toMap(),
        EducationFields.verification: status,
      });
    } else {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final ref = _history(record.userId).doc(record.id);
        final current = (await tx.get(ref)).data();
        if (current?[EducationFields.status] != EducationStatus.current ||
            current?[EducationFields.verification] !=
                EducationVerification.pending ||
            current?[EducationFields.instituteId] != institute.id) {
          throw StateError('This request has changed.');
        }
        final changes = {
          EducationFields.verification: status,
          EducationFields.updatedAt: FieldValue.serverTimestamp(),
        };
        tx.update(ref, changes);
        tx.update(_mirror(record), changes);
        tx.update(_membership(record), {EducationFields.verification: status});
        tx.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(record.userId)
              .collection('notifications')
              .doc(),
          {
            'type': 'student_affiliation_result',
            'fromId': InstituteAccess.uid,
            'instituteId': institute.id,
            EducationFields.id: record.id,
            'text': status == EducationVerification.approved
                ? '${institute.name} confirmed your current enrollment.'
                : '${institute.name} declined your enrollment request.',
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          },
        );
      });
    }
    notifyListeners();
  }

  @visibleForTesting
  void resetDemo() {
    _demo.clear();
    notifyListeners();
  }
}
