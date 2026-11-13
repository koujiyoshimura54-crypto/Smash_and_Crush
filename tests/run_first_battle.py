"""Pure state/config verification and syntax checks; native persistence tests are separate."""
import pathlib, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[1]
exe=pathlib.Path('C:/Users/kouji/stage_skip_work/luau')
def source(p): return (root/p).read_text(encoding='utf8')
def lit(s): return '[======['+s+']======]'
state=source('src/ReplicatedStorage/Modules/FirstBattleTutorialState.luau')
reward=source('src/ReplicatedStorage/Config/TimeRewardConfig.luau')
balance=source('src/ReplicatedStorage/Config/World1BossConfig.luau')
body='local S=assert(loadstring('+lit(state)+'))()\n'
body+='local reward=assert(loadstring('+lit(reward)+'))\n'
body+='setfenv(reward,setmetatable({script={Parent={OreConfig={}}},require=function()return {Get=function()return {Name="Iron"}end}end},{__index=getfenv()}))\n'
body+='local R=reward()\nlocal C=assert(loadstring('+lit(balance)+'))()\n'
body+='assert(loadstring('+lit(source('tests/FirstBattleTutorialState.luau'))+'))()(S,R,C)\n'
with tempfile.TemporaryDirectory(prefix='first-battle-') as td:
 p=pathlib.Path(td)/'pure.luau';p.write_text(body,encoding='utf8')
 subprocess.run([str(exe/'luau.exe'),str(p)],check=True)
subprocess.run([str(exe/'luau.exe'),str(root/'tests/Stage1WallPromptState.luau')],check=True)
paths=subprocess.check_output(['git','diff','--name-only'],cwd=root,text=True).splitlines()
paths+=['src/ReplicatedStorage/Modules/FirstBattleTutorialState.luau','src/ServerScriptService/Services/FirstBattleTutorialService.luau']
paths += [str(p.relative_to(root)) for p in (root/'tests/FirstBattleTutorial').glob('*.luau')]
paths += ['tests/FirstBattleTutorialState.luau','tools/ApplyStage1SingleWall.luau']
for path in set(paths):
 if not path.endswith('.luau'): continue
 result=subprocess.run([str(exe/'luau-compile.exe'),str(root/path)],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True,encoding='utf8')
 if result.returncode: raise RuntimeError(path+'\n'+result.stderr)
print('Changed Luau syntax checks passed')
