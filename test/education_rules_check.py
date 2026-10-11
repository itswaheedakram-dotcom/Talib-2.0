"""Exercise education history against a local emulator; never production."""
# Reuse the REST helpers without executing the older suite.
from pathlib import Path
exec(Path('test/student_affiliation_rules_check.py').read_text().split("check(200, call('PATCH'")[0])
from datetime import datetime, timezone

u = 'education-student'
i = 'education-institute'
base = f'projects/{PROJECT}/databases/(default)/documents'
check(200, call('PATCH', ROOT + '/institutes/' + i, {'fields': fields({'name': 'School', 'type': 'schools', 'status': 'approved', 'ownerId': 'education-owner'})}, seed=True), 'seed non-university institute')
check(200, call('PATCH', ROOT + '/users/' + u, {'fields': fields({'name': 'Student', 'privateProfile': True})}, seed=True), 'seed private student')

def encode(v):
    if v is None: return {'nullValue': None}
    if isinstance(v, bool): return {'booleanValue': v}
    return {'stringValue': v}

def record(rid='degree-1', status='current', verification='pending', primary=False):
    data = {'educationRecordId': rid, 'userId': u, 'instituteId': i, 'instituteName': 'School',
            'programId': 'matric', 'program': 'Matric', 'educationLevelId': 'school',
            'educationStatus': status, 'verificationStatus': verification, 'isPrimary': primary,
            'startDate': None, 'completionDate': None}
    return {k: encode(v) for k, v in data.items()}

def membership(data):
    return {k: data[k] for k in ['educationRecordId', 'userId', 'instituteId', 'educationStatus', 'verificationStatus']}

def commit(data, uid=u, create=False, extra=None):
    rid = data['educationRecordId']['stringValue']
    writes = []
    for path in [f'users/{u}/educationRecords/{rid}', f'institutes/{i}/educationRecords/{rid}']:
        transforms = [{'fieldPath': 'updatedAt', 'setToServerValue': 'REQUEST_TIME'}]
        if create: transforms.append({'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'})
        else:
            existing = json.loads(call('GET', ROOT + '/users/' + u + '/educationRecords/' + rid, seed=True)[1])['fields']
            data['createdAt'] = existing['createdAt']
        writes.append({'update': {'name': base + '/' + path, 'fields': data}, 'updateTransforms': transforms})
    writes.append({'update': {'name': base + f'/institutes/{i}/educationMemberships/{rid}', 'fields': membership(data)}})
    return call('POST', ROOT + ':commit', {'writes': writes + (extra or [])}, uid=uid)

check(403, commit(record(verification='approved'), create=True), 'student cannot self-verify')
check(200, commit(record(), create=True), 'school enrollment saved atomically')
check(403, call('GET', ROOT + f'/institutes/{i}/educationRecords/degree-1', uid='stranger'), 'pending details stay private')
check(403, call('GET', ROOT + f'/institutes/{i}/educationMemberships/degree-1', uid='stranger'), 'pending membership stays private')
check(200, call('GET', ROOT + f'/institutes/{i}/educationRecords/degree-1', uid='education-owner'), 'school owner reads request')
check(403, commit(record(verification='approved'), uid='stranger'), 'unrelated user cannot approve')
check(200, commit(record(verification='approved'), uid='education-owner'), 'institute approves current enrollment')
check(403, call('GET', ROOT + f'/institutes/{i}/educationRecords/degree-1', uid='stranger'), 'approved qualification details remain private')
check(200, call('GET', ROOT + f'/institutes/{i}/educationMemberships/degree-1', uid='stranger'), 'minimal count membership is readable')
check(403, call('PATCH', ROOT + f'/institutes/{i}/educationMemberships/forged', {'fields': membership(record())}, uid=u), 'cannot fabricate count membership')
check(200, commit(record(status='completed', verification='not_requested')), 'completion needs no approval')
check(403, commit(record(status='completed', verification='approved')), 'alumni cannot carry an approved current badge')
check(200, commit(record('degree-2', status='completed', verification='not_requested'), create=True), 'second completed qualification at same institute')
check(200, commit(record('degree-3'), create=True), 'another simultaneous current qualification')
check(403, commit(record('degree-3', primary=True)), 'primary requires matching serialized pointer')
settings_path = base + f'/users/{u}/private/educationState'
check(200, commit(record('degree-3', primary=True), extra=[{'update': {'name': settings_path, 'fields': fields({'primaryEducationRecordId': 'degree-3'})}}]), 'current degree can become primary atomically')
check(403, commit(record('degree-3')), 'cannot clear primary flag without clearing pointer')
check(403, call('PATCH', ROOT + f'/users/{u}/private/educationState', {'fields': fields({'primaryEducationRecordId': ''})}, uid=u), 'cannot abandon primary pointer while record remains primary')
check(200, commit(record('degree-3', status='left', verification='not_requested'), extra=[{'update': {'name': settings_path, 'fields': fields({'primaryEducationRecordId': ''})}}]), 'left enrollment clears primary atomically')
print('All education history rules checks passed.')

# Preserve an existing verified affiliation during canonical migration.
check(200, call('PATCH', ROOT + '/users/' + u, {'fields': fields({'name': 'Student', 'studentInstituteId': i, 'studentInstituteName': 'School', 'studentProgram': 'Matric', 'studentVerificationStatus': 'pending'})}, seed=True), 'seed legacy selected institute')
check(200, call('PATCH', ROOT + f'/institutes/{i}/studentAffiliations/{u}', {'fields': fields({'studentId': u, 'instituteId': i, 'status': 'approved'}) | {'verifiedAt': {'timestampValue': datetime.now(timezone.utc).isoformat()}}}, seed=True), 'seed existing institute approval')
legacy_extra = [
    {'delete': base + f'/institutes/{i}/studentAffiliations/{u}'},
    {'update': {'name': base + f'/users/{u}', 'fields': fields({'name': 'Student', 'studentInstituteId': '', 'studentInstituteName': '', 'studentProgram': '', 'studentVerificationStatus': 'not_requested'})}}
]
check(200, commit(record('legacy-' + u, verification='approved'), create=True, extra=legacy_extra), 'migration preserves approved badge and removes old count atomically')
check(403, commit(record('unmatched-legacy', verification='approved'), create=True), 'legacy migration cannot forge another approved record')
check(403, call('PATCH', ROOT + f'/institutes/{i}/educationMemberships/degree-3', {'fields': membership(record('degree-3', verification='approved'))}, uid=u), 'cannot mutate count independently of history')
print('Legacy migration and membership integrity checks passed.')

new_i = 'education-next-institute'
check(200, call('PATCH', ROOT + '/institutes/' + new_i, {'fields': fields({'name': 'Next institute', 'status': 'approved', 'ownerId': 'next-owner'})}, seed=True), 'seed next institute')
moved = record('degree-2', status='completed', verification='not_requested')
moved['instituteId'] = encode(new_i)
moved['instituteName'] = encode('Next institute')
moved['createdAt'] = json.loads(call('GET', ROOT + f'/users/{u}/educationRecords/degree-2', seed=True)[1])['fields']['createdAt']
writes = [
    {'update': {'name': base + f'/users/{u}/educationRecords/degree-2', 'fields': moved}, 'updateTransforms': [{'fieldPath': 'updatedAt', 'setToServerValue': 'REQUEST_TIME'}]},
    {'update': {'name': base + f'/institutes/{new_i}/educationRecords/degree-2', 'fields': moved}, 'updateTransforms': [{'fieldPath': 'updatedAt', 'setToServerValue': 'REQUEST_TIME'}]},
    {'update': {'name': base + f'/institutes/{new_i}/educationMemberships/degree-2', 'fields': membership(moved)}}
]
check(403, call('POST', ROOT + ':commit', {'writes': writes}, uid=u), 'switch cannot leave old count behind')
writes.extend([{'delete': base + f'/institutes/{i}/educationRecords/degree-2'}, {'delete': base + f'/institutes/{i}/educationMemberships/degree-2'}])
check(200, call('POST', ROOT + ':commit', {'writes': writes}, uid=u), 'switch removes old mirror and membership atomically')
print('Institute switch integrity checks passed.')
