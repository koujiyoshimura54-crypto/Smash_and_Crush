 -- Extension to the established isolated TrainingManager/AutoTap/GamePass fixture.
 -- Uses real current service Sources and memory Strength/Level updates; occupancy is still mocked.
 debugConfig.GamePassEffectsEnabled=true;setEventTime(200)
 ownership[p.UserId][1977128286]=false;pass.RefreshShopPass(p,"VIP")
 controls.Dumbbell=0;controls.Aura=0;controls.Protein=0;controls.Belt=0;controls.TrainingPotion=0
 controls.StrengthPotion=1;controls.Pet=1;p:SetAttribute("RebirthCount",0)
 local boostRows={}
 for world=1,2 do
  ownership[p.UserId][tc.GetPremiumTreadmillPassId(world)]=true;pass.RefreshPremiumTreadmill(p,world)
  p:SetAttribute("CurrentWorld",world)
  for _,owns in {false,true} do
   ownership[p.UserId][passId]=owns;pass.RefreshStrengthPass(p)
   sessions[p].Data.StrengthBoost={ExpiresAt=math.floor(now)+300,Receipts={}}
   for _,premiumKind in {false,true} do
    local m=machines[(world-1)*2+(premiumKind and 2 or 1)]
    occupied[p]=m;check(training.StartTraining(p,m),"boost valid treadmill")
    local config=tc.GetForModel(m)
    local expected=config.Multiplier+1+(owns and 1 or 0)
    local gained=tick(p);near(gained,expected,"real training loop + memory gain")
    local before=sessions[p].Data.Strength
    check(not auto.HandleTap(p),"tap blocked during treadmill")
    check(not auto.TryAutomatic(p),"auto blocked during treadmill")
    near(sessions[p].Data.Strength,before,"no duplicate source")
    table.insert(boostRows,{World=world,Premium=premiumKind,Pass=owns,Base=config.Multiplier,Gain=gained})
    training.StopTraining(p)
   end
   occupied[p]=nil
   for _,manual in {false,true} do
    advance(2);local before=sessions[p].Data.Strength
    check(manual and auto.HandleTap(p) or auto.TryAutomatic(p),"normal routed training")
    near(sessions[p].Data.Strength-before,2+(owns and 1 or 0),"manual / AutoTap walking boost")
   end
  end
 end
 -- Existing equipment and source additions stay in their original order.
 p:SetAttribute("CurrentWorld",1);occupied[p]=premium;controls.Belt=2;controls.TrainingPotion=1
 controls.Dumbbell=10;controls.Aura=3;controls.Protein=2;controls.StrengthPotion=1.5;controls.Pet=1.25
 ownership[p.UserId][1977128286]=true;pass.RefreshShopPass(p,"VIP");p:SetAttribute("RebirthCount",2)
 check(training.StartTraining(p,premium),"combined boosts")
 near(tick(p),16*2*(7+2+1+1+1)*1.5*1.1*1.25,"equipment/pass/temporary +1 composition")
 sessions[p].Data.StrengthBoost.ExpiresAt=math.floor(now)
 near(tick(p),16*2*(7+2+1+1)*1.5*1.1*1.25,"expiry checked inside next training calculation")
 training.StopTraining(p);occupied[p]=nil
 local before=sessions[p].Data.Strength;strength.AddRewardStrength(p,42)
 near(sessions[p].Data.Strength-before,42,"direct reward not boosted")
 results.BoostGains=boostRows
