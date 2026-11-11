-- Pure rules; LevelRequirements owns the current per-level costs.
local Requirements=require(game.ReplicatedStorage.Config.LevelRequirements)
local M={Version=1}
local function finite(v) return typeof(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
local function validLevel(v) return finite(v) and v%1==0 and v>=1 and v<=Requirements.MaxLevel end
function M.Normalize(raw)
 raw=typeof(raw)=="table" and raw or {}
 local version=raw.LevelProgressVersion
 if version~=nil and version~=M.Version then return nil,"Unsupported LevelProgressVersion" end
 local level=raw.Level
 if level~=nil and not validLevel(level) then return nil,"Invalid saved Level" end
 if version~=nil and (level==nil or raw.LevelProgress==nil) then return nil,"Incomplete saved level state" end
 -- One-time legacy conversion ONLY; prefer an explicitly saved Level.
 if level==nil then level=Requirements.CalculateLevel(raw.Strength) end
 local progress=raw.LevelProgress
 if progress==nil then progress=0 end
 if not finite(progress) or progress<0 then return nil,"Invalid saved LevelProgress" end
 -- Carry existing excess before publishing Level/Progress, without inventing Strength.
 return M.Advance(level,progress,0)
end
function M.Advance(level,progress,gain)
 if not validLevel(level) or not finite(progress) or progress<0 then return nil,"Invalid level state" end
 if not finite(gain) or gain<0 or not finite(progress+gain) then return nil,"Invalid progression gain" end
 -- Zero gain also normalizes an existing level/progress pair. Fresh 1/0 stays 1/0.
 progress+=gain
 while level<Requirements.MaxLevel do
  local required=Requirements.GetRequiredStrength(level)
  if progress<required then break end
  progress-=required
  level+=1
 end
 return level,progress -- MaxLevel retains progress but cannot level further.
end
-- Shared by live grants and durable reward snapshots. No mutation or yielding.
function M.ApplyGain(state,gain)
 if not finite(state.Strength) or not finite(gain) or gain<0 or not finite(state.Strength+gain) then return nil,"Invalid Strength gain" end
 local level,progress=M.Advance(state.Level,state.LevelProgress,gain)
 if not level then return nil,progress end
 return state.Strength+gain,level,progress
end
return table.freeze(M)
