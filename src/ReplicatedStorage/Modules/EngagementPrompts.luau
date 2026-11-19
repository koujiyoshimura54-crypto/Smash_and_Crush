-- Native prompts only on Click(). Test adapters supply fake eligibility/events.
-- Closed means closed, never permission granted / invitation delivered.
local M={}
function M.new(d)
	local alive,busy,serial=true,false,0
	local opened,nextCheck=false,0
	local now=d.Now or os.clock
	local closing=d.Closed:Connect(function() if opened then busy=false;opened=false end end)
	local api={}
	function api.Click()
		if not alive or busy or now()<nextCheck or not d.Enabled() then return "DisabledOrBusy" end
		busy=true;serial+=1;nextCheck=now()+2
		local attempt=serial
		local ok,allowed=pcall(d.CanPrompt)
		if not alive or serial~=attempt then return "Disposed" end
		if not ok or not allowed then busy=false;return ok and "Unavailable" or "CheckFailed" end
		opened=true
		local prompted=pcall(d.Prompt)
		if not prompted then busy=false;opened=false;return "PromptFailed" end
		-- Keep the lock until the native closed signal. No timed unlock while a prompt is open.
		return "Opened"
	end
	function api.Destroy() alive=false;serial+=1;busy=false;closing:Disconnect() end
	return api
end
return M
