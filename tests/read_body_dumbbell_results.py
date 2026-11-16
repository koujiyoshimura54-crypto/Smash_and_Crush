"""Extract complete native Studio results; reject truncated or missing output."""
from pathlib import Path
import argparse,json,statistics
p=argparse.ArgumentParser();p.add_argument('log',type=Path);p.add_argument('--out',type=Path)
a=p.parse_args();lines=a.log.read_text(encoding='utf-8').splitlines()
chunks=[];expected=None
for line in lines:
 if line.startswith('BODY_DIAGNOSTICS_RESULT_BYTES '):expected=int(line.split()[-1])
 elif line.startswith('BODY_DIAGNOSTICS_CHUNK '):
  _,i,s=line.split(' ',2);chunks.append((int(i),s))
if chunks:
 assert [i for i,_ in chunks]==list(range(1,len(chunks)+1)), 'Missing result chunk'
 encoded=''.join(s for _,s in chunks)
 assert len(encoded.encode())==expected,'Truncated result chunks'
else:encoded=next(x.split(' ',1)[1]for x in lines if x.startswith('BODY_DIAGNOSTICS_RESULT '))
r=json.loads(encoded)
if a.out:a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
result=r.get('Result',{});m=result.get('Measurements',[])
print(json.dumps({'Success':r.get('Success'),'Passed':result.get('Passed'),'Error':result.get('Error')or result.get('FixtureFailure'),'Checks':len(result.get('Checks',[])),'Failed':[c['Name']for c in result.get('Checks',[])if not c['Passed']],'Speeds':{name:{'Mean':statistics.mean(x['Speed']for x in m if x['Name']==name),'Trials':[x['Speed']for x in m if x['Name']==name]}for name in dict.fromkeys(x['Name']for x in m)}},indent=2))
