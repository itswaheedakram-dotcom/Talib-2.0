"""Public catalogue isolation checks; emulator only."""
import base64,json,os,time,urllib.request,urllib.error
HOST=os.environ.get('FIRESTORE_EMULATOR_HOST','');assert HOST.startswith(('127.0.0.1:','localhost:'))
PROJECT='demo-talib-review-tests';ROOT=f'http://{HOST}/v1/projects/{PROJECT}/databases/(default)/documents'
def token(uid,admin=False):
 def enc(v):return base64.urlsafe_b64encode(json.dumps(v).encode()).decode().rstrip('=')
 return enc({'alg':'none','typ':'JWT'})+'.'+enc({'sub':uid,'user_id':uid,'aud':PROJECT,'iss':f'https://securetoken.google.com/{PROJECT}','iat':int(time.time()),'exp':int(time.time())+3600,'admin':admin,'firebase':{'sign_in_provider':'custom'}})+'.'
def val(v):
 if isinstance(v,bool):return {'booleanValue':v}
 if isinstance(v,str):return {'stringValue':v}
 if isinstance(v,list):return {'arrayValue':{'values':[val(x) for x in v]}}
 if isinstance(v,dict):return {'mapValue':{'fields':{k:val(x) for k,x in v.items()}}}
 raise ValueError(v)
def call(method,path,data=None,uid='viewer',admin=False,seed=False):
 headers={'Content-Type':'application/json','Authorization':'Bearer '+('owner' if seed else token(uid,admin))}
 request=urllib.request.Request(ROOT+path,data=json.dumps(data).encode() if data is not None else None,headers=headers,method=method)
 try:
  with urllib.request.urlopen(request) as response:return response.status
 except urllib.error.HTTPError as error:return error.code
base=f'projects/{PROJECT}/databases/(default)/documents/'
def save(path,data,admin=False):
 return call('POST',':commit',{'writes':[{'update':{'name':base+path,'fields':{k:val(v) for k,v in data.items()}},'updateTransforms':[{'fieldPath':'updatedAt','setToServerValue':'REQUEST_TIME'}]}]},admin=admin)
def check(expected,actual,label):assert expected==actual,(label,actual);print('PASS:',label)
catalog={'label':'Transport','icon':'category','aliases':['bus'],'facets':[],'enabled':True}
check(403,save('searchCatalogs/transport',catalog),'ordinary users cannot register catalogues')
check(200,save('searchCatalogs/transport',catalog,True),'super admin registers future catalogue')
item={'catalogId':'transport','title':'Campus bus','description':'Public schedule','city':'Lahore','area':'Johar Town','tags':[],'attributes':{'mode':'Shared'},'published':False}
check(403,save('catalogItems/test-bus',item),'ordinary users cannot publish')
check(200,save('catalogItems/test-bus',item,True),'admin creates draft')
check(403,call('GET','/catalogItems/test-bus'),'draft is private')
item['published']=True;check(200,save('catalogItems/test-bus',item,True),'admin publishes')
check(200,call('GET','/catalogItems/test-bus'),'published listing is readable')
# Runtime query has the same equality constraints as the adapter.
query={'structuredQuery':{'from':[{'collectionId':'catalogItems'}],'where':{'compositeFilter':{'op':'AND','filters':[{'fieldFilter':{'field':{'fieldPath':'catalogId'},'op':'EQUAL','value':val('transport')}},{'fieldFilter':{'field':{'fieldPath':'published'},'op':'EQUAL','value':val(True)}}]}}}}
check(200,call('POST',':runQuery',query),'published category query is allowed')
catalog['enabled']=False;check(200,save('searchCatalogs/transport',catalog,True),'admin disables catalogue')
check(403,call('GET','/catalogItems/test-bus'),'disabled catalogue hides listings')
check(403,call('GET','/searchCatalogs/transport'),'disabled descriptor is private')
