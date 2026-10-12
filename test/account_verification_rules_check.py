"""Verification access tests against the local emulator only."""
import base64,json,os,time,urllib.request,urllib.error
PROJECT='demo-talib-review-tests';HOST=os.environ.get('FIRESTORE_EMULATOR_HOST','')
assert HOST.startswith(('127.0.0.1:','localhost:')),'Emulator only'
ROOT=f'http://{HOST}/v1/projects/{PROJECT}/databases/(default)/documents'
def token(uid,admin=False):
 def enc(v):return base64.urlsafe_b64encode(json.dumps(v).encode()).decode().rstrip('=')
 return enc({'alg':'none','typ':'JWT'})+'.'+enc({'sub':uid,'user_id':uid,'aud':PROJECT,'iss':f'https://securetoken.google.com/{PROJECT}','iat':int(time.time()),'exp':int(time.time())+3600,'admin':admin,'firebase':{'sign_in_provider':'custom'}})+'.'
def fields(data):return {k:{'stringValue':v} for k,v in data.items()}
def call(method,path,data=None,uid=None,admin=False,seed=False):
 headers={'Content-Type':'application/json'}
 if seed or uid:headers['Authorization']='Bearer '+('owner' if seed else token(uid,admin))
 req=urllib.request.Request(ROOT+path,data=json.dumps(data).encode() if data is not None else None,headers=headers,method=method)
 try:
  with urllib.request.urlopen(req) as res:return res.status,res.read().decode()
 except urllib.error.HTTPError as e:return e.code,e.read().decode()
def check(code,result,label):
 assert result[0]==code,f'{label}: expected {code}, got {result}'
 print('PASS:',label)
check(200,call('PATCH','/users/verification-target',{'fields':fields({'name':'Verification target'})},seed=True),'seed target account')
base=f'projects/{PROJECT}/databases/(default)/documents/'
def write(uid='super-admin',admin=True,audit='verification-audit-1',status='verified',category='education_professional',reason='Institute confirmed teaching affiliation.',include_audit=True):
 doc={'name':base+'accountVerifications/verification-target','fields':fields({'status':status,'category':category,'auditId':audit})}
 transforms=[{'fieldPath':'updatedAt','setToServerValue':'REQUEST_TIME'},{'fieldPath':'verifiedAt','setToServerValue':'REQUEST_TIME'}]
 writes=[{'update':doc,'updateTransforms':transforms}]
 if include_audit:writes.append({'update':{'name':base+'accountVerificationAudits/'+audit,'fields':fields({'targetUid':'verification-target','actorUid':uid,'action':'verify' if status=='verified' else 'revoke','category':category,'reason':reason,'previousStatus':'unverified'})},'updateTransforms':[{'fieldPath':'createdAt','setToServerValue':'REQUEST_TIME'}]})
 return call('POST',':commit',{'writes':writes},uid=uid,admin=admin)
check(403,write(uid='verification-target',admin=False),'account cannot self-verify')
check(403,write(uid='manager-admin',admin=False),'manager admin cannot grant tick')
check(403,write(include_audit=False),'verification requires atomic audit record')
check(403,write(category='fake-category'),'unknown verification category rejected')
check(403,write(reason='short'),'empty/short evidence reason rejected')
check(200,write(),'super admin grants tick with private audit')
check(200,call('GET','/accountVerifications/verification-target',uid='viewer'),'signed-in viewer reads public verification category')
check(403,call('GET','/accountVerificationAudits/verification-audit-1',uid='viewer'),'evidence and admin history remain private')
check(200,call('GET','/accountVerificationAudits/verification-audit-1',uid='super-admin',admin=True),'super admin can read audit')
check(403,call('PATCH','/accountVerificationAudits/verification-audit-1',{'fields':fields({'reason':'Changed audit history'})},uid='super-admin',admin=True),'audit history is immutable')
check(403,call('DELETE','/accountVerifications/verification-target',uid='verification-target'),'account cannot remove verification record')
# Revoke with original grant date preserved and a new immutable audit.
current=json.loads(call('GET','/accountVerifications/verification-target',uid='viewer')[1])['fields']
public=fields({'status':'revoked','category':'education_professional','auditId':'verification-audit-2'})
public['verifiedAt']=current['verifiedAt']
writes=[{'update':{'name':base+'accountVerifications/verification-target','fields':public},'updateTransforms':[{'fieldPath':'updatedAt','setToServerValue':'REQUEST_TIME'}]},{'update':{'name':base+'accountVerificationAudits/verification-audit-2','fields':fields({'targetUid':'verification-target','actorUid':'super-admin','action':'revoke','category':'education_professional','reason':'Institute withdrew the affiliation.','previousStatus':'verified'})},'updateTransforms':[{'fieldPath':'createdAt','setToServerValue':'REQUEST_TIME'}]}]
check(200,call('POST',':commit',{'writes':writes},uid='super-admin',admin=True),'super admin revokes with audit and preserves original grant date')
