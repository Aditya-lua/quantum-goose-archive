-- SAE diagnostic (read-only: no remotes fired, no movement, no UI)
local RS = game:GetService("ReplicatedStorage")
local WS = game:GetService("Workspace")
local say = function(fmt, ...)
	print("[SAE-DIAG]", (fmt):format(...))
end

local function checkModule(path)
	local inst = RS
	for part in string.gmatch(path, "[^%.]+") do
		if not (inst and inst:FindFirstChild(part)) then
			return false
		end
		inst = inst:FindFirstChild(part)
	end
	return true
end

for _, p in ipairs({
	"Client.EggState", "Client.PlotState", "Client.AssetRoster", "Client.BaseUpgrade",
	"Data.Treadmills", "Shared.Save", "Shared.Util.AssetItems", "Shared.Util.FuseKernel",
	"Shared.Remotes",
}) do
	say("module %-28s %s", p, checkModule(p) and "OK" or "MISSING")
end

local eggState = RS:FindFirstChild("Client") and RS.Client:FindFirstChild("EggState")
if eggState and eggState:IsA("ModuleScript") then
	local ok, mod = pcall(require, eggState)
	if ok and type(mod) == "table" then
		local fns = {}
		for k, v in pairs(mod) do
			if type(v) == "function" then
				table.insert(fns, k)
			end
		end
		table.sort(fns)
		say("EggState fns: %s", table.concat(fns, ", "))
		if type(mod.GetAreaEggSnapshot) == "function" then
			local ok2, snap = pcall(mod.GetAreaEggSnapshot)
			if not (ok2 and type(snap) == "table" and type(snap.Records) == "table")
				and type(mod.RequestAreaEggSnapshot) == "function" then
				pcall(mod.RequestAreaEggSnapshot)
				task.wait(2)
				ok2, snap = pcall(mod.GetAreaEggSnapshot)
			end
			if ok2 and type(snap) == "table" and type(snap.Records) == "table" then
				local n, firstUid, firstRec = 0, nil, nil
				for uid, rec in pairs(snap.Records) do
					n = n + 1
					if not firstRec then
						firstUid, firstRec = uid, rec
					end
				end
				say("snapshot records: %d", n)
				if firstRec then
					local parts = {}
					for k, v in pairs(firstRec) do
						if type(v) ~= "table" and type(v) ~= "function" then
							table.insert(parts, k .. "=" .. tostring(v))
						end
					end
					table.sort(parts)
					say("sample uid %s", tostring(firstUid))
					say("sample rec: %s", table.concat(parts, " | "))
				end
			else
				say("snapshot: %s", ok2 and tostring(snap) or tostring(snap))
			end
		else
			say("EggState has NO GetAreaEggSnapshot")
		end
		if type(mod.GetPlayerCarryStates) == "function" then
			local ok3, states = pcall(mod.GetPlayerCarryStates)
			if ok3 and type(states) == "table" then
				local n = 0
				for _ in pairs(states) do
					n = n + 1
				end
				say("carry states entries: %d", n)
			else
				say("carry states: %s", ok3 and type(states) or tostring(states))
			end
		end
	else
		say("require(EggState) failed: %s", tostring(mod))
	end
else
	say("EggState module missing")
end

local slots = WS:FindFirstChild("AreaEggSlotsClient")
if slots then
	local kids = slots:GetChildren()
	local names = {}
	for i = 1, math.min(5, #kids) do
		table.insert(names, kids[i].Name)
	end
	say("AreaEggSlotsClient children: %d | sample: %s", #kids, table.concat(names, ", "))
else
	say("AreaEggSlotsClient MISSING")
end

local okR, Remotes = pcall(function()
	local shared = RS:FindFirstChild("Shared")
	local r = shared and shared:FindFirstChild("Remotes")
	return r and require(r)
end)
local wanted = {
	{ "EggWorld", "AskFieldEggCarry" }, { "EggWorld", "AskFieldEggDrop" },
	{ "EggWorld", "AskPlaceEgg" }, { "EggWorld", "AskFinishHatch" },
	{ "EggWorld", "AskHatch" }, { "EggWorld", "AskWearTool" },
	{ "Fusery", "BeginFuse" }, { "Fusery", "CompleteFuse" },
	{ "Fusions", "FUSE_BY_ID" }, { "Fusions", "REVEAL_FUSE" },
	{ "Backpack", "EQUIP_BEST" }, { "AssetInventory", "SELL_ASSET" },
	{ "Index", "REQUEST_CLAIM_ALL" }, { "OfflineAssets", "GET_SUMMARY" },
	{ "OfflineAssets", "REQUEST_REDEEM" }, { "AwayEarnings", "FetchSummary" },
	{ "AwayEarnings", "AskCollect" }, { "GroupPerk", "RedeemPerk" },
	{ "Codex", "AskRedeemAll" }, { "Trails", "REQUEST_PURCHASE" },
	{ "Trails", "REQUEST_SELECT" }, { "Trails", "WORN_SNAPSHOT" },
	{ "Treadmills", "REQUEST_EQUIP_STATIC" }, { "Treadmills", "REQUEST_UNEQUIP" },
	{ "Treadmills", "REQUEST_UPGRADE" }, { "Plots", "REQUEST_BASE_UPGRADE" },
	{ "Haul", "WearBest" },
}
if okR and type(Remotes) == "table" then
	local missing = {}
	for _, wn in ipairs(wanted) do
		local bag = Remotes[wn[1]]
		local r = bag and bag[wn[2]]
		if not (r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction"))) then
			table.insert(missing, wn[1] .. "." .. wn[2])
		end
	end
	if #missing == 0 then
		say("REMOTES: all %d found", #wanted)
	else
		say("REMOTES MISSING: %s", table.concat(missing, ", "))
	end
else
	say("Shared.Remotes module missing or failed")
	local pkg = RS:FindFirstChild("Packages")
	local net = pkg and pkg:FindFirstChild("Networking")
	if net then
		local groups = {}
		for _, c in ipairs(net:GetChildren()) do
			table.insert(groups, c.Name)
		end
		table.sort(groups)
		say("Packages.Networking children: %s", table.concat(groups, ", "))
	else
		say("Packages.Networking MISSING")
	end
end

local found = 0
for _, m in ipairs(WS:GetChildren()) do
	if (m:IsA("Model") or m:IsA("BasePart")) then
		for _, c in ipairs(m:GetChildren()) do
			if c.Name:find("Egg") then
				found = found + 1
				if found <= 3 then
					local attrs = {}
					pcall(function()
						for _, a in ipairs(m:GetAttributes()) do
							table.insert(attrs, a .. "=" .. tostring(m:GetAttribute(a)))
						end
					end)
					say("egg model %s (%s) child=%s", m.Name, m.ClassName, c.Name)
					if #attrs > 0 then
						say("  attrs: %s", table.concat(attrs, " | "))
					end
				end
				break
			end
		end
		if found >= 3 then
			break
		end
	end
end
if found == 0 then
	say("no egg-named children under workspace top level")
end

say("DONE (read-only, nothing was fired)")
