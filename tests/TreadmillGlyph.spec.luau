return function(s)
 local function load(source)
  local f=assert(loadstring(source));setfenv(f,setmetatable({script={Parent={World2GameplayConfig={}}},require=function()return {Treadmills={}}end},{__index=getfenv()}))
  return f()
 end
 local before,after=load(s.BeforeTreadmill),load(s.Treadmill)
 local n=0;local function eq(a,b) n+=1;assert(a==b,tostring(a).." ~= "..tostring(b))end
 local function same(a,b)
  if type(a)=="function" then return end
  if type(a)=="table"then for k,v in a do same(v,b[k])end;for k in b do assert(a[k]~=nil)end
  else eq(a,b)end
 end
 same(before,after) -- All tiers, amounts, access, style and guide values unchanged.
 local broken=before.GetGainDisplayText("Iron01","en-us")
 eq(utf8.codepoint(broken),0xFFFD);eq(string.byte(broken,4),126)
 local rows={}
 for model,kind in after.Assignments do
  local gain=after.GetGainDisplayText(model,"en-us")
  local amount=after.Types[kind].Multiplier
  eq(gain,utf8.char(0xD7)..tostring(amount).." Strength")
  eq(string.byte(gain,1),195);eq(string.byte(gain,2),151)
  eq(after.GetGainDisplayText(model,"ja-jp"),gain)
  eq(after.GetDisplayText(model):find(utf8.char(0xD7),1,true)~=nil,true)
  eq(gain:find(utf8.char(0xFFFD),1,true),nil)
  table.insert(rows,{Model=model,Text=gain,UTF8Prefix={195,151}})
 end
 return {Assertions=n,BeforePrefix="U+FFFD + ~",AfterPrefix="U+00D7 (C3 97)",Rows=rows,NonTextConfigUnchanged=true,LivePublishedPlaceVerified=false}
end
