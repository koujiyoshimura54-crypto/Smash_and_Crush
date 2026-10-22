from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
import argparse, os
parser=argparse.ArgumentParser(description='Prepare an unsaved StudioTestService two-client fixture; no place file is changed.')
parser.add_argument('--output',type=Path,default=Path(os.environ['TEMP'])/'World2BossWalkNative.luau')
parser.add_argument('--saved',action='store_true',help='Test the actual saved Sources without injecting repository Sources')
parser.add_argument('--kill',action='store_true')
parser.add_argument('--lifecycle',action='store_true')
parser.add_argument('--stage5-only',action='store_true')
args=parser.parse_args()
work=root/'tests/World2BossWalk'
files={
 'ReplicatedStorage.Config.World2BossAnimationConfig':'src/ReplicatedStorage/Config/World2BossAnimationConfig.luau',
 'ReplicatedStorage.Modules.World2BossRig':'src/ReplicatedStorage/Modules/World2BossRig.luau',
 'ReplicatedStorage.Modules.World2BossClip':'src/ReplicatedStorage/Modules/World2BossClip.luau',
 'ServerScriptService.World.World2BossAnimationService':'src/ServerScriptService/World/World2BossAnimationService.luau',
 'StarterPlayer.StarterPlayerScripts.World2BossAnimationClient':'src/StarterPlayer/StarterPlayerScripts/World2BossAnimationClient.client.luau',
 'ServerScriptService.World.BossChaseService':'src/ServerScriptService/World/BossChaseService.luau',
 'ServerScriptService.World.BossVisualPlacement':'src/ServerScriptService/World/BossVisualPlacement.luau',
 'ServerScriptService.World.EnemyManager':'src/ServerScriptService/World/EnemyManager.luau',
 'ServerScriptService.StudioBossAnimationPreview':'src/ServerScriptService/StudioBossAnimationPreview.server.luau',
 'StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview':'src/StarterPlayer/StarterPlayerScripts/StudioBossAnimationPreview.client.luau',
}
def quote(value): return json.dumps(value,ensure_ascii=False)
sources={p:(root/f).read_text(encoding='utf-8') for p,f in files.items()}
code='local sources='+ '{'+','.join('['+quote(p)+']='+quote(s) for p,s in sources.items())+'}\n'
code+='local savedMode='+('true' if args.saved else 'false')+'\n'
code+='''
local function resolve(path,kind)
 local at=game
 local names=string.split(path,".")
 for i,name in names do
  local next=at:FindFirstChild(name)
  if not next then next=Instance.new(i==#names and kind or "Folder");next.Name=name;next.Parent=at end
  at=next
 end
 return at
end
for path,source in sources do
 local kind=path:find("StarterPlayer") and "LocalScript" or path=="ServerScriptService.StudioBossAnimationPreview" and "Script" or "ModuleScript"
 local object=resolve(path,kind)
 assert(loadstring(source),path)
 if savedMode then assert(object.Source:gsub(string.char(13,10),string.char(10))==source:gsub(string.char(13,10),string.char(10)),"Saved Source mismatch: "..path)
 else object.Source=source end
end
'''
code+='local memorySource='+quote((work/'Memory.luau').read_text())+'\n'
code+='''
resolve("ReplicatedStorage.__WalkTestMemory","ModuleScript").Source=memorySource
local replacements={DataStoreService=true,MarketplaceService=true,BadgeService=true}
for _,obj in game:GetDescendants() do
 if obj:IsA("LuaSourceContainer") and obj.Name~="__WalkTestMemory" then
  local source=obj.Source
  for service in replacements do
   source=source:gsub('game:GetService%("'..service..'"%)','require(game.ReplicatedStorage.__WalkTestMemory).'..service)
   source=source:gsub("game:GetService%('"..service.."'%)",'require(game.ReplicatedStorage.__WalkTestMemory).'..service)
  end
  if source~=obj.Source then obj.Source=source end
 end
end
'''
code+='resolve("ServerScriptService.__WalkTestDriver","Script").Source='+quote((work/'Server.luau').read_text())+'\n'
code+='resolve("StarterPlayer.StarterPlayerScripts.__WalkTestClient","LocalScript").Source='+quote((work/'Client.luau').read_text())+'\n'
code+='''
task.wait(3)
print("WALK_NATIVE_STARTING")
local ok,result=pcall(function() return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2,"World2Walk") end)
print("WALK_NATIVE_RESULT "..game:GetService("HttpService"):JSONEncode({Success=ok,Result=result}))
print("WALK_NATIVE_EDIT_RETURNED",game:GetService("StudioTestService").EditModeActive)
'''
if args.kill: code=code.replace('ExecuteMultiplayerTestAsync(2,"World2Walk")','ExecuteMultiplayerTestAsync(2,{OnlyKill=true})')
if args.lifecycle: code=code.replace('ExecuteMultiplayerTestAsync(2,"World2Walk")','ExecuteMultiplayerTestAsync(2,{LifecycleOnly=true})')
if args.stage5_only: code=code.replace('ExecuteMultiplayerTestAsync(2,"World2Walk")','ExecuteMultiplayerTestAsync(2,{Stage5Only=true})')
args.output.write_text(code,encoding='utf-8')
print('Prepared owned Studio memory-only test runner; no place written')
