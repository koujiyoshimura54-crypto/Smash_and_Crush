"""Check the actual progression/shape configuration without Roblox or persistence."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'src/ServerScriptService/Config/MuscleScaleConfig.luau').read_text(encoding='utf8')
script = '''local mt={}
Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end}
mt.__mul=function(v,n)return Vector3.new(v.X*n,v.Y*n,v.Z*n)end
Vector3.one=Vector3.new(1,1,1);Vector3.zero=Vector3.new(0,0,0)
local Config=(function()
''' + source + '''
end)()
local thresholds={40,250,955,2840,7215,37315,196915,462965,30000000,150000000,700000000,2000000000,6000000000}
local heights={1.10,1.175,1.25,1.35,1.45,1.70,2,2.15,2.40,2.65,2.95,3.25,3.55}
local arms={1.30,1.45,1.525,1.60,1.675,1.825,1.975,2.05,2.20,2.35,2.50,2.65,2.80}
local function near(a,b)assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..tostring(b))end
assert(Config.MAX_STAGE==13)
assert(Config.GetMuscleStage(0)==0)
for stage,threshold in thresholds do
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
assert(Config.GetMuscleStage(6000000001)==13)
assert(Config.GetMuscleStage(1e15)==13)
for _,part in {'Head','LeftHand','RightHand','LeftFoot','RightFoot','HumanoidRootPart'} do
 local v=Config.GetPartScale(part,13);near(v.X,1);near(v.Y,1);near(v.Z,1)
end
for part in Config.PART_SCALE_KEYS do
 local v=Config.GetPartScale(part,0);near(v.X,1);near(v.Y,1);near(v.Z,1)
end
print('PASS: all13 thresholds below/at/above, cap, heights/arms, original part ratios and excluded parts')
'''
with tempfile.TemporaryDirectory(prefix='mtf-growth-') as temp:
    test = Path(temp) / 'check.luau'
    test.write_text(script, encoding='utf8')
    subprocess.run([str(Path.home() / 'AppData/Local/Temp/luau.exe'), str(test)], check=True)
