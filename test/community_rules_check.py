"""Community ownership, reactions, votes and counters. Emulator only."""
import base64,json,os,time,urllib.request,urllib.error,datetime
HOST=os.environ.get('FIRESTORE_EMULATOR_HOST','');assert HOST.startswith(('127.0.0.1:','localhost:')),'Emulator only'
PROJECT='demo-talib-review-tests';BASE=f'projects/{PROJECT}/databases/(default)/documents/';ROOT=f'http://{HOST}/v1/'+BASE.rstrip('/')
def token(uid):
 def enc(value):return base64.urlsafe_b64encode(json.dumps(value).encode()).decode().rstrip('=')
 return enc({'alg':'none','typ':'JWT'})+'.'+enc({'sub':uid,'user_id':uid,'aud':PROJECT,'iss':f'https://securetoken.google.com/{PROJECT}','iat':int(time.time()),'exp':int(time.time())+3600,'firebase':{'sign_in_provider':'custom'}})+'.'
def val(value):
 if value is None:return {'nullValue':None}
 if isinstance(value,bool):return {'booleanValue':value}
 if isinstance(value,str):return {'stringValue':value}
 if isinstance(value,int):return {'integerValue':str(value)}
 if isinstance(value,datetime.datetime):return {'timestampValue':value.isoformat().replace('+00:00','Z')}
 if isinstance(value,list):return {'arrayValue':{'values':[val(v) for v in value]}}
 if isinstance(value,dict):return {'mapValue':{'fields':{k:val(v) for k,v in value.items()}}}
 raise ValueError(value)
def call(method,path,data=None,uid='community-alice',seed=False):
 headers={'Content-Type':'application/json','Authorization':'Bearer '+('owner' if seed else token(uid))}
 request=urllib.request.Request(ROOT+path,data=json.dumps(data).encode() if data is not None else None,headers=headers,method=method)
 try:
  with urllib.request.urlopen(request) as res:return res.status,res.read().decode()
 except urllib.error.HTTPError as error:return error.code,error.read().decode()
def check(code,result,label):assert result[0]==code,(label,result);print('PASS:',label)
def write(path,data,transforms=(),update=False):
 result={'update':{'name':BASE+path,'fields':{k:val(v) for k,v in data.items()}}}
 if update:result['updateMask']={'fieldPaths':list(data)}
 if transforms:result['updateTransforms']=[{'fieldPath':key,'setToServerValue':'REQUEST_TIME'} for key in transforms]
 return result
def commit(writes,uid='community-alice'):return call('POST',':commit',{'writes':writes},uid)
legacy={'text':'A legacy question','authorId':'community-bob','authorName':'Bob','category':'Study Help','isQuestion':True,'createdAt':datetime.datetime.now(datetime.timezone.utc),'likesCount':1,'likedBy':['community-bob'],'commentsCount':0,'pollOptions':[],'pollVotes':{},'attachments':[]}
check(200,call('PATCH','/posts/community-legacy',{'fields':{k:val(v) for k,v in legacy.items()}},seed=True),'seed legacy post')
def reaction(values,ids,count=None):return commit([write('posts/community-legacy',{'reactions':values,'likedBy':ids,'likesCount':len(ids) if count is None else count},update=True)])
check(200,reaction({'community-alice':'helpful'},['community-bob','community-alice']),'add helpful reaction without losing legacy like')
check(403,reaction({'community-alice':'helpful','community-bob':'support'},['community-bob','community-alice']),'cannot change another account reaction')
check(403,reaction({'community-alice':'laugh'},['community-bob','community-alice']),'unknown reaction rejected')
check(403,reaction({'community-alice':'helpful'},['community-bob','community-alice'],99),'cannot inflate reaction count')
check(403,reaction({'community-alice':'helpful'},['community-alice','community-alice']),'cannot remove another reactor through duplicate IDs')
check(200,reaction({'community-alice':'insightful'},['community-bob','community-alice']),'change own reaction without double counting')
check(200,reaction({},['community-bob']),'remove own reaction only')
check(200,commit([write('posts/community-legacy',{'likedBy':[],'likesCount':0},update=True)],'community-bob'),'legacy client may remove its own legacy like')
check(403,commit([write('posts/community-legacy',{'text':'Not mine'},update=True)]),'non-owner cannot edit content')
check(200,commit([write('posts/community-legacy',{'text':'Edited question'},('updatedAt',),True)],'community-bob'),'owner edits and adds server edit time')
post={'text':'Choose a subject','authorId':'community-alice','authorName':'Alice','category':'Study Help','postType':'poll','educationalData':{'duration':'3 days'},'isQuestion':False,'likesCount':0,'likedBy':[],'reactions':{},'commentsCount':0,'pollOptions':['Physics','Mathematics'],'pollVotes':{},'pollVoters':{},'attachments':[],'pollClosesAt':datetime.datetime.now(datetime.timezone.utc)+datetime.timedelta(days=3)}
check(200,commit([write('posts/community-poll',post,('createdAt',))]),'publish structured educational poll')
for field,value,label in [('likesCount',99,'initial fake engagement'),('educationalData',{'verified':'true'},'fake verified metadata'),('authorId','community-bob','forged author')]:
 bad={**post,field:value};check(403,commit([write('posts/community-bad-'+field,bad,('createdAt',))]),label+' rejected')
def vote(voters,votes,uid='community-alice'):return commit([write('posts/community-poll',{'pollVoters':voters,'pollVotes':votes},update=True)],uid)
check(200,vote({'community-alice':0},{'0':1}),'first vote initializes own ballot')
check(200,vote({'community-alice':0,'community-bob':1},{'0':1,'1':1},'community-bob'),'another user votes independently')
check(403,vote({'community-alice':0,'community-bob':0},{'0':2,'1':0}),'cannot change another ballot')
check(403,vote({'community-alice':0,'community-bob':1},{'0':100,'1':1}),'cannot forge poll totals')
check(200,vote({'community-alice':1,'community-bob':1},{'0':0,'1':2}),'change vote decrements old choice exactly once')
check(403,commit([write('posts/community-poll',{'pollOptions':['A','B']},update=True)]),'owner cannot change options after votes')
check(403,commit([write('posts/community-poll',{'pollClosesAt':datetime.datetime.now(datetime.timezone.utc)+datetime.timedelta(days=7)},update=True)]),'owner cannot extend a voted poll')
check(200,call('PATCH','/posts/community-poll',{'fields':{'pollClosesAt':val(datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(days=1))}},seed=True),'seed expired deadline')
check(403,vote({'community-alice':0,'community-bob':1},{'0':1,'1':1}),'closed poll rejects votes')
comment={'text':'An educational answer','authorId':'community-alice','authorName':'Alice'}
check(403,commit([write('posts/community-legacy',{'commentsCount':1,'lastCommentId':'no-comment'},update=True)]),'counter cannot increment without a real comment')
check(200,commit([write('posts/community-legacy',{'commentsCount':1,'lastCommentId':'community-comment'},update=True),write('posts/community-legacy/comments/community-comment',comment,('createdAt',))]),'atomic comment and count succeed')
check(200,commit([write('posts/community-legacy',{'bestAnswerId':'community-comment'},update=True)],'community-bob'),'question owner selects an existing best answer')
check(403,call('DELETE','/posts/community-legacy/comments/community-comment'),'standalone delete cannot leave a stale counter')
check(200,commit([write('posts/community-legacy',{'commentsCount':0,'lastCommentId':'community-comment','bestAnswerId':None},update=True),{'delete':BASE+'posts/community-legacy/comments/community-comment'}]),'deleting own best answer clears count and badge atomically')
hidden={'postId':'community-legacy','title':'Legacy question','reason':'not_interested'}
check(200,commit([write('users/community-alice/hiddenPosts/community-legacy',hidden,('createdAt',))]),'save own feed preference')
check(403,call('GET','/users/community-alice/hiddenPosts/community-legacy',uid='community-bob'),'hidden preferences are private')
check(403,commit([write('users/community-bob/hiddenPosts/community-legacy',hidden,('createdAt',))]),'cannot write another user feed preferences')
print('Community permissions verified.')
