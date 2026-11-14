# Isolated native cases

Evidence and exact executed case bodies: [evidence.json](../../reports/PetStage2Camera_20261114/evidence.json).
Results include setup failures; use the final successful cases and report matrix, not a count of every attempt as passing.

Run only in duplicate PlaceId 126576845524886 with the existing FirstBattleTutorial/InstallIsolation.luau installed, replacing its __FirstBattle names with __PetCamera. Never enable production DataStore/payment calls. Cases were invoked from a real Script or LocalScript through a temporary BindableFunction, because plugin execute_luau require has a different module cache. The harness and all replacements were removed after Play.

Server case preamble:
```luau
assert(game.PlaceId==126576845524886 and game.ReplicatedStorage:FindFirstChild("__PetCameraMemory"))
local RS=game.ReplicatedStorage;local S=game.ServerScriptService.Services
local D=require(S.PlayerDataService);local E=require(game.ServerScriptService.World.EnemyManager)
local M=require(RS.__PetCameraMemory);local T=require(RS.Modules.EggPetTutorialState)
local p=assert(game.Players:GetPlayers()[1]);local H=game:GetService("HttpService")
local function state() local s=D.Get(p);return {Loaded=s.Loaded,Saving=s.Saving,Pending=s.PendingItemMutation~=nil,Tutorial=s.Data.EggPetTutorial,Win=s.Data.Win,World=p:GetAttribute("CurrentWorld"),Stage=p:GetAttribute("CurrentStage"),Attr=p:GetAttribute("EggTutorialStage2Defeated"),Health=p.Character and p.Character.Humanoid.Health}end

local function saved()return M.DataStoreService:GetDataStore(require(game.ServerScriptService.Config.DataStoreConfig).GetName("PlayerData_v1")):GetAsync("Player_"..p.UserId)end
local function pet(action,a,b,id)local pets,_,g=D.GetPetState(p);return require(S.EggServer).request(p,action,id or H:GenerateGUID(false),pets.Revision,a,b,g)end
local function nearEgg() local part=require(RS.Modules.Egg).part("Basic");p.Character.HumanoidRootPart.Anchored=false;p.Character:PivotTo(part.CFrame+Vector3.new(0,3,5)) end
```

Client case preamble:
```luau
local p=game.Players.LocalPlayer;local cam=workspace.CurrentCamera
local mod=require(game.StarterPlayer.PlayerModule.CameraModule)
local c=mod.activeCameraController
local function snap()local yaw,pitch,roll=cam.CFrame:ToOrientation();return {Distance=c:GetCameraToSubjectDistance(),ActualDistance=(cam.CFrame.Position-cam.Focus.Position).Magnitude,Rotation={yaw,pitch,roll},Focus=tostring(cam.Focus.Position),Type=cam.CameraType.Name,Subject=cam.CameraSubject and cam.CameraSubject:GetFullName(),Min=p.CameraMinZoomDistance,Max=p.CameraMaxZoomDistance,Offset=tostring(p.Character.Humanoid.CameraOffset),Scale=p:GetAttribute("MuscleHeightScale"),Stage2=p:GetAttribute("EggTutorialStage2Defeated"),Guide=p:GetAttribute("EggTutorialGuideState")}end
```

Each body executes in a fresh ModuleScript returning a function, required by the corresponding native Script/LocalScript. This is a sequenced diagnostic record, not a standalone unattended suite: skip failed preparation attempts as explained by the report, and prepare the stated world, character, inventory and prior guide conditions. Reset calls affect only the memory-isolated profile. Do not run this against production storage.
