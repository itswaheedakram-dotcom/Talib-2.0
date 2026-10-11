# Education history and institute bridge

Every institute category uses the same enrollment system. A student may retain
multiple current and historical qualifications, with at most one primary current
record. A current institute is optional.

## Canonical fields and relationships

`users/{userId}/educationRecords/{educationRecordId}` is canonical history.
`institutes/{instituteId}/educationRecords/{educationRecordId}` is an identical,
private review mirror. Save and review transactions update both together.

`institutes/{instituteId}/educationMemberships/{educationRecordId}` contains only
immutable relation IDs, education status and verification status. It contains no
name, program, dates, or profile information. Rules require this public count
record to match canonical history. Only approved current and completed memberships
are publicly readable; pending and left memberships remain private. Ordinary users cannot read institute review
mirrors; profile history follows the existing profile privacy setting.

Use `EducationFields`, `EducationStatus`, `EducationVerification`, and
`EducationLevels` rather than screen-specific field strings. `userId` is the
permanent Auth UID, not the editable username. Program keys are centralized,
deterministic institute-scoped keys derived from the current string catalog;
renaming a catalog program requires an explicit ID/alias migration in future.

Education statuses: `current`, `completed`, `left`.
Verification statuses: `not_requested`, `pending`, `approved`, `rejected`.
Only current records with institute approval receive Current verified student.
Completed records receive the gold Alumni badge immediately; it is self-declared,
not evidence of institute approval. Left records receive neither badge.

Changing institute, program, or education level resets current verification.
Editing dates or the primary flag preserves approval. Resaving a declined current
record sends a fresh pending request. Completing a record removes current approval
and its current count contribution. No record is erased on completion.

The private `educationState` document serializes primary selections. Saving a new
primary record clears the old primary flag atomically. Rules prevent inconsistent
primary pointers and independent count edits.

## Existing users

Existing single-institute affiliations remain visible. The profile action
“Move existing institute into education history” creates `legacy-{userId}` and
removes the old affiliation/count atomically. A matching, already approved legacy
program retains its approval. Moving to another program/institute requires fresh
approval. No bulk rewrite of existing profiles is performed.

## Counts and scale

Counts deduplicate immutable user IDs per institute and status. Multiple degrees
at one institute count once in Alumni. A person with both a completed and an
approved current degree can contribute once to each count.

This first implementation streams minimal membership documents and computes
unique users in the client. It is correct for testing and modest institute sizes,
but is not a constant-cost server aggregate. At larger scale, move unique-member
materialization to a trusted backend and preserve the canonical record IDs/schema;
do not let clients write arbitrary aggregate counters.

## Validation and deployment

- `flutter test test/education_history_test.dart test/student_affiliation_test.dart`
- `firebase emulators:exec --only firestore --project demo-talib-review-tests 'python test/education_rules_check.py'`
- Existing security regressions: `test/student_affiliation_rules_check.py`.
- Deploy `firestore.rules` and `firestore.indexes.json` before distributing the new APK.
- Android APK is produced by the existing Build Android APK workflow.

Demo history includes completed school and college qualifications, alongside the
existing demo current-student approvals. Demo edits never write to Firebase.
