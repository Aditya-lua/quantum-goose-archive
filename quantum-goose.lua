local request = (syn and syn.request) or (http and http.request) or http_request;
-- Essential services
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LightingService = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local Camera = Workspace.Camera
local client = Players.LocalPlayer
-- anti-cheat bypass (1:1 port of user-supplied technique)
local nextFunction = next
local secondaryGetgc, alternateGetgc = getgc()
repeat
	local flag = false
	while true do
		local getgcResult
		alternateGetgc, getgcResult = nextFunction(secondaryGetgc, alternateGetgc)
		if not alternateGetgc then
			break
		end
		if type(getgcResult) == "function" and islclosure(getgcResult) then
			local secondaryGetconstants = getconstants(getgcResult)
			if type(secondaryGetconstants) == "table" then
				local nextFunction = next
				local result
				repeat
					local flagResult
					result, flagResult = nextFunction(secondaryGetconstants, result)
					if not result then
						flag = true
					end
					if flag then
						break
					end
				until flagResult == "X-14"
				if not flag then
					local callback
					callback = hookfunction(getgcResult, function(...)
						local getstack = debug.getstack(1)
						local nextFunction = next
						local flag
						while true do
							local flagResult
							flag, flagResult = nextFunction(getstack, flag)
							if not flag then
								break
							end
							if flagResult == "X-14" then
								debug.setstack(Level, flag, nil)
							end
						end
						return callback(...)
					end)
				end
			end
		end
		if flag then
			break
		end
	end
until not flag
local detectionFunction = filtergc(
    "function",
    {
        Constants = {
            "gmatch",
            "GetFullName",
        },
    },
    true
)
for _, upvalueValue in debug.getupvalues(detectionFunction) do
    if typeof(upvalueValue) == "table" then
        setrawmetatable(upvalueValue, {
            __newindex = function(_, key, newValue)
                warn(("Blocked detection %* %*"):format(key, newValue))
            end,
        })
    end
end
print("Bypassed")


local Services = {}
local function svc(name)
	local cached = Services[name]
	if cached then
		return cached
	end
	local ok, result = pcall(game.GetService, game, name)
	if ok and typeof(result) == "Instance" then
		Services[name] = result
		return result
	end
	return nil
end

local RunService = svc("RunService")
local Players = svc("Players")
local Workspace = svc("Workspace")
local ReplicatedStorage = svc("ReplicatedStorage")
local HttpService = svc("HttpService")
local UserInputService = svc("UserInputService")
local VirtualUser = svc("VirtualUser")
local Lighting = svc("Lighting")
local CoreGui = svc("CoreGui")
local PathfindingService = svc("PathfindingService")
local TeleportService = svc("TeleportService")
local Rendering = svc("Rendering")

local client = Players and Players.LocalPlayer or nil

-- Wait for game load (game's own Kernel does the same)
do
	local ok, loaded = pcall(function() return game:IsLoaded() end)
	if ok and not loaded and typeof(game.Loaded) == "Instance" then
		pcall(function() game.Loaded:Wait() end)
	end
end

local GameAPI = {}
local World = {}
local Movement = {}
local Farm = {}
local Progress = {}
local Protection = {}
local Dispute = {}
local Esp = {}
local Fusion = {}
local EventMod = {}
local ServerHop = {}
local Webhook = {}
local ConfigMod = {}
local Status = { label = nil, text = "Idle" }
local Watchdog = { lastProgressAt = os.clock(), sessionStart = os.clock(), rejoinCooldown = 0 }

local Conns = {}
local function track(conn, tag)
	if conn and typeof(conn) == "RBXScriptConnection" then
		table.insert(Conns, { conn = conn, tag = tag or "Core" })
	end
	return conn
end
local function disconnectTag(tag)
	for i = #Conns, 1, -1 do
		if Conns[i].tag == tag then
			pcall(Conns[i].conn.Disconnect, Conns[i].conn)
			table.remove(Conns, i)
		end
	end
end
local function disconnectAllExcept(coreTag)
	for i = #Conns, 1, -1 do
		if Conns[i].tag ~= coreTag then
			pcall(Conns[i].conn.Disconnect, Conns[i].conn)
			table.remove(Conns, i)
		end
	end
end

local function resolveUiParent()
	local okHui, hui = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if okHui and typeof(hui) == "Instance" then
		return hui
	end
	if type(sethui) == "function" then
		pcall(sethui)
	end
	return CoreGui
end

local Library = loadstring(game:HttpGet("https://versusairlines.top/scripts/NewLibrary.lua"))()

local ui = Library:Setup({
	Location = resolveUiParent(),
	OpenCloseLocation = "Top Center",
})

do
	local ctrls = {}
	local origCreateSection = ui.CreateSection
	local function adapt(obj)
		if not obj then
			return nil
		end
		return setmetatable({}, {
			__index = function(_, k)
				if k == "Set" then
					return function(_, ...)
						if obj.Set then
							obj:Set(...)
						end
					end
				end
				if k == "updateText" then
					return function(_, t)
						if obj.Set then
							obj:Set(t)
						elseif obj.updateText then
							obj:updateText(t)
						end
					end
				end
				if k == "updateList" then
					return function(_, l)
						if obj.updateList then
							obj:updateList(l)
						end
					end
				end
				return obj[k]
			end,
		})
	end
	ui.CreateSection = function(self, name)
		local sec = origCreateSection(self, name)
		local proxy = setmetatable({}, {
			__index = function(_, k)
				if k == "FindFirstChild" then
					return function(_, tag)
						return adapt(ctrls[tag])
					end
				end
				return sec[k]
			end,
		})
		for _, m in ipairs({
			"createLabel",
			"createDropdown",
			"createToggle",
			"createSlider",
			"createButton",
			"createInputBox",
			"createKeybind",
		}) do
			proxy[m] = function(_, cfg)
				local ok, obj = pcall(sec[m], sec, cfg)
				if cfg and cfg.flagName and obj then
					ctrls[cfg.flagName] = obj
				end
				return obj
			end
		end
		return proxy
	end
end

local function labelUpdate(ctrl, text)
	if not ctrl then
		return
	end
	if type(ctrl.updateText) == "function" then
		pcall(ctrl.updateText, ctrl, text)
		return
	end
	if type(ctrl.Set) == "function" then
		pcall(ctrl.Set, ctrl, text)
	end
end

local DEFAULTS = {
	-- farm
	AutoSteal = false, AutoPlace = false, AutoDrop = false, AutoHatch = false,
	AutoRecover = false, AutoSell = false, AutoFavorite = false,
	SpawnSniper = false, SnipeDropped = false,
	FarmMode = "Ground Walk (recommended)", SmartTween = false, TweenSpeed = 700,
	TargetPriority = "Rarest", PrioritizeRarity = false, DistantEggTarget = false,
	FarmMinRarity = "Common", MinEggWeight = 0, MinEarnings = 0,
	ColossalHunt = false, ColossalThreshold = 100000, MutatedOnly = false,
	AvoidGuards = false, GuardRadius = 40, IgnoreFriends = false,
	SellBelowKG = 0, SellRarities = { "Common", "Uncommon", "Rare", "Epic" },
	SellKeepAllMutated = false,
	FavoriteRarities = { "Legendary", "Mythic", "Mythical", "Divine", "Celestial", "Secret", "Eternal", "Limited" },
	FavoriteMinKG = 0,
	PreferParasiteEggs = false, DragonEventSafe = false, ForestGuardBypass = false,
	NightFarmSync = false,
	SelectRarity = { "All" }, SelectMutation = { "All" }, SelectArea = { "All" },
	SelectEggType = { "All" }, SellMutationWhitelist = { "All" },
	DisputeRarities = { "All" }, EspMutations = { "All" }, EspAreas = { "All" },
	StealCooldown = 1,
	-- progress
	AutoClaimIndex = false, AutoClaimOffline = false,
	AutoTreadmill = false, AutoTreadmillUpgrade = false, AutoBaseUpgrade = false,
	AutoEquipBest = false, AutoEquipTrail = false, AutoEquipBatBest = false, AutoBuyBest = false,
	-- protection
	AutoDisarmTraps = false, AutoEvasion = false, EvasionRadius = 35, EvasionCarryOnly = false,
	EscapeHeight = 60, DodgeHeight = 60,
	BatAura = false, AuraRange = 17, SwingDelay = 0.7, AutoEquipBat = false,
	LagbackRecovery = false, LagbackThreshold = 3, LagbackRejoin = false,
	Immortality = false, AntiTreadmill = false, AntiFling = false, AntiRagdoll = false,
	-- dispute
	AutoDispute = false, DisputeGiveUp = 20, DisputeMaxDistance = 2000, DisputeLock = false,
	-- esp
	EggEsp = false, EspTracers = false, PlotEsp = false, EspShowTaken = false, EspMaxDistance = 800,
	EspMinRarity = "Common", EspMinKG = 0, EspMinEarnings = 0,
	-- fusion
	AutoFuse = false, FusionRarities = { "All" },
	-- event
	EventMonitor = false, AutoConsumeChest = false, EventExcludeRare = false,
	-- server hop
	AutoHopTarget = false, MaxHops = 10, HopMinKG = 0,
	HopRarities = { "All" }, HopMutations = { "All" }, HopMutatedOnly = false,
	-- webhook
	WebhookURL = "", WebhookEnabled = false, WebhookRare = false, WebhookRareMin = "Epic",
	WebhookPingRarities = { "All" },
	WebhookChest = false, WebhookFuse = false, WebhookHop = false, WebhookDisconnect = false,
	WebhookRolePing = "",
	-- config
	BlackScreen = false, FpsBoost = false, FpsCap = 0, OptimizationMethod = "Balanced",
	AntiAfk = false, InfiniteJump = false,
	WalkSpeedEnabled = false, WalkSpeedValue = 30, LockLegalWalkSpeed = false,
	JumpPowerEnabled = false, JumpPowerValue = 50,
	Watchdog = false, StuckTimeout = 120, RejoinDelay = 180,
	AutoRejoin = false, AntiRejoin = false,
	AutoLoadConfig = false, DebugConsole = false, UiTheme = "Dark Mode", ToggleUIKey = "RightControl",
	LoaderURL = "",
}

local function getFlag(name, default)
	if Library and type(Library.Flags) == "table" then
		local v = Library.Flags[name]
		if v ~= nil then
			return v
		end
	end
	if DEFAULTS[name] ~= nil then
		return DEFAULTS[name]
	end
	return default
end
local function setFlag(name, value)
	if Library and type(Library.Flags) == "table" then
		Library.Flags[name] = value
	end
end
local function getDropdownValue(name, default)
	local v = getFlag(name, nil)
	if type(v) == "table" then
		return v[1] or default
	end
	if v == nil then
		return default
	end
	return v
end
local function getSelectedList(name)
	local v = getFlag(name, nil)
	if type(v) == "table" then
		return v
	end
	if v ~= nil then
		return { v }
	end
	return {}
end
local function listAllowsAll(list)
	for _, item in ipairs(list) do
		if item == "All" then
			return true
		end
	end
	return false
end
local function tableFind(list, value)
	for _, item in ipairs(list) do
		if item == value then
			return true
		end
	end
	return false
end
local function notify(title, desc, style)
	if not Library then
		return
	end
	pcall(function()
		Library:createDisplayMessage(title, desc, { { text = "OK" } }, style or "info")
	end)
end
local function jitter(base, spread)
	spread = spread or base * 0.4
	return base + (math.random() * 2 - 1) * spread
end
local function fmtDuration(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end
function Status.set(text)
	Status.text = text
	labelUpdate(Status.label, text)
end

local Scheduler = {}
Scheduler.active = {}
function Scheduler.start(tag, delay, fn, jitterFrac)
	Scheduler.stop(tag)
	local running = false
	local function loop()
		if not Scheduler.active[tag] then
			return
		end
		if running then
			task.delay(delay, loop)
			return
		end
		running = true
		task.spawn(function()
			pcall(fn)
			running = false
			if Scheduler.active[tag] then
				local d = delay
				if jitterFrac and jitterFrac > 0 then
					d = delay * (1 + (math.random() * 2 - 1) * jitterFrac)
				end
				task.delay(math.max(0.05, d), loop)
			end
		end)
	end
	Scheduler.active[tag] = true
	task.delay(0.2, loop)
end
function Scheduler.stop(tag)
	Scheduler.active[tag] = nil
end
function Scheduler.stopAll()
	for tag in pairs(Scheduler.active) do
		Scheduler.active[tag] = nil
	end
end
local function toggleTask(tag, enabled, delay, fn, jitterFrac)
	if enabled == true then
		Scheduler.start(tag, delay, fn, jitterFrac)
	else
		Scheduler.stop(tag)
	end
end

do
	local requestFn = nil
	local ok, fn = pcall(function()
		if type(request) == "function" then
			return request
		end
		if syn and type(syn.request) == "function" then
			return syn.request
		end
		if http and type(http.request) == "function" then
			return http.request
		end
		if type(http_request) == "function" then
			return http_request
		end
		return nil
	end)
	if ok then
		requestFn = fn
	end

	Webhook.state = { lastSent = 0, queue = {} }
	function Webhook.send(title, desc, color, mention)
		if getFlag("WebhookEnabled", true) ~= true then
			return false
		end
		local url = getFlag("WebhookURL", "")
		if typeof(url) ~= "string" or url == "" then
			return false
		end
		if string.find(url, "discord", 1, true) == nil then
			return false
		end
		if type(requestFn) ~= "function" or not HttpService then
			return false
		end
		local now = os.clock()
		if now - Webhook.state.lastSent < 1 then
			table.insert(Webhook.state.queue, { title = title, desc = desc, color = color, mention = mention })
			return false
		end
		Webhook.state.lastSent = now
		local payload = HttpService:JSONEncode({
			embeds = { {
				title = tostring(title or "Steal an Egg Hub"),
				description = tostring(desc or ""),
				color = color or 0x5865f2,
				footer = { text = "Steal an Egg Hub" },
			} },
			content = mention or "",
		})
		local ok2, res = pcall(function()
			return requestFn({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = payload,
			})
		end)
		return ok2 and res ~= nil
	end
	function Webhook.flush()
		if #Webhook.state.queue > 0 then
			local item = table.remove(Webhook.state.queue, 1)
			Webhook.send(item.title, item.desc, item.color, item.mention)
			task.delay(1.5, Webhook.flush)
		end
	end
	-- "Rarity: @mention" pairs from WebhookRolePing
	local pingCache = {}
	function Webhook.mentionForRarity(rarity)
		local pings = getSelectedList("WebhookPingRarities")
		if listAllowsAll(pings) or tableFind(pings, tostring(rarity)) then
			return "@here"
		end
		local spec = getFlag("WebhookRolePing", "")
		if typeof(spec) ~= "string" or spec == "" then
			return nil
		end
		local key = spec .. "|" .. tostring(rarity)
		if pingCache[key] ~= nil then
			return pingCache[key]
		end
		local mention = nil
		for pair in string.gmatch(spec, "([^,]+),?") do
			local r, m = string.match(pair, "^%s*(%-?[%w ]+)[:=](.-)%s*$")
			if r and m and m ~= "" and string.lower(r) == string.lower(tostring(rarity or "")) then
				mention = m
			end
		end
		pingCache[key] = mention
		return mention
	end
end

local function getCharacter()
	return client and client.Character or nil
end
local function getHumanoid()
	local char = getCharacter()
	return char and char:FindFirstChildOfClass("Humanoid") or nil
end
local function getHRP()
	local char = getCharacter()
	return char and char:FindFirstChild("HumanoidRootPart") or nil
end
local function findHeldEggTool()
	local candidates = {}
	local char = getCharacter()
	if char then
		for _, child in ipairs(char:GetChildren()) do
			table.insert(candidates, child)
		end
	end
	local backpack = client and client:FindFirstChild("Backpack")
	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			table.insert(candidates, child)
		end
	end
	for _, tool in ipairs(candidates) do
		if tool.ClassName == "Tool" and tool:GetAttribute("ItemType") == "AssetEgg" then
			return tool, tool:GetAttribute("UID")
		end
	end
	return nil, nil
end
local function waitForHeldEgg(timeout)
	local deadline = os.clock() + (timeout or 2.5)
	while os.clock() < deadline do
		if findHeldEggTool() then
			return true
		end
		task.wait(0.1)
	end
	return findHeldEggTool() ~= nil
end
local function waitForNotHolding(timeout)
	local deadline = os.clock() + (timeout or 2.5)
	while os.clock() < deadline do
		if not findHeldEggTool() then
			return true
		end
		task.wait(0.1)
	end
	return not findHeldEggTool()
end
local function clickGuiButtonByText(pattern)
	local playerGui = client and client:FindFirstChild("PlayerGui")
	if not playerGui then
		return false
	end
	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant.ClassName == "TextButton" or descendant.ClassName == "ImageButton" then
			local text = string.lower(tostring(descendant.Text or "") .. " " .. tostring(descendant.Name or ""))
			if string.find(text, pattern, 1, true) then
				local ok = pcall(function() descendant:Click() end)
				if ok then
					return true
				end
			end
		end
	end
	return false
end


GameAPI.Modules = {}
GameAPI.remotes = {}

local function safeRequire(instance)
	if typeof(instance) == "Instance" and instance:IsA("ModuleScript") then
		local ok, mod = pcall(require, instance)
		if ok then
			return mod
		end
	end
	return nil
end

local function findReplicatedPath(parts)
	local node = ReplicatedStorage
	if not node then
		return nil
	end
	for _, part in ipairs(parts) do
		local child = node:FindFirstChild(part)
		if not child then
			return nil
		end
		node = child
	end
	return node
end

function GameAPI.init()
	local M = GameAPI.Modules
	M.Remotes = safeRequire(findReplicatedPath({ "Shared", "Remotes" }))
	M.EggState = safeRequire(findReplicatedPath({ "Client", "EggState" }))
	M.PlotState = safeRequire(findReplicatedPath({ "Client", "PlotState" }))
	M.BaseUpgrade = safeRequire(findReplicatedPath({ "Client", "BaseUpgrade" }))
	M.AreaEggSlotIdentity = safeRequire(findReplicatedPath({ "Shared", "Util", "AreaEggSlotIdentity" }))
	M.AreaEggCycle = safeRequire(findReplicatedPath({ "Shared", "Util", "AreaEggCycle" }))
	M.PlacedEggRenderer = safeRequire(findReplicatedPath({ "Shared", "Eggs", "PlacedEggRenderer" }))
	M.Save = safeRequire(findReplicatedPath({ "Shared", "Save" }))
	M.Mutations = safeRequire(findReplicatedPath({ "Shared", "Modules", "Mutations" }))
	M.Time = safeRequire(findReplicatedPath({ "Shared", "Utils", "Time" }))

	local packages = ReplicatedStorage and ReplicatedStorage:FindFirstChild("Packages") or nil
	GameAPI.networking = packages and packages:FindFirstChild("Networking") or nil

	-- hatch module probe: PlacedEggRenderer first, then EggState
	GameAPI.hatchModule = nil
	local candidates = { M.PlacedEggRenderer, M.EggState }
	for _, mod in ipairs(candidates) do
		if type(mod) == "table" and type(mod.ActivateLocalEgg) == "function" then
			GameAPI.hatchModule = mod
			break
		end
	end
end

function GameAPI.getRemote(group, name)
	local key = group .. "." .. name
	local cached = GameAPI.remotes[key]
	if cached ~= nil then
		return cached
	end
	local remote = nil
	local g = GameAPI.Modules.Remotes
	if type(g) == "table" then
		local sub = g[group]
		if type(sub) == "table" and typeof(sub[name]) == "Instance" then
			remote = sub[name]
		end
	end
	if not remote and typeof(GameAPI.networking) == "Instance" then
		local candidate = GameAPI.networking:FindFirstChild("RF/" .. group .. "/" .. name)
		if candidate and (candidate:IsA("RemoteEvent") or candidate:IsA("RemoteFunction")) then
			remote = candidate
		end
	end
	GameAPI.remotes[key] = remote
	return remote
end

function GameAPI.invoke(group, name, ...)
	local r = GameAPI.getRemote(group, name)
	if not r or type(r.InvokeServer) ~= "function" then
		return false, nil
	end
	local ok, res = pcall(r.InvokeServer, r, ...)
	if not ok then
		return false, res
	end
	return true, res
end

function GameAPI.fire(group, name, ...)
	local r = GameAPI.getRemote(group, name)
	if not r or type(r.FireServer) ~= "function" then
		return false
	end
	local ok = pcall(r.FireServer, r, ...)
	return ok
end

function GameAPI.carryEgg(uid)
	if typeof(uid) ~= "string" or uid == "" then
		return false
	end
	local mod = GameAPI.Modules.EggState
	if type(mod) == "table" and type(mod.CarryFieldEgg) == "function" then
		local ok = pcall(mod.CarryFieldEgg, mod, uid)
		if ok then
			return true
		end
	end
	return GameAPI.invoke("EggWorld", "AskFieldEggCarry", { Uid = uid })
end

function GameAPI.placeEgg(uid, localCFrame)
	if typeof(uid) ~= "string" or uid == "" then
		return false
	end
	local cf = typeof(localCFrame) == "CFrame" and localCFrame or CFrame.new()
	local mod = GameAPI.Modules.EggState
	if type(mod) == "table" and type(mod.PlantEgg) == "function" then
		local ok = pcall(mod.PlantEgg, mod, uid, cf)
		if ok then
			return true
		end
	end
	return GameAPI.invoke("EggWorld", "AskPlaceEgg", { Uid = uid, LocalCFrame = cf })
end

function GameAPI.dropEgg()
	local mod = GameAPI.Modules.EggState
	if type(mod) == "table" and type(mod.DropFieldEgg) == "function" then
		local ok = pcall(mod.DropFieldEgg, mod, "PlayerRequest")
		if ok then
			return true
		end
	end
	return GameAPI.invoke("EggWorld", "AskFieldEggDrop", { Reason = "PlayerRequest" })
end

function GameAPI.hatchEgg(uid)
	if typeof(uid) ~= "string" or uid == "" then
		return false
	end
	local ok1 = GameAPI.invoke("EggWorld", "AskHatch", uid)
	if ok1 then
		return true
	end
	if GameAPI.hatchModule then
		local ok = pcall(GameAPI.hatchModule.ActivateLocalEgg, GameAPI.hatchModule, uid)
		if ok then
			return true
		end
	end
	return false
end

function GameAPI.finishHatch(uid)
	if typeof(uid) ~= "string" or uid == "" then
		return false
	end
	local ok = GameAPI.invoke("EggWorld", "AskFinishHatch", uid)
	if ok then
		return true
	end
	return false
end

function GameAPI.wearTool(uid)
	if typeof(uid) ~= "string" or uid == "" then
		return false
	end
	return GameAPI.invoke("EggWorld", "AskWearTool", uid)
end

function GameAPI.doffTool(uid)
	if typeof(uid) ~= "string" or uid == "" then
		return false
	end
	return GameAPI.invoke("EggWorld", "AskDoffTool", uid)
end

function GameAPI.wearBestPet()
	return GameAPI.invoke("Haul", "WearBest")
end

function GameAPI.chooseTrail(name)
	return GameAPI.invoke("Trailwear", "AskChoose", name or "Fastest")
end

function GameAPI.sellPets(uids)
	if type(uids) ~= "table" or #uids == 0 then
		return false
	end
	return GameAPI.fire("PetSatchel", "SellEveryPet", uids)
end

function GameAPI.favoritePet(uid)
	if typeof(uid) ~= "string" or uid == "" then
		return false
	end
	local ok = GameAPI.invoke("PetSatchel", "WriteFavourite", { Uid = uid })
	if ok then
		return true
	end
	return GameAPI.invoke("PetSatchel", "WriteFavourite", uid)
end

function GameAPI.fuse()
	return GameAPI.invoke("Fusery", "BeginFuse")
end

function GameAPI.treadmillWear()
	return GameAPI.invoke("Treadmill", "AskWearStill")
end

function GameAPI.treadmillDoff()
	return GameAPI.invoke("Treadmill", "AskDoff")
end

function GameAPI.treadmillTierRaise(id)
	if typeof(id) ~= "string" or id == "" then
		return false
	end
	return GameAPI.invoke("Treadmill", "AskTierRaise", id)
end

function GameAPI.claimCodex()
	return GameAPI.invoke("Codex", "AskRedeemAll")
end

function GameAPI.collectAway()
	return GameAPI.invoke("AwayEarnings", "AskCollect", { Kind = "Claim" })
end

function GameAPI.redeemGroupPerk()
	return GameAPI.invoke("GroupPerk", "RedeemPerk", false)
end

function GameAPI.chestClaim()
	return GameAPI.invoke("MonsterParasite", "AskChestClaim")
end

function GameAPI.baseUpgrade()
	local mod = GameAPI.Modules.BaseUpgrade
	if type(mod) == "table" and type(mod.PurchaseNextTier) == "function" then
		local ok, res = pcall(mod.PurchaseNextTier, mod)
		if ok then
			return true, res
		end
	end
	return false, nil
end

function GameAPI.readFieldEgg(uid)
	if typeof(uid) ~= "string" or uid == "" then
		return nil
	end
	local mod = GameAPI.Modules.EggState
	if type(mod) == "table" and type(mod.ReadFieldEgg) == "function" then
		local ok, rec = pcall(mod.ReadFieldEgg, mod, uid)
		if ok and type(rec) == "table" then
			return rec
		end
	end
	return nil
end

function GameAPI.saveData()
	local mod = GameAPI.Modules.Save
	if type(mod) == "table" and type(mod.Get) == "function" then
		local ok, data = pcall(mod.Get, mod)
		if ok and type(data) == "table" then
			return data
		end
	end
	return nil
end

function GameAPI.serverTime()
	local t = GameAPI.Modules.Time
	if type(t) == "table" then
		local ok, res = pcall(function() return t:GetServerTimeNow() end)
		if ok and type(res) == "number" then
			return res
		end
		local el = t.Elapsed
		if type(el) == "table" then
			local ok2, res2 = pcall(function() return el:GetServerTimeNow() end)
			if ok2 and type(res2) == "number" then
				return res2
			end
		end
	end
	return os.time()
end

function GameAPI.isNight()
	local mod = GameAPI.Modules.AreaEggCycle
	if type(mod) == "table" and type(mod.IsNightPhase) == "function" then
		local ok, res = pcall(mod.IsNightPhase, mod, GameAPI.serverTime())
		if ok then
			return res == true
		end
	end
	return false
end

function GameAPI.secondsUntilPhaseEnd()
	local mod = GameAPI.Modules.AreaEggCycle
	if type(mod) == "table" and type(mod.SecondsUntilPhaseEnd) == "function" then
		local ok, res = pcall(mod.SecondsUntilPhaseEnd, mod, GameAPI.serverTime())
		if ok and type(res) == "number" then
			return res
		end
	end
	return nil
end

function GameAPI.inNightTransition()
	local mod = GameAPI.Modules.AreaEggCycle
	if type(mod) == "table" and type(mod.IsWithinNightTransition) == "function" then
		local ok, res = pcall(mod.IsWithinNightTransition, mod, GameAPI.serverTime())
		if ok then
			return res == true
		end
		local ok2, res2 = pcall(mod.IsWithinNightTransition, mod, GameAPI.serverTime(), 300, 60)
		if ok2 then
			return res2 == true
		end
	end
	return false
end

function GameAPI.dragonEventActive()
	local phase = Workspace:GetAttribute("DragonEventPhase")
	if phase ~= nil then
		local s = tostring(phase)
		if s ~= "" and s ~= "Idle" and s ~= "Ended" and s ~= "None" then
			return true
		end
	end
	return Workspace:GetAttribute("DragonEventMap") == true
end

World.eggFolder = nil
World.eggs = {}          -- model -> info
World.eggConns = {}
World.promptCache = {}
World.promptScanAt = 0
World.promptBackups = {}
World.guards = {}
World.lastGuardScan = 0
World.plotFolder = nil
World.plotCFrame = nil
World.treadmill = nil
World.parasite = nil
World.lastParasiteScan = 0
World.friendCache = {}
World.friendCacheAt = 0

local AREA_NAMES = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano", "Abyss", "Ocean" }
World.areaNames = AREA_NAMES
local AREA_WAYPOINTS = {
	Vector3.new(586.69, 70.57, -323.43),
	Vector3.new(744.43, 70.57, -409.91),
	Vector3.new(953.64, 70.57, -320.68),
	Vector3.new(1189.46, 70.57, -408.11),
	Vector3.new(1497.20, 70.57, -311.09),
	Vector3.new(1879.72, 70.57, -396.42),
	Vector3.new(2284.08, 70.57, -329.22),
	Vector3.new(2813.06, 70.57, -397.42),
	Vector3.new(3392.44, 70.57, -323.93),
	Vector3.new(4032.04, 70.57, -400.21),
}

local function areaFromWaypoints(pos)
	local bestIndex, bestDistance = 0, math.huge
	for i, wp in ipairs(AREA_WAYPOINTS) do
		local d = (wp - pos).Magnitude
		if d < bestDistance then
			bestDistance = d
			bestIndex = i
		end
	end
	if bestDistance > 400 then
		return "Unknown", 0
	end
	return AREA_NAMES[bestIndex] or ("Area " .. bestIndex), bestIndex
end

function World.makeEggInfo(model)
	return {
		model = model,
		uid = tostring(model.Name),
		pos = nil,
		rarity = nil,
		mutation = nil,
		weight = 0,
		earnings = 0,
		eggType = nil,
		record = nil,
		recordAt = 0,
		areaName = nil,
		areaIndex = 0,
	}
end

function World.eggPos(model)
	if typeof(model) ~= "Instance" then
		return nil
	end
	local hitbox = model:FindFirstChild("Hitbox")
	local part = (hitbox and hitbox:IsA("BasePart") and hitbox)
		or model.PrimaryPart
		or model:FindFirstChildOfClass("BasePart")
	return part and part.Position or nil
end

local EARNINGS_ATTRS = { "Earnings", "MoneyPerSec", "EPS", "Mps", "YieldPerSec" }

function World.refreshEgg(info)
	local model = info.model
	if typeof(model) ~= "Instance" then
		return
	end
	info.pos = World.eggPos(model)
	info.rarity = model:GetAttribute("Rarity")
	info.mutation = model:GetAttribute("Mutation")
	local w = model:GetAttribute("Weight")
	info.weight = type(w) == "number" and w or 0
	info.eggType = model:GetAttribute("EggType") or model:GetAttribute("Type")
	local e = 0
	for _, key in ipairs(EARNINGS_ATTRS) do
		local v = model:GetAttribute(key)
		if type(v) == "number" and v > 0 then
			e = v
			break
		end
	end
	if e == 0 and info.record then
		for _, key in ipairs({ "Earnings", "MoneyPerSec", "Yield" }) do
			local v = info.record[key]
			if type(v) == "number" and v > 0 then
				e = v
				break
			end
		end
	end
	info.earnings = e
end

function World.eggRecord(info)
	local now = os.clock()
	if info.record and now - info.recordAt < 5 then
		return info.record
	end
	local rec = GameAPI.readFieldEgg(info.uid)
	if rec then
		info.record = rec
		info.recordAt = now
	end
	return info.record
end

function World.areaName(info)
	local rec = World.eggRecord(info)
	if rec then
		local idx = tonumber(rec.AreaId)
		if idx and idx >= 1 then
			return AREA_NAMES[idx] or ("Area " .. idx), idx
		end
	end
	if info.pos then
		return areaFromWaypoints(info.pos)
	end
	return "Unknown", 0
end

function World.ensureEggFolder()
	local folder = Workspace:FindFirstChild("AreaEggSlotsClient")
	if typeof(folder) == "Instance" and (folder:IsA("Folder") or folder:IsA("Model")) then
		if World.eggFolder ~= folder then
			World.eggFolder = folder
			World.bindEggEvents()
		end
		return folder
	end
	return World.eggFolder
end

function World.bindEggEvents()
	for _, c in ipairs(World.eggConns) do
		pcall(c.Disconnect, c)
	end
	World.eggConns = {}
	local folder = World.eggFolder
	if not folder then
		return
	end

	local function onAdded(child)
		if child:IsA("Model") then
			World.eggs[child] = World.makeEggInfo(child)
			World.refreshEgg(World.eggs[child])
			if World.onEggSpawn then
				task.spawn(World.onEggSpawn, World.eggs[child])
			end
		end
	end
	local function onRemoved(child)
		World.eggs[child] = nil
	end
	local c1 = track(folder.ChildAdded:Connect(onAdded), "World")
	local c2 = track(folder.ChildRemoved:Connect(onRemoved), "World")
	World.eggConns = { c1, c2 }
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			World.eggs[child] = World.makeEggInfo(child)
		end
	end
end

function World.pruneEggs()
	for model, info in pairs(World.eggs) do
		if typeof(model) ~= "Instance" or not model:IsDescendantOf(Workspace) then
			World.eggs[model] = nil
		end
	end
end

function World.refreshAllEggs()
	World.ensureEggFolder()
	World.pruneEggs()
	for _, info in pairs(World.eggs) do
		World.refreshEgg(info)
	end
end

function World.allEggs()
	return World.eggs
end

function World.findEggPrompt(model)
	if typeof(model) ~= "Instance" then
		return nil
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant.ClassName == "ProximityPrompt" and descendant.Name == "CarryAreaEgg" then
			return descendant
		end
	end
	local pos = World.eggPos(model)
	if not pos then
		return nil
	end
	local now = os.clock()
	if now - World.promptScanAt > 2 then
		World.promptScanAt = now
		World.promptCache = {}
		local folder = World.eggFolder
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("Model") then
					for _, descendant in ipairs(child:GetDescendants()) do
						if descendant.ClassName == "ProximityPrompt" and descendant.Name == "CarryAreaEgg" then
							table.insert(World.promptCache, { prompt = descendant, model = child })
						end
					end
				end
			end
		end
	end
	for _, entry in ipairs(World.promptCache) do
		if entry.model == model then
			return entry.prompt
		end
	end
	return nil
end

function World.triggerPrompt(prompt)
	if not prompt or typeof(prompt) ~= "Instance" then
		return false
	end
	if prompt.HoldDuration > 0 and World.promptBackups[prompt] == nil then
		World.promptBackups[prompt] = prompt.HoldDuration
	end
	pcall(function() prompt.HoldDuration = 0 end)
	local ok = false
	if type(fireproximityprompt) == "function" then
		ok = pcall(fireproximityprompt, prompt)
	elseif type(prompt.InputHold) == "function" then
		ok = pcall(function()
			prompt:InputHold()
			task.wait(0.2)
			prompt:InputRelease()
		end)
	end
	task.wait(0.15)
	return ok
end

function World.restorePromptDurations()
	for prompt, original in pairs(World.promptBackups) do
		if typeof(prompt) == "Instance" then
			pcall(function() prompt.HoldDuration = original end)
		end
	end
	World.promptBackups = {}
end

function World.scanGuards(force)
	local now = os.clock()
	if not force and now - World.lastGuardScan < 2 then
		return World.guards
	end
	World.lastGuardScan = now
	local found = {}
	local objects = Workspace:FindFirstChild("__OBJECTS")
	local areas = objects and objects:FindFirstChild("Areas")
	local guardAreas = areas and areas:FindFirstChild("GuardAreas")
	if typeof(guardAreas) == "Instance" then
		for _, model in ipairs(guardAreas:GetDescendants()) do
			if model:IsA("Model") and model.Name == "Guard" then
				local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
				found[model] = {
					model = model,
					state = model:GetAttribute("GuardState") or "",
					pos = root and root.Position or nil,
				}
			end
		end
	end
	World.guards = found
	return found
end

function World.nearestGuardDistance(pos, onlyChasing)
	local best = math.huge
	for _, info in pairs(World.scanGuards()) do
		if info.pos and (not onlyChasing or info.state == "Chasing") then
			local d = (info.pos - pos).Magnitude
			if d < best then
				best = d
			end
		end
	end
	return best
end

function World.plotInfo(force)
	if not force and World.plotFolder and typeof(World.plotFolder) == "Instance" then
		return World.plotFolder, World.plotCFrame
	end
	local folder = nil
	local cf = nil
	local mod = GameAPI.Modules.PlotState
	if type(mod) == "table" and type(mod.ResolvePlot) == "function" then
		local ok, plot = pcall(mod.ResolvePlot, mod)
		if ok and type(plot) == "table" and typeof(plot.PlotFolder) == "Instance" then
			folder = plot.PlotFolder
			local cp = folder:FindFirstChild("CenterPoint")
			if cp and cp:IsA("BasePart") then
				cf = cp.CFrame
			end
		end
	end
	if not folder and client then
		local plots = Workspace:FindFirstChild("Plots")
		if plots then
			folder = plots:FindFirstChild(client.Name)
				or plots:FindFirstChild(tostring(client.UserId))
			if not folder then
				for _, child in ipairs(plots:GetChildren()) do
					if child:IsA("Model") then
						folder = child
						break
					end
				end
			end
			if folder then
				local cp = folder:FindFirstChild("CenterPoint")
				if cp and cp:IsA("BasePart") then
					cf = cp.CFrame
				end
			end
		end
	end
	World.plotFolder = folder
	World.plotCFrame = cf
	return folder, cf
end

function World.basePosition()
	local _, cf = World.plotInfo()
	if cf then
		return cf.Position
	end
	return nil
end

function World.treadmillModel()
	if World.treadmill and typeof(World.treadmill) == "Instance" then
		return World.treadmill
	end
	local folder = World.plotInfo()
	if folder then
		World.treadmill = folder:FindFirstChild("TreadmillUpgrade") or folder:FindFirstChild("Treadmill")
	end
	return World.treadmill
end

function World.treadmillId()
	local model = World.treadmillModel()
	if not model then
		return nil
	end
	local id = model:GetAttribute("_id") or model:GetAttribute("Id") or model:GetAttribute("Type")
	if typeof(id) == "string" and id ~= "" then
		return id
	end
	return model.Name
end

function World.parasiteModel()
	local now = os.clock()
	if World.parasite and typeof(World.parasite) == "Instance" and now - World.lastParasiteScan < 3 then
		return World.parasite
	end
	World.lastParasiteScan = now
	World.parasite = Workspace:FindFirstChild("MonsterParasite")
		or Workspace:FindFirstChild("Parasite")
		or nil
	return World.parasite
end

function World.parasitePosition()
	local model = World.parasiteModel()
	if not model then
		return nil
	end
	local part = model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
	return part and part.Position or nil
end

function World.isFriend(player)
	if not client or player == client then
		return false
	end
	local now = os.clock()
	if now - World.friendCacheAt > 60 then
		World.friendCache = {}
		World.friendCacheAt = now
	end
	local cached = World.friendCache[player.UserId]
	if cached ~= nil then
		return cached
	end
	local ok, isFriend = pcall(function()
		return player:IsFriendsWith(client.UserId)
	end)
	local result = ok and isFriend == true
	World.friendCache[player.UserId] = result
	return result
end

function World.carriedEggsByOthers()
	local list = {}
	if not Players then
		return list
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= client and player.Character then
			for _, child in ipairs(player.Character:GetChildren()) do
				if child.ClassName == "Tool" and child:GetAttribute("ItemType") == "AssetEgg" then
					table.insert(list, {
						player = player,
						uid = child:GetAttribute("UID"),
						rarity = child:GetAttribute("Rarity") or "Common",
						tool = child,
					})
				end
			end
		end
	end
	return list
end

local function collectPets()
	local pets = {}
	local data = GameAPI.saveData()
	if not data then
		return pets
	end
	local depth = 0
	local function scanNode(node)
		if type(node) ~= "table" or depth > 4 then
			return
		end
		depth = depth + 1
		for _, v in pairs(node) do
			if type(v) == "table" then
				local uid = v.Uid or v.uid or v.ID
				local rarity = v.Rarity
				local weight = v.Weight or v.KG or v.kg
				if type(uid) == "string" and uid ~= "" and type(rarity) == "string" then
					if not pets[uid] then
						pets[uid] = {
							uid = uid,
							rarity = rarity,
							weight = type(weight) == "number" and weight or 0,
							mutation = v.BaseMutation or v.Mutation or nil,
						}
					end
				else
					scanNode(v)
				end
			end
		end
		depth = depth - 1
	end
	scanNode(data)
	return pets
end
World.collectPets = collectPets


Movement.token = 0
Movement.active = false
Movement.lastResult = "idle"
Movement.finished = nil

local glideState = nil
function Movement.speed()
	local v = tonumber(getFlag("TweenSpeed", 340))
	return v or 340
end
local function getGlideSpeed()
	return Movement.speed()
end

local function applyWalkSpeed()
	local hum = getHumanoid()
	if not hum then
		return
	end
	local v = tonumber(getFlag("WalkSpeedValue", 30)) or 30
	if getFlag("LockLegalWalkSpeed", true) == true then
		v = math.min(v, 16)
	end
	pcall(function() hum.WalkSpeed = v end)
end
local function applyJumpPower()
	local hum = getHumanoid()
	if not hum then
		return
	end
	pcall(function() hum.JumpPower = tonumber(getFlag("JumpPowerValue", 50)) or 50 end)
end

local pathOptions = nil
local function computeWaypoints(from, to)
	if not PathfindingService then
		return nil
	end
	local ok, waypoints = pcall(function()
		local path = PathfindingService:CreatePath(0.5, 60, 5)
		local okPath = pcall(path.ComputePath, path, from, to, pathOptions)
		if not okPath then
			return nil
		end
		if path.Status == Enum.PathfindingStatus.Success then
			return path:GetWaypoints()
		end
		return nil
	end)
	if ok then
		return waypoints
	end
	return nil
end

function Movement.cancel()
	Movement.token = Movement.token + 1
	Movement.active = false
	glideState = nil
	Movement.finished = nil
	Movement.lastResult = "cancelled"
end

-- single-frame glide driver (idle cost: one nil check per frame)
local glideConn = RunService.Heartbeat:Connect(function(dt)
	local st = glideState
	if not st then
		return
	end
	if Movement.token ~= st.token then
		glideState = nil
		return
	end
	local hrp = getHRP()
	if not hrp or not hrp:IsDescendantOf(Workspace) then
		local cb = st.onDone
		glideState = nil
		Movement.active = false
		Movement.lastResult = "dead"
		Movement.finished = { token = st.token, result = "dead" }
		if cb then
			task.spawn(cb, "dead")
		end
		return
	end

	-- stuck detection: no progress for 4s -> nudge once, give up after 9s
	local now = os.clock()
	local moved = false
	if st.lastPos then
		moved = (hrp.Position - st.lastPos).Magnitude > 1.0
	end
	if not moved then
		if not st.stuckSince then
			st.stuckSince = now
			if not st.nudged then
				st.nudged = true
				local dir = (st.target - hrp.Position)
				if dir.Magnitude > 0.1 then
					pcall(function()
						hrp.AssemblyLinearVelocity = Vector3.new(dir.Unit.X * 8, 24, dir.Unit.Z * 8)
					end)
				end
			end
		elseif now - st.stuckSince > 9 then
			local cb = st.onDone
			glideState = nil
			Movement.active = false
			Movement.lastResult = "stuck"
			Movement.finished = { token = st.token, result = "stuck" }
			if cb then
				task.spawn(cb, "stuck")
			end
			return
		end
	else
		st.lastPos = hrp.Position
		st.stuckSince = nil
	end

	-- periodic re-path (path modes)
	if st.usePath and PathfindingService and now - (st.lastRepath or 0) > 2.5 then
		st.lastRepath = now
		task.spawn(function()
			local wp = computeWaypoints(hrp.Position, st.target)
			if wp and #wp > 0 and Movement.token == st.token then
				st.path = wp
				st.wpIndex = 1
			end
		end)
	end

	-- current waypoint (or straight target)
	local target = st.target
	if st.path then
		local wp = st.path[st.wpIndex or 1]
		if wp then
			while wp and (hrp.Position - wp.Position).Magnitude < 4 and st.wpIndex < #st.path do
				st.wpIndex = st.wpIndex + 1
				wp = st.path[st.wpIndex]
			end
			if wp then
				target = wp.Position
			end
		end
	end

	local distance = (target - hrp.Position).Magnitude
	if distance <= 1.5 then
		local cb = st.onDone
		glideState = nil
		Movement.active = false
		Movement.lastResult = "arrived"
		Movement.finished = { token = st.token, result = "arrived" }
		if cb then
			task.spawn(cb, "arrived")
		end
		return
	end
	local dir = (target - hrp.Position).Unit
	local step = math.min(st.speed * math.min(dt, 0.1), distance)
	pcall(function()
		hrp.CFrame = CFrame.new(hrp.Position + dir * step)
	end)
end)
track(glideConn, "Core")

-- blocking move; returns "arrived" | "stuck" | "timeout" | "dead" | "cancelled"
function Movement.moveTo(targetPos, opts)
	opts = opts or {}
	if typeof(targetPos) ~= "Vector3" then
		return "dead"
	end
	local timeout = opts.timeout or 45
	local speed = opts.speed or getGlideSpeed()

	local mode = getDropdownValue("FarmMode", "Ground Walk (recommended)")
	if mode == "Ground Walk (recommended)" then
		mode = "Walk"
	end
	if mode == "Walk" then
		return Movement.walkTo(targetPos, timeout)
	end

	local hrp = getHRP()
	if not hrp then
		return "dead"
	end

	Movement.cancel()
	local token = Movement.token + 1
	Movement.token = token
	Movement.active = true

	local usePath = getFlag("SmartTween", true) == true or mode == "Smart Tween"
	local path = nil
	if usePath then
		path = computeWaypoints(hrp.Position, targetPos)
	end
	glideState = {
		token = token,
		target = targetPos,
		speed = speed,
		usePath = usePath,
		path = path,
		wpIndex = 1,
		lastRepath = os.clock(),
		lastPos = hrp.Position,
		stuckSince = nil,
		nudged = false,
		onDone = nil,
	}

	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		local f = Movement.finished
		if f and f.token == token then
			Movement.finished = nil
			return f.result
		end
		task.wait(0.1)
	end
	Movement.cancel()
	return "timeout"
end

function Movement.walkTo(targetPos, timeout)
	local hum = getHumanoid()
	if not hum then
		return "dead"
	end
	applyWalkSpeed()
	local ok = pcall(hum.MoveTo, hum, targetPos)
	if not ok then
		return "dead"
	end
	local deadline = os.clock() + (timeout or 45)
	local lastPos = nil
	local lastMoveAt = os.clock()
	while os.clock() < deadline do
		local hrp = getHRP()
		if not hrp then
			return "dead"
		end
		if (targetPos - hrp.Position).Magnitude <= 4 then
			return "arrived"
		end
		if lastPos then
			if (hrp.Position - lastPos).Magnitude < 0.5 then
				if os.clock() - lastMoveAt > 5 then
					pcall(hum.MoveTo, hum, targetPos + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6)))
					lastMoveAt = os.clock()
				end
			else
				lastMoveAt = os.clock()
			end
		end
		lastPos = hrp.Position
		task.wait(0.2)
	end
	return "timeout"
end

-- fast non-blocking glide (used by flee / spawn sniper)
function Movement.startFastGlide(targetPos, speed)
	local hrp = getHRP()
	if not hrp then
		return false
	end
	Movement.cancel()
	local token = Movement.token + 1
	Movement.token = token
	Movement.active = true
	glideState = {
		token = token,
		target = targetPos,
		speed = speed or 500,
		usePath = false,
		path = nil,
		wpIndex = 1,
		lastRepath = os.clock(),
		lastPos = hrp.Position,
		stuckSince = nil,
		nudged = false,
		onDone = nil,
	}
	return true
end

Farm.state = "Idle"
Farm.cooldownUntil = 0
Farm.failStreak = 0
Farm.stats = { steals = 0, fails = 0, placed = 0, hatched = 0 }
Farm.lastRareAlert = {}
Farm.hatchQueue = {}
Farm.hatchIndex = 1

local RARITY_ORDER = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary",
	"Mythic", "Mythical", "Divine", "Celestial", "Secret", "Eternal", "Limited",
}
Farm.rarityOrder = RARITY_ORDER
local rarityRank = {}
for i, name in ipairs(RARITY_ORDER) do
	rarityRank[name] = i
end
local function getRarityRank(r)
	return rarityRank[r] or 0
end
Farm.getRarityRank = getRarityRank

local MAX_LOCAL_RANGE = 1200

local function eggOwnerMatchesMe(info)
	local rec = World.eggRecord(info)
	if not rec then
		return nil
	end
	if not client then
		return nil
	end
	for _, key in ipairs({ "OwnerId", "OwnerUserId", "Owner" }) do
		local v = rec[key]
		if type(v) == "number" then
			return v == client.UserId
		elseif type(v) == "table" and type(v.UserId) == "number" then
			return v.UserId == client.UserId
		end
	end
	return nil
end

local function eggIsMine(info)
	local mine = eggOwnerMatchesMe(info)
	return mine == true
end

local function eggIsFriends(info)
	local rec = World.eggRecord(info)
	if not rec or not client then
		return false
	end
	for _, key in ipairs({ "OwnerId", "OwnerUserId" }) do
		local v = rec[key]
		if type(v) == "number" and v ~= client.UserId then
			local owner = Players:GetPlayerByUserId(v)
			if owner then
				return World.isFriend(owner)
			end
			return false
		end
	end
	return false
end

function Farm.passesFilters(info)
	local pos = info.pos
	if not pos then
		return false
	end

	local rarity = info.rarity or "Common"

	local minRarity = getDropdownValue("FarmMinRarity", "Common")
	if getRarityRank(rarity) < getRarityRank(minRarity) then
		return false
	end

	local sel = getSelectedList("SelectRarity")
	if not listAllowsAll(sel) and #sel > 0 and not tableFind(sel, rarity) then
		return false
	end

	local mutSel = getSelectedList("SelectMutation")
	if not listAllowsAll(mutSel) and #mutSel > 0 then
		local mut = info.mutation
		if mut == nil then
			if not tableFind(mutSel, "None") then
				return false
			end
		elseif not tableFind(mutSel, mut) then
			return false
		end
	end

	if getFlag("MutatedOnly", false) == true and info.mutation == nil then
		return false
	end

	local eggTypeSel = getSelectedList("SelectEggType")
	if not listAllowsAll(eggTypeSel) and #eggTypeSel > 0 then
		local eggType = info.eggType or "Unknown"
		if not tableFind(eggTypeSel, eggType) then
			return false
		end
	end

	local areaSel = getSelectedList("SelectArea")
	if not listAllowsAll(areaSel) and #areaSel > 0 then
		local areaName, areaIndex = World.areaName(info)
		if not tableFind(areaSel, areaName) and not tableFind(areaSel, tostring(areaIndex)) then
			return false
		end
	end

	local minW = tonumber(getFlag("MinEggWeight", 0)) or 0
	if minW > 0 and info.weight < minW then
		return false
	end

	local minE = tonumber(getFlag("MinEarnings", 0)) or 0
	if minE > 0 and info.earnings < minE then
		return false
	end

	if getFlag("ColossalHunt", false) == true then
		local threshold = tonumber(getFlag("ColossalThreshold", 100000)) or 100000
		if info.weight < threshold then
			return false
		end
	end

	if getFlag("IgnoreFriends", true) == true then
		if eggIsFriends(info) then
			return false
		end
	end

	if getFlag("AvoidGuards", true) == true then
		local radius = tonumber(getFlag("GuardRadius", 40)) or 40
		if World.nearestGuardDistance(pos, true) < radius then
			return false
		end
	end

	return true
end

local function scoreEgg(info, playerPos)
	local distance = (playerPos - info.pos).Magnitude
	local mode = getDropdownValue("TargetPriority", "Rarest")
	if getFlag("PrioritizeRarity", true) == true then
		mode = "Rarest"
	end

	local base
	if mode == "Nearest" then
		base = -distance
	elseif mode == "Furthest" then
		base = distance
	elseif mode == "Biggest" then
		base = info.weight
	else
		base = getRarityRank(info.rarity or "Common") * 100000 - distance * 0.5
	end

	if getFlag("DistantEggTarget", false) ~= true and distance > MAX_LOCAL_RANGE then
		base = base - 1000000
	end

	if getFlag("PreferParasiteEggs", false) == true then
		local parasitePos = World.parasitePosition()
		if parasitePos and (parasitePos - info.pos).Magnitude < 80 then
			base = base + 50000
		end
	end
	return base
end

function Farm.pickBestEgg()
	local hrp = getHRP()
	if not hrp then
		return nil
	end
	local best, bestScore = nil, -math.huge
	for _, info in pairs(World.eggs) do
		if typeof(info.model) == "Instance" and info.pos then
			if Farm.passesFilters(info) then
				local score = scoreEgg(info, hrp.Position)
				if score > bestScore then
					best = info
					bestScore = score
				end
			end
		end
	end
	return best
end

function Farm.findDroppedEgg()
	for _, info in pairs(World.eggs) do
		if typeof(info.model) == "Instance" then
			local rec = World.eggRecord(info)
			if rec and tostring(rec.State) == "Dropped" then
				if Farm.passesFilters(info) then
					return info
				end
			end
		end
	end
	return nil
end

function Farm.findOwnDroppedEgg()
	for _, info in pairs(World.eggs) do
		if typeof(info.model) == "Instance" then
			local rec = World.eggRecord(info)
			if rec and tostring(rec.State) == "Dropped" and eggIsMine(info) then
				return info
			end
		end
	end
	return nil
end

local function maybeRareAlert(info)
	local rarity = info.rarity or "Common"
	local minRare = getDropdownValue("WebhookRareMin", "Epic")
	if getFlag("WebhookRare", false) == true and getRarityRank(rarity) >= getRarityRank(minRare) then
		local mention = Webhook.mentionForRarity(rarity)
		Webhook.send("Rare Egg Sniped!", ("Rarity: %s | %dkg | E/s: %d"):format(
			rarity,
			math.floor(info.weight or 0),
			math.floor(info.earnings or 0)
		), 0x9b59b6, mention)
	end
end

function Farm.placeEgg(uid)
	local _, cf = World.plotInfo()
	local hrp = getHRP()
	local worldPos = hrp and hrp.Position or (cf and cf.Position) or Vector3.zero
	local localCF
	if cf then
		localCF = cf:ToObjectSpace(CFrame.new(worldPos))
	end
	local ok = GameAPI.placeEgg(uid, localCF)
	if ok then
		return true
	end
	clickGuiButtonByText("place")
	clickGuiButtonByText("deposit")
	return false
end

function Farm.returnToBase()
	Farm.state = "Returning"
	Status.set("Carrying egg to base")
	local base = World.basePosition()
	if base then
		Movement.moveTo(base, { timeout = 90 })
	end
	local _, uid = findHeldEggTool()
	if uid then
		if getFlag("AutoPlace", true) == true then
			if Farm.placeEgg(uid) then
				Farm.stats.placed = Farm.stats.placed + 1
				Status.set("Placing egg")
			end
		end
		if findHeldEggTool() and getFlag("AutoDrop", false) == true then
			GameAPI.dropEgg()
		end
	end
	waitForNotHolding(2.5)
	if findHeldEggTool() then
		Status.set("Cannot release egg, pausing")
		Farm.cooldownUntil = os.clock() + 10
	else
		Watchdog.lastProgressAt = os.clock()
	end
	Farm.state = "Idle"
end

function Farm.trySteal(info)
	Farm.state = "ToEgg"
	Status.set("Moving to egg")
	local hrp = getHRP()
	if not hrp or not info.pos then
		return false
	end

	local goal = info.pos
	local delta = goal - hrp.Position
	if delta.Magnitude > 3 then
		goal = goal - delta.Unit * 3
		goal = Vector3.new(goal.X, info.pos.Y, goal.Z)
	end
	local result = Movement.moveTo(goal, { timeout = 60 })
	if result ~= "arrived" then
		if result == "stuck" then
			Status.set("Stuck, recovering")
			local base = World.basePosition()
			if base then
				Movement.startFastGlide(base, 500)
			end
			Farm.cooldownUntil = os.clock() + 5
		end
		return false
	end

	hrp = getHRP()
	if not hrp then
		return false
	end
	if getFlag("AvoidGuards", true) == true then
		local radius = tonumber(getFlag("GuardRadius", 40)) or 40
		if World.nearestGuardDistance(hrp.Position, true) < radius then
			Status.set("Guard chasing, skipping")
			if getFlag("ForestGuardBypass", true) == true then
				local base = World.basePosition()
				if base then
					Movement.startFastGlide(base, 600)
				end
				Farm.cooldownUntil = os.clock() + 5
			end
			return false
		end
	end

	Farm.state = "Carry"
	Status.set("Stealing")
	local prompt = World.findEggPrompt(info.model)
	if prompt then
		World.triggerPrompt(prompt)
	end
	if not waitForHeldEgg(2.5) then
		GameAPI.carryEgg(info.uid)
		waitForHeldEgg(2)
	end

	local held, uid = findHeldEggTool()
	if held then
		Farm.stats.steals = Farm.stats.steals + 1
		Farm.failStreak = 0
		Watchdog.lastProgressAt = os.clock()
		maybeRareAlert(info)
		Status.set("Stolen #" .. Farm.stats.steals)
		if getFlag("AutoPlace", true) == true then
			Farm.state = "Return"
			Farm.returnToBase()
		end
		return true
	end

	Farm.stats.fails = Farm.stats.fails + 1
	Farm.failStreak = Farm.failStreak + 1
	Status.set("Steal failed")
	if Farm.failStreak >= 3 then
		Farm.failStreak = 0
		Farm.cooldownUntil = os.clock() + 8
		local base = World.basePosition()
		if base then
			Movement.moveTo(base, { speed = 500, timeout = 60 })
		end
	end
	return false
end

local function farmStep()
	if getFlag("AutoSteal", true) ~= true then
		if Farm.state ~= "Idle" then
			Farm.state = "Idle"
		end
		return
	end
	local hrp = getHRP()
	if not hrp then
		Status.set("Waiting for character")
		return
	end
	local now = os.clock()
	if now < Farm.cooldownUntil then
		return
	end

	if getFlag("DragonEventSafe", true) == true and GameAPI.dragonEventActive() then
		Status.set("Dragon event active, paused")
		return
	end
	if getFlag("NightFarmSync", false) == true and GameAPI.inNightTransition() then
		Status.set("Night transition, paused")
		return
	end

	local held = findHeldEggTool()
	if held then
		Farm.state = "Return"
		Farm.returnToBase()
		return
	end

	if getFlag("AutoRecover", true) == true then
		local own = Farm.findOwnDroppedEgg()
		if own then
			Status.set("Recovering own egg")
			if GameAPI.carryEgg(own.uid) and waitForHeldEgg(2.5) then
				Farm.state = "Return"
				Farm.returnToBase()
				return
			end
		end
	end

	if getFlag("SnipeDropped", false) == true then
		local dropped = Farm.findDroppedEgg()
		if dropped then
			Farm.trySteal(dropped)
			return
		end
	end

	Farm.state = "Scout"
	World.refreshAllEggs()
	local target = Farm.pickBestEgg()
	if not target then
		Status.set("No matching eggs")
		return
	end
	Farm.trySteal(target)
	if not findHeldEggTool() then
		Farm.cooldownUntil = os.clock() + (tonumber(getFlag("StealCooldown", 1)) or 1)
	end
end
Farm.step = farmStep

-- spawn sniper: event-driven fast move (no teleport)
World.onEggSpawn = function(info)
	if getFlag("SpawnSniper", false) ~= true then
		return
	end
	if findHeldEggTool() or Movement.active then
		return
	end
	if not Farm.passesFilters(info) then
		return
	end
	local base = World.basePosition()
	local hrp = getHRP()
	if not hrp or not base then
		return
	end
	if (base - info.pos).Magnitude < 120 then
		return
	end
	task.spawn(function()
		Status.set("Spawn sniper: new egg")
		local result = Movement.moveTo(info.pos, { speed = 600, timeout = 25 })
		if result == "arrived" and not findHeldEggTool() then
			local prompt = World.findEggPrompt(info.model)
			if prompt then
				World.triggerPrompt(prompt)
			end
			if not waitForHeldEgg(2) then
				GameAPI.carryEgg(info.uid)
			end
			if findHeldEggTool() and getFlag("AutoPlace", true) == true then
				Farm.returnToBase()
			end
		end
	end)
end

-- hatch queue: uids of placed (growing) eggs found under the local plot
local function scanPlotForPlacedEggs()
	local uids = {}
	local folder = World.plotInfo()
	if not folder then
		return uids
	end
	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("Model") then
			local name = tostring(descendant.Name)
			if string.match(name, "^%x+$") then
				table.insert(uids, name)
			end
		end
	end
	return uids
end

local function hatchStep()
	if getFlag("AutoHatch", true) ~= true then
		return
	end
	-- finish queued hatches
	for i = #Farm.hatchQueue, 1, -1 do
		local entry = Farm.hatchQueue[i]
		if os.clock() >= entry.finishAt then
			table.remove(Farm.hatchQueue, i)
			local ok = GameAPI.finishHatch(entry.uid)
			if ok then
				Farm.stats.hatched = Farm.stats.hatched + 1
				notify("Hatch", "Finished hatch " .. entry.uid)
				Webhook.send("Egg Hatched", entry.uid, 0x22c55e)
			end
		end
	end
	-- find ready eggs under plot
	local uids = scanPlotForPlacedEggs()
	if #uids == 0 then
		clickGuiButtonByText("hatch")
		return
	end
	local uid = uids[((Farm.hatchIndex - 1) % #uids) + 1]
	Farm.hatchIndex = Farm.hatchIndex + 1
	local ok = GameAPI.hatchEgg(uid)
	if ok then
		table.insert(Farm.hatchQueue, { uid = uid, finishAt = os.clock() + 6 })
		Status.set("Hatching egg")
	end
end
Farm.hatchStep = hatchStep

-- sell / favorite (save-data driven)
function Farm.recommendedSpeed()
	local total, n = 0, 0
	local hrp = getHRP()
	if not hrp then
		return nil, 0
	end
	for _, info in pairs(World.eggs) do
		if info.pos then
			total = total + (info.pos - hrp.Position).Magnitude
			n = n + 1
		end
	end
	if n > 0 then
		local speed = math.floor((total / n) / 20)
		if speed < 40 then
			speed = 40
		end
		if speed > 2000 then
			speed = 2000
		end
		return speed, n
	end
	return nil, 0
end

local function sellStep()
	if getFlag("AutoSell", false) ~= true then
		return
	end
	local pets = World.collectPets()
	local minSellKG = tonumber(getFlag("SellBelowKG", 0)) or 0
	local sellRarities = getSelectedList("SellRarities")
	local keepAllMutated = getFlag("SellKeepAllMutated", false) == true
	local whitelist = getSelectedList("SellMutationWhitelist")
	local hasWhitelist = not listAllowsAll(whitelist) and #whitelist > 0
	local uids = {}
	for uid, p in pairs(pets) do
		local belowKG = minSellKG > 0 and p.weight < minSellKG
		local inRarityList = listAllowsAll(sellRarities) or tableFind(sellRarities, p.rarity) ~= nil
		if (belowKG or inRarityList) and not (keepAllMutated and p.mutation) then
			if not (hasWhitelist and p.mutation and tableFind(whitelist, p.mutation)) then
				table.insert(uids, uid)
			end
		end
	end
	if #uids > 0 then
		if GameAPI.sellPets(uids) then
			Status.set("Sold " .. #uids .. " pets")
			task.wait(1)
		end
	end
end
Farm.sellStep = sellStep

local function favoriteStep()
	if getFlag("AutoFavorite", false) ~= true then
		return
	end
	local pets = World.collectPets()
	local favRarities = getSelectedList("FavoriteRarities")
	local minKG = tonumber(getFlag("FavoriteMinKG", 0)) or 0
	local count = 0
	for uid, p in pairs(pets) do
		local inRarityList = listAllowsAll(favRarities) or tableFind(favRarities, p.rarity) ~= nil
		if (inRarityList or (minKG > 0 and p.weight >= minKG)) then
			if GameAPI.favoritePet(uid) then
				count = count + 1
			end
		end
	end
	if count > 0 then
		Status.set("Favorited " .. count .. " pets")
		task.wait(1)
	end
end
Farm.favoriteStep = favoriteStep


Progress.lastClaimAt = 0

local function claimStep()
	if getFlag("AutoClaimIndex", true) == true then
		if GameAPI.claimCodex() then
			Status.set("Index rewards claimed")
			task.wait(1)
		end
	end
	if getFlag("AutoClaimOffline", false) == true then
		if GameAPI.collectAway() then
			Status.set("Offline cash collected")
			task.wait(1)
		end
	end
end
Progress.claimStep = claimStep

local function treadmillStep()
	if getFlag("AutoTreadmill", true) ~= true then
		return
	end
	local model = World.treadmillModel()
	if not model then
		return
	end
	local part = model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
	if not part then
		return
	end
	local hrp = getHRP()
	if not hrp then
		return
	end
	local distance = (part.Position - hrp.Position).Magnitude
	if distance > 8 then
		if Movement.active then
			return
		end
		if getFlag("AntiTreadmill", true) == true then
			GameAPI.treadmillDoff()
		end
		Movement.moveTo(part.Position, { timeout = 30 })
		return
	end
	-- on treadmill: keep the "wear still" state alive
	GameAPI.treadmillWear()
end
Progress.treadmillStep = treadmillStep

local function treadmillUpgradeStep()
	if getFlag("AutoTreadmillUpgrade", false) ~= true then
		return
	end
	local id = World.treadmillId()
	if id and GameAPI.treadmillTierRaise(id) then
		Status.set("Treadmill upgraded: " .. id)
		task.wait(1)
	end
end
Progress.treadmillUpgradeStep = treadmillUpgradeStep

local function baseUpgradeStep()
	if getFlag("AutoBaseUpgrade", false) ~= true then
		return
	end
	local ok = GameAPI.baseUpgrade()
	if ok then
		Status.set("Base upgraded")
		task.wait(1)
	else
		clickGuiButtonByText("upgrade")
	end
end
Progress.baseUpgradeStep = baseUpgradeStep

local function equipBestStep(force)
	local wantPets = force == true or getFlag("AutoEquipBest", false) == true
	local wantBat = force == true or getFlag("AutoEquipBatBest", false) == true
	local wantTrail = force == true or getFlag("AutoEquipTrail", false) == true
	if not (wantPets or wantBat or wantTrail) then
		return
	end
	if wantPets and GameAPI.wearBestPet() then
		Status.set("Best pet equipped")
		task.wait(0.5)
	end
	-- best bat: highest-rarity bat in save data, worn via AskWearTool
	local pets = World.collectPets()
	local bestBat, bestRank = nil, 0
	for _, p in pairs(pets) do
		local isBat = false
		if p.mutation and string.find(string.lower(p.mutation), "bat", 1, true) then
			isBat = true
		end
		local uidType = string.find(string.lower(p.uid), "bat", 1, true)
		if isBat or uidType then
			local rank = Farm.getRarityRank(p.rarity)
			if rank > bestRank then
				bestRank = rank
				bestBat = p.uid
			end
		end
	end
	if wantBat and bestBat and GameAPI.wearTool(bestBat) then
		Status.set("Best bat equipped")
		task.wait(0.5)
	end
	if wantTrail and GameAPI.chooseTrail("Fastest") then
		Status.set("Best trail equipped")
		task.wait(0.5)
	end
end
Progress.equipBestStep = equipBestStep

local function buyBestStep()
	if getFlag("AutoBuyBest", false) ~= true then
		return
	end
	clickGuiButtonByText("buy")
end
Progress.buyBestStep = buyBestStep

Protection.traps = {}
Protection.lastTrapScan = 0
Protection.lastEvasionAt = 0
Protection.lastSwingAt = 0
Protection.lagbackStalls = 0
Protection.lagbackGraceUntil = os.clock() + 30

local function scanTraps(force)
	local now = os.clock()
	if not force and now - Protection.lastTrapScan < 4 then
		return Protection.traps
	end
	Protection.lastTrapScan = now
	local found = {}
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") or descendant:IsA("BasePart") then
			if string.find(string.lower(tostring(descendant.Name)), "trap", 1, true) then
				found[descendant] = true
			end
		end
	end
	Protection.traps = found
	return found
end

local function disarmStep()
	if getFlag("AutoDisarmTraps", false) ~= true then
		return
	end
	local count = 0
	for trap in pairs(scanTraps()) do
		if typeof(trap) == "Instance" then
			for _, descendant in ipairs(trap:GetDescendants()) do
				if descendant.ClassName == "ProximityPrompt" and descendant.HoldDuration < 9000 then
					pcall(function() descendant.HoldDuration = 9999 end)
					count = count + 1
				end
			end
			pcall(function() trap:SetAttribute("SAEDisarmed", true) end)
		end
	end
	if count > 0 then
		Status.set("Disarmed " .. count .. " trap prompts")
	end
end
Protection.disarmStep = disarmStep

local function evasionStep()
	if getFlag("AutoEvasion", true) ~= true then
		return
	end
	local now = os.clock()
	if now - Protection.lastEvasionAt < 2 then
		return
	end
	local hrp = getHRP()
	if not hrp then
		return
	end
	if getFlag("EvasionCarryOnly", false) == true and not findHeldEggTool() then
		return
	end
	local radius = tonumber(getFlag("EvasionRadius", 25)) or 25
	local threat = nil
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= client and player.Character then
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local d = (root.Position - hrp.Position).Magnitude
				if d < radius then
					threat = root
					break
				end
			end
		end
	end
	if threat then
		Protection.lastEvasionAt = now
		local away = hrp.Position - threat.Position
		if away.Y == 0 then
			away = away + Vector3.new(0, 1, 0)
		end
		away = away.Unit
		local dodgeH = tonumber(getFlag("DodgeHeight", 60)) or 60
		local escapeH = tonumber(getFlag("EscapeHeight", 60)) or 60
		local yBoost = 20
		if dodgeH > 0 then
			yBoost = math.clamp(15 + dodgeH * 0.35, 15, 60)
		end
		local d = (threat.Position - hrp.Position).Magnitude
		if d < radius * 0.6 and escapeH > 0 then
			yBoost = math.max(yBoost, math.clamp(15 + escapeH * 0.35, 15, 60))
		end
		local hum = getHumanoid()
		if hum then
			pcall(function()
				hrp.AssemblyLinearVelocity = Vector3.new(away.X * 10, yBoost, away.Z * 10)
			end)
		end
		Status.set("Evasive maneuver")
	end
end
Protection.evasionStep = evasionStep

local function batAuraStep()
	if getFlag("BatAura", false) ~= true then
		return
	end
	local hrp = getHRP()
	if not hrp then
		return
	end
	local range = tonumber(getFlag("AuraRange", 20)) or 20
	local delay = math.max(0.15, tonumber(getFlag("SwingDelay", 0.5)) or 0.5)
	local targetInRange = false
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= client and player.Character then
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - hrp.Position).Magnitude < range then
				targetInRange = true
				break
			end
		end
	end
	if not targetInRange then
		return
	end

	-- ensure a bat is equipped
	local char = getCharacter()
	local backpack = client and client:FindFirstChild("Backpack")
	local batTool = nil
	local function searchTools(container)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child.ClassName == "Tool" then
				if string.find(string.lower(tostring(child.Name)), "bat", 1, true)
					or child:GetAttribute("ItemType") == "Bat" then
					batTool = child
					return
				end
			end
		end
	end
	searchTools(char)
	if not batTool then
		searchTools(backpack)
	end
	if batTool then
		if batTool.Parent ~= char then
			local uid = batTool:GetAttribute("UID")
			if uid and not GameAPI.wearTool(uid) then
				pcall(function() batTool.Parent = char end)
			end
		end
		if os.clock() - Protection.lastSwingAt >= delay then
			Protection.lastSwingAt = os.clock()
			pcall(batTool.Activate, batTool)
		end
	end
end
Protection.batAuraStep = batAuraStep

local function safetyStep()
	local hum = getHumanoid()
	local hrp = getHRP()
	if getFlag("Immortality", false) == true and hum then
		if hum.Health <= 0 then
			pcall(function() hum.Health = 1 end)
		end
	end
	if getFlag("AntiRagdoll", true) == true and hum then
		if hum:GetState() == Enum.HumanoidStateType.Ragdoll then
			pcall(hum.ChangeState, hum, Enum.HumanoidStateType.GettingUp)
		end
	end
	if getFlag("AntiFling", true) == true and hrp then
		local v = hrp.AssemblyLinearVelocity
		if v.Magnitude > 250 then
			pcall(function()
				hrp.AssemblyLinearVelocity = Vector3.new(0, math.min(v.Y, 40), 0)
			end)
		end
	end
end
Protection.safetyStep = safetyStep

-- lagback monitor: one Heartbeat, cheap when healthy
local lagbackConn = RunService.Heartbeat:Connect(function(dt)
	if os.clock() < Protection.lagbackGraceUntil then
		return
	end
	if getFlag("LagbackRecovery", true) ~= true then
		return
	end
	local threshold = tonumber(getFlag("LagbackThreshold", 3)) or 3
	if dt > threshold then
		Protection.lagbackStalls = Protection.lagbackStalls + 1
		if Protection.lagbackStalls >= 3 then
			Protection.lagbackStalls = 0
			notify("Lagback", ("Detected %.1fs stall"):format(dt), "danger")
			if getFlag("LagbackRejoin", false) == true and not getFlag("AntiRejoin", false) then
				pcall(TeleportService.TeleportToPlaceInstance, TeleportService,
					game.PlaceId, game.JobId, client)
			end
		end
	else
		Protection.lagbackStalls = 0
	end
end)
track(lagbackConn, "Core")

Dispute.locked = nil
Dispute.lastAttemptAt = 0

local function disputeStep()
	if getFlag("AutoDispute", false) ~= true then
		Dispute.locked = nil
		return
	end
	if findHeldEggTool() or Movement.active then
		return
	end
	local hrp = getHRP()
	if not hrp then
		return
	end
	if os.clock() - Dispute.lastAttemptAt < 3 then
		return
	end

	local maxDist = tonumber(getFlag("DisputeMaxDistance", 300)) or 300
	local giveUp = tonumber(getFlag("DisputeGiveUp", 30)) or 30
	local rarSel = getSelectedList("DisputeRarities")

	local carriers = World.carriedEggsByOthers()
	local target = nil

	if Dispute.locked then
		local valid = false
		for _, c in ipairs(carriers) do
			if c.uid == Dispute.locked.uid then
				valid = true
				target = c
				break
			end
		end
		if not valid then
			Dispute.locked = nil
		end
	else
		for _, c in ipairs(carriers) do
			if c.uid then
				local root = c.player.Character:FindFirstChild("HumanoidRootPart")
				if root and (root.Position - hrp.Position).Magnitude <= maxDist then
					if listAllowsAll(rarSel) or tableFind(rarSel, c.rarity or "Common") then
						target = c
						break
					end
				end
			end
		end
	end

	if target and target.uid then
		local root = target.player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			if getFlag("DisputeLock", true) == true then
				if not Dispute.locked then
					Dispute.locked = { uid = target.uid, since = os.clock() }
				elseif os.clock() - Dispute.locked.since > giveUp then
					Dispute.locked = nil
					return
				end
			end
			Dispute.lastAttemptAt = os.clock()
			Status.set("Chasing disputed egg")
			local result = Movement.moveTo(root.Position, { timeout = math.min(giveUp, 30), speed = Movement.speed() })
			if result == "arrived" then
				GameAPI.carryEgg(target.uid)
			end
		end
	end
end
Dispute.step = disputeStep

Fusion.lastFuseAt = 0
Fusion.best = nil

function Fusion.scanTrios()
	local pets = World.collectPets()
	local byRarity = {}
	for _, p in pairs(pets) do
		byRarity[p.rarity] = byRarity[p.rarity] or {}
		table.insert(byRarity[p.rarity], p)
	end
	local best = nil
	for rarity, list in pairs(byRarity) do
		if #list >= 3 then
			local rank = Farm.getRarityRank(rarity)
			if not best or rank > Farm.getRarityRank(best.rarity) then
				best = { rarity = rarity, count = #list }
			end
		end
	end
	Fusion.best = best
	if best then
		labelUpdate(Fusion.statusLabel, ("Best trio: %s x%d"):format(best.rarity, best.count))
	else
		labelUpdate(Fusion.statusLabel, "No fusable trio (need 3x same rarity)")
	end
	return best
end

function Fusion.checkTrios()
	local best = Fusion.scanTrios()
	if best then
		notify("Fusion", ("Best trio: %s x%d"):format(best.rarity, best.count), "info")
	else
		notify("Fusion", "No fusable trio (need 3x same rarity)", "danger")
	end
end

function Fusion.scanFusion()
	local best = Fusion.scanTrios()
	if not best then
		notify("Fusion", "Scan complete — no fusable trio", "danger")
		return
	end
	if os.clock() - Fusion.lastFuseAt > 1 then
		Fusion.lastFuseAt = os.clock()
		local ok = GameAPI.fuse()
		if ok then
			notify("Fusion", ("Feeding %s trio"):format(best.rarity))
		else
			notify("Fusion", "Fuse remote failed — tried GUI fallback", "danger")
			clickGuiButtonByText("fuse")
		end
	end
end

local function fusionStep(forceFuse)
	local best = Fusion.scanTrios()
	if not best then
		return
	end
	local feedRarities = getSelectedList("FusionRarities")
	if not (listAllowsAll(feedRarities) or tableFind(feedRarities, best.rarity) ~= nil) then
		return
	end
	local fuseDelay = forceFuse == true and 1 or 30
	if (forceFuse == true or getFlag("AutoFuse", false) == true)
		and os.clock() - Fusion.lastFuseAt > fuseDelay then
		Fusion.lastFuseAt = os.clock()
		local ok = GameAPI.fuse()
		if ok then
			notify("Fusion", ("Feeding %s trio"):format(best.rarity))
			if getFlag("WebhookFuse", true) == true then
				Webhook.send("Fusion Started", ("Feeding %s trio"):format(best.rarity), 0xf59e0b)
			end
			task.wait(1)
		else
			clickGuiButtonByText("fuse")
		end
	end
end
Fusion.step = fusionStep

EventMod.active = false
EventMod.chestsClaimed = 0

local function eventStep()
	local model = World.parasiteModel()
	local wasActive = EventMod.active
	EventMod.active = model ~= nil
	if EventMod.active and not wasActive then
		notify("Event", "Monster event started!")
		if getFlag("WebhookChest", true) == true then
			Webhook.send("Monster Event", "Event started on this server", 0x3b82f6)
		end
	end
	labelUpdate(EventMod.statusLabel,
		EventMod.active and ("Monster Event ACTIVE — chests claimed: " .. EventMod.chestsClaimed)
		or "Monster Event inactive")
	if not EventMod.active then
		return
	end

	if getFlag("EventMonitor", true) == true then
		local pos = World.parasitePosition()
		local held, uid = findHeldEggTool()
		if held and uid and pos and not Movement.active then
			if getFlag("EventExcludeRare", true) == true then
				local heldRarity = held and held:GetAttribute("Rarity") or "Common"
				if Farm.getRarityRank(heldRarity) >= Farm.getRarityRank("Epic") then
					-- keep rares: go home instead
					local base = World.basePosition()
					if base then
						Movement.startFastGlide(base, 400)
					end
					return
				end
			end
			if (pos - (getHRP() and getHRP().Position or Vector3.zero)).Magnitude > 10 then
				Movement.moveTo(pos, { timeout = 30 })
			end
			GameAPI.dropEgg()
		end
	end

	if getFlag("AutoConsumeChest", true) == true then
		local ok, res = GameAPI.chestClaim()
		if ok and type(res) == "table" then
			if res.Success == true then
				EventMod.chestsClaimed = EventMod.chestsClaimed + 1
				if getFlag("WebhookChest", true) == true then
					Webhook.send("Monster Chest", ("Chest consumed (%d this session)"):format(EventMod.chestsClaimed), 0x22c55e)
				end
				task.wait(1)
			end
		end
	end
end
EventMod.step = eventStep

ServerHop.hops = 0

function ServerHop.listServers()
	local ok, servers = pcall(TeleportService.GetServerServers, TeleportService,
		game.PlaceId, 20, false)
	if ok and type(servers) == "table" and #servers > 0 then
		return servers
	end
	return nil
end

function ServerHop.hopToNext()
	local servers = ServerHop.listServers()
	if servers then
		for _, s in ipairs(servers) do
			if s and s.id and s.id ~= game.JobId then
				local ok = pcall(TeleportService.TeleportToPlaceInstance, TeleportService,
					game.PlaceId, s.id, client)
				if ok then
					return true
				end
			end
		end
	end
	return pcall(TeleportService.Teleport, TeleportService, game.PlaceId)
end

local function targetHopStep()
	if getFlag("AutoHopTarget", false) ~= true then
		return
	end
	local maxHops = tonumber(getFlag("MaxHops", 10)) or 10
	if ServerHop.hops >= maxHops then
		notify("Server Hop", "Max hops reached, stopping")
		Scheduler.stop("SAE_TargetHop")
		return
	end
	World.refreshAllEggs()
	local hopMinKG = tonumber(getFlag("HopMinKG", 0)) or 0
	local hopRarities = getSelectedList("HopRarities")
	local hopMutations = getSelectedList("HopMutations")
	local hopMutOnly = getFlag("HopMutatedOnly", false) == true
	local function hopMatches(info)
		if not info.pos then
			return false
		end
		if hopMinKG > 0 and info.weight < hopMinKG then
			return false
		end
		if not (listAllowsAll(hopRarities) or tableFind(hopRarities, info.rarity or "Common") ~= nil) then
			return false
		end
		if hopMutOnly and info.mutation == nil then
			return false
		end
		if not (listAllowsAll(hopMutations) or tableFind(hopMutations, info.mutation or "None") ~= nil) then
			return false
		end
		return true
	end
	local target = nil
	for _, info in pairs(World.eggs) do
		if hopMatches(info) then
			target = info
			break
		end
	end
	if target then
		notify("Server Hop", "Target found on this server!")
		if getFlag("WebhookHop", true) == true then
			Webhook.send("Server Hop", "Found server with matching eggs", 0x22c55e)
		end
		Scheduler.stop("SAE_TargetHop")
	else
		ServerHop.hops = ServerHop.hops + 1
		Status.set(("No target — hopping (%d/%d)"):format(ServerHop.hops, maxHops))
		notify("Server Hop", ("No matching eggs — hop %d/%d"):format(ServerHop.hops, maxHops))
		ServerHop.hopToNext()
	end
end
ServerHop.step = targetHopStep

function ServerHop.rejoinCurrent()
	return pcall(TeleportService.TeleportToPlaceInstance, TeleportService,
		game.PlaceId, game.JobId, client)
end

-- rejoin protection: persist hub state + loader URL in getgenv
function ServerHop.saveState()
	local ok = pcall(function()
		local env = getgenv()
		if type(env) == "table" then
			local flagCopy = {}
			if Library and type(Library.Flags) == "table" then
				for k, v in pairs(Library.Flags) do
					if type(k) == "string" then
						flagCopy[k] = v
					end
				end
			end
			env.SAE_HUB = {
				url = getFlag("LoaderURL", ""),
				flags = flagCopy,
				savedAt = os.time(),
			}
		end
	end)
	return ok
end

function ServerHop.restoreState()
	local ok = pcall(function()
		local env = getgenv()
		if type(env) == "table" and type(env.SAE_HUB) == "table" then
			local saved = env.SAE_HUB
			if Library and type(Library.Flags) == "table" then
				for k, v in pairs(saved.flags or {}) do
					if type(k) == "string" then
						Library.Flags[k] = v
					end
				end
			end
			if typeof(saved.url) == "string" and saved.url ~= "" then
				setFlag("LoaderURL", saved.url)
			end
			return true
		end
	end)
	return ok
end


GameAPI.init()

Esp.boxes = {}
Esp.labels = {}
Esp.tracers = {}
Esp.folder = nil
local MAX_ESP_TARGETS = 60

local RARITY_COLORS = {
	Common = Color3.fromRGB(160, 160, 160),
	Uncommon = Color3.fromRGB(90, 200, 90),
	Rare = Color3.fromRGB(80, 140, 255),
	Epic = Color3.fromRGB(160, 80, 255),
	Legendary = Color3.fromRGB(255, 150, 40),
	Mythic = Color3.fromRGB(255, 90, 60),
	Mythical = Color3.fromRGB(255, 70, 50),
	Divine = Color3.fromRGB(255, 50, 50),
	Celestial = Color3.fromRGB(255, 230, 90),
	Secret = Color3.fromRGB(255, 120, 200),
	Eternal = Color3.fromRGB(90, 220, 255),
	Limited = Color3.fromRGB(240, 240, 240),
}
local function rarityColor(r)
	return RARITY_COLORS[r] or Color3.fromRGB(180, 180, 180)
end
Esp.rarityColor = rarityColor

function Esp.ensureFolder()
	if Esp.folder and Esp.folder.Parent then
		return Esp.folder
	end
	local f = Instance.new("Folder")
	f.Name = "SAEHubFX"
	local ok = pcall(function() f.Parent = Workspace.Terrain end)
	if not f.Parent then
		pcall(function() f.Parent = Workspace end)
	end
	Esp.folder = f
	return f
end

local function ensureBox(model, color, keep)
	local existing = Esp.boxes[model]
	if existing then
		existing.FillColor = color
		keep[model] = true
		return existing
	end
	local h = Instance.new("Highlight")
	h.FillColor = color
	h.FillTransparency = 0.5
	h.OutlineColor = color
	h.OutlineTransparency = 0.4
	h.DepthMode = Enum.HighlightDepthMode.Onion
	local ok = pcall(function() h.Parent = model end)
	if not ok then
		h:Destroy()
		return nil
	end
	Esp.boxes[model] = h
	keep[model] = true
	return h
end

local function ensureLabel(model)
	local existing = Esp.labels[model]
	if existing then
		return existing
	end
	local label = Instance.new("BillboardGui")
	label.Size = UDim2.new(0, 240, 0, 44)
	label.AlwaysOnTop = true
	label.StudsOffset = Vector3.new(0, 2.5, 0)
	label.Adornee = model
	label.LightInfluence = 0
	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0
	text.Font = Enum.Font.GothamBold
	text.TextSize = 14
	text.Text = "..."
	text.Parent = label
	local ok = pcall(function() label.Parent = model end)
	if not ok then
		label:Destroy()
		return nil
	end
	Esp.labels[model] = { gui = label, text = text }
	return Esp.labels[model]
end

local function ensureTracer(model, color)
	local existing = Esp.tracers[model]
	if existing then
		existing.Color = color
		return existing
	end
	local line = Instance.new("Line")
	line.Thickness = 2
	line.Color = color
	local ok = pcall(function() line.Parent = Esp.ensureFolder() end)
	if not ok then
		line:Destroy()
		return nil
	end
	Esp.tracers[model] = line
	return line
end

local function espPassesEgg(info, ctx)
	local pos = info.pos
	if not pos then
		return false
	end
	if (pos - ctx.playerPos).Magnitude > ctx.maxDist then
		return false
	end
	local rarity = info.rarity or "Common"
	if Farm.getRarityRank(rarity) < Farm.getRarityRank(ctx.minRarity) then
		return false
	end
	if ctx.minKG > 0 and info.weight < ctx.minKG then
		return false
	end
	if ctx.minE > 0 and info.earnings < ctx.minE then
		return false
	end
	if not listAllowsAll(ctx.mutSel) and #ctx.mutSel > 0 then
		local mut = info.mutation
		if mut == nil then
			if not tableFind(ctx.mutSel, "None") then
				return false
			end
		elseif not tableFind(ctx.mutSel, mut) then
			return false
		end
	end
	if not listAllowsAll(ctx.areaSel) and #ctx.areaSel > 0 then
		local areaName = World.areaName(info)
		if not tableFind(ctx.areaSel, areaName) then
			return false
		end
	end
	return true
end

function Esp.prune(keep)
	for model, h in pairs(Esp.boxes) do
		if not keep[model] then
			pcall(function() h:Destroy() end)
			Esp.boxes[model] = nil
		end
	end
	for model, l in pairs(Esp.labels) do
		if not keep[model] then
			pcall(function() l.gui:Destroy() end)
			Esp.labels[model] = nil
		end
	end
	for model, line in pairs(Esp.tracers) do
		if not keep[model] then
			pcall(function() line:Destroy() end)
			Esp.tracers[model] = nil
		end
	end
end

function Esp.clear()
	Esp.prune({})
end

function Esp.step()
	local eggOn = getFlag("EggEsp", false) == true
	local plotOn = getFlag("PlotEsp", false) == true
	if not eggOn and not plotOn then
		Esp.clear()
		return
	end
	World.refreshAllEggs()
	local ctx = {
		playerPos = (getHRP() and getHRP().Position) or Vector3.zero,
		maxDist = tonumber(getFlag("EspMaxDistance", 800)) or 800,
		minRarity = getDropdownValue("EspMinRarity", "Common"),
		minKG = tonumber(getFlag("EspMinKG", 0)) or 0,
		minE = tonumber(getFlag("EspMinEarnings", 0)) or 0,
		mutSel = getSelectedList("EspMutations"),
		areaSel = getSelectedList("EspAreas"),
		showTaken = getFlag("EspShowTaken", true) == true,
	}
	local keep = {}
	if eggOn then
		local count = 0
		for _, info in pairs(World.eggs) do
			if count >= MAX_ESP_TARGETS then
				break
			end
			if typeof(info.model) == "Instance" and info.pos and espPassesEgg(info, ctx) then
				count = count + 1
				local color = rarityColor(info.rarity or "Common")
				local box = ensureBox(info.model, color, keep)
				if box then
					local label = ensureLabel(info.model)
					if label then
						local dist = math.floor((info.pos - ctx.playerPos).Magnitude)
						local state = ""
						local rec = World.eggRecord(info)
						if rec and rec.State then
							state = tostring(rec.State)
						end
						local marker = ""
						if ctx.showTaken then
							if state == "Carried" or state == "Held" then
								marker = "  [TAKEN]"
							elseif state == "Dropped" then
								marker = "  [DROPPED]"
							end
						end
						label.text.Text = string.format("%s %dkg %dm%s",
							tostring(info.rarity or "Common"),
							math.floor(info.weight or 0),
							dist, marker)
					end
					if getFlag("EspTracers", false) == true then
						local line = ensureTracer(info.model, color)
						if line then
							local cam = Workspace.CurrentCamera
							local camPos = cam and cam.CFrame.Position or ctx.playerPos
							line.PointA = info.pos + Vector3.new(0, 2, 0)
							line.PointB = camPos + Vector3.new(0, -500, 0)
						end
					end
				end
			end
		end
	end
	if plotOn then
		local folder = World.plotInfo()
		if folder then
			ensureBox(folder, Color3.fromRGB(90, 220, 90), keep)
		end
	end
	Esp.prune(keep)
end

local blackScreenGui = nil

function ConfigMod.setBlackScreen(enabled)
	if enabled then
		if not blackScreenGui or not blackScreenGui.Parent then
			local sg = Instance.new("ScreenGui")
			sg.Name = "SAEBlackScreen"
			sg.DisplayOrder = 2147483646
			sg.IgnoreGuiInset = true
			sg.ResetOnSpawn = false
			local f = Instance.new("Frame")
			f.Size = UDim2.new(1, 0, 1, 0)
			f.BackgroundColor3 = Color3.new(0, 0, 0)
			f.BorderSizePixel = 0
			f.Parent = sg
			local ok = pcall(function() sg.Parent = resolveUiParent() end)
			if not sg.Parent then
				pcall(function() sg.Parent = CoreGui end)
			end
			blackScreenGui = sg
		end
		blackScreenGui.Enabled = true
	else
		if blackScreenGui then
			blackScreenGui.Enabled = false
		end
	end
end

function ConfigMod.applyFps()
	local cap = tonumber(getFlag("FpsCap", 0)) or 0
	if Rendering then
		pcall(function() Rendering.FramerateLimit = cap > 0 and cap or 240 end)
	end
end

function ConfigMod.checkFpsCapSupport()
	if not Rendering then
		notify("Config", "Rendering service unavailable on this executor", "danger")
		return
	end
	local cap = tonumber(getFlag("FpsCap", 0)) or 0
	local test = cap > 0 and cap or 30
	local ok = pcall(function()
		Rendering.FramerateLimit = test
	end)
	pcall(function()
		Rendering.FramerateLimit = 240
	end)
	ConfigMod.applyFps()
	if ok then
		notify("Config", "FPS cap supported — applied " .. (cap > 0 and cap or "off"), "info")
	else
		notify("Config", "FPS cap not supported on this executor", "danger")
	end
end

function ConfigMod.applyOptimization()
	ConfigMod.applyFps()
	local method = getDropdownValue("OptimizationMethod", "Balanced")
	if Lighting then
		if method == "Maximum FPS" then
			pcall(function() Lighting.LightsLevel = 0 end)
			pcall(function() Lighting.TexturesLevel = 1 end)
			pcall(function() Lighting.ShadowsLevel = 0 end)
		elseif method == "High Performance" then
			pcall(function() Lighting.LightsLevel = 1 end)
			pcall(function() Lighting.TexturesLevel = 2 end)
			pcall(function() Lighting.ShadowsLevel = 1 end)
		else
			pcall(function() Lighting.LightsLevel = 2 end)
			pcall(function() Lighting.TexturesLevel = 3 end)
			pcall(function() Lighting.ShadowsLevel = 2 end)
		end
	end
	if method == "Maximum FPS" then
		ConfigMod.setFpsBoost(true)
	end
end

function ConfigMod.setFpsBoost(enabled)
	if not enabled then
		return
	end
	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function() part.Material = Enum.Material.SmoothPlastic end)
		elseif part:IsA("ParticleEmitter") then
			pcall(function() part.Enabled = false end)
		elseif part:IsA("Beam") then
			pcall(function() part.Enabled = false end)
		end
	end
end

local StatsLabel = nil
local HomeStatsLabel = nil
local RecSpeedLabel = nil

function ConfigMod.bindLabels(homeLabel, statsLabel, recSpeedLabel)
	HomeStatsLabel = homeLabel
	StatsLabel = statsLabel
	RecSpeedLabel = recSpeedLabel
end

local FrameCount = 0
local FrameFps = 0
local PingSamples = {}

track(RunService.Heartbeat:Connect(function()
	FrameCount = FrameCount + 1
end), "Core")

local function samplePing()
	local ok, tracker = pcall(function()
		return ReplicatedStorage:FindFirstChild("ClientTracker")
			or (game:GetService("ReplicatedFirst") and game:GetService("ReplicatedFirst"):FindFirstChild("ClientTracker"))
	end)
	if ok and typeof(tracker) == "Instance" then
		local ok2, ping = pcall(tracker.GetAttribute, tracker, "CurrentPing")
		if ok2 and type(ping) == "number" and ping > 0 then
			return ping
		end
	end
	return nil
end

local function pingCv()
	local n = #PingSamples
	if n < 2 then
		return 0
	end
	local sum = 0
	for _, p in ipairs(PingSamples) do
		sum = sum + p
	end
	local mean = sum / n
	local sq = 0
	for _, p in ipairs(PingSamples) do
		sq = sq + (p - mean) * (p - mean)
	end
	local stdev = math.sqrt(sq / n)
	if mean <= 0 then
		return 0
	end
	return math.floor(stdev / mean * 100)
end

local function updatePill()
	FrameFps = math.floor(FrameCount / 2)
	FrameCount = 0
	local ping = samplePing()
	if ping then
		table.insert(PingSamples, ping)
		if #PingSamples > 10 then
			table.remove(PingSamples, 1)
		end
	end
	local sumPing = 0
	for _, p in ipairs(PingSamples) do
		sumPing = sumPing + p
	end
	local meanPing = #PingSamples > 0 and sumPing / #PingSamples or 0
	local hrp = getHRP()
	local walkSpeed = 16
	local hum = hrp and hrp:FindFirstChildOfClass("Humanoid")
	if hum then
		walkSpeed = hum.WalkSpeed
	end
	local pill = string.format(
		"TIME: %s | FPS: %d | PING: %s (%d%%CV)",
		fmtDuration(os.clock() - Watchdog.sessionStart),
		FrameFps,
		#PingSamples > 0 and string.format("%.1f", meanPing) or "--",
		pingCv())
	labelUpdate(HomeStatsLabel, pill)
	labelUpdate(StatsLabel, pill)
	local rec, n = Farm.recommendedSpeed()
	if rec then
		local limit = math.clamp(math.floor(rec * 1.15), 40, 2000)
		local below = limit - rec
		labelUpdate(RecSpeedLabel, string.format("%d studs/s\nFPS %d | Ping %s ms | WalkSpeed %d\n%d below the limit.",
			rec, FrameFps, #PingSamples > 0 and string.format("%.0f", meanPing) or "--", math.floor(walkSpeed), below))
	else
		labelUpdate(RecSpeedLabel, "No eggs measured yet")
	end
end

local function countEggs()
	local n = 0
	for _ in pairs(World.eggs) do
		n = n + 1
	end
	return n
end

local function countGuards()
	local total, chasing = 0, 0
	for _, info in pairs(World.scanGuards()) do
		total = total + 1
		if info.state == "Chasing" then
			chasing = chasing + 1
		end
	end
	return total, chasing
end

local function watchdogStep()
	updatePill()
	local hrp = getHRP()
	if not hrp then
		return
	end
	if hrp.Position.Y < -80 then
		Status.set("Fallen — recovering")
		local base = World.basePosition()
		if base then
			Movement.startFastGlide(base + Vector3.new(0, 20, 0), 800)
		end
		Watchdog.lastProgressAt = os.clock() + 30
		return
	end
	local hum = getHumanoid()
	if hum and hum.Health <= 0 and getFlag("Immortality", false) ~= true then
		return
	end
	if getFlag("AutoSteal", true) ~= true then
		return
	end
	local now = os.clock()
	local stuckTimeout = tonumber(getFlag("StuckTimeout", 120)) or 120
	if findHeldEggTool() or now - Watchdog.lastProgressAt < stuckTimeout then
		return
	end
	if getFlag("AutoRejoin", true) == true
		and getFlag("AntiRejoin", false) ~= true
		and now > Watchdog.rejoinCooldown then
		Watchdog.rejoinCooldown = now + (tonumber(getFlag("RejoinDelay", 180)) or 180)
		Status.set("Stuck — rejoining server")
		ServerHop.rejoinCurrent()
		return
	end
	Status.set("Stuck — recovering at base")
	Movement.cancel()
	local base = World.basePosition()
	if base then
		Movement.moveTo(base, { speed = 600, timeout = 60 })
	end
	Farm.cooldownUntil = os.clock() + 5
	Watchdog.lastProgressAt = os.clock() + 30
end

local debugGui = nil
local DebugLabel = nil

local function debugStep()
	if not debugGui or not debugGui.Enabled or not DebugLabel then
		return
	end
	local M = GameAPI.Modules
	local lines = {}
	table.insert(lines, ("Mods — EggState:%s PlotState:%s BaseUpgrade:%s Remotes:%s Networking:%s"):format(
		type(M.EggState) == "table" and "Y" or "N",
		type(M.PlotState) == "table" and "Y" or "N",
		type(M.BaseUpgrade) == "table" and "Y" or "N",
		type(M.Remotes) == "table" and "Y" or "N",
		typeof(GameAPI.networking) == "Instance" and "Y" or "N"))
	local guards, chasing = countGuards()
	table.insert(lines, ("Eggs:%d  Guards:%d (chasing:%d)  Plot:%s"):format(
		countEggs(), guards, chasing,
		World.plotFolder and "found" or "MISSING"))
	local untilEnd = GameAPI.secondsUntilPhaseEnd()
	table.insert(lines, ("Phase:%s (%ss to end)  DragonEvent:%s"):format(
		GameAPI.isNight() and "Night" or "Day",
		untilEnd and tostring(math.floor(untilEnd)) or "?",
		GameAPI.dragonEventActive() and "ACTIVE" or "off"))
	table.insert(lines, ("State:%s | Steals:%d Fails:%d | %s"):format(
		Farm.state, Farm.stats.steals, Farm.stats.fails, Status.text))
	local n = 0
	local activeTags = {}
	for tag in pairs(Scheduler.active) do
		n = n + 1
		if n <= 12 then
			table.insert(activeTags, tag)
		end
	end
	table.insert(lines, ("Tasks active:%d %s"):format(n, table.concat(activeTags, ", ")))
	DebugLabel.Text = table.concat(lines, "\n")
end

local function setDebugConsole(enabled)
	if enabled then
		if not debugGui then
			debugGui = Instance.new("ScreenGui")
			debugGui.Name = "SAEDebug"
			debugGui.ResetOnSpawn = false
			local frame = Instance.new("Frame")
			frame.Position = UDim2.new(0, 8, 0, 40)
			frame.Size = UDim2.new(0, 360, 0, 220)
			frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
			frame.BackgroundTransparency = 0.1
			local scroll = Instance.new("ScrollingFrame")
			scroll.Position = UDim2.fromScale(0, 0)
			scroll.Size = UDim2.fromScale(1, 1)
			scroll.BackgroundTransparency = 1
			scroll.BorderSizePixel = 0
			scroll.ScrollBarThickness = 4
			DebugLabel = Instance.new("TextLabel")
			DebugLabel.Position = UDim2.new(0, 6, 0, 4)
			DebugLabel.Size = UDim2.new(1, -14, 0, 300)
			DebugLabel.BackgroundTransparency = 1
			DebugLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
			DebugLabel.Font = Enum.Font.Code
			DebugLabel.TextXAlignment = Enum.TextXAlignment.Left
			DebugLabel.TextYAlignment = Enum.TextYAlignment.Top
			DebugLabel.TextSize = 12
			DebugLabel.Text = "..."
			DebugLabel.Parent = scroll
			scroll.Parent = frame
			frame.Parent = debugGui
			local ok = pcall(function() debugGui.Parent = resolveUiParent() end)
			if not debugGui.Parent then
				pcall(function() debugGui.Parent = CoreGui end)
			end
		end
		debugGui.Enabled = true
		toggleTask("SAE_Debug", true, 2, debugStep, 0)
	else
		if debugGui then
			debugGui.Enabled = false
		end
		Scheduler.stop("SAE_Debug")
	end
end

local antiAfkConn = nil
local function setAntiAfk(enabled)
	if antiAfkConn then
		antiAfkConn:Disconnect()
		antiAfkConn = nil
	end
	if not enabled or not client or not VirtualUser then
		return
	end
	antiAfkConn = track(client.Idled:Connect(function()
		local cam = Workspace.CurrentCamera
		local cf = cam and cam.CFrame or CFrame.new()
		VirtualUser:Button2Down(Vector2.new(0, 0), cf)
		task.wait(1)
		VirtualUser:Button2Up(Vector2.new(0, 0), cf)
	end), "Core")
end
setAntiAfk(getFlag("AntiAfk", true) == true)

local infJumpConn = nil
local function setInfiniteJump(enabled)
	if infJumpConn then
		infJumpConn:Disconnect()
		infJumpConn = nil
	end
	if not enabled or not UserInputService then
		return
	end
	infJumpConn = track(UserInputService.JumpRequest:Connect(function()
		local hrp = getHRP()
		local hum = getHumanoid()
		if not hrp or not hum then
			return
		end
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
		pcall(hum.ChangeState, hum, Enum.HumanoidStateType.Jumping)
	end), "SAE_InfJump")
end
setInfiniteJump(getFlag("InfiniteJump", false) == true)

local function setWalkSpeedEnabled(enabled)
	if enabled then
		toggleTask("SAE_WalkSpeed", true, 1, function() applyWalkSpeed() end)
	else
		toggleTask("SAE_WalkSpeed", false, 1, nil)
	end
end
setWalkSpeedEnabled(getFlag("WalkSpeedEnabled", false) == true)

local function setJumpPowerEnabled(enabled)
	if enabled then
		toggleTask("SAE_JumpPower", true, 1, function() applyJumpPower() end)
	else
		toggleTask("SAE_JumpPower", false, 1, nil)
	end
end
setJumpPowerEnabled(getFlag("JumpPowerEnabled", false) == true)

local charConn = Players.LocalPlayer.CharacterAdded:Connect(function()
	Farm.state = "Idle"
	Movement.cancel()
	World.treadmill = nil
	applyWalkSpeed()
	applyJumpPower()
end)
track(charConn, "Core")

local function stopEverything()
	Scheduler.stopAll()
	Movement.cancel()
	disconnectAllExcept("Core")
	Esp.clear()
	World.restorePromptDurations()
	setAntiAfk(getFlag("AntiAfk", true) == true)
	notify("Hub", "All features stopped", "info")
	Status.set("Stopped")
end

pcall(function()
	if game and type(game.BindToClose) == "function" then
		game:BindToClose(function()
			if getFlag("WebhookDisconnect", true) == true then
				Webhook.send("Disconnected", "Hub lost connection / closed", 0xef4444)
			end
		end)
	end
end)

if getFlag("AutoLoadConfig", false) == true then
	ServerHop.restoreState()
end

ConfigMod.applyOptimization()
World.ensureEggFolder()

local function bootDefaults()
	if getFlag("AutoSteal", false) == true then
		toggleTask("SAE_Farm", true, 0.5, Farm.step)
	end
	if getFlag("AutoHatch", false) == true then
		toggleTask("SAE_Hatch", true, 3, Farm.hatchStep)
	end
	if getFlag("AutoSell", false) == true then
		toggleTask("SAE_Sell", true, 6, Farm.sellStep)
	end
	if getFlag("AutoFavorite", false) == true then
		toggleTask("SAE_Fav", true, 10, Farm.favoriteStep)
	end
	if getFlag("AutoClaimIndex", false) == true then
		toggleTask("SAE_Claim", true, 30, Progress.claimStep)
	end
	if getFlag("AutoClaimOffline", false) == true then
		toggleTask("SAE_ClaimOffline", true, 60, Progress.claimStep)
	end
	if getFlag("AutoTreadmill", false) == true then
		toggleTask("SAE_Treadmill", true, 5, Progress.treadmillStep)
	end
	if getFlag("AutoTreadmillUpgrade", false) == true then
		toggleTask("SAE_TreadmillUp", true, 15, Progress.treadmillUpgradeStep)
	end
	if getFlag("AutoBaseUpgrade", false) == true then
		toggleTask("SAE_BaseUp", true, 20, Progress.baseUpgradeStep)
	end
	if getFlag("AutoEquipBest", false) == true then
		toggleTask("SAE_Equip", true, 30, Progress.equipBestStep)
	end
	if getFlag("AutoEquipTrail", false) == true then
		toggleTask("SAE_EquipTrail", true, 30, Progress.equipBestStep)
	end
	if getFlag("AutoEquipBatBest", false) == true then
		toggleTask("SAE_EquipBat", true, 30, Progress.equipBestStep)
	end
	if getFlag("AutoDisarmTraps", false) == true then
		toggleTask("SAE_TrapDisarm", true, 4, Protection.disarmStep)
	end
	if getFlag("AutoEvasion", false) == true then
		toggleTask("SAE_Evasion", true, 0.5, Protection.evasionStep)
	end
	if getFlag("BatAura", false) == true then
		toggleTask("SAE_BatAura", true, 0.3, Protection.batAuraStep)
	end
	if getFlag("AntiRagdoll", false) == true then
		toggleTask("SAE_Safety", true, 0.2, Protection.safetyStep)
	end
	if getFlag("AutoDispute", false) == true then
		toggleTask("SAE_Dispute", true, 1, Dispute.step)
	end
	if getFlag("EggEsp", false) == true then
		toggleTask("SAE_Esp", true, 0.5, Esp.step)
	end
	if getFlag("AutoFuse", false) == true then
		toggleTask("SAE_Fusion", true, 5, Fusion.step)
	end
	if getFlag("EventMonitor", false) == true then
		toggleTask("SAE_Event", true, 3, EventMod.step)
	end
	if getFlag("AutoHopTarget", false) == true then
		toggleTask("SAE_TargetHop", true, 25, ServerHop.step)
	end
	if getFlag("Watchdog", false) == true then
		toggleTask("SAE_Watchdog", true, 2, watchdogStep)
	end
end
bootDefaults()


local MUTATION_OPTIONS = { "All", "None", "Golden", "Silver", "Rainbow" }
local RARITY_OPTIONS = Farm.rarityOrder
local RARITY_MULTI = { "All" }
for _, name in ipairs(RARITY_OPTIONS) do
	table.insert(RARITY_MULTI, name)
end
local AREA_OPTIONS = { "All" }
for _, name in ipairs(World.areaNames) do
	table.insert(AREA_OPTIONS, name)
end
for i = 9, 10 do
	table.insert(AREA_OPTIONS, "Area " .. i)
end

local function addIntervalToggle(section, cfg)
	section:createToggle({
		Name = cfg.Name,
		Description = cfg.Description,
		Warning = cfg.Warning,
		Flag = cfg.Flag or false,
		flagName = cfg.flagName,
		Callback = function(enabled)
			toggleTask(cfg.tag, enabled, cfg.delay, cfg.Step, cfg.jitter or 0.15)
		end,
	})
end

local HomeSection = ui:CreateSection("Home")
local FarmSection = ui:CreateSection("Farm")
local ProgressSection = ui:CreateSection("Progress")
local ProtectionSection = ui:CreateSection("Protection")
local DisputeSection = ui:CreateSection("Dispute")
local EspSection = ui:CreateSection("ESPs")
local FusionSection = ui:CreateSection("Fusions")
local EventSection = ui:CreateSection("Event")
local HopSection = ui:CreateSection("Server Hop")
local WebhookSection = ui:CreateSection("Webhook")
local ConfigSection = ui:CreateSection("Config")

-- Home
HomeSection:createLabel({
	Name = "Status",
	Special = true,
	flagName = "saeHomeStats",
})
HomeSection:createLabel({
	Name = "Idle",
	Special = true,
	flagName = "saeFarmStatus",
})
HomeSection:createButton({
	Name = "Claim Now (Index + Offline + Group Perk)",
	Callback = function()
		Progress.claimStep(true)
	end,
})
HomeSection:createButton({
	Name = "Rejoin Server",
	Callback = function()
		ServerHop.rejoinCurrent()
	end,
})

-- Farm
FarmSection:createLabel({
	Name = "Filters",
	Special = true,
})
FarmSection:createInputBox({
	Name = "Min KG",
	flagName = "MinEggWeight",
	Flag = "0",
	Callback = function() end,
})
FarmSection:createInputBox({
	Name = "Min Earnings",
	Description = "in millions per second – type 10 for 10M/s",
	flagName = "MinEarnings",
	Flag = "",
	Callback = function() end,
})
FarmSection:createDropdown({
	Name = "Rarities",
	flagName = "SelectRarity",
	Flag = { "All" },
	List = RARITY_MULTI,
	multi = true,
	Callback = function() end,
})
FarmSection:createDropdown({
	Name = "Mutations",
	flagName = "SelectMutation",
	Flag = { "All" },
	List = MUTATION_OPTIONS,
	multi = true,
	Callback = function() end,
})
FarmSection:createDropdown({
	Name = "Areas",
	flagName = "SelectArea",
	Flag = { "All" },
	List = AREA_OPTIONS,
	multi = true,
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Mutated Only",
	Flag = false,
	flagName = "MutatedOnly",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Colossal Hunt",
	Flag = false,
	flagName = "ColossalHunt",
	Callback = function() end,
})
FarmSection:createSlider({
	Name = "Colossal Threshold (kg)",
	flagName = "ColossalThreshold",
	value = 100000,
	minValue = 10000,
	maxValue = 1000000,
	Callback = function() end,
})
FarmSection:createLabel({
	Name = "Farm",
	Special = true,
})
FarmSection:createLabel({
	Name = "No eggs measured yet",
	Special = true,
	flagName = "saeRecSpeed",
})
FarmSection:createButton({
	Name = "Apply Recommended Speed",
	Callback = function()
		local rec = Farm.recommendedSpeed()
		if rec then
			setFlag("TweenSpeed", rec)
			notify("Farm", ("Recommended speed applied: %d studs/s"):format(rec), "info")
		else
			notify("Farm", "No eggs to measure", "danger")
		end
	end,
})
FarmSection:createDropdown({
	Name = "Farm Mode",
	flagName = "FarmMode",
	Flag = { "Ground Walk (recommended)" },
	List = { "Ground Walk (recommended)", "Glide", "Smart Tween" },
	Callback = function() end,
})
FarmSection:createSlider({
	Name = "Tween Speed",
	flagName = "TweenSpeed",
	value = 700,
	minValue = 16,
	maxValue = 2000,
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Smart Tween",
	Flag = false,
	flagName = "SmartTween",
	Callback = function() end,
})
addIntervalToggle(FarmSection, {
	Name = "Auto Steal",
	flagName = "AutoSteal",
	tag = "SAE_Farm",
	delay = 0.5,
	Step = Farm.step,
	Flag = false,
})
FarmSection:createToggle({
	Name = "Auto Place",
	Flag = false,
	flagName = "AutoPlace",
	Callback = function() end,
})
addIntervalToggle(FarmSection, {
	Name = "Auto Hatch",
	flagName = "AutoHatch",
	tag = "SAE_Hatch",
	delay = 3,
	Step = Farm.hatchStep,
	Flag = false,
})
FarmSection:createLabel({
	Name = "Sell",
	Special = true,
})
FarmSection:createDropdown({
	Name = "Sell These Rarities",
	flagName = "SellRarities",
	Flag = { "Common", "Uncommon", "Rare", "Epic" },
	List = RARITY_MULTI,
	multi = true,
	Callback = function() end,
})
FarmSection:createInputBox({
	Name = "Sell Below KG",
	flagName = "SellBelowKG",
	Flag = "0",
	Callback = function() end,
})
FarmSection:createDropdown({
	Name = "Keep Mutations",
	flagName = "SellMutationWhitelist",
	Flag = { "All" },
	List = MUTATION_OPTIONS,
	multi = true,
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Keep All Mutated",
	Flag = false,
	flagName = "SellKeepAllMutated",
	Callback = function() end,
})
addIntervalToggle(FarmSection, {
	Name = "Auto Sell",
	flagName = "AutoSell",
	tag = "SAE_Sell",
	delay = 6,
	Step = Farm.sellStep,
})
FarmSection:createLabel({
	Name = "Auto Favorite",
	Special = true,
})
FarmSection:createDropdown({
	Name = "Favorite These Rarities",
	flagName = "FavoriteRarities",
	Flag = { "Legendary", "Mythic", "Mythical", "Divine", "Celestial", "Secret", "Eternal", "Limited" },
	List = RARITY_MULTI,
	multi = true,
	Callback = function() end,
})
FarmSection:createInputBox({
	Name = "Favorite Above KG",
	flagName = "FavoriteMinKG",
	Flag = "0",
	Callback = function() end,
})
addIntervalToggle(FarmSection, {
	Name = "Auto Favorite",
	flagName = "AutoFavorite",
	tag = "SAE_Fav",
	delay = 10,
	Step = Farm.favoriteStep,
})
FarmSection:createLabel({
	Name = "Misc",
	Special = true,
})
FarmSection:createButton({
	Name = "Clear Pets",
	Warning = function()
		return "Sells ALL pets in your collection."
	end,
	Callback = function()
		local pets = World.collectPets()
		local uids = {}
		for uid in pairs(pets) do
			table.insert(uids, uid)
		end
		if #uids > 0 and GameAPI.sellPets(uids) then
			notify("Farm", ("Cleared %d pets"):format(#uids), "info")
			task.wait(1)
		else
			notify("Farm", "No pets to clear", "info")
		end
	end,
})
FarmSection:createToggle({
	Name = "Auto Drop",
	Flag = false,
	flagName = "AutoDrop",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Auto Recover",
	Flag = false,
	flagName = "AutoRecover",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Spawn Sniper",
	Flag = false,
	flagName = "SpawnSniper",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Snipe Dropped Eggs",
	Flag = false,
	flagName = "SnipeDropped",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Night Farm Sync",
	Flag = false,
	flagName = "NightFarmSync",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Dragon Event Safe",
	Flag = false,
	flagName = "DragonEventSafe",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Forest Guard Bypass",
	Flag = false,
	flagName = "ForestGuardBypass",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Prefer Parasite Eggs",
	Flag = false,
	flagName = "PreferParasiteEggs",
	Callback = function() end,
})
FarmSection:createSlider({
	Name = "Steal Cooldown (s)",
	flagName = "StealCooldown",
	value = 1,
	minValue = 0.5,
	maxValue = 10,
	Callback = function() end,
})
FarmSection:createDropdown({
	Name = "Target Priority",
	flagName = "TargetPriority",
	Flag = { "Rarest" },
	List = { "Rarest", "Nearest", "Furthest", "Biggest" },
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Distant Egg Target",
	Flag = false,
	flagName = "DistantEggTarget",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Prioritize Rarity",
	Flag = false,
	flagName = "PrioritizeRarity",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Ignore Friends",
	Flag = false,
	flagName = "IgnoreFriends",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Avoid Guards",
	Flag = false,
	flagName = "AvoidGuards",
	Callback = function() end,
})
FarmSection:createSlider({
	Name = "Guard Radius",
	flagName = "GuardRadius",
	value = 40,
	minValue = 5,
	maxValue = 200,
	Callback = function() end,
})

-- Progress
ProgressSection:createLabel({
	Name = "Claim",
	Special = true,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Claim Index",
	flagName = "AutoClaimIndex",
	tag = "SAE_Claim",
	delay = 30,
	Step = Progress.claimStep,
	Flag = false,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Claim Offline Cash",
	flagName = "AutoClaimOffline",
	tag = "SAE_ClaimOffline",
	delay = 60,
	Step = Progress.claimStep,
})
ProgressSection:createButton({
	Name = "Claim Now (Index + Offline + Group Perk)",
	Callback = function()
		Progress.claimStep(true)
	end,
})
ProgressSection:createLabel({
	Name = "Progression",
	Special = true,
})
addIntervalToggle(ProgressSection, {
	Name = "AFK Treadmill",
	flagName = "AutoTreadmill",
	tag = "SAE_Treadmill",
	delay = 5,
	Step = Progress.treadmillStep,
	Flag = false,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Treadmill Upgrade",
	flagName = "AutoTreadmillUpgrade",
	tag = "SAE_TreadmillUp",
	delay = 15,
	Step = Progress.treadmillUpgradeStep,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Base Upgrade",
	flagName = "AutoBaseUpgrade",
	tag = "SAE_BaseUp",
	delay = 20,
	Step = Progress.baseUpgradeStep,
})
ProgressSection:createLabel({
	Name = "Utility",
	Special = true,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Equip Best Pets",
	flagName = "AutoEquipBest",
	tag = "SAE_Equip",
	delay = 30,
	Step = Progress.equipBestStep,
})
addIntervalToggle(ProgressSection, {
	Name = "Buy and Equip Best Trail",
	flagName = "AutoEquipTrail",
	tag = "SAE_EquipTrail",
	delay = 30,
	Step = Progress.equipBestStep,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Equip Best Bat",
	flagName = "AutoEquipBatBest",
	tag = "SAE_EquipBat",
	delay = 30,
	Step = Progress.equipBestStep,
})

-- Protection
ProtectionSection:createLabel({
	Name = "Traps",
	Special = true,
})
addIntervalToggle(ProtectionSection, {
	Name = "Disarm Traps",
	flagName = "AutoDisarmTraps",
	tag = "SAE_TrapDisarm",
	delay = 4,
	Step = Protection.disarmStep,
})
ProtectionSection:createLabel({
	Name = "Players",
	Special = true,
})
ProtectionSection:createSlider({
	Name = "Detection Radius",
	flagName = "EvasionRadius",
	value = 35,
	minValue = 5,
	maxValue = 100,
	Callback = function() end,
})
ProtectionSection:createSlider({
	Name = "Escape Height",
	flagName = "EscapeHeight",
	value = 60,
	minValue = 0,
	maxValue = 200,
	Callback = function() end,
})
ProtectionSection:createSlider({
	Name = "Dodge Height",
	Description = "how high it climbs to dodge someone. 0 disables it. no effect while Glide Mode is on",
	flagName = "DodgeHeight",
	value = 60,
	minValue = 0,
	maxValue = 200,
	Callback = function() end,
})
addIntervalToggle(ProtectionSection, {
	Name = "Anti Player",
	flagName = "AutoEvasion",
	tag = "SAE_Evasion",
	delay = 0.5,
	Step = Protection.evasionStep,
	Flag = false,
})
ProtectionSection:createToggle({
	Name = "Only While Carrying",
	Flag = false,
	flagName = "EvasionCarryOnly",
	Callback = function() end,
})
ProtectionSection:createLabel({
	Name = "Bat Aura",
	Special = true,
})
ProtectionSection:createSlider({
	Name = "Aura Range",
	flagName = "AuraRange",
	value = 17,
	minValue = 5,
	maxValue = 60,
	Callback = function() end,
})
ProtectionSection:createSlider({
	Name = "Swing Delay",
	flagName = "SwingDelay",
	value = 0.7,
	minValue = 0.15,
	maxValue = 3,
	Callback = function() end,
})
ProtectionSection:createToggle({
	Name = "Auto Equip Bat",
	Flag = false,
	flagName = "AutoEquipBat",
	Callback = function() end,
})
addIntervalToggle(ProtectionSection, {
	Name = "Bat Aura",
	flagName = "BatAura",
	tag = "SAE_BatAura",
	delay = 0.3,
	Step = Protection.batAuraStep,
})
ProtectionSection:createLabel({
	Name = "Other",
	Special = true,
})
ProtectionSection:createToggle({
	Name = "Lagback Recovery",
	Flag = false,
	flagName = "LagbackRecovery",
	Callback = function() end,
})
ProtectionSection:createSlider({
	Name = "Lagback Recovery",
	flagName = "LagbackThreshold",
	value = 3,
	minValue = 0.5,
	maxValue = 10,
	Callback = function() end,
})
ProtectionSection:createToggle({
	Name = "Lagback: Auto Rejoin",
	Flag = false,
	flagName = "LagbackRejoin",
	Callback = function() end,
})
ProtectionSection:createToggle({
	Name = "Immortality",
	Flag = false,
	flagName = "Immortality",
	Callback = function() end,
})
ProtectionSection:createToggle({
	Name = "Anti Treadmill",
	Flag = false,
	flagName = "AntiTreadmill",
	Callback = function() end,
})
ProtectionSection:createToggle({
	Name = "Anti Fling",
	Flag = false,
	flagName = "AntiFling",
	Callback = function() end,
})
addIntervalToggle(ProtectionSection, {
	Name = "Anti Ragdoll / Anti Hit",
	flagName = "AntiRagdoll",
	tag = "SAE_Safety",
	delay = 0.2,
	Step = Protection.safetyStep,
	Flag = false,
})

-- Dispute
DisputeSection:createLabel({
	Name = "Egg Recovery",
	Special = true,
})
DisputeSection:createSlider({
	Name = "Give Up After (s)",
	flagName = "DisputeGiveUp",
	value = 20,
	minValue = 5,
	maxValue = 300,
	Callback = function() end,
})
DisputeSection:createSlider({
	Name = "Max Chase Distance",
	flagName = "DisputeMaxDistance",
	value = 2000,
	minValue = 20,
	maxValue = 2000,
	Callback = function() end,
})
DisputeSection:createToggle({
	Name = "Only The Farm Target",
	Flag = false,
	flagName = "DisputeLock",
	Callback = function() end,
})
DisputeSection:createDropdown({
	Name = "Dispute These Rarities",
	flagName = "DisputeRarities",
	Flag = { "All" },
	List = RARITY_MULTI,
	multi = true,
	Callback = function() end,
})
addIntervalToggle(DisputeSection, {
	Name = "Egg Recovery",
	flagName = "AutoDispute",
	tag = "SAE_Dispute",
	delay = 1,
	Step = Dispute.step,
})

-- ESPs
EspSection:createInputBox({
	Name = "Min KG",
	flagName = "EspMinKG",
	Flag = "0",
	Callback = function() end,
})
EspSection:createInputBox({
	Name = "Min Earnings",
	Description = "in millions per second – type 10 for 10M/s",
	flagName = "EspMinEarnings",
	Flag = "",
	Callback = function() end,
})
EspSection:createDropdown({
	Name = "Rarities",
	flagName = "EspMinRarity",
	Flag = { "Common" },
	List = RARITY_OPTIONS,
	Callback = function() end,
})
EspSection:createDropdown({
	Name = "Mutations",
	flagName = "EspMutations",
	Flag = { "All" },
	List = MUTATION_OPTIONS,
	multi = true,
	Callback = function() end,
})
EspSection:createDropdown({
	Name = "Areas",
	flagName = "EspAreas",
	Flag = { "All" },
	List = AREA_OPTIONS,
	multi = true,
	Callback = function() end,
})
EspSection:createSlider({
	Name = "Max Distance",
	flagName = "EspMaxDistance",
	value = 800,
	minValue = 100,
	maxValue = 5000,
	Callback = function() end,
})
addIntervalToggle(EspSection, {
	Name = "Enable ESP",
	flagName = "EggEsp",
	tag = "SAE_Esp",
	delay = 0.5,
	Step = Esp.step,
	jitter = 0,
})
EspSection:createToggle({
	Name = "Plot ESP",
	Flag = false,
	flagName = "PlotEsp",
	Callback = function() end,
})
EspSection:createToggle({
	Name = "Show Taken",
	Flag = false,
	flagName = "EspShowTaken",
	Callback = function() end,
})

-- Fusions
FusionSection:createLabel({
	Name = "Fuse",
	Special = true,
})
FusionSection:createButton({
	Name = "Fusion",
	Description = "Press Check Fusable Trios",
	Callback = function()
		Fusion.step(true)
	end,
})
FusionSection:createDropdown({
	Name = "Feed These Rarities",
	flagName = "FusionRarities",
	Flag = { "All" },
	List = RARITY_MULTI,
	multi = true,
	Callback = function() end,
})
addIntervalToggle(FusionSection, {
	Name = "Auto Fuse",
	flagName = "AutoFuse",
	tag = "SAE_Fusion",
	delay = 5,
	Step = Fusion.step,
})
FusionSection:createButton({
	Name = "Check Fusable Trios",
	Callback = function()
		Fusion.checkTrios()
	end,
})
FusionSection:createLabel({
	Name = "No fusable trio (need 3x same rarity)",
	TransparentBackground = true,
	flagName = "saeFusionStatus",
})
FusionSection:createLabel({
	Name = "Fusion",
	Special = true,
})
FusionSection:createButton({
	Name = "Scan Fusion",
	Callback = function()
		Fusion.scanFusion()
	end,
})

-- Event
EventSection:createLabel({
	Name = "Monster event",
	Special = true,
})
addIntervalToggle(EventSection, {
	Name = "Auto Monster",
	flagName = "EventMonitor",
	tag = "SAE_Event",
	delay = 3,
	Step = EventMod.step,
	Flag = false,
})
EventSection:createToggle({
	Name = "Exclude Rare Eggs",
	Flag = false,
	flagName = "EventExcludeRare",
	Callback = function() end,
})
EventSection:createToggle({
	Name = "Auto Use Chest",
	Flag = false,
	flagName = "AutoConsumeChest",
	Callback = function() end,
})
EventSection:createLabel({
	Name = "Monster Event inactive",
	TransparentBackground = true,
	flagName = "saeEventStatus",
})

-- Server Hop
HopSection:createLabel({
	Name = "Rejoin Protection",
	Special = true,
})
HopSection:createInputBox({
	Name = "Loader URL",
	Description = "paste the hub loadstring",
	flagName = "LoaderURL",
	Flag = "",
	Callback = function() end,
})
HopSection:createButton({
	Name = "Save State (Rejoin Protection)",
	Callback = function()
		if ServerHop.saveState() then
			notify("Server Hop", "Hub state saved to getgenv", "info")
		else
			notify("Server Hop", "Save failed", "danger")
		end
	end,
})
HopSection:createButton({
	Name = "Test Rejoin Protection",
	Callback = function()
		ServerHop.saveState()
		notify("Server Hop", "State saved. Rejoin to test (executor must auto-execute on join).", "info")
	end,
})
HopSection:createButton({
	Name = "Rejoin Server",
	Callback = function()
		ServerHop.rejoinCurrent()
	end,
})
HopSection:createButton({
	Name = "Server Hop (Random)",
	Callback = function()
		ServerHop.hopToNext()
	end,
})
HopSection:createSlider({
	Name = "Max Hops",
	flagName = "MaxHops",
	value = 10,
	minValue = 1,
	maxValue = 50,
	Callback = function() end,
})
HopSection:createLabel({
	Name = "Hop",
	Special = true,
})
HopSection:createDropdown({
	Name = "Rarities",
	flagName = "HopRarities",
	Flag = { "All" },
	List = RARITY_MULTI,
	multi = true,
	Callback = function() end,
})
HopSection:createDropdown({
	Name = "Mutations",
	flagName = "HopMutations",
	Flag = { "All" },
	List = MUTATION_OPTIONS,
	multi = true,
	Callback = function() end,
})
HopSection:createInputBox({
	Name = "Min KG",
	flagName = "HopMinKG",
	Flag = "0",
	Callback = function() end,
})
HopSection:createToggle({
	Name = "Mutated Only",
	Flag = false,
	flagName = "HopMutatedOnly",
	Callback = function() end,
})
addIntervalToggle(HopSection, {
	Name = "Start Hopping",
	flagName = "AutoHopTarget",
	tag = "SAE_TargetHop",
	delay = 25,
	Step = ServerHop.step,
})

-- Webhook
WebhookSection:createInputBox({
	Name = "Discord Webhook URL",
	flagName = "WebhookURL",
	Flag = "",
	Callback = function() end,
})
WebhookSection:createToggle({
	Name = "Report Monster Chest",
	Flag = false,
	flagName = "WebhookChest",
	Callback = function() end,
})
WebhookSection:createToggle({
	Name = "Report Fusion Result",
	Flag = false,
	flagName = "WebhookFuse",
	Callback = function() end,
})
WebhookSection:createToggle({
	Name = "Report Server Hop Find",
	Flag = false,
	flagName = "WebhookHop",
	Callback = function() end,
})
WebhookSection:createDropdown({
	Name = "Ping On These Rarities",
	flagName = "WebhookPingRarities",
	Flag = { "All" },
	List = RARITY_MULTI,
	multi = true,
	Callback = function() end,
})
WebhookSection:createDropdown({
	Name = "Rare Alert Min Rarity",
	flagName = "WebhookRareMin",
	Flag = { "Epic" },
	List = RARITY_OPTIONS,
	Callback = function() end,
})
WebhookSection:createInputBox({
	Name = "Role Pings (Rarity:@mention)",
	flagName = "WebhookRolePing",
	Flag = "",
	Callback = function() end,
})
WebhookSection:createToggle({
	Name = "Webhook Alerts",
	Flag = false,
	flagName = "WebhookEnabled",
	Callback = function() end,
})
WebhookSection:createToggle({
	Name = "Disconnect Alerts",
	Flag = false,
	flagName = "WebhookDisconnect",
	Callback = function() end,
})
WebhookSection:createButton({
	Name = "Send Test Message",
	Callback = function()
		local ok = Webhook.send("Test", "Steal an Egg Hub webhook test", 0x95a5a6)
		if ok then
			notify("Webhook", "Test message sent", "info")
		else
			notify("Webhook", "Send failed — check URL and alerts toggle", "danger")
		end
	end,
})

-- Config
ConfigSection:createToggle({
	Name = "Anti Rejoin",
	Flag = false,
	flagName = "AntiRejoin",
	Callback = function() end,
})
ConfigSection:createLabel({
	Name = "Fps Boost",
	Special = true,
})
ConfigSection:createToggle({
	Name = "Fps Boost",
	Flag = false,
	flagName = "FpsBoost",
	Callback = function(enabled)
		ConfigMod.setFpsBoost(enabled == true)
	end,
})
ConfigSection:createLabel({
	Name = "Performance",
	Special = true,
})
ConfigSection:createSlider({
	Name = "FPS Cap",
	flagName = "FpsCap",
	value = 0,
	minValue = 0,
	maxValue = 600,
	Callback = function()
		ConfigMod.applyFps()
	end,
})
ConfigSection:createButton({
	Name = "Check FPS Cap Support",
	Callback = function()
		ConfigMod.checkFpsCapSupport()
	end,
})
ConfigSection:createDropdown({
	Name = "Optimization Method",
	flagName = "OptimizationMethod",
	Flag = { "Balanced" },
	List = { "Balanced", "High Performance", "Maximum FPS" },
	Callback = function()
		ConfigMod.applyOptimization()
	end,
})
ConfigSection:createLabel({
	Name = "Movement",
	Special = true,
})
ConfigSection:createToggle({
	Name = "Black Screen (AFK Mode)",
	Flag = false,
	flagName = "BlackScreen",
	Callback = function(enabled)
		ConfigMod.setBlackScreen(enabled == true)
	end,
})
ConfigSection:createToggle({
	Name = "Anti AFK",
	Flag = false,
	flagName = "AntiAfk",
	Callback = function(enabled)
		setAntiAfk(enabled == true)
	end,
})
ConfigSection:createToggle({
	Name = "Infinite Jump",
	Flag = false,
	flagName = "InfiniteJump",
	Callback = function(enabled)
		setInfiniteJump(enabled == true)
	end,
})
ConfigSection:createToggle({
	Name = "Set Walk Speed",
	Flag = false,
	flagName = "WalkSpeedEnabled",
	Callback = function(enabled)
		setWalkSpeedEnabled(enabled == true)
	end,
})
ConfigSection:createSlider({
	Name = "Walk Speed Value",
	flagName = "WalkSpeedValue",
	value = 30,
	minValue = 16,
	maxValue = 300,
	Callback = function()
		applyWalkSpeed()
	end,
})
ConfigSection:createToggle({
	Name = "Lock Legal Walk Speed",
	Flag = false,
	flagName = "LockLegalWalkSpeed",
	Callback = function() end,
})
ConfigSection:createToggle({
	Name = "Set Jump Power",
	Flag = false,
	flagName = "JumpPowerEnabled",
	Callback = function(enabled)
		setJumpPowerEnabled(enabled == true)
	end,
})
ConfigSection:createSlider({
	Name = "Jump Power Value",
	flagName = "JumpPowerValue",
	value = 50,
	minValue = 1,
	maxValue = 200,
	Callback = function()
		applyJumpPower()
	end,
})
ConfigSection:createLabel({
	Name = "Watchdog",
	Special = true,
})
addIntervalToggle(ConfigSection, {
	Name = "Watchdog",
	flagName = "Watchdog",
	tag = "SAE_Watchdog",
	delay = 2,
	Step = watchdogStep,
	Flag = false,
	jitter = 0,
})
ConfigSection:createToggle({
	Name = "Auto Rejoin",
	Flag = false,
	flagName = "AutoRejoin",
	Callback = function() end,
})
ConfigSection:createSlider({
	Name = "Stuck Timeout (s)",
	flagName = "StuckTimeout",
	value = 120,
	minValue = 30,
	maxValue = 600,
	Callback = function() end,
})
ConfigSection:createSlider({
	Name = "Rejoin Cooldown (s)",
	flagName = "RejoinDelay",
	value = 180,
	minValue = 60,
	maxValue = 900,
	Callback = function() end,
})
ConfigSection:createButton({
	Name = "Stop Everything",
	Callback = stopEverything,
})
ConfigSection:createLabel({
	Name = "Misc",
	Special = true,
})
ConfigSection:createToggle({
	Name = "Debug Console",
	Flag = false,
	flagName = "DebugConsole",
	Callback = function(enabled)
		setDebugConsole(enabled == true)
	end,
})
ConfigSection:createButton({
	Name = "Save Configuration",
	Callback = function()
		local ok = pcall(function()
			Library:ShowSaveScreen()
		end)
		if not ok then
			pcall(function()
				Library:SaveCurrentThemeAs("StealEggHub")
			end)
		end
		notify("Config", "Configuration saved.", "info")
	end,
})
ConfigSection:createButton({
	Name = "Load Configuration",
	Callback = function()
		pcall(function()
			Library:ApplyCloudConfig(nil, "StealEggHub")
		end)
		notify("Config", "Configuration loaded.", "info")
	end,
})
ConfigSection:createToggle({
	Name = "Auto-Load Saved Config",
	Flag = false,
	flagName = "AutoLoadConfig",
	Callback = function(enabled)
		if enabled == true then
			ServerHop.restoreState()
		end
	end,
})
ConfigSection:createDropdown({
	Name = "UI Theme",
	flagName = "UiTheme",
	Flag = { "Dark Mode" },
	List = { "Dark Mode", "Halloween", "Neon Command", "Midnight", "Ocean", "Forest", "Rose", "Light", "Custom" },
	Callback = function()
		local v = getDropdownValue("UiTheme", "Dark Mode")
		pcall(function()
			ui:UpdateUI(v)
		end)
	end,
})
ConfigSection:createKeybind({
	Name = "Toggle UI Keybind",
	flagName = "ToggleUIKey",
	Flag = "RightControl",
	Callback = function() end,
})
ConfigSection:createButton({
	Name = "Open Theme Customizer",
	Callback = function()
		pcall(function()
			Library:OpenCustomizer()
		end)
	end,
})
ConfigSection:createLabel({
	Name = "TIME: -- | FPS: -- | PING: --",
	TransparentBackground = true,
	flagName = "saeStats",
})

Status.label = HomeSection:FindFirstChild("saeFarmStatus")
Fusion.statusLabel = FusionSection:FindFirstChild("saeFusionStatus")
EventMod.statusLabel = EventSection:FindFirstChild("saeEventStatus")
ConfigMod.bindLabels(
	HomeSection:FindFirstChild("saeHomeStats"),
	ConfigSection:FindFirstChild("saeStats"),
	FarmSection:FindFirstChild("saeRecSpeed")
)

print("[SAEHub] Steal an Egg Hub v2 loaded.")

