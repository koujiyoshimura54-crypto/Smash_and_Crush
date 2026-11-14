"""Check the actual progression/shape configuration without Roblox or persistence."""
from pathlib import Path
import subprocess
import tempfile
import os
import shutil

root = Path(__file__).resolve().parents[1]
source = (root / 'src/ServerScriptService/Config/MuscleScaleConfig.luau').read_text(encoding='utf8')
script = '''local mt={}
Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end}
mt.__mul=function(v,n)return Vector3.new(v.X*n,v.Y*n,v.Z*n)end
Vector3.one=Vector3.new(1,1,1);Vector3.zero=Vector3.new(0,0,0)
local Config=(function()
''' + source + '''
end)()
local thresholds={2,4,8,16,32,50,70,90,115,140}
local heights={1.20,1.38,1.54,1.68,1.80,1.88,1.93,1.97,1.99,2.00}
local arms={1.40,1.75,2.05,2.30,2.50,2.60,2.68,2.74,2.78,2.80}
local function near(a,b)assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..tostring(b))end
assert(Config.MAX_STAGE==10)
assert(Config.GetMuscleStage(0)==0)
for stage,threshold in thresholds do
 assert(Config.LEVEL_THRESHOLDS[stage]==threshold)
 assert(stage==1 or Config.LEVEL_THRESHOLDS[stage]>Config.LEVEL_THRESHOLDS[stage-1])
 assert(Config.GetMuscleStage(threshold-1)==stage-1)
 assert(Config.GetMuscleStage(threshold)==stage)
 assert(Config.GetMuscleStage(threshold+1)==stage)
 near(Config.GetHeightScale(stage),heights[stage])
 local arm=Config.GetPartScale('LeftUpperArm',stage)
 near(arm.X,arms[stage]);near(arm.Y,heights[stage]);near(arm.Z,arms[stage])
 local factor=(arms[stage]-1)/.15
 for part,key in Config.PART_SCALE_KEYS do
  local growth=Config.MUSCLE1_GROWTH[key]
  local scale=Config.GetPartScale(part,stage)
  near(scale.X,1+growth.X*factor);near(scale.Y,heights[stage]);near(scale.Z,1+growth.Z*factor)
 end
end
assert(Config.GetMuscleStage(141)==10)
assert(Config.GetMuscleStage(1e15)==10)
for _,part in {'Head','LeftHand','RightHand','LeftFoot','RightFoot','HumanoidRootPart'} do
 local v=Config.GetPartScale(part,10);near(v.X,1);near(v.Y,1);near(v.Z,1)
end
for part in Config.PART_SCALE_KEYS do
 local v=Config.GetPartScale(part,0);near(v.X,1);near(v.Y,1);near(v.Z,1)
end
print('PASS: all10 thresholds below/at/above, cap, heights/arms, original part ratios and excluded parts')
'''
size_source = (root / 'src/ReplicatedStorage/Config/SizeChangeConfig.luau').read_text(encoding='utf8')
script += '\nlocal Size=(function()\n' + size_source + '\nend)()\n' + '''
assert(Size.MaxTier==10 and Size.RequiredRebirth==5 and Size.WinPrice==500)
assert(Size.NormalizeSavedTier(nil)==0)
for old=0,13 do
 local new=Size.NormalizeSavedTier(old)
 assert(new==math.min(old,10))
 assert(Size.NormalizeSavedTier(new)==new)
end
for _,bad in {-1,14,1.5,'10',math.huge,0/0} do assert(Size.NormalizeSavedTier(bad)==nil) end
print('PASS: saved-tier migration, idempotence, invalid saved data and unchanged price/unlock')
'''
with tempfile.TemporaryDirectory(prefix='mtf-growth-') as temp:
    test = Path(temp) / 'check.luau'
    test.write_text(script, encoding='utf8')
    executable = os.environ.get('LUAU_BIN') or shutil.which('luau') or str(Path.home() / 'stage_skip_work/luau/luau.exe')
    subprocess.run([executable, str(test)], check=True)
