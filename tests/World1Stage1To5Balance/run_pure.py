"""Use exact captured baseline Sources, never a historical fixture as production code."""
import json,sys,subprocess,tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[2]
before=json.loads(Path(sys.argv[1]).read_text(encoding='utf8'))
exe=Path(sys.argv[2])
paths={'Requirements':'ReplicatedStorage.Config.LevelRequirements','Progression':'ReplicatedStorage.Modules.LevelProgression','Rebirth':'ReplicatedStorage.Config.RebirthConfig','Balance':'ReplicatedStorage.Config.World1BossConfig','World2':'ReplicatedStorage.Config.World2Config'}
sources={}
for name,path in paths.items():
 sources[name]=(root/'src'/(path.replace('.','/')+'.luau')).read_text(encoding='utf8')
 sources['Old'+name]=before[path]
def literal(s): return '[=====['+s+']=====]'
body='local sources={'+','.join('['+json.dumps(k)+']='+literal(v) for k,v in sources.items())+'}\n'
body+='local result=assert(loadstring('+literal((Path(__file__).parent/'Pure.luau').read_text(encoding='utf8'))+'))()(sources)\nfor k,v in result do print(k,v)end\n'
with tempfile.TemporaryDirectory(prefix='w1-balance-pure-') as td:
 p=Path(td)/'run.luau';p.write_text(body,encoding='utf8')
 subprocess.run([str(exe),str(p)],check=True)
