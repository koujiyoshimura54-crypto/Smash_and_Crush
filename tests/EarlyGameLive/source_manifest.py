import hashlib,json,pathlib
root=pathlib.Path(__file__).resolve().parents[2]
pairs={
"ReplicatedStorage.Config.LevelRequirements":"src/ReplicatedStorage/Config/LevelRequirements.luau",
"ReplicatedStorage.Config.World1BossConfig":"src/ReplicatedStorage/Config/World1BossConfig.luau",
"StarterPlayer.StarterPlayerScripts.Tutorial.TutorialGuideClient":"src/StarterPlayer/StarterPlayerScripts/Tutorial/TutorialGuideClient.client.luau",
"ReplicatedStorage.Modules.LevelProgression":"src/ReplicatedStorage/Modules/LevelProgression.luau",
"ServerScriptService.Services.PlayerDataService":"src/ServerScriptService/Services/PlayerDataService.luau"}
out={}
for full,file in pairs.items():
 b=(root/file).read_text(encoding="utf-8").rstrip().encode("utf-8")+b"\n"
 a,c=5381,2166136261
 for v in b:a=(a*33+v)%(2**32);c=(c*65599+v)%(2**32)
 out[full]={"File":file,"Bytes":len(b),"Rolling":[a,c],"SHA256":hashlib.sha256(b).hexdigest()}
(root/"reports/EarlyGameLive_20261111/source-manifest.json").write_text(json.dumps(out,indent=2)+"\n",encoding="utf-8")
print(json.dumps(out))
