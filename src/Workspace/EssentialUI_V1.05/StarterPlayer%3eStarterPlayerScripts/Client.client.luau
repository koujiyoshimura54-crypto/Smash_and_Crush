local ControllersFolder = script.Parent.Controllers

local controllers = {}
local initThreads = {}

-- Load controllers
for _, module in ControllersFolder:GetChildren() do
	if not module:IsA("ModuleScript") then
		continue
	end

	local success, controller = pcall(require, module)
	if not success then
		warn("[ControllerLoader] Failed to require:", module.Name, controller)
		continue
	end

	controllers[#controllers + 1] = controller

	-- Init phase (async)
	if type(controller) ~= "function" and controller.init and type(controller.init) == "function" then
		local thread = task.spawn(function()
			local ok, err = pcall(controller.init, controller)
			if not ok then
				warn("[controllerLoader] Init failed for", module.Name, err)
			end
		end)

		initThreads[#initThreads + 1] = thread
	end
end

for _, thread in initThreads do
	task.wait() 
end

for _, controller in controllers do
	if type(controller) ~= "function" and controller.start and type(controller.start) == "function" then
		task.spawn(function()
			local ok, err = pcall(controller.start, controller)
			if not ok then
				warn("[controllerLoader] Start failed:", err)
			end
		end)
	end
end
