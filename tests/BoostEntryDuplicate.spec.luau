-- Runs with the same native GUI fixture and actual controller as the availability suite.
return function(s,fixture,eq,settle)
 local function count(root)
  local n=0;for _,g in root:GetChildren()do if g.Name=="RewardedStrengthBoostGui"and g:IsA("ScreenGui")then n+=1 end end
  return n
 end
 local before=fixture(s.BeforeDuplicateClient,false,true)
 local late=before.Gui:Clone();late.Parent=before.Root;settle()
 eq(count(before.Root),2,"before: late StarterGui copy creates duplicate")
 before.Cleanup()

 local f=fixture(s.Client,false,true)
 local unrelated=Instance.new("ScreenGui");unrelated.Name="OtherNotification";unrelated.Parent=f.Root
 local connected=f.Gui
 for _=1,3 do
  late=connected:Clone();late.Parent=f.Root;settle()
  eq(count(f.Root),1,"late copies removed")
  eq(connected.Parent,f.Root,"keep the connected GUI")
  eq(late.Parent,nil,"discard only the extra copy")
 end
 eq(unrelated.Parent,f.Root,"other HUD preserved")
 eq(f.Client.Mount(f.Main,f.Dependencies),f.Api,"mount is idempotent")
 eq(#f.Queries,0);eq(#f.Sent,0)
 eq(f.Api.Open(),true);eq(connected.Overlay.Visible,true)
 eq(connected.Overlay.Panel.Watch.Title.Text,"Unavailable")
 f.Api.Close();eq(connected.Overlay.Visible,false)
 f.Api.Destroy();settle()
 local a=connected -- destroyed; use the production presentation via a fresh mount as a template
 f.Api=f.Client.Mount(f.Main,f.Dependencies);settle();f.Gui=f.Api.Gui
 a=f.Gui:Clone();local b=f.Gui:Clone()
 f.Api.Destroy();settle();a.Parent=f.Root;b.Parent=f.Root;settle()
 eq(count(f.Root),2,"destroy disconnects the duplicate guard")
 f.Api=f.Client.Mount(f.Main,f.Dependencies);settle();f.Gui=f.Api.Gui
 eq(count(f.Root),1,"mount clears all old copies")
 eq(a.Parent,nil);eq(b.Parent,nil);eq(unrelated.Parent,f.Root)
 f.Cleanup()
 return {BeforeLateCopyCount=2,AfterLateCopyCount=1,RepeatedLateCopies=3,Remount=true,OtherHUDPreserved=true}
end
