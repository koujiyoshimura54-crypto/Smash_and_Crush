"""Build a gallery of the requested native, time-separated client captures."""
from pathlib import Path
import datetime,html,json
root=Path(__file__).resolve().parents[1]/'reports/World2FourBossWalk_20261022'
names={1:'096',2:'023',3:'035',4:'058',5:'049',6:'173',7:'939',8:'106',10:'323'}
rows=[];sections=[]
for stage in [2,4,6,7,1,5,3,8,10]:
 pids=[15816,29568] if stage in (1,2) else [31200,12468]
 views=['Front','Side','Normal'] if stage in (2,4,6,7) else ['Side']
 for view in views:
  pictures=[]
  for client,pid in enumerate(pids,1):
   for frame in (1,2):
    file=root/f'frames/SavedRegression/S{stage}_{view}_P{pid}_{frame}.jpg'
    assert file.exists(),file
    path=file.relative_to(root).as_posix()
    stamp=datetime.datetime.fromtimestamp(file.stat().st_mtime,datetime.timezone.utc).isoformat()
    rows.append({'Stage':stage,'Boss':names[stage],'View':view,'ClientProcess':pid,'Frame':frame,'CapturedUTC':stamp,'Path':path})
    pictures.append(f'<figure><img loading="lazy" src="{path}"><figcaption>Client process {pid}, frame {frame} — {html.escape(stamp)}</figcaption></figure>')
  sections.append(f'<section><h2>Stage {stage} / SCP-{names[stage]} / {view}</h2><div class="grid">'+''.join(pictures)+'</div></section>')
(root/'EvidenceManifest.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8')
(root/'Evidence.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><title>Four Boss native movement evidence</title>
<style>body{font:16px system-ui;background:#121824;color:#eef3ff;margin:24px}a{color:#8dd4ff}.grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}figure{margin:0}img{width:100%;height:auto}figcaption{font-size:12px}section{margin-bottom:30px}</style>
<h1>Native two-client movement sequences</h1><p>Actual personal battle actors from the written CurrentCloud file. Each pair shows different captured times, not an animation mockup. Front/side use diagnostic camera framing; Normal uses an ordinary third-person distance aimed at the encounter. Server-driven QA input and in-memory data; physical input and published-server behavior were not tested.</p><p><a href="README.md">Implementation and verification record</a> · <a href="EvidenceManifest.json">Capture timestamps</a></p>
'''+''.join(sections)+'</html>',encoding='utf-8')
print(f'{len(rows)} native images selected; {sum((root/r["Path"]).stat().st_size for r in rows)/1e6:.1f} MB')
