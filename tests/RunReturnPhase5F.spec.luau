-- Runs without any real DataStore. Pass the production modules from Studio.
return function(Return, Ownership)
	local Http = game:GetService("HttpService")
	local function clone(v)
		if typeof(v) ~= "table" then return v end
		local c = {} for k, x in pairs(v) do c[k] = clone(x) end return c
	end
	local function equal(a, b)
		if typeof(a) ~= typeof(b) then return false end
		if typeof(a) ~= "table" then return a == b end
		for k, v in pairs(a) do if not equal(v, b[k]) then return false end end
		for k in pairs(b) do if a[k] == nil then return false end end
		return true
	end
	local results = {}
	local function test(name, callback)
		local ok, err = pcall(callback)
		results[#results+1] = {name=name, passed=ok, error=not ok and tostring(err) or nil}
	end
	local function fixture()
		local store = {Data={OwnedItems={test=10}, EquippedItems={Glove="existing"}, ResetToken="reset"},
			Meta={unrelated="preserved"}, Requests=0, Writes=0}
		function store:GetAsync() return clone(self.Data) end
		function store:UpdateAsync(_, transform)
			self.Requests += 1
			local request = self.Requests
			if self.Before then self.Before(self, request) end
			if self.FailBefore == request then error("injected before write", 0) end
			local function info()
				local meta=clone(self.Meta)
				return {GetMetadata=function() return clone(meta) end, GetUserIds=function() return {} end}
			end
			if self.Conflict then transform(clone(self.Data), info()) end
			local value, _, meta = transform(clone(self.Data), info())
			if not value then return nil end
			self.Data, self.Meta = clone(value), clone(meta or {})
			self.Writes += 1
			if self.After then self.After(self, request) end
			if self.FailAfter == request then error("injected response loss", 0) end
			return clone(self.Data), info()
		end
		local function acquire(token, attempt)
			attempt = attempt or {Token=token}
			local data = Ownership.Acquire(store,"key",attempt,function() return {OwnedItems={}} end,
				function(raw) return raw or {OwnedItems={}} end,function() return true end)
			return {OwnerToken=token, Data=clone(data), Loaded=true}, attempt
		end
		local function operation(session, id, sequence, amount)
			local context = {Permit=true, Alive=true}
			context.Validate=function() return context.Alive end
			local op={Id=id,OwnerToken=session.OwnerToken,Sequence=sequence,RunId="run-"..id,
				CreatedAt=1,Deltas={test=amount},ResetToken="reset",RunReturn=context}
			session.PendingItemMutation=op
			local adapter={
				Update=function(transform) return Ownership.Update(store,"key",session,transform,function() return not session.Released end) end,
				Current=function() return not session.Released and not session.OwnershipLost end,
				Items=clone,ResetToken=function(d) return d.ResetToken end,
				Metadata=function(info) return info:GetUserIds(),info:GetMetadata() end,
			}
			return op,adapter
		end
		local function transition(session,op,action)
			return Ownership.Update(store,"key",session,function(old,info)
				local nextData,state=Return.Transition(old,op,action)
				if not nextData then return nil end
				local meta=info:GetMetadata()
				if nextData~=old then meta.RunReturnId=op.Id;meta.RunReturnState=state end
				return nextData,{},meta
			end,function() return not session.Released end)
		end
		return store,acquire,operation,transition
	end
	test("normal 1 / separate Pending and Grant",function()
		local st,acquire,op=fixture() local s=acquire("A") local o,a=op(s,"T",1,1)
		local writes=st.Writes assert(Return.Resolve(nil,s,o,a))
		assert(st.Writes-writes==2 and st.Data.OwnedItems.test==11 and o.PendingConfirmed)
		assert(st.Data.RunReturnJournal.State=="Granted" and st.Data.EquippedItems.Glove=="existing")
	end)
	test("normal 5 / response retry and callback replay",function()
		local st,acquire,op=fixture() local s=acquire("A") local o,a=op(s,"T",1,5)
		st.Conflict=true st.FailAfter=st.Requests+2
		assert(not Return.Resolve(nil,s,o,a)) assert(st.Data.OwnedItems.test==15 and s.Data.OwnedItems.test==10)
		for _=1,10 do assert(Return.Resolve(nil,s,o,a)) end
		assert(st.Data.OwnedItems.test==15)
	end)
	test("Pending write failure cannot grant",function()
		local st,acquire,op=fixture() local s=acquire("A") local o,a=op(s,"T",1,5)
		st.FailBefore=st.Requests+1 assert(not Return.Resolve(nil,s,o,a))
		assert(st.Data.OwnedItems.test==10 and not st.Data.RunReturnJournal)
		assert(not o.PendingConfirmed) assert(Return.Resolve(nil,s,o,a)) assert(st.Data.OwnedItems.test==15)
	end)
	test("Pending response loss / retry uses same journal",function()
		local st,acquire,op=fixture() local s=acquire("A") local o,a=op(s,"T",1,5)
		st.FailAfter=st.Requests+1 assert(not Return.Resolve(nil,s,o,a))
		assert(st.Data.RunReturnJournal.State=="Pending" and st.Data.OwnedItems.test==10)
		assert(not o.PendingConfirmed) assert(Return.Resolve(nil,s,o,a)) assert(st.Data.OwnedItems.test==15)
	end)
	test("Pending crash -> acquire cancels before exposing inventory",function()
		local st,acquire,op,tr=fixture() local s=acquire("A") local o=op(s,"T",1,5)
		tr(s,o,"Prepare")
		local b=acquire("B")
		assert(b.Data.RunReturnJournal.State=="Cancelled" and b.Data.OwnedItems.test==10)
		assert(not pcall(tr,s,o,"Grant"))
		assert(not pcall(tr,s,o,"Cancel"))
	end)
	test("Granted crash -> acquire preserves; Cancel never rolls back",function()
		local st,acquire,op,tr=fixture() local s=acquire("A") local o=op(s,"T",1,5)
		tr(s,o,"Prepare") tr(s,o,"Grant") tr(s,o,"Cancel")
		assert(st.Data.RunReturnJournal.State=="Granted" and st.Data.OwnedItems.test==15)
		local b=acquire("B") assert(b.Data.OwnedItems.test==15)
		assert(not pcall(tr,s,o,"Cancel")) assert(st.Data.OwnedItems.test==15)
	end)
	test("5E: T Granted -> Cancel -> U Granted -> old Cancel -> U retry = 16",function()
		local st,acquire,op,tr=fixture() local s=acquire("A") local t=op(s,"T",1,5)
		tr(s,t,"Prepare") tr(s,t,"Grant") tr(s,t,"Cancel")
		local b=acquire("B") local u=op(b,"U",1,1)
		tr(b,u,"Prepare") tr(b,u,"Grant")
		local data,meta=clone(st.Data),clone(st.Meta)
		assert(not pcall(tr,s,t,"Cancel"))
		assert(equal(data,st.Data) and equal(meta,st.Meta))
		for _=1,5 do tr(b,u,"Grant") end
		assert(st.Data.OwnedItems.test==16 and st.Data.RunReturnJournal.TransactionId=="U")
	end)
	test("5E: T Pending -> Cancel -> U Granted -> old Cancel -> U retry = 11",function()
		local st,acquire,op,tr=fixture() local s=acquire("A") local t=op(s,"T",1,5)
		tr(s,t,"Prepare") tr(s,t,"Cancel")
		local b=acquire("B") local u=op(b,"U",1,1)
		tr(b,u,"Prepare") tr(b,u,"Grant")
		local data,meta=clone(st.Data),clone(st.Meta)
		assert(not pcall(tr,s,t,"Cancel"))
		assert(equal(data,st.Data) and equal(meta,st.Meta))
		tr(b,u,"Grant") assert(st.Data.OwnedItems.test==11)
	end)
	test("same-owner old Cancel and Prepare do not overwrite successor",function()
		local st,acquire,op,tr=fixture() local s=acquire("A") local t=op(s,"T",1,5)
		tr(s,t,"Prepare") tr(s,t,"Grant")
		local u=op(s,"U",2,1) tr(s,u,"Prepare") tr(s,u,"Grant")
		local data,meta,writes=clone(st.Data),clone(st.Meta),st.Writes
		assert(tr(s,t,"Cancel")==nil and tr(s,t,"Prepare")==nil and tr(s,t,"Grant")==nil)
		assert(equal(data,st.Data) and equal(meta,st.Meta) and writes==st.Writes)
		tr(s,u,"Grant") assert(st.Data.OwnedItems.test==16)
	end)
	test("death/leave before Grant cancels Pending only",function()
		local st,acquire,op=fixture() local s=acquire("A") local o,a=op(s,"T",1,5)
		st.After=function(_,request) if request==2 then o.RunReturn.Alive=false end end
		assert(not Return.Resolve(nil,s,o,a))
		assert(st.Data.RunReturnJournal.State=="Cancelled" and st.Data.OwnedItems.test==10)
	end)
	test("death/leave after Grant write preserves terminal grant",function()
		local st,acquire,op=fixture() local s=acquire("A") local o,a=op(s,"T",1,5)
		st.After=function(_,request) if request==3 then o.RunReturn.Alive=false end end
		assert(Return.Resolve(nil,s,o,a))
		assert(st.Data.OwnedItems.test==15 and st.Data.RunReturnJournal.State=="Granted")
	end)
	test("autosave/shutdown cannot retry an unconfirmed grant",function()
		local st,acquire,op=fixture() local s=acquire("A") local o,a=op(s,"T",1,5)
		st.FailBefore=st.Requests+2 assert(not Return.Resolve(nil,s,o,a))
		o.RunReturn.Permit=false local requests=st.Requests
		assert(not Return.Resolve(nil,s,o,a))
		assert(requests==st.Requests and st.Data.OwnedItems.test==10)
		o.RunReturn.Permit=true assert(Return.Resolve(nil,s,o,a)) assert(st.Data.OwnedItems.test==15)
	end)
	test("ownership transfer fences generic mutation and stale autosave",function()
		local st,acquire=fixture() local s=acquire("A") local b=acquire("B")
		local called=false
		assert(not pcall(Ownership.Update,st,"key",s,function() called=true end,function() return true end))
		assert(not called and st.Data.SessionOwnerToken=="B")
		Ownership.Update(st,"key",b,function(old,info)
			local d=clone(old) d.OwnedItems.test+=1 return d,{},info:GetMetadata()
		end,function() return true end)
		assert(st.Data.OwnedItems.test==11)
	end)
	test("response-lost ownership acquisition cannot steal owner back",function()
		local st,acquire=fixture() local attempt={Token="A"} st.FailAfter=1
		assert(not pcall(acquire,"A",attempt))
		acquire("B")
		assert(not pcall(acquire,"A",attempt) and st.Data.SessionOwnerToken=="B")
	end)
	test("response-lost ownership acquisition retries same token",function()
		local st,acquire=fixture() local attempt={Token="A"} st.FailAfter=1
		assert(not pcall(acquire,"A",attempt))
		local s=acquire("A",attempt) assert(s.OwnerToken=="A")
	end)
	test("owner changes during UpdateAsync callback retry",function()
		local st,acquire=fixture() local s=acquire("A")
		st.Before=function(self) self.Before=nil acquire("B") end
		assert(not pcall(Ownership.Update,st,"key",s,function(old) old.OwnedItems.test+=50 return old end,function() return true end))
		assert(st.Data.OwnedItems.test==10 and st.Data.SessionOwnerToken=="B")
	end)
	test("changed delta or reused ID/sequence is rejected",function()
		local st,acquire,op,tr=fixture() local s=acquire("A") local t=op(s,"T",1,5)
		tr(s,t,"Prepare") tr(s,t,"Grant")
		t.Deltas.test=1 assert(tr(s,t,"Grant")==nil)
		t.Deltas.test=5 t.Sequence=2 assert(tr(s,t,"Prepare")==nil)
		assert(st.Data.OwnedItems.test==15)
	end)
	test("Released session cannot write",function()
		local st,acquire,op=fixture() local s=acquire("A") local o,a=op(s,"T",1,5)
		s.Released=true assert(not Return.Resolve(nil,s,o,a))
		assert(st.Data.OwnedItems.test==10 and not st.Data.RunReturnJournal)
	end)
	local passed=0 for _,r in results do if r.passed then passed+=1 end end
	return {passed=passed,total=#results,results=results}
end
