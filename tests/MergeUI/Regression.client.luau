-- Native Play integration checks. Component methods exercise the same callbacks as UI controls;
-- these assertions alone do not establish physical pointer/touch or screenshot fidelity.
local p=game.Players.LocalPlayer
local RS=game.ReplicatedStorage
local Http=game:GetService('HttpService')
local control=RS:WaitForChild('__MergeY01Control')
while not control:InvokeServer('Ready') do task.wait(.1) end
local bridge=p.PlayerScripts:WaitForChild('__MergeY01Client')
local report={Checks={},Snapshots={},PhysicalInput=false,VisualComparison=false}
local function call(op,arg)return bridge:Invoke(op,arg)end
local function check(name,condition,detail)
 assert(condition,name..': '..tostring(detail));table.insert(report.Checks,{Name=name,Passed=true,Detail=detail})
end
local function find(state,key)for _,row in state.Rows do if row.Key==key then return row end end end
local function count(t)local n=0;for _ in pairs(t)do n+=1 end;return n end
local function clean(state)state.ItemState=nil;state.PetState=nil;return state end
local function untilState(predicate)
 for _=1,80 do local s=call('Refresh');if predicate(s)then return s end;task.wait(.1)end
 error('State confirmation timeout')
end
local function sameRect(a,b)for i=1,4 do if math.abs(a[i]-b[i])>.05 then return false end end;return true end
local function run()
 local s=call('Show');local baseline=s
 check('Locked UI',#s.Rows==15 and not s.ItemState.World2Unlocked)
 check('Locked server',control:InvokeServer('RejectLocked').Code=='WorldNotReached')
 check('Saved arrival respects Studio reset',not control:InvokeServer('SavedArrivalReset').EffectiveArrival)
 local rejected=call('RejectPets');check('Server rejects forged/protected/equipped Pet IDs',count(rejected)==4,rejected)
 control:InvokeServer('Gate','ToWorld2');call('Travel','ToWorld2')
 for _=1,50 do if p:GetAttribute('CurrentWorld')==2 then break end;task.wait(.1)end
 check('Actual first arrival',p:GetAttribute('CurrentWorld')==2 and control:InvokeServer('State').EffectiveArrival)
 task.wait(1.1);control:InvokeServer('Gate','ReturnWorld1');call('Travel','ReturnWorld1')
 for _=1,50 do if p:GetAttribute('CurrentWorld')==1 then break end;task.wait(.1)end
 check('World1 return retains arrival',p:GetAttribute('CurrentWorld')==1 and control:InvokeServer('State').EffectiveArrival)
 control:InvokeServer('MergeArea');task.wait(.3);s=call('Show')
 check('All ranks visible after return',#s.Rows==30 and s.ItemState.World2Unlocked)
 for i,row in s.Rows do check('Rank/order '..i,row.Rank==math.ceil(i/3) and row.Key:find(({'GLOVE','PROTEIN','TRAININGBELT'})[(i-1)%3+1],1,true)~=nil)end
 local materialList=p.PlayerGui.MergeShopGui.MergeShopPanel.Body.Materials
 call('Scroll',s.Rows[10].Bounds[2]-s.Rows[1].Bounds[2]);report.Snapshots.ItemBoundary=clean(call('State'))
 call('Scroll',100000);s=call('State');local last=s.Rows[30].Bounds
 check('Scroll reaches rank 10',s.Rows[30].Rank==10 and last[2]>=materialList.AbsolutePosition.Y and last[2]+last[4]<=materialList.AbsolutePosition.Y+materialList.AbsoluteSize.Y+.1)
 call('Clear');call('Add','GLOVE_COMMON_FIRE');call('Add','GLOVE_COMMON_FIRE');s=call('Remove','GLOVE_COMMON_FIRE')
 check('Item remove one, owned unchanged',s.Selected=='Selected: 1' and find(s,'GLOVE_COMMON_FIRE').Owned==8)
 s=call('Clear');check('Item Clear',s.Selected=='Selected: 0' and #s.Inputs==0)
 s=call('Drag','GLOVE_COMMON_FIRE');check('Drag handler adds one',s.Selected=='Selected: 1');call('Clear')
 for _=1,3 do s=call('Add','W2_GLOVE_RARE_FIRE')end
 check('Rank 9 candidate in World1',s.Enabled and #s.Candidates==1 and s.Candidates[1].ItemId=='W2_GLOVE_EPIC_FIRE' and s.Candidates[1].Percent==100)
 call('Submit');s=untilState(function(x)return x.ItemState.LastResult and x.ItemState.LastResult.Success end)
 check('Rank 9 real grant and consumption',s.ItemState.OwnedItems.W2_GLOVE_RARE_FIRE==5 and s.ItemState.OwnedItems.W2_GLOVE_EPIC_FIRE==9 and s.Selected=='Selected: 0')
 local root=p.PlayerGui.MergeShopGui.MergeShopPanel
 check('Completed rank presentation',root.Body.Result.ResultItems.Candidate_1.Card.RarityStars.RankNumber.Text=='9')
 for _,name in {'Pet','Ore','Item','Pet'} do
  s=call('Tab',name)
  for _,tab in {'Item','Pet','Ore'} do check('Stable '..name..'/'..tab,s.Tabs[tab].Visible and sameRect(s.Tabs[tab].Bounds,baseline.Tabs[tab].Bounds))end
  check('Stable footer '..name,sameRect(s.Footer.Merge,baseline.Footer.Merge) and sameRect(s.Footer.Clear,baseline.Footer.Clear))
 end
 call('Refresh');s=call('State');check('Pet group uses owned copies',find(s,'Dog').Owned==5)
 for _=1,4 do s=call('Add','Dog')end
 check('Pet capacity excludes protected/equipped',s.Selected=='Selected: 3' and s.Total=='Total: 30 pt' and find(s,'Dog').Owned==5)
 s=call('Remove','Dog');check('Pet remove one',s.Selected=='Selected: 2' and s.Total=='Total: 20 pt')
 call('Clear');s=call('State');check('Pet Clear',s.Selected=='Selected: 0')
 call('Add','Cow');s=call('Add','Cow');report.Snapshots.PetGrouped=clean(s);call('Clear')
 call('Add','Dog');s=call('Add','Dog');local before=count(s.PetState.Owned);call('Submit')
 s=untilState(function(x)return x.PetState.Revision>0 end);local pets=s.PetState
 check('Pet Egg roll/open/grant',pets.LastMergeEgg~=nil and #pets.LastResults==1 and pets.Owned[pets.LastResults[1].id]==pets.LastResults[1].pet and count(pets.Owned)==before-1,pets.LastMergeEgg)
 check('Exact Pet consumption',not pets.Owned['dog-eligible-1'] and not pets.Owned['dog-eligible-2'])
 check('Protected/equipped/performance retained',pets.Owned['dog-protected']=='Dog' and pets.Owned['dog-equipped']=='Dog' and pets.Owned['performance-variant']=='W2 Dog' and pets.Protected['dog-protected'])
 check('Pet refreshed after merge',s.Selected=='Selected: 0' and #s.Inputs==0)
 call('Tab','Ore');task.wait(.3)
 for _=1,3 do call('Add','ORE_015')end;for _=1,3 do s=call('Add','ORE_016')end
 check('Ore cap, points, inputs',s.Selected=='Selected: 5/5' and s.Total=='Total: 560 pt' and #s.Inputs==5)
 check('Ore calculated candidates',s.Candidates[1].Id=='NORMAL_11' and s.Candidates[1].Percent==75 and s.Candidates[2].Id=='NORMAL_12' and s.Candidates[2].Percent==25)
 s=call('Remove','ORE_016:2');check('Ore remove one and recalculate',s.Selected=='Selected: 4/5' and s.Total=='Total: 430 pt');call('Add','ORE_016')
 call('Scroll',440);report.Snapshots.OreSelected=clean(call('State'));call('Submit');task.wait(.5)
 local forge=control:InvokeServer('State').Forge
 check('Ore consumes/grants one',forge.Ores.ORE_015==9 and forge.Ores.ORE_016==10 and forge.DumbbellCounts[forge.Journal.ResultId]==1,forge.Journal.ResultId)
 check('Ore clears after confirmation',call('State').Selected=='Selected: 0/5')
 call('Sell',true);call('Add','ORE_015');s=call('Add','ORE_015')
 check('Sale quantity and Win preview',s.Selected=='Selected: 2' and s.Total=='Total: 110 Win' and find(s,'ORE_015').Owned==9)
 call('Submit');task.wait(.5);forge=control:InvokeServer('State').Forge
 check('Sale exact count/Win',forge.Ores.ORE_015==7 and forge.Win==100110,forge.Win)
 check('Sale resets selection',call('State').Selected=='Selected: 0')
 call('Sell',false)
 -- One Gray Crystal deterministically produces NORMAL_03 using the unchanged point formula.
 for pass=1,2 do
  call('Add','ORE_010');call('Submit');task.wait(.5)
 end
 forge=control:InvokeServer('State').Forge
 check('Dumbbell duplicate ownership',forge.DumbbellCounts.NORMAL_03==2,forge.DumbbellCounts.NORMAL_03)
 for _=1,3 do s=call('Show');task.wait(.6);s=call('Add','GLOVE_COMMON_FIRE');check('Reopen adds exactly once',s.Selected=='Selected: 1')end
 call('Narrow',{X=360,Y=640})
 for _,name in {'Item','Pet','Ore'} do
  s=call('Tab',name);check('Narrow tabs '..name,s.Tabs.Item.Visible and s.Tabs.Pet.Visible and s.Tabs.Ore.Visible)
  local key=name=='Item' and 'GLOVE_COMMON_FIRE' or name=='Pet' and 'Dog' or 'ORE_015'
  s=call('Add',key);check('Narrow selection callback '..name,s.Selected==(name=='Ore' and 'Selected: 1/5' or 'Selected: 1'))
  local panel=p.PlayerGui.StrengthGui.__MergeNarrow.MergeShopPanel
  local card=panel.Body.Materials:FindFirstChild(key);local icon=card.Main.Icon
  if name~='Item' then
   local points=card.Points;local owned=card.OwnedCount;local badge=card.SelectedCount
   check('Narrow point/owned separation '..name,points.AbsolutePosition.Y+points.AbsoluteSize.Y<owned.AbsolutePosition.Y)
   check('Narrow point/selection separation '..name,points.AbsolutePosition.X+points.AbsoluteSize.X<=badge.AbsolutePosition.X+.1)
  end
  check('Narrow button separation '..name,s.Footer.Clear[1]+s.Footer.Clear[3]<s.Footer.Merge[1])
  s=call('Clear');check('Narrow Clear callback '..name,s.Selected==(name=='Ore' and 'Selected: 0/5' or 'Selected: 0'))
 end
 call('EndNarrow')
 report.ArrivalReset=control:InvokeServer('State').ArrivalReset
 report.RNG='Unmodified production Random.new sampling; guaranteed candidates follow unchanged Config.'
 local n=0;local c=game:GetService('RunService').RenderStepped:Connect(function()n+=1 end);task.wait(.5);c:Disconnect()
 report.RenderSteps=n;report.Viewport=tostring(workspace.CurrentCamera.ViewportSize)
end
local ok,err=xpcall(run,debug.traceback);report.Success=ok;report.Error=not ok and tostring(err) or nil
local result=Instance.new('StringValue');result.Name='__MergeY01Regression';result.Value=Http:JSONEncode(report);result.Parent=p.PlayerScripts
