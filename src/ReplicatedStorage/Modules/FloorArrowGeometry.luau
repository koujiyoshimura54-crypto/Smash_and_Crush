-- Pure shared geometry: total chevron width includes the two .34-stud strokes.
local M={Stroke=.34}
function M.Dimensions(multiplier)
 local halfWidth,halfDepth=1.05,.65
 if multiplier and multiplier~=1 then
  local length=math.sqrt(halfWidth^2+(2*halfDepth)^2)
  local width=(2*halfWidth+M.Stroke*2*halfDepth/length)*multiplier
  local depth=2*halfDepth+M.Stroke*halfWidth/length
  for _=1,12 do
   length=math.sqrt(halfWidth^2+(2*halfDepth)^2)
   halfWidth=(width-M.Stroke*2*halfDepth/length)/2
   halfDepth=(depth-M.Stroke*halfWidth/math.sqrt(halfWidth^2+(2*halfDepth)^2))/2
  end
 end
 local length=math.sqrt(halfWidth^2+(2*halfDepth)^2)
 return {HalfWidth=halfWidth,HalfDepth=halfDepth,
  Width=2*halfWidth+M.Stroke*2*halfDepth/length,
  Depth=2*halfDepth+M.Stroke*halfWidth/length}
end
return table.freeze(M)
