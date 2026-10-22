"""Prepare an unsaved native two-client test. Never saves/publishes a place."""
from pathlib import Path
import argparse,json,os
ROOT=Path(__file__).resolve().parents[1]
FILES={
 'ReplicatedStorage.Config.World2BossAnimationConfig':'src/ReplicatedStorage/Config/World2BossAnimationConfig.luau',
 'ReplicatedStorage.Modules.World2BossRig':'src/ReplicatedStorage/Modules/World2BossRig.luau',
 'ReplicatedStorage.Modules.World2BossGaitRig':'src/ReplicatedStorage/Modules/World2BossGaitRig.luau',
 'ReplicatedStorage.Modules.World2BossGait':'src/ReplicatedStorage/Modules/World2BossGait.luau',
 'StarterPlayer.StarterPlayerScripts.World2BossAnimationClient':'src/StarterPlayer/StarterPlayerScripts/World2BossAnimationClient.client.luau',
 'ServerScriptService.StudioBossAnimationPreview':'src/ServerScriptService/StudioBossAnimationPreview.server.luau',
 'StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview':'src/StarterPlayer/StarterPlayerScripts/StudioBossAnimationPreview.client.luau',
}
def main():
 p=argparse.ArgumentParser();p.add_argument('--saved',action='store_true');p.add_argument('--mode',default='Smoke');p.add_argument('--stages',default='2,4,6,7');a=p.parse_args()
 q=lambda v:json.dumps(v,ensure_ascii=False)
 code='local sources={'+','.join('['+q(k)+']='+q((ROOT/v).read_text(encoding='utf-8'))for k,v in FILES.items())+'}\n'
 code+='local savedMode='+str(a.saved).lower()+'\n'
 code+='''
local function resolve(path,kind)
 local at=game;local names=string.split(path,".")
 for i,name in names do
  local child=at:FindFirstChild(name)
  if not child then assert(not savedMode,"Missing saved object "..path);child=Instance.new(i==#names and kind or "Folder");child.Name=name;child.Parent=at end
  at=child
 end
 return at
end
for path,source in sources do
 local kind=path:find("StarterPlayer") and "LocalScript" or path=="ServerScriptService.StudioBossAnimationPreview" and "Script" or "ModuleScript"
 local object=resolve(path,kind);assert(loadstring(source),path)
 if savedMode then assert(object.Source:gsub("\\r\\n","\\n")==source:gsub("\\r\\n","\\n"),"Saved Source mismatch "..path)
 else object.Source=source end
end
'''
 code+=(ROOT/'tests/World2FourBossWalk/InspectRig.luau').read_text(encoding='utf-8')+'\n'
 code+='savedMode=false\nresolve("ReplicatedStorage.__WalkTestMemory","ModuleScript").Source='+q((ROOT/'tests/World2BossWalk/Memory.luau').read_text())+'\n'
 code+='''
for _,obj in game:GetDescendants() do
 if obj:IsA("LuaSourceContainer") and obj.Name~="__WalkTestMemory" then
  local source=obj.Source
  for _,service in {"DataStoreService","MarketplaceService","BadgeService"} do
   source=source:gsub('game:GetService%("'..service..'"%)','require(game.ReplicatedStorage.__WalkTestMemory).'..service)
   source=source:gsub("game:GetService%('"..service.."'%)",'require(game.ReplicatedStorage.__WalkTestMemory).'..service)
  end
  if source~=obj.Source then obj.Source=source end
 end
end
'''
 # Test-only instances may be created in an otherwise saved-source verification.
 code+='savedMode=false\n'
 code+='''
local animation=game.StarterPlayer.StarterPlayerScripts.World2BossAnimationClient
animation.Source..=[[
local diagnostic=Instance.new("BindableFunction",script);diagnostic.Name="__FourDiagnostics"
diagnostic.OnInvoke=function()
 local active,waiting=0,0
 for _ in records do active+=1 end
 for _ in pending do waiting+=1 end
 return {Active=active,Pending=waiting}
end
]]
local preview=game.StarterPlayer.StarterPlayerScripts.StudioBossAnimationPreview
preview.Source..=[[
local qa=Instance.new("BindableFunction",script);qa.Name="__FourPreview"
qa.OnInvoke=function(stage)
 panel.Visible=true;selectBoss(stage)
 local deadline=os.clock()+15
 repeat task.wait(.1) until metadata or os.clock()>deadline
 assert(metadata,"Preview metadata timeout")
 selected=nil
 for _,candidate in metadata.Candidates do if candidate.Kind=="ProductionGait" then selected=candidate;break end end
 assert(selected,"Shared candidate missing")
 play();task.wait(.3)
 local initial=jointPose();local maxChanged=0
 for n=1,20 do task.wait(.1);maxChanged=math.max(maxChanged,changed(initial,jointPose())) end
 close();return {VisibleJointsChanged=maxChanged,Candidate="Approved Walk (production)",InvokedThrough="Existing Preview callbacks"}
end
]]
'''
 for path,file,kind in [('ServerScriptService.__FourBossServer','Server.luau','Script'),('StarterPlayer.StarterPlayerScripts.__FourBossClient','Client.luau','LocalScript')]:
  code+='resolve('+q(path)+','+q(kind)+').Source='+q((ROOT/'tests/World2FourBossWalk'/file).read_text(encoding='utf-8'))+'\n'
 groups=[[x] for x in a.stages.split(',')] if a.mode=='Full' else [a.stages.split(',')]
 for group in groups:
  code+='do local ok,result=pcall(function() return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2,{Mode='+q(a.mode)+',Stages={'+','.join(group)+'}}) end)\n'
  code+='print("FOUR_RESULT "..game:GetService("HttpService"):JSONEncode({Success=ok,Result=result}))\nprint("FOUR_EDIT",game:GetService("StudioTestService").EditModeActive) end\ntask.wait(5)\n'
 out=Path(os.environ['TEMP'])/'FourBossNative.luau';out.write_text(code,encoding='utf-8');print(out)
if __name__=='__main__':main()
