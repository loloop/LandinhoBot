from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse,parse_qs
import json,uuid
categories=[dict(id=str(uuid.uuid4()),title=title,tag=tag) for title,tag in [('Fórmula 1','f1'),('Fórmula 2','f2'),('Stock Car Brasil','stock')]]
rounds=[]
for i in range(10):
 c=categories[2 if i>=6 else i%2]
 day=9+i
 rounds.append(dict(id=str(uuid.UUID(int=i+1)),title=f'Etapa {day}/10',shortTitle=['Singapura','Baku','Interlagos'][categories.index(c)],category=c,isCancelled=False,events=[dict(id=str(uuid.UUID(int=i+100)),title='Corrida',date=f'2026-10-{day:02}T17:00:00Z',isMainEvent=True,isCancelled=False)]))
rounds[7]['events'].append(dict(id=str(uuid.uuid4()),title='Classificação',date=None,scheduledDay='2026-10-16',isMainEvent=False,isCancelled=False))
class Handler(BaseHTTPRequestHandler):
 def do_GET(self):
  url=urlparse(self.path); q=parse_qs(url.query); items=rounds
  if url.path=='/category': data=categories
  elif url.path=='/next-races':
   if q.get('category',[''])[0]: items=[r for r in items if r['category']['tag']==q['category'][0]]
   favorites=set(q.get('favorites',[''])[0].split(',')); items=sorted(items,key=lambda r:(r['category']['tag'] not in favorites,r['events'][0]['date'],r['id']))
   page=max(1,int(q.get('page',['1'])[0])); per=int(q.get('per',['10'])[0]); data=dict(items=items[(page-1)*per:page*per],metadata=dict(page=page,per=per,total=len(items)))
  elif url.path=='/next-race': data=rounds[0]
  else: data=[]
  payload=json.dumps(data,ensure_ascii=False).encode();self.send_response(200);self.send_header('Content-Type','application/json');self.send_header('Content-Length',str(len(payload)));self.end_headers();self.wfile.write(payload)
HTTPServer(('127.0.0.1',18083),Handler).serve_forever()
