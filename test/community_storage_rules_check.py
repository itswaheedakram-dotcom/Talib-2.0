"""Attachment ownership and public-community reads; Storage emulator only."""
import base64,json,os,time,urllib.request,urllib.error,urllib.parse
HOST=os.environ.get('FIREBASE_STORAGE_EMULATOR_HOST','127.0.0.1:9199');assert HOST.startswith(('127.0.0.1:','localhost:')),'Emulator only'
PROJECT='demo-talib-review-tests';ROOT=f'http://{HOST}/v0/b/{PROJECT}.appspot.com/o'
def token(uid):
 def enc(v):return base64.urlsafe_b64encode(json.dumps(v).encode()).decode().rstrip('=')
 return enc({'alg':'none','typ':'JWT'})+'.'+enc({'sub':uid,'user_id':uid,'aud':PROJECT,'iss':f'https://securetoken.google.com/{PROJECT}','iat':int(time.time()),'exp':int(time.time())+3600,'firebase':{'sign_in_provider':'custom'}})+'.'
def request(method,url,uid=None,data=None,mime='image/jpeg',extra=None):
 headers={'Content-Type':mime,**(extra or {})}
 if uid:headers['Authorization']='Firebase '+token(uid)
 req=urllib.request.Request(url,data=data,headers=headers,method=method)
 try:
  with urllib.request.urlopen(req) as res:return res.status,res.read()
 except urllib.error.HTTPError as error:return error.code,error.read()
def check(code,result,label):assert result[0]==code,(label,result);print('PASS:',label)
def upload(path,uid,mime='image/jpeg',size=20):
 boundary='talib-community-test-boundary'
 metadata=json.dumps({'name':path,'contentType':mime}).encode()
 body=b'--'+boundary.encode()+b'\r\nContent-Type: application/json; charset=utf-8\r\n\r\n'+metadata+b'\r\n--'+boundary.encode()+b'\r\nContent-Type: '+mime.encode()+b'\r\n\r\n'+b'x'*size+b'\r\n--'+boundary.encode()+b'--'
 return request('POST',ROOT+'?name='+urllib.parse.quote(path,safe=''),uid,data=body,mime='multipart/related; boundary='+boundary,extra={'X-Goog-Upload-Protocol':'multipart'})
path='community/community-alice/test/photo.jpg'
check(200,upload(path,'community-alice'),'owner uploads to scoped community folder')
check(403,upload(path,'community-bob'),'another user cannot overwrite attachment')
check(403,upload('community/community-bob/test/photo.jpg','community-alice'),'cannot upload into another user folder')
check(403,upload('community/community-alice/test/file.exe','community-alice','application/x-msdownload'),'executable attachment rejected')
check(403,upload('community/community-alice/test/huge.jpg','community-alice',size=10*1024*1024+1),'oversized attachment rejected')
url=ROOT+'/'+urllib.parse.quote(path,safe='')+'?alt=media'
check(200,request('GET',url,'community-bob'),'signed-in community member can read public post media')
check(403,request('GET',url),'anonymous media read denied without a shared download token')
check(403,request('DELETE',ROOT+'/'+urllib.parse.quote(path,safe=''),'community-bob'),'another member cannot delete media')
check(200,request('DELETE',ROOT+'/'+urllib.parse.quote(path,safe=''),'community-alice'),'owner removes own media')
