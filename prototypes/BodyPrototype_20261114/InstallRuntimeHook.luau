assert(game.PlaceId==126576845524886 and not game:GetService("RunService"):IsRunning())
assert(game.ReplicatedStorage:FindFirstChild("__BodyPrototypeMemory"),"Install existing memory isolation first")
assert(not game.ServerStorage:FindFirstChild("__BodyPrototypeRuntimePatch"),"Runtime hook already installed")
local target=game.ServerScriptService.Services.LobbySpawnService
local before=target.Source
local needle='character:SetAttribute("SpawnEngineReady", true)'
local insertion=[=[if game:GetService("RunService"):IsStudio() and game.PlaceId==126576845524886 and player.UserId==7467238848 then
 local folder=game.ServerStorage.BodyPrototype_20261114
 local prototype=require(folder.BodyPrototype)
 prototype.Apply(character,folder:GetAttribute("DefaultRatio"))
 prototype.Clothes(character,folder.Clothing["3670737444"],folder.Clothing["398633812"])
end
 ]=]..needle
local a,b=string.find(before,needle,1,true);assert(a and not string.find(before,needle,b+1,true),"Expected one readiness gate")
local after=before:sub(1,a-1)..insertion..before:sub(b+1)
local backup=Instance.new("Folder");backup.Name="__BodyPrototypeRuntimePatch"
local ref=Instance.new("ObjectValue");ref.Name="Target";ref.Value=target;ref.Parent=backup
local old=Instance.new("StringValue");old.Name="Before";old.Value=before;old.Parent=backup
local new=Instance.new("StringValue");new.Name="After";new.Value=after;new.Parent=backup
backup.Parent=game.ServerStorage
target.Source=after
return {hooked=target:GetFullName(),scope="single Studio account; before growth baseline capture"}
