#!/usr/bin/env python3
"""Fetch official Godot 4.3 macOS editor and only its single-thread web template.
Range chunks are cached to tolerate interrupted downloads.
"""
import ssl,certifi
ssl._create_default_https_context=lambda:ssl.create_default_context(cafile=certifi.where())
import urllib.request,concurrent.futures,zipfile,io,struct,zlib,os
from pathlib import Path
base='https://github.com/godotengine/godot-builds/releases/download/4.3-stable/'
out=Path(__file__).resolve().parents[1]/'Builds/Toolchain'
out.mkdir(parents=True,exist_ok=True)
def get(url,start=None,end=None):
 import time,hashlib
 key=hashlib.sha256((url.split('?')[0]+str(start)+str(end)).encode()).hexdigest()
 cache=out/('chunk-'+key)
 if cache.exists():return cache.read_bytes()
 for attempt in range(8):
  try:
   h={} if start is None else {'Range':f'bytes={start}-{end}'}
   with urllib.request.urlopen(urllib.request.Request(url,headers=h),timeout=90) as r:data=r.read()
   if start is not None and len(data)!=end-start+1:raise ValueError('range length')
   cache.write_bytes(data)
   return data
  except Exception as e:
   if attempt==7:raise
   time.sleep(1)
def resolve(name):
 with urllib.request.urlopen(urllib.request.Request(base+name,headers={'Range':'bytes=0-0'}),timeout=60) as r:
  print(name,r.status,r.headers.get('Content-Range'),flush=True)
  return r.url,int(r.headers['Content-Range'].split('/')[-1])
def parallel(url,start,length):
 parts=[(p,min(p+262143,start+length-1)) for p in range(start,start+length,262144)]
 with concurrent.futures.ThreadPoolExecutor(max_workers=24) as ex:
  result=[]
  for i,data in enumerate(ex.map(lambda p:get(url,*p),parts)):
   result.append(data)
   if i%32==0:print('chunks',i,len(parts),flush=True)
  return b''.join(result)
def mac():
 if (out/'Godot.app/Contents/MacOS/Godot').exists():return
 u,n=resolve('Godot_v4.3-stable_macos.universal.zip')
 data=parallel(u,0,n);z=zipfile.ZipFile(io.BytesIO(data));z.extractall(out)
 for f in (out/'Godot.app/Contents/MacOS').iterdir():f.chmod(0o755)
 print('mac done',flush=True)
def web():
 if (out/'web_nothreads_release.zip').exists():return
 u,n=resolve('Godot_v4.3-stable_export_templates.tpz')
 tail=get(u,n-65536,n-1);idx=tail.rfind(b'PK\x05\x06');e=struct.unpack_from('<4s4H2LH',tail,idx)
 cdsize,cdoff=e[5:7];cd=get(u,cdoff,cdoff+cdsize-1);p=0
 while p<len(cd):
  f=struct.unpack_from('<4s6H3L5H2L',cd,p);nl,el,cl=f[10:13];name=cd[p+46:p+46+nl].decode();p+=46+nl+el+cl
  if 'web_nothreads_release.zip' not in name:continue
  print('extract',name,f[8],flush=True)
  off=f[-1];head=get(u,off,off+29);h=struct.unpack('<4s5H3L2H',head);dataoff=off+30+h[-2]+h[-1]
  data=parallel(u,dataoff,f[8]);data=zlib.decompress(data,-15) if f[4]==8 else data
  assert len(data)==f[9] and zlib.crc32(data)==f[7], 'Template CRC mismatch'
  (out/'web_nothreads_release.zip').write_bytes(data);print('web done',flush=True);return
 raise RuntimeError('No template')
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:
 for f in [ex.submit(mac),ex.submit(web)]:f.result()
