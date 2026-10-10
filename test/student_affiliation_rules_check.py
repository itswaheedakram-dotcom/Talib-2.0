"""Checks student affiliation authorization against the local Firestore emulator only."""
import base64
import json
import os
import time
import urllib.error
import urllib.request

PROJECT = 'demo-talib-review-tests'
HOST = os.environ.get('FIRESTORE_EMULATOR_HOST', '')
if not HOST or not (HOST.startswith('127.0.0.1:') or HOST.startswith('localhost:')):
    raise RuntimeError('This test must run against a local Firestore emulator.')
ROOT = f'http://{HOST}/v1/projects/{PROJECT}/databases/(default)/documents'


def token(uid):
    def encode(obj):
        return base64.urlsafe_b64encode(json.dumps(obj).encode()).decode().rstrip('=')
    return encode({'alg': 'none', 'typ': 'JWT'}) + '.' + encode({
        'sub': uid, 'user_id': uid, 'aud': PROJECT,
        'iss': f'https://securetoken.google.com/{PROJECT}',
        'iat': int(time.time()), 'exp': int(time.time()) + 3600,
        'firebase': {'sign_in_provider': 'custom'},
    }) + '.'


def fields(values):
    return {key: ({'booleanValue': value} if isinstance(value, bool) else
                  {'integerValue': str(value)} if isinstance(value, int) else
                  {'stringValue': value}) for key, value in values.items()}


def call(method, url, body=None, uid=None, seed=False):
    headers = {'Content-Type': 'application/json'}
    if seed or uid:
        headers['Authorization'] = 'Bearer ' + ('owner' if seed else token(uid))
    request = urllib.request.Request(url, data=json.dumps(body).encode() if body is not None else None,
                                     headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            return response.status, response.read().decode()
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode()


def check(code, result, description):
    assert result[0] == code, f'{description}: expected {code}, got {result}'
    print('PASS:', description)


check(200, call('PATCH', ROOT + '/institutes/affiliation-rules-university',
               {'fields': fields({'name': 'Affiliation rules university', 'status': 'approved', 'ownerId': 'affiliation-owner'})}, seed=True), 'seed approved university owner')
check(200, call('PATCH', ROOT + '/users/affiliation-student',
               {'fields': fields({'name': 'Student'})}, seed=True), 'seed student profile')

student_path = f'projects/{PROJECT}/databases/(default)/documents/users/affiliation-student'
request_path = f'{student_path.rsplit("/users/", 1)[0]}/institutes/affiliation-rules-university/studentAffiliations/affiliation-student'


def submit():
    return call('POST', ROOT + ':commit', {'writes': [
        {'update': {'name': request_path, 'fields': fields({
            'studentId': 'affiliation-student', 'studentName': 'Student',
            'instituteId': 'affiliation-rules-university', 'program': 'BS Computer Science', 'status': 'pending'})},
         'updateTransforms': [{'fieldPath': 'updatedAt', 'setToServerValue': 'REQUEST_TIME'}]},
        {'update': {'name': student_path, 'fields': fields({
            'name': 'Student', 'studentInstituteId': 'affiliation-rules-university',
            'studentInstituteName': 'Affiliation rules university', 'studentProgram': 'BS Computer Science',
            'studentVerificationStatus': 'pending'})}},
        {'update': {'name': f'{student_path}/notifications/affiliation-request-{time.time_ns()}', 'fields': fields({
            'type': 'student_affiliation', 'text': 'Student requested verification.',
            'instituteId': 'affiliation-rules-university', 'fromId': 'affiliation-student', 'read': False})},
         'updateTransforms': [{'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'}]},
    ]}, uid='affiliation-student')


check(200, submit(), 'student selects university and sends private verification request')
check(200, call('GET', ROOT + '/institutes/affiliation-rules-university/studentAffiliations/affiliation-student', uid='affiliation-owner'), 'university representative reads request')
check(403, call('GET', ROOT + '/institutes/affiliation-rules-university/studentAffiliations/affiliation-student', uid='unrelated-user'), 'unrelated user cannot read request')
check(403, call('PATCH', ROOT + '/users/affiliation-student',
                {'fields': fields({'studentVerificationStatus': 'approved'})}, uid='affiliation-student'), 'student cannot grant self verification badge')
check(403, call('PATCH', ROOT + '/institutes/affiliation-rules-university/studentAffiliations/affiliation-student',
                {'fields': fields({'status': 'approved'})}, uid='affiliation-student'), 'student cannot approve own request')
check(403, call('PATCH', ROOT + '/institutes/affiliation-rules-university/studentAffiliations/affiliation-student',
                {'fields': fields({'status': 'approved'})}, uid='unrelated-user'), 'unrelated user cannot approve requests')

request = f'projects/{PROJECT}/databases/(default)/documents/institutes/affiliation-rules-university/studentAffiliations/affiliation-student'
check(200, call('POST', ROOT + ':commit', {'writes': [
    {'update': {'name': request, 'fields': fields({'studentId': 'affiliation-student',
        'instituteId': 'affiliation-rules-university', 'status': 'approved'})},
     'updateTransforms': [{'fieldPath': 'verifiedAt', 'setToServerValue': 'REQUEST_TIME'}]},
]}, uid='affiliation-owner'), 'university approves pending request and redacts student details')
public_record = call('GET', ROOT + '/institutes/affiliation-rules-university/studentAffiliations/affiliation-student', uid='unrelated-user')
check(200, public_record, 'public reads approved minimal verification record')
public_fields = json.loads(public_record[1])['fields']
assert set(public_fields) == {'studentId', 'instituteId', 'status', 'verifiedAt'}
print('PASS: approved verification record reveals no student name or program')
check(403, call('PATCH', ROOT + '/institutes/affiliation-rules-university/studentAffiliations/forged-student',
                {'fields': fields({'studentId': 'forged-student', 'instituteId': 'affiliation-rules-university', 'status': 'approved'})}, uid='affiliation-student'), 'student cannot forge a public verification badge')
check(403, call('DELETE', ROOT + '/institutes/affiliation-rules-university/studentAffiliations/affiliation-student', uid='affiliation-student'), 'student cannot remove verified affiliation to alter count')
print('All student affiliation rules checks passed; no production services contacted.')

check(200, submit(), 'verified student can edit course by resetting affiliation to pending')
check(403, call('GET', ROOT + '/institutes/affiliation-rules-university/studentAffiliations/affiliation-student', uid='unrelated-user'), 'old public badge disappears while course change awaits approval')

check(200, call('POST', ROOT + ':commit', {'writes': [
    {'update': {'name': request_path, 'fields': fields({
        'studentId': 'affiliation-student', 'instituteId': 'affiliation-rules-university', 'status': 'approved'})},
     'updateTransforms': [{'fieldPath': 'verifiedAt', 'setToServerValue': 'REQUEST_TIME'}]},
]}, uid='affiliation-owner'), 'university reapproves edited course before student changes university')

check(200, call('PATCH', ROOT + '/institutes/affiliation-rules-other',
               {'fields': fields({'name': 'Other university', 'status': 'approved', 'ownerId': 'other-owner'})}, seed=True), 'seed second university')
new_request = f'projects/{PROJECT}/databases/(default)/documents/institutes/affiliation-rules-other/studentAffiliations/affiliation-student'
check(200, call('POST', ROOT + ':commit', {'writes': [
    {'update': {'name': new_request, 'fields': fields({
        'studentId': 'affiliation-student', 'studentName': 'Student',
        'instituteId': 'affiliation-rules-other', 'program': 'BS Education', 'status': 'pending'})},
     'updateTransforms': [{'fieldPath': 'updatedAt', 'setToServerValue': 'REQUEST_TIME'}]},
    {'update': {'name': student_path, 'fields': fields({
        'name': 'Student', 'studentInstituteId': 'affiliation-rules-other',
        'studentInstituteName': 'Other university', 'studentProgram': 'BS Education',
        'studentVerificationStatus': 'pending'})}},
    {'delete': request_path},
]}, uid='affiliation-student'), 'student can switch university and remove previous affiliation atomically')
check(403, call('PATCH', ROOT + '/users/affiliation-student',
               {'fields': fields({'name': 'Student', 'studentInstituteId': 'affiliation-rules-university',
                                 'studentProgram': 'Unmatched course', 'studentVerificationStatus': 'pending'})},
               uid='affiliation-student'), 'profile cannot switch to an unmatched verification request')
print('Student affiliation edit checks passed.')

# A listed university can be saved without inventing a course/approval.
check(200, call('POST', ROOT + ':commit', {'writes': [
    {'update': {'name': student_path, 'fields': fields({
        'name': 'Student', 'studentInstituteId': 'affiliation-rules-other',
        'studentInstituteName': 'Other university', 'studentProgram': '',
        'studentVerificationStatus': 'not_requested'})}},
    {'delete': new_request},
]}, uid='affiliation-student'), 'student saves university without a course or approval request')
check(403, call('PATCH', ROOT + '/users/affiliation-student?updateMask.fieldPaths=uid',
               {'fields': fields({'uid': 'forged-other-id'})}, uid='affiliation-student'),
      'student cannot change their immutable UID')
check(200, call('PATCH', ROOT + '/users/affiliation-student?updateMask.fieldPaths=privateProfile',
               {'fields': fields({'privateProfile': True})}, uid='affiliation-student'), 'owner enables private profile')
check(403, call('GET', ROOT + '/users/affiliation-student', uid='unrelated-user'), 'private profile blocked by backend')
check(200, call('GET', ROOT + '/users/affiliation-student', uid='affiliation-student'), 'owner can read private profile')
check(200, call('PATCH', ROOT + '/users/affiliation-student/private/account',
               {'fields': fields({'email': 'owner@example.test'})}, uid='affiliation-student'), 'owner saves private account details')
check(403, call('GET', ROOT + '/users/affiliation-student/private/account', uid='unrelated-user'), 'other user cannot read account email')
print('Central profile privacy and UID checks passed.')

# User IDs are public, unique claims; internal UID stays permanent.
base_path = f'projects/{PROJECT}/databases/(default)/documents'
for actor in ['handle-owner', 'handle-other']:
    check(200, call('PATCH', ROOT + '/users/' + actor,
                   {'fields': fields({'name': actor, 'uid': actor})}, seed=True), 'seed ' + actor)
def claim_handle(actor, username, previous=None):
    writes = [
        {'update': {'name': base_path + '/usernames/' + username, 'fields': fields({'uid': actor})}},
        {'update': {'name': base_path + '/users/' + actor, 'fields': fields({'username': username})},
         'updateMask': {'fieldPaths': ['username']}},
    ]
    if previous:
        writes.append({'delete': base_path + '/usernames/' + previous})
    return call('POST', ROOT + ':commit', {'writes': writes}, uid=actor)
check(200, claim_handle('handle-owner', 'waheed'), 'claim available User ID atomically')
check(200, call('GET', ROOT + '/usernames/waheed', uid='handle-other'), 'check availability without reading private profile')
check(403, claim_handle('handle-other', 'waheed'), 'duplicate User ID cannot be stolen')
check(403, call('PATCH', ROOT + '/users/handle-other?updateMask.fieldPaths=username',
               {'fields': fields({'username': 'waheed'})}, uid='handle-other'), 'cannot bypass username registry')
check(403, claim_handle('handle-other', 'Bad-ID'), 'invalid User ID rejected')
check(403, claim_handle('handle-owner', 'waheed_2'), 'rename must release old User ID atomically')
check(200, claim_handle('handle-owner', 'waheed_2', 'waheed'), 'rename retains permanent UID and releases old User ID')
check(200, claim_handle('handle-other', 'waheed'), 'released User ID becomes available')
check(403, call('DELETE', ROOT + '/usernames/waheed', uid='handle-other'), 'cannot release a still-active User ID')
print('Unique User ID claim and rename checks passed.')
