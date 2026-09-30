-- Run with production PlayerDataService copies redirected to the Phase5F memory
-- store. No real user profiles are touched by fault/concurrency injection.
return function(A,B,Store)
	local results = {}
	local function fixture(win, capacity)
		Store.Reset(); Store.Data.Win = win; Store.Data.InventoryCapacity = capacity
		local attrs = {}
		local p = {Name="CapacityFixture", UserId=1,
			SetAttribute=function(_, k, v) attrs[k]=v end,
			GetAttribute=function(_, k) return attrs[k] end}
		assert(A.Load(p)); return p
	end
	local function check(name, fn)
		local ok, err = pcall(fn)
		table.insert(results, {name=name, passed=ok, error=not ok and tostring(err) or nil})
	end
	check("legacy missing Capacity defaults to 5; atomic 150 -> 50 / 6; rejoin", function()
		local p=fixture(150)
		assert(A.GetInventoryCapacity(p)==5)
		assert(A.PurchaseInventoryCapacity(p,5))
		assert(Store.Data.InventoryCapacity==6 and Store.Data.Win==50)
		assert(p:GetAttribute("InventoryCapacity")==6 and p:GetAttribute("Win")==50)
		assert(B.Load(p)); assert(B.GetInventoryCapacity(p)==6 and B.Get(p).Data.Win==50)
	end)
	check("insufficient Win: no DataStore request or field changes", function()
		local p=fixture(99); local requests=Store.Requests
		local ok,code=A.PurchaseInventoryCapacity(p,5)
		assert(not ok and code=="NotEnoughWin")
		assert(Store.Requests==requests and A.GetInventoryCapacity(p)==5 and A.Get(p).Data.Win==99)
	end)
	check("100 repeated requests / UpdateAsync callback replay charge only once", function()
		local p=fixture(200); Store.Repeat=true
		assert(A.PurchaseInventoryCapacity(p,5))
		for _=1,100 do assert(not A.PurchaseInventoryCapacity(p,5)) end
		assert(not A.PurchaseInventoryCapacity(p,6))
		assert(Store.Data.Win==100 and Store.Data.InventoryCapacity==6)
	end)
	check("save fails before write: live and durable fields unchanged; retry succeeds", function()
		local p=fixture(150,5); Store.FailBefore=Store.Requests+1
		assert(not A.PurchaseInventoryCapacity(p,5))
		assert(Store.Data.Win==150 and Store.Data.InventoryCapacity==5)
		assert(A.Get(p).Data.Win==150 and A.GetInventoryCapacity(p)==5)
		assert(A.PurchaseInventoryCapacity(p,5))
		assert(Store.Data.Win==50 and A.GetInventoryCapacity(p)==6)
	end)
	check("lost save response: AutoSave resolves same receipt, no refund or duplicate debit", function()
		local p=fixture(150,5); Store.FailAfter=Store.Requests+1
		assert(not A.PurchaseInventoryCapacity(p,5))
		assert(Store.Data.Win==50 and Store.Data.InventoryCapacity==6)
		assert(A.Get(p).Data.Win==150 and A.GetInventoryCapacity(p)==5)
		assert(A.Save(p)); assert(Store.Data.Win==50 and A.GetInventoryCapacity(p)==6)
		assert(Store.Data.OwnedItems.PROTEIN_COMMON_FIRE==10 and Store.Meta.Keep=="unchanged")
	end)
	check("crash after committed save: next owner loads both fields; old retry is fenced", function()
		local p=fixture(150,5); Store.FailAfter=Store.Requests+1
		assert(not A.PurchaseInventoryCapacity(p,5))
		assert(B.Load(p)); assert(B.GetInventoryCapacity(p)==6 and B.Get(p).Data.Win==50)
		assert(not A.ResolveItemMutation(p)); assert(not A.Save(p))
		assert(Store.Data.Win==50 and Store.Data.InventoryCapacity==6)
	end)
	check("new ownership acquired before purchase rejects old writer", function()
		local p=fixture(150,5); assert(B.Load(p))
		assert(not A.PurchaseInventoryCapacity(p,5))
		assert(Store.Data.Win==150 and Store.Data.InventoryCapacity==5)
	end)
	check("other spending is blocked pending confirmation; concurrent earned Win retained", function()
		local p=fixture(150,5)
		local target=Store.Requests+1
		Store.After=function(_,request)
			if request==target then
				assert(not A.SetWin(p,100))
				assert(A.SetWin(p,175))
				assert(not A.Save(p))
				assert(not A.PurchaseInventoryCapacity(p,5))
			end
		end
		assert(A.PurchaseInventoryCapacity(p,5)); assert(A.Get(p).Data.Win==75)
		assert(A.Save(p)); assert(Store.Data.Win==75 and Store.Data.InventoryCapacity==6)
	end)
	check("exit save resolves response loss; rejoin retains capacity and equipment", function()
		local p=fixture(150,5); Store.FailAfter=Store.Requests+1
		assert(not A.PurchaseInventoryCapacity(p,5))
		assert(A.Save(p)); A.Release(p); assert(B.Load(p))
		assert(B.Get(p).Data.Win==50 and B.GetInventoryCapacity(p)==6)
		assert(Store.Data.OwnedItems.PROTEIN_COMMON_FIRE==10 and Store.Data.EquippedItems.Protein=="")
	end)
	check("missing profile initializes Capacity 5", function()
		local p=fixture(0); A.Release(p); Store.Data=nil
		assert(A.Load(p)); assert(A.GetInventoryCapacity(p)==5)
	end)
	return results
end
