"""Checks review authorization against the local Firestore emulator only."""
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


check(200, call('PATCH', ROOT + '/institutes/rules-institute',
               {'fields': fields({'name': 'Rules institute', 'status': 'approved', 'ownerId': 'institute-owner'})}, seed=True), 'seed approved institute')
check(200, call('PATCH', ROOT + '/institutes/pending-institute',
               {'fields': fields({'name': 'Pending institute', 'status': 'pending', 'ownerId': 'institute-owner'})}, seed=True), 'seed pending institute')


def write(uid='reviewer', doc_uid='reviewer', rating=4, text='Public experience', institute='rules-institute'):
    name = f'projects/{PROJECT}/databases/(default)/documents/institutes/{institute}/instituteReviews/{doc_uid}'
    return call('POST', ROOT + ':commit', {'writes': [{
        'update': {'name': name, 'fields': fields({'instituteId': institute, 'userId': uid,
            'authorName': 'Community member', 'rating': rating, 'text': text, 'published': True})},
        'updateTransforms': [{'fieldPath': 'updatedAt', 'setToServerValue': 'REQUEST_TIME'}],
    }]}, uid=uid)


check(200, write(), 'user creates own review')
check(200, call('GET', ROOT + '/institutes/rules-institute/instituteReviews/reviewer'), 'public reads published review')
check(200, write(rating=5), 'user updates own rating in same document')
check(403, write(uid='other', doc_uid='reviewer'), 'other user cannot overwrite reviewer')
check(403, write(rating=6), 'rating above five rejected')
check(403, write(rating=0), 'rating below one rejected')
check(403, write(text='x' * 1001), 'oversized review rejected')
check(403, write(doc_uid='duplicate'), 'second review document for same person rejected')
check(403, write(institute='pending-institute'), 'pending institute cannot receive public reviews')
check(403, call('DELETE', ROOT + '/institutes/rules-institute/instituteReviews/reviewer', uid='institute-owner'), 'institute owner cannot delete another person’s criticism')
check(403, call('DELETE', ROOT + '/institutes/rules-institute/instituteReviews/reviewer'), 'anonymous delete rejected')
check(200, call('DELETE', ROOT + '/institutes/rules-institute/instituteReviews/reviewer', uid='reviewer'), 'author deletes own review')
print('All review rules checks passed; no production services contacted.')
