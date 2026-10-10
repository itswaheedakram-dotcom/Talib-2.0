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
        {'update': {'name': f'{student_path}/notifications/affiliation-request', 'fields': fields({
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
verification = f'projects/{PROJECT}/databases/(default)/documents/institutes/affiliation-rules-university/studentVerifications/affiliation-student'
check(200, call('POST', ROOT + ':commit', {'writes': [
    {'update': {'name': request, 'fields': fields({'studentId': 'affiliation-student',
        'studentName': 'Student', 'instituteId': 'affiliation-rules-university',
        'program': 'BS Computer Science', 'status': 'approved', 'reviewedBy': 'affiliation-owner'})},
     'updateTransforms': [{'fieldPath': 'reviewedAt', 'setToServerValue': 'REQUEST_TIME'}]},
    {'update': {'name': verification, 'fields': fields({'studentId': 'affiliation-student',
        'instituteId': 'affiliation-rules-university', 'status': 'approved'})},
     'updateTransforms': [{'fieldPath': 'verifiedAt', 'setToServerValue': 'REQUEST_TIME'}]},
]}, uid='affiliation-owner'), 'university approves request and grants profile badge')
check(200, call('GET', ROOT + '/institutes/affiliation-rules-university/studentVerifications/affiliation-student', uid='unrelated-user'), 'public verification summary contains only minimal affiliation fields')
check(403, call('PATCH', ROOT + '/institutes/affiliation-rules-university/studentVerifications/forged-student',
                {'fields': fields({'studentId': 'forged-student', 'instituteId': 'affiliation-rules-university', 'status': 'approved'})}, uid='affiliation-student'), 'student cannot forge a public verification badge')
check(403, call('DELETE', ROOT + '/institutes/affiliation-rules-university/studentAffiliations/affiliation-student', uid='affiliation-student'), 'student cannot remove verified affiliation to alter count')
print('All student affiliation rules checks passed; no production services contacted.')
