"""Hostel privacy and admin/owner authorization checks, emulator only."""
import base64,json,os,time,urllib.request,urllib.error
PROJECT='demo-talib-review-tests'
HOST=os.environ.get('FIRESTORE_EMULATOR_HOST','')
assert HOST.startswith(('127.0.0.1:','localhost:')), 'Emulator only'
ROOT=f'http://{HOST}/v1/projects/{PROJECT}/databases/(default)/documents'
def token(uid,admin=False):
 def enc(v):return base64.urlsafe_b64encode(json.dumps(v).encode()).decode().rstrip('=')
 return enc({'alg':'none','typ':'JWT'})+'.'+enc({'sub':uid,'user_id':uid,'aud':PROJECT,'iss':f'https://securetoken.google.com/{PROJECT}','iat':int(time.time()),'exp':int(time.time())+3600,'admin':admin,'firebase':{'sign_in_provider':'custom'}})+'.'
def value(v):
 if isinstance(v,bool):return {'booleanValue':v}
 if isinstance(v,int):return {'integerValue':str(v)}
 if isinstance(v,float):return {'doubleValue':v}
 if isinstance(v,str):return {'stringValue':v}
 if isinstance(v,list):return {'arrayValue':{'values':[value(x) for x in v]}}
 return {'mapValue':{'fields':{k:value(x) for k,x in v.items()}}}
def call(method,path,data=None,uid=None,admin=False,seed=False):
 headers={'Content-Type':'application/json'}
 if seed or uid:headers['Authorization']='Bearer '+('owner' if seed else token(uid,admin))
 req=urllib.request.Request(ROOT+path,data=json.dumps(data).encode() if data is not None else None,headers=headers,method=method)
 try:
  with urllib.request.urlopen(req) as res:return res.status,res.read().decode()
 except urllib.error.HTTPError as e:return e.code,e.read().decode()
def check(expected,result,label):
 assert result[0]==expected,f'{label}: expected {expected}, got {result}'
 print('PASS:',label)
def patch(path,data,**auth):return call('PATCH',path,{'fields':{k:value(v) for k,v in data.items()}},**auth)
room={'type':'4-Seater','rent':'10000','securityFee':'0','rentBasis':'Per bed','roomCount':2,'totalBeds':8,'availableBeds':3,'ac':True,'notes':'','securityPolicy':'No security fee','id':''}
hostel={'name':'Hostel rules test','city':'Lahore','area':'Town','ownerId':'hostel-owner','ownerName':'Owner','status':'approved','isVerified':True,'isDemo':False,'reviewCount':0,'ratingTotal':0.0,'rating':0.0,'phone':'','rooms':[room],'listingDetails':{'publicPhone':False}}
check(200,patch('/hostels/hostel-rules-test',hostel,seed=True),'seed structured hostel')
check(200,patch('/hostels/hostel-rules-test/private/contact',{'phone':'03001234567'},uid='hostel-owner'),'owner saves private phone')
check(403,call('GET','/hostels/hostel-rules-test/private/contact',uid='stranger'),'private phone hidden from stranger')
check(403,call('GET','/hostels/hostel-rules-test/private/contact'),'private phone hidden from public')
check(200,call('GET','/hostels/hostel-rules-test/private/contact',uid='super-admin',admin=True),'super admin can read private phone')
check(200,patch('/hostels/hostel-rules-test?updateMask.fieldPaths=name',{'name':'Admin edited'},uid='super-admin',admin=True),'super admin edits another owner hostel')
check(403,patch('/hostels/hostel-rules-test?updateMask.fieldPaths=name',{'name':'Unauthorized'},uid='stranger'),'stranger cannot edit hostel')
check(403,patch('/hostels/hostel-rules-test?updateMask.fieldPaths=ownerId',{'ownerId':'stranger'},uid='hostel-owner'),'owner cannot transfer ownership through listing editor')
check(403,patch('/hostels/hostel-rules-test?updateMask.fieldPaths=phone',{'phone':'03001234567'},uid='hostel-owner'),'private phone cannot leak into public listing')
check(403,patch('/hostels/hostel-rules-test?updateMask.fieldPaths=rooms',{'rooms':[{**room,'availableBeds':9}]},uid='hostel-owner'),'available beds cannot exceed total')
check(200,patch('/hostels/hostel-rules-test?updateMask.fieldPaths=rooms',{'rooms':[{**room,'availableBeds':0}]},uid='hostel-owner'),'zero available beds is valid')
# Atomic new listing plus private contact is authorized by parent getAfter.
new={**hostel,'status':'pending','isVerified':False}
name=f'projects/{PROJECT}/databases/(default)/documents/hostels/hostel-new-test'
writes=[{'update':{'name':name,'fields':{k:value(v) for k,v in new.items()}}},{'update':{'name':name+'/private/contact','fields':{'phone':value('03001234567')}}}]
check(200,call('POST',':commit',{'writes':writes},uid='hostel-owner'),'owner creates pending listing and private contact atomically')
