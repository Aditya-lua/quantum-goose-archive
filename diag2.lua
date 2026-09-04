-- SAE diagnostic v2 (read-only: no remotes fired, no movement, no UI)
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local LP = game:GetService("Players").LocalPlayer
local say = function(fmt, ...)
	print("[SAE-DIAG2]", (fmt):format(...))
end

local function describe(t, depth)
	if typeof(t) ~= "table" then
		return tostring(t)
	end
	local parts = {}
	local count = 0
	for k, v in pairs(t) do
		count = count + 1
		if count > 20 then
			table.insert(parts, "...")
			break
		end
		if type(v) == "function" then
			table.insert(parts, k .. "=fn")
		elseif depth and depth > 0 and typeof(v) == "table" then
			table.insert(parts, k .. "{" .. describe(v, depth - 1) .. "}")
		elseif typeof(v) == "Instance" then
			table.insert(parts, k .. "=" .. v.ClassName)
		else
			table.insert(parts, k .. "=" .. tostring(v))
		end
	end
	table.sort(parts)
	return table.concat(parts, " ")
end

local okR, Remotes = pcall(function()
	local shared = RS:FindFirstChild("Shared")
	local r = shared and shared:FindFirstChild("Remotes")
	return r and require(r)
end)
if okR and type(Remotes) == "table" then
	local groups = {}
	for g in pairs(Remotes) do
		table.insert(groups, g)
	end
	table.sort(groups)
	for _, g in ipairs(groups) do
		local bag = Remotes[g]
		local names = {}
		if type(bag) == "table" then
			for name, inst in pairs(bag) do
				if typeof(inst) == "Instance" then
					table.insert(names, name)
				end
			end
		end
		table.sort(names)
		say("REMOTE %s: %s", g, table.concat(names, ", "))
	end
else
	say("Shared.Remotes unavailable: %s", tostring(Remotes))
end

local client = RS:FindFirstChild("Client")
if client then
	local mods = {}
	for _, c in ipairs(client:GetChildren()) do
		table.insert(mods, c.Name)
	end
	table.sort(mods)
	say("RS.Client: %s", table.concat(mods, ", "))
end

local function listFns(label, path)
	local inst = RS
	local ok = true
	for part in string.gmatch(path, "[^%.]+") do
		if not (inst and inst:FindFirstChild(part)) then
			ok = false
			break
		end
		inst = inst:FindFirstChild(part)
	end
	if not ok or not (inst and inst:IsA("ModuleScript")) then
		say("module %s: MISSING", label)
		return
	end
	local ok2, mod = pcall(require, inst)
	if ok2 and type(mod) == "table" then
		local fns = {}
		for k, v in pairs(mod) do
			if type(v) == "function" then
				table.insert(fns, k)
			end
		end
		table.sort(fns)
		say("module %s: %s", label, table.concat(fns, ", "))
	else
		say("module %s: require failed", label)
	end
end
listFns("Client.PlotState", "Client.PlotState")
listFns("Client.AssetRoster", "Client.AssetRoster")
listFns("Client.BaseUpgrade", "Client.BaseUpgrade")
listFns("Data.Treadmills", "Data.Treadmills")
listFns("Shared.Save", "Shared.Save")
listFns("Shared.Util.FuseKernel", "Shared.Util.FuseKernel")
listFns("Shared.Util.AssetItems", "Shared.Util.AssetItems")

local es = client and client:FindFirstChild("EggState")
local okE, E = pcall(require, es)
if okE and type(E) == "table" then
	local fieldEggs, firstKey = nil, nil
	if type(E.ReadFieldEggs) == "function" then
		local ok3, eggs = pcall(E.ReadFieldEggs)
		if ok3 and type(eggs) == "table" then
			local n = 0
			for k, v in pairs(eggs) do
				n = n + 1
				if not firstKey then
					firstKey = k
				end
			end
			fieldEggs = eggs
			say("ReadFieldEggs: %d entries, first key = %s (%s)", n, tostring(firstKey), type(firstKey))
		else
			say("ReadFieldEggs: %s", ok3 and type(eggs) or tostring(eggs))
		end
	end
	if fieldEggs then
		for k, v in pairs(fieldEggs) do
			if type(v) == "table" then
				say("field egg[%s]: %s", tostring(k), describe(v, 1))
				break
			end
		end
	end
	local uid = nil
	if fieldEggs and firstKey ~= nil then
		local rec = fieldEggs[firstKey]
		if type(rec) == "table" then
			uid = rec.Uid or rec.uid or rec.Id or firstKey
		else
			uid = firstKey
		end
	end
	if uid ~= nil and type(E.ReadFieldEgg) == "function" then
		local ok4, rec = pcall(E.ReadFieldEgg, E, uid)
		say("ReadFieldEgg(%s): %s", tostring(uid), ok4 and describe(rec, 1) or tostring(rec))
	end
	if type(E.ReadOwnedEggs) == "function" then
		local ok5, owned = pcall(E.ReadOwnedEggs)
		if ok5 and type(owned) == "table" then
			local n, sample = 0, nil
			for k, v in pairs(owned) do
				n = n + 1
				if not sample then
					sample = v
				end
			end
			say("ReadOwnedEggs: %d entries", n)
			if sample then
				say("owned egg: %s", describe(sample, 1))
			end
		else
			say("ReadOwnedEggs: %s", ok5 and type(owned) or tostring(owned))
		end
	end
	local carried = {}
	for _, container in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
		if container then
			for _, c in ipairs(container:GetChildren()) do
				if c:IsA("Tool") or c:IsA("Model") then
					table.insert(carried, c.Name)
				end
			end
		end
	end
	say("character/backpack tools: %s", table.concat(carried, ", "))
end

local objects = WS:FindFirstChild("__OBJECTS")
if objects then
	local kids = {}
	for _, c in ipairs(objects:GetChildren()) do
		table.insert(kids, c.Name)
	end
	table.sort(kids)
	say("Workspace.__OBJECTS: %s", table.concat(kids, ", "))
	local areas = objects:FindFirstChild("Areas")
	if areas then
		local zones = {}
		for _, c in ipairs(areas:GetChildren()) do
			table.insert(zones, c.Name)
		end
		table.sort(zones)
		say("Areas children: %s", table.concat(zones, ", "))
		local firstZone = areas:GetChildren()
		if firstZone and firstZone[1] then
			local zkids = {}
			for i, c in ipairs(firstZone[1]:GetChildren()) do
				if i > 8 then
					table.insert(zkids, "...")
					break
				end
				table.insert(zkids, c.Name .. "(" .. c.ClassName .. ")")
			end
			say("first zone %s children: %s", firstZone[1].Name, table.concat(zkids, ", "))
		end
	end
end

say("DONE (read-only, nothing was fired)")
