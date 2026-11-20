"""Validate measured Studio Edit geometry, not a synthetic UI implementation."""
from pathlib import Path
import json, math

root=Path(__file__).resolve().parents[1]
report=root/'reports/RewardBadgeHalf_20261120'
rows=json.loads((report/'measurements.json').read_text(encoding='utf-8'))
checks=0
def check(ok, message):
 global checks
 assert ok, message
 checks+=1
def intersects(a,b):
 return a['X']<b['X']+b['W'] and a['X']+a['W']>b['X'] and a['Y']<b['Y']+b['H'] and a['Y']+a['H']>b['Y']
summary=[]
for after in (r for r in rows if not r['Before']):
 before=next(r for r in rows if r['Before'] and r['Device']==after['Device'] and r['Phase']==after['Phase'])
 check(before['Viewport']==after['Viewport'],'same device canvas')
 for b,a in zip(before['Rows'],after['Rows']):
  check(a['Name']==b['Name'],'same badge')
  for key in ('Button','Icon','ButtonScale','ImageId','Color','Rotation','Active','Interactable','Visible'):
   check(a[key]==b[key],key+' preserved')
  for key in ('W','H'):
   check(math.isclose(a['Image'][key]/b['Image'][key],.5,abs_tol=1e-6),'final image '+key+' halved once')
   check(math.isclose(a['Rotated'][key]/b['Rotated'][key],.5,abs_tol=1e-6),'animated bounds '+key+' halved')
  check(math.isclose(a['Image']['W'],a['Image']['H'],abs_tol=1e-5),'aspect ratio')
  check(intersects(a['Image'],a['Icon']),'badge overlaps icon corner, no floating gap')
  check(abs(a['Image']['X']+a['Image']['W']/2-a['Button']['X']-a['Button']['W'])<.001,'center anchored at right edge')
  r,v=a['Rotated'],after['Viewport']
  check(r['X']>=0 and r['Y']>=0 and r['X']+r['W']<=v['W'] and r['Y']+r['H']<=v['H'],'animation inside safe canvas')
  check(math.isclose(a['Rotation'],{'normal':0,'plus10':10,'minus10':-10}[after['Phase']],abs_tol=.0001),'original animation at requested phase')
 check(not intersects(after['Rows'][0]['Rotated'],after['Rows'][1]['Rotated']),'badges do not overlap each other')
 if after['Phase']=='normal':
  summary.append({'Device':after['Device'],'Canvas':after['Viewport'],
   'BeforePixels':before['Rows'][0]['Image']['W'],'AfterPixels':after['Rows'][0]['Image']['W'],'Ratio':.5})
result={'Checks':checks,'Mode':'Studio Edit rendering and injected time for unchanged animation; not Play or physical devices','Devices':summary}
(report/'geometry_verification.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,indent=2))
