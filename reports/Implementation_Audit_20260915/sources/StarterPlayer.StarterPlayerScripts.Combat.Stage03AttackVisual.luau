-- Personal encounter presentation: driven only by server CombatState events.
local M={}
local rig,track,destroyConnection
local generation=0
local lastId=0
local function stop()
 generation+=1
 if track then track:Stop(0.04)end
end
function M.Stop()stop()end
function M.Reset()
 stop()
 lastId=0
 if destroyConnection then destroyConnection:Disconnect();destroyConnection=nil end
 if track then track:Destroy();track=nil end
 rig=nil
end
function M.Prepare()
 local enemies=workspace:FindFirstChild("Enemies")
 local enemy=enemies and enemies:FindFirstChild("Stage03_Enemy")
 local current=enemy and enemy:FindFirstChild("TungTungSahurRig")
 if current==rig and track then return track end
 M.Reset()
 if not current then return end
 local humanoid=current:FindFirstChildOfClass("Humanoid")
 local animator=humanoid and humanoid:FindFirstChildOfClass("Animator")
 local animation=current:FindFirstChild("Stage03Attack")
 if not animator or not animation then return end
 local ok,result=pcall(function()return animator:LoadAnimation(animation)end)
 if not ok then warn("Stage03 attack animation could not load: "..tostring(result));return end
 rig=current
 track=result
 track.Priority=Enum.AnimationPriority.Action
 track.Looped=false
 destroyConnection=rig.Destroying:Connect(M.Reset)
 return track
end
function M.Play(d)
 -- Wall attacks do not carry the server's boss Attack counter.
 if d.Stage~=3 or typeof(d.Attack)~="number" or typeof(d.Id)~="number"then return end
 local active=M.Prepare()
 if not active or d.Id<=lastId then return end
 lastId=d.Id
 stop()
 local version=generation
 local animation=rig.Stage03Attack
 local speed=animation:GetAttribute("PlaybackSpeed")
 local delay=math.max(0,d.HitDelay-animation:GetAttribute("SwingTime")/speed)
 task.delay(delay,function()
  if generation~=version or track~=active or not rig or not rig.Parent then return end
  active:Play(0.03,1,speed)
  active.TimePosition=0
 end)
end
return M

