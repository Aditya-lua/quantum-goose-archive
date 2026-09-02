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
	StealSpeed = 300, StealBigEggs = false, StealBigEggScale = 1.5,
	AutoStealAll = false, AutoReturn = true,
	AutoPlaceSelected = false, AutoPlaceAll = false,
	LifecycleRarities = { "All" }, LifecycleMutations = { "All" },
	PrioritySlot1 = "Auto Steal Egg", PrioritySlot2 = "Auto Place Egg",
	PrioritySlot3 = "Auto Hatch", PrioritySlot4 = "Auto Treadmill",
	SellMaxScale = 10, SellKeepMutated = true, SellKeepEquipped = true,
	AutoSellPets = false, SellInterval = 6,
	AutoSellEggs = false, SellEggRarities = { "All" }, SellEggInterval = 8,
	SelectRarity = { "All" }, SelectMutation = { "All" }, SelectArea = { "All" },
	SelectEggType = { "All" }, SellMutationWhitelist = { "All" },
	DisputeRarities = { "All" }, EspMutations = { "All" }, EspAreas = { "All" },
	StealCooldown = 1,
	-- progress
	AutoClaimIndex = false, AutoClaimOffline = false, AutoClaimGroupReward = false,
	AutoTreadmill = false, AutoTreadmillUpgrade = false, AutoBaseUpgrade = false,
	AutoEquipBest = false, AutoEquipTrail = false, AutoEquipBatBest = false, AutoBuyBest = false,
	AutoEquipBestTrail = false, AutoEquipBestGear = false,
	UpgradeTypes = { "Base", "Treadmill" },
	AutoBuyTrail = false, TrailWanted = { "All" },
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
	FuseTarget = "Highest Rarity", FuseKeepPerCategory = 0, FuseMaxScale = 10,
	FuseKeepMutated = true, FuseKeepEquipped = true, FuseAutoReveal = true, FuseInterval = 8,
	-- event
	EventMonitor = false, AutoConsumeChest = false, EventExcludeRare = false,
	-- server hop
	AutoHopTarget = false, MaxHops = 10, HopMinKG = 0,
	HopRarities = { "All" }, HopMutations = { "All" }, HopMutatedOnly = false,
	AutoServerHop = false, HopMode = "No Matching Eggs", HopValue = 15,
	-- webhook
	WebhookURL = "", WebhookEnabled = false, WebhookRare = false, WebhookRareMin = "Epic",
	WebhookPingRarities = { "All" },
	WebhookChest = false, WebhookFuse = false, WebhookHop = false, WebhookDisconnect = false,
	WebhookRolePing = "", WebhookPingId = "", WebhookEggSpawns = true, WebhookSummaryInterval = 15,
	-- config
	BlackScreen = false, FpsBoost = false, FpsCap = 0, OptimizationMethod = "Balanced",
	AntiAfk = true, InfiniteJump = false,
	AntiGameplayPause = true, AutoReconnect = false,
	Fly = false, FlySpeed = 60, NoClip = false, WaypointTarget = "Base",
	DisableRendering = false,
	GuardEsp = false, PetEsp = false, PlayerEsp = false,
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
	function Webhook.postRaw(payload)
		if type(requestFn) ~= "function" or not HttpService then
			return false
		end
		local url = getFlag("WebhookURL", "")
		if typeof(url) ~= "string" or url == "" then
			return false
		end
		local body = HttpService:JSONEncode(payload)
		local ok2, res = pcall(function()
			return requestFn({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = body,
			})
		end)
		return ok2 and res ~= nil
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

Webhook.session = {
	started = os.clock(),
	stolen = 0,
	pets = 0,
	rebirths = 0,
	eggLog = {},
	spawnLog = {},
	spawnsSeen = {},
	lastPetsSeen = nil,
	lastRebirth = nil,
}
Webhook.lastSummary = 0

local function fmtMoney(n)
	n = tonumber(n) or 0
	local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi" }
	local i = 1
	while n >= 1000 and i < #suffixes do
		n = n / 1000
		i = i + 1
	end
	if i == 1 then
		return string.format("%d", n)
	end
	return string.format("%.2f%s", n, suffixes[i])
end
Webhook.fmtMoney = fmtMoney

function Webhook.eggLogEntry(rec)
	if type(rec) ~= "table" then
		return
	end
	if #Webhook.session.eggLog >= 100 then
		return
	end
	local parts = {}
	local rarity = GameAPI.resolveRarity(rec.AssetCategory)
	table.insert(parts, string.format("**%s** `%s`", GameAPI.assetName(rec.AssetCategory), tostring(rarity or "?")))
	if typeof(rec.AreaId) == "string" and rec.AreaId ~= "" then
		table.insert(parts, rec.AreaId)
	end
	local muts = GameAPI.eggMutations(rec)
	if #muts > 0 then
		table.insert(parts, table.concat(muts, ", "))
	end
	local scale = tonumber(rec.AssetScale)
	if scale then
		table.insert(parts, string.format("x%.2f", scale))
	end
	table.insert(Webhook.session.eggLog, table.concat(parts, " | "))
end

function Webhook.trackEvents()
	local save = GameAPI.saveData()
	if not save then
		return
	end
	local s = Webhook.session
	if s.lastPetsSeen == nil then
		s.lastPetsSeen = {}
		local inv = save.Inventory
		if type(inv) == "table" then
			for uid in pairs(inv) do
				s.lastPetsSeen[uid] = true
			end
		end
		s.lastRebirth = tonumber(save.Rebirth) or 0
		local records = GameAPI.areaEggSnapshot()
		if type(records) == "table" then
			for uid, rec in pairs(records) do
				if type(rec) == "table" then
					s.spawnsSeen[uid] = true
				end
			end
		end
		return
	end
	local inv = save.Inventory
	if type(inv) == "table" then
		for uid in pairs(inv) do
			if not s.lastPetsSeen[uid] then
				s.lastPetsSeen[uid] = true
				s.pets = s.pets + 1
			end
		end
		for uid in pairs(s.lastPetsSeen) do
			if inv[uid] == nil then
				s.lastPetsSeen[uid] = nil
			end
		end
	end
	local rebirth = tonumber(save.Rebirth) or 0
	if rebirth > s.lastRebirth then
		s.rebirths = s.rebirths + rebirth - s.lastRebirth
	end
	s.lastRebirth = rebirth
	if getFlag("WebhookEggSpawns", true) == true then
		local records = GameAPI.areaEggSnapshot()
		if type(records) == "table" then
			local current = {}
			for uid, rec in pairs(records) do
				if type(rec) == "table" then
					current[uid] = true
					if not s.spawnsSeen[uid] and #s.spawnLog < 60 then
						s.spawnsSeen[uid] = true
						local rarity = GameAPI.resolveRarity(rec.AssetCategory)
						local rank = rarity and Farm.getRarityRank(rarity) or 0
						table.insert(s.spawnLog, {
							rank = rank,
							text = string.format("**%s** `%s` in %s",
								GameAPI.assetName(rec.AssetCategory),
								tostring(rarity or "?"),
								tostring(rec.AreaId or "?")),
						})
					end
				end
			end
			for uid in pairs(s.spawnsSeen) do
				if not current[uid] then
					s.spawnsSeen[uid] = nil
				end
			end
		end
	end
end

function Webhook.buildSummaryEmbed()
	local save = GameAPI.saveData() or {}
	local s = Webhook.session
	local elapsed = os.clock() - s.started
	local fields = {}
	local function addField(name, value)
		table.insert(fields, { name = name, value = value, inline = true })
	end
	addField("Money", "`" .. fmtMoney(save.Money) .. "`")
	addField("Speed Power", "`" .. fmtMoney(save.SpeedPower) .. "`")
	if save.Rebirth ~= nil then
		addField("Rebirth", "`" .. tostring(save.Rebirth) .. "`")
	end
	if save.BaseUpgradeLevel ~= nil then
		addField("Base Level", "`" .. tostring(save.BaseUpgradeLevel) .. "`")
	end
	if save.TreadmillUpgradeLevel ~= nil then
		addField("Treadmill Level", "`" .. tostring(save.TreadmillUpgradeLevel) .. "`")
	end
	local petCount = 0
	if type(save.Inventory) == "table" then
		for _ in pairs(save.Inventory) do
			petCount = petCount + 1
		end
	end
	addField("Pets Owned", "`" .. petCount .. "`")
	table.insert(fields, {
		name = "Since Last Summary",
		value = string.format("**Eggs stolen:** %d\n**Pets obtained:** %d\n**Rebirths:** %d", s.stolen, s.pets, s.rebirths),
	})
	if #s.eggLog > 0 then
		local shown = {}
		local n = math.min(#s.eggLog, 15)
		for i = 1, n do
			table.insert(shown, s.eggLog[i])
		end
		local value = table.concat(shown, "\n")
		if #s.eggLog > 15 then
			value = value .. string.format("\n... and %d more", #s.eggLog - 15)
		end
		table.insert(fields, { name = string.format("Eggs Obtained (%d)", #s.eggLog), value = value })
	end
	if #s.spawnLog > 0 then
		local sorted = {}
		for i, e in ipairs(s.spawnLog) do
			e.order = i
			table.insert(sorted, e)
		end
		table.sort(sorted, function(a, b)
			if a.rank == b.rank then
				return a.order < b.order
			end
			return a.rank > b.rank
		end)
		local shown = {}
		local n = math.min(#sorted, 15)
		for i = 1, n do
			table.insert(shown, sorted[i].text)
		end
		local value = table.concat(shown, "\n")
		if #sorted > 15 then
			value = value .. string.format("\n... and %d more", #sorted - 15)
		end
		table.insert(fields, { name = string.format("Eggs Spawned (%d)", #sorted), value = value })
	end
	return {
		author = { name = "Steal an Egg Hub" },
		title = "Session Summary",
		description = string.format("**Player** `%s`\n**Server** `%s`\n**Runtime** `%s`",
			client and client.Name or "?",
			tostring(game.JobId),
			fmtDuration(elapsed)),
		color = 5793266,
		fields = fields,
		footer = { text = "Steal an Egg Hub" },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
end

function Webhook.sendEmbed(embed, ping)
	if getFlag("WebhookEnabled", false) ~= true then
		return false
	end
	local payload = { username = "Steal an Egg Hub", embeds = { embed } }
	if ping then
		local raw = tostring(getFlag("WebhookPingId", "") or "")
		local id = raw:gsub("%D", "")
		if id ~= "" then
			payload.content = "<@" .. id .. ">"
		end
	end
	return Webhook.postRaw(payload)
end

function Webhook.sendSummary()
	local ok = Webhook.sendEmbed(Webhook.buildSummaryEmbed(), true)
	if ok then
		local s = Webhook.session
		s.stolen, s.pets, s.rebirths = 0, 0, 0
		s.eggLog = {}
		s.spawnLog = {}
	end
	return ok
end

function Webhook.summaryStep()
	local mins = tonumber(getFlag("WebhookSummaryInterval", 15)) or 15
	if os.clock() - Webhook.lastSummary < mins * 60 then
		return
	end
	Webhook.lastSummary = os.clock()
	task.spawn(Webhook.sendSummary)
end

function Webhook.webhookStep()
	if getFlag("WebhookEnabled", false) ~= true then
		return
	end
	pcall(Webhook.trackEvents)
	pcall(Webhook.summaryStep)
end

local CoreTasks = {}
CoreTasks.lastRun = {}
CoreTasks.busy = false
CoreTasks.registry = {}
local CORE_TASK_NAMES = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill" }

function CoreTasks.register(name, def)
	CoreTasks.registry[name] = def
end

function CoreTasks.order()
	local order, seen = {}, {}
	for i = 1, 4 do
		local pick = getFlag("PrioritySlot" .. i, nil)
		if typeof(pick) == "string" and pick ~= "" and not seen[pick] then
			table.insert(order, pick)
			seen[pick] = true
		end
	end
	for _, name in ipairs(CORE_TASK_NAMES) do
		if not seen[name] then
			table.insert(order, name)
			seen[name] = true
		end
	end
	return order
end

function CoreTasks.pump()
	if CoreTasks.busy then
		return
	end
	World.pollCarry()
	if Progress.treadmillActive == true and GameAPI.doubleSpeedVisible() ~= true then
		CoreTasks.busy = true
		pcall(Progress.stopTreadmillTraining)
		CoreTasks.busy = false
	end
	for _, name in ipairs(CoreTasks.order()) do
		local def = CoreTasks.registry[name]
		if def then
			local last = CoreTasks.lastRun[name] or 0
			if os.clock() - last >= def.interval then
				local okReady, ready = pcall(def.ready)
				if okReady and ready == true then
					CoreTasks.busy = true
					local okRun = pcall(def.run)
					CoreTasks.busy = false
					if okRun and name ~= "Auto Treadmill" then
						CoreTasks.lastRun[name] = os.clock()
					end
					return
				end
			end
		end
	end
end

local Stability = {}
Stability.checkAt = 0
Stability.handling = false

function Stability.handleDisconnect(reason)
	if Stability.handling then
		return
	end
	Stability.handling = true
	if getFlag("WebhookDisconnect", false) == true then
		Webhook.sendEmbed({
			author = { name = "Steal an Egg Hub" },
			title = "Disconnected",
			description = string.format("**Player** `%s`\n**Reason** %s",
				client and client.Name or "?",
				tostring(reason or "Connection lost")),
			color = 15158332,
			footer = { text = "Steal an Egg Hub" },
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		}, true)
	end
	if getFlag("AutoReconnect", false) == true then
		task.delay(2, function()
			GameAPI.rejoinServer()
		end)
	end
	task.delay(15, function()
		Stability.handling = false
	end)
end

function Stability.pump()
	local now = os.clock()
	if now - Stability.checkAt < 1 then
		return
	end
	Stability.checkAt = now
	if getFlag("AutoReconnect", false) ~= true and getFlag("WebhookDisconnect", false) ~= true then
		return
	end
	local prompt = CoreGui and CoreGui:FindFirstChild("RobloxPromptGui")
	local overlay = prompt and prompt:FindFirstChild("promptOverlay")
	if typeof(overlay) == "Instance" then
		for _, child in ipairs(overlay:GetChildren()) do
			if child.Name:find("ErrorPrompt") and child.Visible == true then
				Stability.handleDisconnect("Roblox error prompt")
				break
			end
		end
	end
end

local lastAfkTap = 0
function ConfigMod.antiAfkTap()
	local VirtualInputManager = svc("VirtualInputManager")
	local cam = Workspace.CurrentCamera
	local cf = cam and cam.CFrame or CFrame.new()
	if VirtualInputManager then
		pcall(function()
			VirtualInputManager:Button2Down(Vector2.new(0, 0), cf)
			task.wait(0.1)
			VirtualInputManager:Button2Up(Vector2.new(0, 0), cf)
		end)
	elseif VirtualUser then
		pcall(function()
			VirtualUser:Button2Down(Vector2.new(0, 0), cf)
			task.wait(0.1)
			VirtualUser:Button2Up(Vector2.new(0, 0), cf)
		end)
	end
	lastAfkTap = tick()
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

local function localRoot()
	local char = client and client.Character
	if typeof(char) ~= "Instance" then
		return nil
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	return typeof(hrp) == "Instance" and hrp or nil
end

local function areasFolder()
	local objects = Workspace and Workspace:FindFirstChild("__OBJECTS")
	if typeof(objects) ~= "Instance" then
		return nil
	end
	local areas = objects:FindFirstChild("Areas")
	return typeof(areas) == "Instance" and areas or nil
end

function GameAPI.initV2()
	local M = GameAPI.Modules
	if not M.TreadmillData then
		M.TreadmillData = safeRequire(findReplicatedPath({ "Data", "Treadmills" }))
	end
	if not M.TrailsData then
		M.TrailsData = safeRequire(findReplicatedPath({ "Data", "Trails" }))
	end
	if not M.GearsData then
		M.GearsData = safeRequire(findReplicatedPath({ "Data", "Gears" }))
	end
	if not M.AssetsData then
		M.AssetsData = safeRequire(findReplicatedPath({ "Data", "Assets" }))
	end
	if not M.EggsTypes then
		M.EggsTypes = safeRequire(findReplicatedPath({ "Shared", "Types", "Eggs" }))
	end
	if not M.Constants then
		M.Constants = safeRequire(findReplicatedPath({ "Shared", "Globals", "Constants" }))
	end
	if not M.AssetItems then
		M.AssetItems = safeRequire(findReplicatedPath({ "Shared", "Util", "AssetItems" }))
	end
	if not M.FuseKernel then
		M.FuseKernel = safeRequire(findReplicatedPath({ "Shared", "Util", "FuseKernel" }))
	end
	if not M.AssetRoster then
		M.AssetRoster = safeRequire(findReplicatedPath({ "Client", "AssetRoster" }))
	end
end

function GameAPI.resolveRarity(assetId)
	if typeof(assetId) ~= "string" or assetId == "" then
		return nil
	end
	local roster = GameAPI.Modules.AssetRoster
	local dir = type(roster) == "table" and roster.Directory
	if type(dir) == "table" and type(dir[assetId]) == "table" then
		local rec = dir[assetId]
		local r = rec.Rarity
		if type(r) == "table" then
			return r._id or r.DisplayName
		end
		if typeof(r) == "string" then
			return r
		end
	end
	return nil
end

function GameAPI.assetName(assetId)
	if typeof(assetId) ~= "string" or assetId == "" then
		return "Unknown"
	end
	local roster = GameAPI.Modules.AssetRoster
	local dir = type(roster) == "table" and roster.Directory
	if type(dir) == "table" and type(dir[assetId]) == "table" then
		return dir[assetId].DisplayName or assetId
	end
	return assetId
end

function GameAPI.areaEggSnapshot()
	local mod = GameAPI.Modules.EggState
	if type(mod) == "table" and type(mod.GetAreaEggSnapshot) == "function" then
		local ok, snap = pcall(mod.GetAreaEggSnapshot, mod)
		if ok and type(snap) == "table" then
			if type(snap.Records) == "table" then
				return snap.Records
			end
			return snap
		end
	end
	return nil
end

function GameAPI.requestSnapshot()
	local mod = GameAPI.Modules.EggState
	if type(mod) == "table" and type(mod.RequestAreaEggSnapshot) == "function" then
		return pcall(mod.RequestAreaEggSnapshot, mod)
	end
	return false
end

function GameAPI.dropHeldEgg()
	local mod = GameAPI.Modules.EggState
	if type(mod) == "table" then
		if type(mod.RequestDropHeldAreaEgg) == "function" then
			local ok = pcall(mod.RequestDropHeldAreaEgg, mod)
			if ok then
				return true
			end
		end
		if type(mod.DropFieldEgg) == "function" then
			local ok = pcall(mod.DropFieldEgg, mod, "PlayerRequest")
			if ok then
				return true
			end
		end
	end
	return GameAPI.dropEgg()
end

function GameAPI.doubleSpeedVisible()
	local gui = client and client:FindFirstChild("PlayerGui")
	if typeof(gui) ~= "Instance" then
		return false
	end
	local paths = {
		{ "Elements", "Tools", "DoubleYourSpeed" },
		{ "Left", "Tools", "DoubleYourSpeed" },
	}
	for _, parts in ipairs(paths) do
		local node = gui
		for _, name in ipairs(parts) do
			node = typeof(node) == "Instance" and node:FindFirstChild(name) or nil
		end
		if typeof(node) == "Instance" and node.Visible == true then
			return true
		end
	end
	return false
end

function GameAPI.maxEggInventory()
	local t = GameAPI.Modules.EggsTypes
	if type(t) == "table" and type(t.MAX_INVENTORY) == "number" then
		return t.MAX_INVENTORY
	end
	return math.huge
end

function GameAPI.eggInventoryCount()
	local save = GameAPI.saveData()
	local inv = save and save.EggInventory
	if type(inv) ~= "table" then
		return 0
	end
	local n = 0
	for _ in pairs(inv) do
		n = n + 1
	end
	return n
end

function GameAPI.eggInventoryFull()
	return GameAPI.eggInventoryCount() >= GameAPI.maxEggInventory()
end

function GameAPI.eggMutations(rec)
	local out = {}
	if type(rec) ~= "table" then
		return out
	end
	if type(rec.Mutations) == "table" then
		for _, m in pairs(rec.Mutations) do
			if typeof(m) == "string" and m ~= "" then
				table.insert(out, m)
			end
		end
	end
	if typeof(rec.BaseMutation) == "string" and rec.BaseMutation ~= "" then
		table.insert(out, rec.BaseMutation)
	end
	return out
end

function GameAPI.eggMatchesFilters(rec, zoneSet, raritySet, mutSet)
	if type(rec) ~= "table" then
		return false
	end
	if zoneSet then
		local area = rec.AreaId
		if typeof(area) ~= "string" or not zoneSet[area] then
			return false
		end
	end
	if raritySet and next(raritySet) ~= nil then
		local rarity = GameAPI.resolveRarity(rec.AssetCategory)
		if typeof(rarity) == "string" and not raritySet[rarity] then
			return false
		end
	end
	if mutSet and next(mutSet) ~= nil then
		local hit = false
		for _, m in ipairs(GameAPI.eggMutations(rec)) do
			if mutSet[m] then
				hit = true
				break
			end
		end
		if not hit then
			return false
		end
	end
	return true
end

function GameAPI.unplacedEggUids(raritySet, mutSet)
	local save = GameAPI.saveData()
	local inv = save and save.EggInventory
	if type(inv) ~= "table" then
		return {}
	end
	local out = {}
	for uid, rec in pairs(inv) do
		if typeof(uid) == "string" and type(rec) == "table" and rec.Placement == nil then
			if GameAPI.eggMatchesFilters(rec, nil, raritySet, mutSet) then
				table.insert(out, uid)
			end
		end
	end
	return out
end

function GameAPI.sellableEggUids(raritySet)
	local save = GameAPI.saveData()
	local inv = save and save.EggInventory
	if type(inv) ~= "table" then
		return {}
	end
	local out = {}
	for uid, rec in pairs(inv) do
		if typeof(uid) == "string" and type(rec) == "table" and rec.Placement == nil then
			if GameAPI.eggMatchesFilters(rec, nil, raritySet, nil) then
				table.insert(out, uid)
			end
		end
	end
	return out
end

function GameAPI.sellAsset(uid)
	if typeof(uid) ~= "string" or uid == "" then
		return false
	end
	if not GameAPI.fire("AssetInventory", "SELL_ASSET", uid) then
		return false
	end
	local deadline = os.clock() + 2
	while os.clock() < deadline do
		local save = GameAPI.saveData()
		if save then
			local inPets = save.Inventory and save.Inventory[uid] ~= nil
			local inEggs = save.EggInventory and save.EggInventory[uid] ~= nil
			if not inPets and not inEggs then
				return true
			end
		end
		task.wait(0.1)
	end
	return false
end

function GameAPI.petInfo(uid)
	local save = GameAPI.saveData()
	if not save then
		return nil, nil
	end
	local rec = save.Inventory and save.Inventory[uid]
	if type(rec) ~= "table" then
		return nil, nil
	end
	local data = rec
	local mod = GameAPI.Modules.AssetItems
	if type(mod) == "table" and type(mod.Deserialize) == "function" then
		local ok, dec = pcall(mod.Deserialize, mod, rec)
		if ok and type(dec) == "table" then
			data = dec
		end
	end
	return data, rec
end

function GameAPI.equippedUids()
	local save = GameAPI.saveData()
	local set = {}
	local list = save and save.EquippedAssets
	if type(list) == "table" then
		for _, uid in pairs(list) do
			if typeof(uid) == "string" then
				set[uid] = true
			end
		end
	end
	return set
end

function GameAPI.sellablePets(opts)
	opts = opts or {}
	local save = GameAPI.saveData()
	if not save then
		return {}
	end
	local inv = save.Inventory
	if type(inv) ~= "table" then
		return {}
	end
	local equipped = GameAPI.equippedUids()
	local out = {}
	for uid, rec in pairs(inv) do
		if typeof(uid) == "string" and type(rec) == "table" then
			local data = rec
			local mod = GameAPI.Modules.AssetItems
			if type(mod) == "table" and type(mod.Deserialize) == "function" then
				local ok, dec = pcall(mod.Deserialize, mod, rec)
				if ok and type(dec) == "table" then
					data = dec
				end
			end
			local skip = data.IsFavorite == true or data.InFuse == true
			if not skip then
				local scale = tonumber(data.Scale) or tonumber(rec.Scale)
				if opts.maxScale and scale and scale > opts.maxScale then
					skip = true
				end
			end
			if not skip and opts.keepEquipped and equipped[uid] then
				skip = true
			end
			if not skip and opts.raritySet and next(opts.raritySet) ~= nil then
				local category = rec.Category or rec.AssetCategory
				local rarity = GameAPI.resolveRarity(category)
				if typeof(rarity) == "string" and not opts.raritySet[rarity] then
					skip = true
				end
			end
			if not skip and opts.keepMutated and opts.mutSet and next(opts.mutSet) ~= nil then
				for _, m in ipairs(GameAPI.eggMutations(data)) do
					if opts.mutSet[m] then
						skip = true
						break
					end
				end
			end
			if not skip then
				table.insert(out, uid)
			end
		end
	end
	return out
end


function GameAPI.fuseGroups()
	local save = GameAPI.saveData()
	if not save then
		return {}
	end
	local inv = save.Inventory
	if type(inv) ~= "table" then
		return {}
	end
	local groups = {}
	for uid, rec in pairs(inv) do
		if typeof(uid) == "string" and type(rec) == "table" then
			local category = rec.Category or rec.AssetCategory or rec.Type or "Unknown"
			local rarity = GameAPI.resolveRarity(rec.Category) or "Common"
			local scale = tonumber(rec.Scale) or 0
			if not groups[category] then
				groups[category] = { category = category, rarity = rarity, items = {} }
			end
			table.insert(groups[category].items, { uid = uid, scale = scale })
		end
	end
	for _, g in pairs(groups) do
		table.sort(g.items, function(a, b)
			return a.scale < b.scale
		end)
	end
	return groups
end

function GameAPI.fusePrice(uids)
	local mod = GameAPI.Modules.FuseKernel
	if type(mod) ~= "table" or type(mod.CalculateFusePrice) ~= "function" then
		return nil
	end
	local save = GameAPI.saveData()
	local inv = save and save.Inventory
	if type(inv) ~= "table" then
		return nil
	end
	local payload = {}
	for _, uid in ipairs(uids) do
		local rec = inv[uid]
		if type(rec) == "table" then
			local data = rec
			local items = GameAPI.Modules.AssetItems
			if type(items) == "table" and type(items.Deserialize) == "function" then
				local ok, dec = pcall(items.Deserialize, items, rec)
				if ok and type(dec) == "table" then
					data = dec
				end
			end
			payload[uid] = data
		end
	end
	local ok, price = pcall(mod.CalculateFusePrice, mod, payload)
	if ok and type(price) == "number" then
		return price
	end
	return nil
end

function GameAPI.equipBestPets()
	if GameAPI.fire("Backpack", "EQUIP_BEST") then
		return true
	end
	return GameAPI.wearBestPet()
end

function GameAPI.claimIndexAll()
	if GameAPI.fire("Index", "REQUEST_CLAIM_ALL") then
		return true
	end
	return GameAPI.claimCodex()
end

function GameAPI.offlineSummary()
	local ok, res = GameAPI.invoke("OfflineAssets", "GET_SUMMARY")
	if ok and type(res) == "table" then
		return res
	end
	return nil
end

function GameAPI.claimOfflineEarnings()
	local summary = GameAPI.offlineSummary()
	if type(summary) == "table" then
		local amount = tonumber(summary.ClaimableAmount) or 0
		if amount <= 0 then
			return false
		end
		return GameAPI.fire("OfflineAssets", "REQUEST_REDEEM")
	end
	return GameAPI.collectAway()
end

function GameAPI.baseUpgradeNext()
	local mod = GameAPI.Modules.BaseUpgrade
	local save = GameAPI.saveData()
	if type(mod) == "table" and type(mod.IsNextTierAffordable) == "function" then
		local ok, affordable = pcall(mod.IsNextTierAffordable, mod, save)
		if ok then
			return affordable == true
		end
	end
	return false
end

function GameAPI.buyBaseUpgrade()
	if GameAPI.fire("Plots", "REQUEST_BASE_UPGRADE") then
		return true
	end
	return GameAPI.baseUpgrade()
end

function GameAPI.nextTreadmillLevel()
	local mod = GameAPI.Modules.TreadmillData
	if type(mod) == "table" and type(mod.GetByUpgradeLevel) == "function" then
		local save = GameAPI.saveData()
		local current = save and (tonumber(save.TreadmillUpgradeLevel) or 0) or 0
		local ok, nextLevel = pcall(mod.GetByUpgradeLevel, mod, current + 1)
		if ok and type(nextLevel) == "table" then
			return nextLevel
		end
	end
	return nil
end

function GameAPI.buyTreadmillUpgrade()
	local nextLevel = GameAPI.nextTreadmillLevel()
	if nextLevel then
		local id = nextLevel._id or nextLevel.Id or nextLevel.ID
		local save = GameAPI.saveData()
		local money = save and tonumber(save.Money) or 0
		local price = tonumber(nextLevel.Price) or 0
		if money >= price and GameAPI.fire("Treadmills", "REQUEST_UPGRADE", id) then
			return true
		end
	end
	local tid = World.treadmillId()
	if tid then
		return GameAPI.treadmillTierRaise(tid)
	end
	return false
end

function GameAPI.treadmillEquipStatic()
	local ok = GameAPI.invoke("Treadmills", "REQUEST_EQUIP_STATIC")
	if ok then
		return true
	end
	ok = GameAPI.fire("Treadmills", "REQUEST_EQUIP_STATIC")
	if ok then
		return true
	end
	return GameAPI.treadmillWear()
end

function GameAPI.treadmillUnequip()
	local ok = GameAPI.invoke("Treadmills", "REQUEST_UNEQUIP")
	if not ok then
		ok = GameAPI.fire("Treadmills", "REQUEST_UNEQUIP")
	end
	if not ok then
		ok = GameAPI.treadmillDoff()
	end
	return ok
end

function GameAPI.trailData()
	local mod = GameAPI.Modules.TrailsData
	local names = {}
	local prices = {}
	if type(mod) == "table" then
		for k, v in pairs(mod) do
			if typeof(k) == "string" and not k:match("^_") and type(v) ~= "function" then
				if type(v) == "table" then
					local price = tonumber(v.Price or v.price or v.Cost or v.cost)
					if price then
						names[k] = true
						prices[k] = price
					end
				elseif type(v) == "number" then
					names[k] = true
					prices[k] = v
				end
			end
		end
	end
	return names, prices
end

function GameAPI.buyTrail(name)
	return GameAPI.fire("Trails", "REQUEST_PURCHASE", name)
end

function GameAPI.wornTrail()
	local ok, res = GameAPI.invoke("Trails", "WORN_SNAPSHOT")
	if ok and type(res) == "table" then
		return res[client and client.UserId]
	end
	return nil
end

function GameAPI.selectTrail(name)
	local ok = GameAPI.invoke("Trails", "REQUEST_SELECT", name)
	if ok then
		return true
	end
	return GameAPI.fire("Trails", "REQUEST_SELECT", name)
end

function GameAPI.bestTrailName()
	local names, prices = GameAPI.trailData()
	local save = GameAPI.saveData()
	local inv = save and save.TrailInventory
	if type(inv) ~= "table" then
		return nil
	end
	local best, bestScore = nil, -1
	for name in pairs(names) do
		if inv[name] ~= nil and prices[name] and prices[name] > bestScore then
			best, bestScore = name, prices[name]
		end
	end
	return best
end

function GameAPI.fetchServerPage(cursor)
	local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers?limit=50"
	if typeof(cursor) == "string" and cursor ~= "" then
		url = url .. "&cursor=" .. cursor
	end
	local ok, body = pcall(function()
		return HttpService:GetAsync(url, false)
	end)
	if not ok or typeof(body) ~= "string" then
		return nil
	end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, body)
	if ok2 and type(data) == "table" and type(data.data) == "table" then
		return { data = data.data, nextPageCursor = data.nextPageCursor }
	end
	return nil
end

function GameAPI.pickServerTargets(visited)
	local out = {}
	local pageCursor, pages = nil, 0
	repeat
		local page = GameAPI.fetchServerPage(pageCursor)
		if not page then
			break
		end
		for _, entry in ipairs(page.data) do
			if type(entry) == "table" and typeof(entry.id) == "string" then
				if entry.id ~= game.JobId and not visited[entry.id] then
					table.insert(out, { id = entry.id, playing = tonumber(entry.playing) or 0 })
				end
			end
		end
		pageCursor = typeof(page.nextPageCursor) == "string" and page.nextPageCursor or nil
		pages = pages + 1
		if #out >= 40 or pages >= 4 then
			break
		end
		if pageCursor then
			task.wait(0.25)
		end
	until not pageCursor
	table.sort(out, function(a, b)
		return a.playing < b.playing
	end)
	return out
end

function GameAPI.teleportToJob(jobId)
	local ok = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, client)
	end)
	return ok
end

function GameAPI.rejoinServer()
	local ok = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, client)
	end)
	if not ok then
		pcall(function()
			TeleportService:Teleport(game.PlaceId, client)
		end)
	end
end

World.laneY = function()
	local areas = areasFolder()
	local part = areas and areas:FindFirstChild("GameplayZ")
	if typeof(part) == "Instance" and part:IsA("BasePart") then
		return part.Position.Y + 3
	end
	local root = localRoot()
	if root then
		return root.Position.Y
	end
	return 70
end

World.laneZ = function()
	local areas = areasFolder()
	local part = areas and areas:FindFirstChild("GameplayZ")
	if typeof(part) == "Instance" and part:IsA("BasePart") then
		return part.Position.Z
	end
	part = areas and areas:FindFirstChild("SeparationLine")
	if typeof(part) == "Instance" and part:IsA("BasePart") then
		return part.Position.Z
	end
	return -365.5
end

World.entryPosition = function()
	local x = 543.5
	local areas = areasFolder()
	local cand = areas and areas:FindFirstChild("StartArea")
	if not (typeof(cand) == "Instance" and cand:IsA("BasePart")) then
		cand = areas and areas:FindFirstChild("SeparationLine")
	end
	if typeof(cand) == "Instance" and cand:IsA("BasePart") then
		x = cand.Position.X
	end
	return Vector3.new(x, World.laneY(), World.laneZ())
end

World.zoneModel = function(name)
	local areas = areasFolder()
	local guard = areas and areas:FindFirstChild("GuardAreas")
	if typeof(guard) == "Instance" then
		local m = guard:FindFirstChild(name)
		return typeof(m) == "Instance" and m or nil
	end
	return nil
end

World.zoneBounds = function(name)
	local m = World.zoneModel(name)
	if not m then
		return nil
	end
	local part = m:FindFirstChild("Bounds")
	if typeof(part) == "Instance" and part:IsA("BasePart") then
		return part.Position, part.Size
	end
	if m:IsA("BasePart") then
		return m.Position, m.Size
	end
	return nil
end

World.zoneCenter = function(name)
	local pos = World.zoneBounds(name)
	return pos
end

World.zoneIndexByX = function(x)
	local best, bestDist = 1, math.huge
	for i, name in ipairs(AREA_NAMES) do
		local pos = World.zoneCenter(name)
		if pos then
			local d = math.abs(pos.X - x)
			if d < bestDist then
				bestDist = d
				best = i
			end
		end
	end
	return best
end

World.corridorBounds = function()
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, name in ipairs(AREA_NAMES) do
		local pos, size = World.zoneBounds(name)
		if pos and size then
			minX = math.min(minX, pos.X - size.X * 0.5)
			maxX = math.max(maxX, pos.X + size.X * 0.5)
			minZ = math.min(minZ, pos.Z - size.Z * 0.5)
			maxZ = math.max(maxZ, pos.Z + size.Z * 0.5)
		end
	end
	if minX == math.huge then
		return nil
	end
	local entry = World.entryPosition()
	minX = math.min(minX, entry.X - 20)
	return minX, maxX, minZ, maxZ
end

World.clampToCorridor = function(pos)
	local minX, maxX, minZ, maxZ = World.corridorBounds()
	if not minX then
		return pos
	end
	return Vector3.new(math.clamp(pos.X, minX, maxX), pos.Y, math.clamp(pos.Z, minZ, maxZ))
end

World.groundedY = function(x, z, y)
	local laneY = World.laneY()
	if type(y) == "number" then
		return math.clamp(y, laneY - 2, laneY + 5)
	end
	local root = localRoot()
	local halfY = root and root.Size.Y * 0.5 or 0
	local found = nil
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	local char = client and client.Character
	if typeof(char) == "Instance" then
		table.insert(exclude, char)
	end
	params.FilterDescendantsInstances = exclude
	local hit = Workspace:Raycast(Vector3.new(x, laneY + 40, z), Vector3.new(0, -160, 0), params)
	if hit then
		local name = string.lower(tostring(hit.Instance.Name))
		if string.find(name, "ground", 1, true) and hit.Position.Y <= laneY + 1.5 then
			found = hit.Position.Y
		end
	end
	if found then
		return math.clamp(found + halfY, laneY - 2, laneY + 5)
	end
	return laneY + 3
end

World.slotEggPosition = function(inst)
	if typeof(inst) ~= "Instance" then
		return nil
	end
	local part = inst:FindFirstChild("Hitbox")
		or inst:FindFirstChild("CustomBoundingBox")
		or inst:FindFirstChildOfClass("BasePart")
	if part then
		return part.Position
	end
	return inst:GetPivot().Position
end

World.placementGrid = function()
	local mod = GameAPI.Modules.PlotState
	if type(mod) ~= "table" or type(mod.GetPlotData) ~= "function" then
		return {}
	end
	local ok, plot = pcall(mod.GetPlotData, mod)
	if not ok or type(plot) ~= "table" then
		return {}
	end
	local petArea = plot.PetArea
	local center = plot.CenterPoint
	if not (typeof(petArea) == "Instance" and petArea:IsA("BasePart")) then
		return {}
	end
	if not (typeof(center) == "Instance" and center:IsA("BasePart")) then
		return {}
	end
	local grid = {}
	local xs, zs = petArea.Size.X, petArea.Size.Z
	for x = -xs * 0.5 + 5, xs * 0.5 - 5, 7 do
		for z = -zs * 0.5 + 5, zs * 0.5 - 5, 7 do
			local world = petArea.CFrame:PointToWorldSpace(Vector3.new(x, 1, z))
			table.insert(grid, center.CFrame:ToObjectSpace(CFrame.new(world)))
		end
	end
	return grid
end

World.petAreaStand = function()
	local mod = GameAPI.Modules.PlotState
	if type(mod) == "table" and type(mod.GetPlotData) == "function" then
		local ok, plot = pcall(mod.GetPlotData, mod)
		if ok and type(plot) == "table" and typeof(plot.PetArea) == "Instance" then
			return plot.PetArea.Position + Vector3.new(0, 4, 0)
		end
	end
	return World.basePosition()
end

World.treadmillStand = function()
	local folder = World.plotInfo()
	if folder then
		local part = folder:FindFirstChild("TreadmillBottom")
		if typeof(part) == "Instance" and part:IsA("BasePart") then
			return part.Position + Vector3.new(0, 4, 0)
		end
	end
	return nil
end

World.isNearPlot = function()
	local root = localRoot()
	if not root then
		return false
	end
	local mod = GameAPI.Modules.PlotState
	if type(mod) == "table" and type(mod.IsWorldPositionWithinLocalPlotBounds) == "function" then
		local ok, res = pcall(mod.IsWorldPositionWithinLocalPlotBounds, mod, root.Position)
		if ok and res == true then
			return true
		end
	end
	local stand = World.petAreaStand()
	if stand then
		return (root.Position - stand).Magnitude <= 30
	end
	return false
end

World.carrying = false
World.carriedRecord = nil
World.onCarryChange = nil

World.pollCarry = function()
	local records = GameAPI.areaEggSnapshot()
	local carrying, rec = false, nil
	if type(records) == "table" then
		for _, r in pairs(records) do
			if type(r) == "table" and r.IsCarrying == true and typeof(r.Uid) == "string" then
				carrying, rec = true, r
				break
			end
		end
	end
	if carrying ~= World.carrying then
		World.carrying = carrying
		World.carriedRecord = rec
		if type(World.onCarryChange) == "function" then
			task.spawn(World.onCarryChange, carrying, rec)
		end
	end
	return carrying, rec
end


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

function Movement.stealSpeed()
	local v = tonumber(getFlag("StealSpeed", 300)) or 300
	return math.clamp(v, 50, 1000)
end

function Movement.buildStealPath(fromPos, toPos)
	local laneZ = World.laneZ()
	local laneY = World.laneY()
	local path = {}
	if math.abs(fromPos.Z - laneZ) > 3 then
		table.insert(path, Vector3.new(fromPos.X, laneY, laneZ))
	end
	if math.abs(fromPos.X - toPos.X) > 2 then
		table.insert(path, Vector3.new(toPos.X, laneY, laneZ))
	end
	table.insert(path, Vector3.new(toPos.X, laneY, toPos.Z))
	return path
end

-- move waypoint-by-waypoint; returns true on full completion
function Movement.glideAlong(path, opts)
	opts = opts or {}
	local speed = opts.speed or Movement.stealSpeed()
	local perStop = opts.perStop or 20
	for _, pt in ipairs(path) do
		local clamped = opts.noClamp and pt or World.clampToCorridor(pt)
		local result = Movement.moveTo(clamped, { timeout = perStop, speed = speed })
		if result ~= "arrived" then
			return false
		end
		if opts.still and not opts.still() then
			return false
		end
	end
	return true
end

function Movement.applyStealSpeed()
	local hum = getHumanoid()
	if not hum then
		return
	end
	local target
	if Farm.stealEnabled() then
		target = Movement.stealSpeed()
	else
		target = tonumber(getFlag("WalkSpeedValue", 30)) or 30
		if getFlag("LockLegalWalkSpeed", true) == true then
			target = math.min(target, 16)
		end
	end
	pcall(function() hum.WalkSpeed = target end)
end

function Movement.groundedLockStep()
	if not Farm.stealEnabled() then
		return
	end
	local hrp = getHRP()
	if not hrp then
		return
	end
	local vel = hrp.AssemblyLinearVelocity
	if hrp.Position.Y > World.laneY() + 12 then
		local gy = World.groundedY(hrp.Position.X, hrp.Position.Z, hrp.Position.Y)
		pcall(function()
			hrp.CFrame = CFrame.new(hrp.Position.X, gy, hrp.Position.Z)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
		return
	end
	if math.abs(vel.Y) > 4 then
		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
		end)
	end
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
	"Mythic", "Cosmic", "Secret", "Eternal", "Divine",
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

local function isBigEgg(info)
	if getFlag("StealBigEggs", false) ~= true then
		return false
	end
	local rec = World.eggRecord(info)
	local scale = rec and tonumber(rec.AssetScale) or tonumber(info.scale)
	if not scale then
		return false
	end
	local minScale = tonumber(getFlag("StealBigEggScale", 1.5)) or 1.5
	return scale >= minScale
end

function Farm.passesFilters(info)
	local pos = info.pos
	if not pos then
		return false
	end

	if getFlag("AutoStealAll", false) == true then
		return true
	end
	if isBigEgg(info) then
		local areaSel = getSelectedList("SelectArea")
		if not listAllowsAll(areaSel) and #areaSel > 0 then
			local areaName, areaIndex = World.areaName(info)
			if not tableFind(areaSel, areaName) and not tableFind(areaSel, tostring(areaIndex)) then
				return false
			end
		end
		return true
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

Farm.placeSlotIndex = 0
local function placementCFrames()
	if not Farm._grid or os.clock() - Farm._gridAt > 10 then
		Farm._grid = World.placementGrid()
		Farm._gridAt = os.clock()
	end
	return Farm._grid
end

function Farm.placeEgg(uid)
	local grid = placementCFrames()
	if #grid == 0 then
		_, cf = World.plotInfo()
		local hrp = getHRP()
		local worldPos = hrp and hrp.Position or (cf and cf.Position) or Vector3.zero
		local localCF = cf and cf:ToObjectSpace(CFrame.new(worldPos))
		local ok = GameAPI.placeEgg(uid, localCF)
		if ok then
			return true
		end
		clickGuiButtonByText("place")
		clickGuiButtonByText("deposit")
		return false
	end
	Farm.placeSlotIndex = Farm.placeSlotIndex + 1
	local cf = grid[((Farm.placeSlotIndex - 1) % #grid) + 1]
	local ok = GameAPI.placeEgg(uid, cf)
	if ok then
		return true
	end
	clickGuiButtonByText("place")
	clickGuiButtonByText("deposit")
	return false
end

function Farm.placeStep()
	if World.carrying or not (getFlag("AutoPlace", false) == true
		or getFlag("AutoPlaceSelected", false) == true
		or getFlag("AutoPlaceAll", false) == true) then
		return
	end
	local raritySet, mutSet
	if getFlag("AutoPlaceAll", false) ~= true then
		local r = getSelectedList("LifecycleRarities")
		if not listAllowsAll(r) and #r > 0 then
			raritySet = {}
			for _, name in ipairs(r) do
				raritySet[name] = true
			end
		end
		local m = getSelectedList("LifecycleMutations")
		if not listAllowsAll(m) and #m > 0 then
			mutSet = {}
			for _, name in ipairs(m) do
				if name ~= "None" then
					mutSet[name] = true
				end
			end
		end
	end
	local uids = GameAPI.unplacedEggUids(raritySet, mutSet)
	local grid = placementCFrames()
	if #grid > 0 and #uids > #grid then
		if not Farm.plotFull() then
			Farm.plotBusyUntil = os.clock() + 30
			notify("Farm", "No free egg spots left, pausing placement 30s", "warning")
		end
		return
	end
	if Farm.plotFull() then
		return
	end
	for _, uid in ipairs(uids) do
		if World.carrying then
			break
		end
		if Farm.placeEgg(uid) then
			Farm.stats.placed = Farm.stats.placed + 1
		end
		task.wait(0.2)
	end
end
Farm.placeStep = Farm.placeStep

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

function Farm.stealEnabled()
	return getFlag("AutoSteal", false) == true
		or getFlag("AutoStealAll", false) == true
		or getFlag("StealBigEggs", false) == true
end
Farm.stealEnabled = Farm.stealEnabled

Farm.plotBusyUntil = 0
function Farm.plotFull()
	return os.clock() < Farm.plotBusyUntil
end
Farm.plotFull = Farm.plotFull

function Farm.trySteal(info)
	Farm.state = "ToEgg"
	Status.set("Moving to egg")
	local hrp = getHRP()
	if not hrp or not info.pos then
		return false
	end

	local eggPos = info.pos
	local homeX, homeZ = hrp.Position.X, hrp.Position.Z
	local homeY = World.groundedY(homeX, homeZ, hrp.Position.Y)
	local still = function()
		return Farm.stealEnabled()
	end

	local path = Movement.buildStealPath(hrp.Position, eggPos)
	if not Movement.glideAlong(path, { still = still }) then
		if Farm.failStreak >= 2 then
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
	if getFlag("AvoidGuards", false) == true then
		local radius = tonumber(getFlag("GuardRadius", 40)) or 40
		if World.nearestGuardDistance(hrp.Position, true) < radius then
			Status.set("Guard chasing, skipping")
			if getFlag("ForestGuardBypass", false) == true then
				local base = World.basePosition()
				if base then
					Movement.startFastGlide(base, 600)
				end
			end
			Farm.cooldownUntil = os.clock() + 5
			return false
		end
	end

	local gy = World.groundedY(eggPos.X, eggPos.Z, eggPos.Y)
	pcall(function()
		hrp.CFrame = CFrame.new(eggPos.X, gy, eggPos.Z)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)

	Farm.state = "Carry"
	Status.set("Stealing")
	local prompt = World.findEggPrompt(info.model)
	if prompt then
		World.triggerPrompt(prompt)
	end
	local grabbed = false
	local t0 = os.clock()
	local attempts = 0
	while os.clock() - t0 < 0.55 and attempts < 6 do
		if not Farm.stealEnabled() then
			break
		end
		attempts = attempts + 1
		GameAPI.carryEgg(info.uid)
		if findHeldEggTool() or World.carrying then
			grabbed = true
			task.wait(0.08)
			break
		end
		task.wait(0.09)
	end
	if not grabbed then
		grabbed = waitForHeldEgg(1.5)
	end

	if grabbed then
		Farm.stats.steals = Farm.stats.steals + 1
		Farm.failStreak = 0
		Watchdog.lastProgressAt = os.clock()
		maybeRareAlert(info)
		Status.set("Stolen #" .. Farm.stats.steals)
		if getFlag("AutoReturn", true) == true then
			Farm.state = "Return"
			Farm.returnToBase()
		end
		return true
	end

	Farm.stats.fails = Farm.stats.fails + 1
	Farm.failStreak = Farm.failStreak + 1
	Status.set("Steal failed")
	local back = getHRP()
	if back then
		Movement.glideAlong(Movement.buildStealPath(back.Position, Vector3.new(homeX, homeY, homeZ)), {})
	end
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
	if not Farm.stealEnabled() then
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

local function claimStep(force)
	if force == true or getFlag("AutoClaimIndex", false) == true then
		if GameAPI.claimIndexAll() then
			Status.set("Index rewards claimed")
			task.wait(1)
		end
	end
	if force == true or getFlag("AutoClaimOffline", false) == true then
		if GameAPI.claimOfflineEarnings() then
			Status.set("Offline cash collected")
			task.wait(1)
		end
	end
	if force == true or getFlag("AutoClaimGroupReward", false) == true then
		if GameAPI.redeemGroupPerk() then
			Status.set("Group perk redeemed")
			task.wait(1)
		end
	end
end
Progress.claimStep = claimStep

Progress.treadmillActive = false

function Progress.stopTreadmillTraining()
	Progress.treadmillActive = false
	pcall(GameAPI.treadmillUnequip)
	if GameAPI.doubleSpeedVisible() then
		local model = World.treadmillModel()
		local hrp = getHRP()
		if model and hrp then
			local part = model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
			if part then
				Movement.moveTo(part.Position + Vector3.new(0, 0, 14), { timeout = 10, speed = 300 })
			end
		end
		task.wait(0.3)
		if GameAPI.doubleSpeedVisible() then
			pcall(GameAPI.treadmillUnequip)
		end
	end
end
Progress.stopTreadmillTraining = Progress.stopTreadmillTraining

function Progress.treadmillWatchStep()
	if (Progress.treadmillActive or GameAPI.doubleSpeedVisible()) and getFlag("AutoTreadmill", false) ~= true then
		pcall(Progress.stopTreadmillTraining)
	end
end
Progress.treadmillWatchStep = Progress.treadmillWatchStep

local function treadmillStep()
	if getFlag("AutoTreadmill", false) ~= true then
		return
	end
	local stand = World.treadmillStand()
	local model = World.treadmillModel()
	if not stand and model then
		local part = model.PrimaryPart or model:FindFirstChildOfClass("BasePart")
		if part then
			stand = part.Position
		end
	end
	if not stand then
		return
	end
	local hrp = getHRP()
	if not hrp then
		return
	end
	local distance = (stand - hrp.Position).Magnitude
	if distance > 12 then
		if Movement.active then
			return
		end
		if Movement.moveTo(stand, { timeout = 40 }) ~= "arrived" then
			return
		end
	end
	GameAPI.treadmillEquipStatic()
	if GameAPI.doubleSpeedVisible() then
		Progress.treadmillActive = true
	end
end
Progress.treadmillStep = treadmillStep

local function treadmillUpgradeStep()
	if getFlag("AutoTreadmillUpgrade", false) ~= true then
		return
	end
	if getFlag("UpgradeTypes", nil) ~= nil then
		local types = getSelectedList("UpgradeTypes")
		if not listAllowsAll(types) and #types > 0 and tableFind(types, "Treadmill") == nil then
			return
		end
	end
	if GameAPI.buyTreadmillUpgrade() then
		Status.set("Treadmill upgraded")
		task.wait(1)
	end
end
Progress.treadmillUpgradeStep = treadmillUpgradeStep

local function baseUpgradeStep()
	if getFlag("AutoBaseUpgrade", false) ~= true then
		return
	end
	if getFlag("UpgradeTypes", nil) ~= nil then
		local types = getSelectedList("UpgradeTypes")
		if not listAllowsAll(types) and #types > 0 and tableFind(types, "Base") == nil then
			return
		end
	end
	if GameAPI.baseUpgradeNext() and GameAPI.buyBaseUpgrade() then
		Status.set("Base upgraded")
		task.wait(1)
	else
		clickGuiButtonByText("upgrade")
	end
end
Progress.baseUpgradeStep = baseUpgradeStep

Progress.lastEquipAt = 0
local function equipBestStep(force)
	local wantPets = force == true or getFlag("AutoEquipBest", false) == true
		or getFlag("AutoEquipBestGear", false) == true
	local wantBat = force == true or getFlag("AutoEquipBatBest", false) == true
	local wantTrail = force == true or getFlag("AutoEquipTrail", false) == true
		or getFlag("AutoEquipBestTrail", false) == true
	if not (wantPets or wantBat or wantTrail) then
		return
	end
	local now = os.clock()
	if now - Progress.lastEquipAt < 5 then
		return
	end
	Progress.lastEquipAt = now
	if wantPets and GameAPI.equipBestPets() then
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
	if wantTrail then
		local best = GameAPI.bestTrailName()
		local worn = GameAPI.wornTrail()
		if best and best ~= worn and GameAPI.selectTrail(best) then
			Status.set("Best trail equipped: " .. tostring(best))
			task.wait(0.5)
		elseif wantTrail and GameAPI.chooseTrail("Fastest") then
			Status.set("Best trail equipped")
			task.wait(0.5)
		end
	end
end
Progress.equipBestStep = equipBestStep

function Progress.buyTrailStep()
	if getFlag("AutoBuyTrail", false) ~= true or World.carrying then
		return
	end
	local wanted = getSelectedList("TrailWanted")
	if listAllowsAll(wanted) or #wanted == 0 then
		return
	end
	local save = GameAPI.saveData()
	if not save then
		return
	end
	local owned = save.TrailInventory
	for _, name in ipairs(wanted) do
		if type(owned) ~= "table" or owned[name] == nil then
			if GameAPI.buyTrail(name) then
				Status.set("Trail purchased: " .. tostring(name))
				notify("Progress", "Bought trail " .. tostring(name), "info")
				task.wait(0.35)
			end
		end
	end
end
Progress.buyTrailStep = Progress.buyTrailStep

function Progress.sellPetsStep()
	if getFlag("AutoSellPets", false) ~= true or World.carrying then
		return
	end
	local raritySet, mutSet
	local r = getSelectedList("SellRarities")
	if not listAllowsAll(r) and #r > 0 then
		raritySet = {}
		for _, name in ipairs(r) do
			raritySet[name] = true
		end
	end
	local m = getSelectedList("SellMutations")
	if not listAllowsAll(m) and #m > 0 then
		mutSet = {}
		for _, name in ipairs(m) do
			if name ~= "None" then
				mutSet[name] = true
			end
		end
	end
	local maxScale = tonumber(getFlag("SellMaxScale", 10)) or 10
	local uids = GameAPI.sellablePets({
		maxScale = maxScale,
		raritySet = raritySet,
		mutSet = mutSet,
		keepMutated = getFlag("SellKeepMutated", true) == true,
		keepEquipped = getFlag("SellKeepEquipped", true) == true,
	})
	local sold = 0
	for _, uid in ipairs(uids) do
		if World.carrying or getFlag("AutoSellPets", false) ~= true then
			break
		end
		if GameAPI.sellAsset(uid) then
			sold = sold + 1
		end
		task.wait(0.15)
	end
	if sold > 0 then
		Status.set("Sold " .. sold .. " pets")
		if getFlag("WebhookFuse", false) == true then
			Webhook.send("Pets Sold", sold .. " pets sold", 0x22c55e)
		end
	end
end
Progress.sellPetsStep = Progress.sellPetsStep

function Progress.sellEggsStep()
	if getFlag("AutoSellEggs", false) ~= true or World.carrying then
		return
	end
	local raritySet
	local r = getSelectedList("SellEggRarities")
	if not listAllowsAll(r) and #r > 0 then
		raritySet = {}
		for _, name in ipairs(r) do
			raritySet[name] = true
		end
	end
	local uids = GameAPI.sellableEggUids(raritySet)
	local sold = 0
	for _, uid in ipairs(uids) do
		if World.carrying or getFlag("AutoSellEggs", false) ~= true then
			break
		end
		if GameAPI.sellAsset(uid) then
			sold = sold + 1
		end
		task.wait(0.15)
	end
	if sold > 0 then
		Status.set("Sold " .. sold .. " eggs")
	end
end
Progress.sellEggsStep = Progress.sellEggsStep

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

Fusion.fusing = false
Fusion.lastFuseAt = Fusion.lastFuseAt or 0

function Fusion.pickFuseGroup()
	local groups = GameAPI.fuseGroups()
	local keepN = tonumber(getFlag("FuseKeepPerCategory", 0)) or 0
	local maxScale = tonumber(getFlag("FuseMaxScale", 10)) or 10
	local targetMode = getDropdownValue("FuseTarget", "Highest Rarity")
	local keepMutated = getFlag("FuseKeepMutated", true) == true
	local keepEquipped = getFlag("FuseKeepEquipped", true) == true
	local equipped = GameAPI.equippedUids()
	local raritySet
	local r = getSelectedList("FusionRarities")
	if not listAllowsAll(r) and #r > 0 then
		raritySet = {}
		for _, name in ipairs(r) do
			raritySet[name] = true
		end
	end
	local mutSet
	local m = getSelectedList("FuseMutations")
	if not listAllowsAll(m) and #m > 0 then
		mutSet = {}
		for _, name in ipairs(m) do
			if name ~= "None" then
				mutSet[name] = true
			end
		end
	end

	local candidates = {}
	for _, group in pairs(groups) do
		local items = {}
		for _, item in ipairs(group.items) do
			local scale = item.scale
			local skip = false
			if maxScale > 0 and scale > maxScale then
				skip = true
			end
			if not skip and keepEquipped and equipped[item.uid] then
				skip = true
			end
			if not skip and keepMutated then
				local data, rec = GameAPI.petInfo(item.uid)
				local hasMut = false
				if rec then
					hasMut = type(rec.Mutations) == "table" and next(rec.Mutations) ~= nil
					if not hasMut and typeof(rec.BaseMutation) == "string" and rec.BaseMutation ~= "" then
						hasMut = true
					end
				end
				if mutSet and next(mutSet) ~= nil then
					for _, mm in ipairs(GameAPI.eggMutations(data or rec)) do
						if mutSet[mm] then
							hasMut = true
							break
						end
					end
				end
				if hasMut then
					skip = true
				end
			end
			if not skip then
				table.insert(items, item)
			end
		end
		if #items > keepN then
			local rarity = group.rarity
			local passesRarity = true
			if raritySet and next(raritySet) ~= nil then
				passesRarity = raritySet[rarity] == true
			end
			if passesRarity then
				local rank = Farm.getRarityRank(rarity) or 0
				local score
				if targetMode == "Lowest Rarity" then
					score = -rank
				elseif targetMode == "Most Duplicates" then
					score = #items * 1000 - rank
				else
					score = rank
				end
				candidates[#candidates + 1] = {
					uidList = { items[1].uid, items[2].uid, items[3].uid },
					rarity = rarity,
					score = score,
				}
			end
		end
	end
	if #candidates == 0 then
		return nil
	end
	table.sort(candidates, function(a, b)
		if a.score == b.score then
			return a.rarity > b.rarity
		end
		return a.score > b.score
	end)
	return candidates[1]
end
Fusion.pickFuseGroup = Fusion.pickFuseGroup

local function fusionStep(forceFuse)
	if Fusion.fusing or World.carrying then
		return
	end
	local group = Fusion.pickFuseGroup()
	if not group then
		return
	end
	local fuseDelay = forceFuse == true and 1 or (tonumber(getFlag("FuseInterval", 8)) or 8)
	if (forceFuse == true or getFlag("AutoFuse", false) == true)
		and os.clock() - Fusion.lastFuseAt > fuseDelay then
		Fusion.lastFuseAt = os.clock()
		Fusion.fusing = true
		local price = GameAPI.fusePrice(group.uidList)
		local ok = GameAPI.fuse()
		if ok then
			local detail = price and (" (price " .. price .. ")") or ""
			notify("Fusion", ("Feeding %s trio%s"):format(group.rarity, detail))
			if getFlag("WebhookFuse", true) == true then
				Webhook.send("Fusion Started", ("Feeding %s trio"):format(group.rarity), 0xf59e0b)
			end
			if getFlag("FuseAutoReveal", true) == true then
				task.delay(8, function()
					clickGuiButtonByText("reveal")
					clickGuiButtonByText("open")
				end)
			end
		else
			clickGuiButtonByText("fuse")
		end
		task.wait(1)
		Fusion.fusing = false
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

ServerHop.visited = {}
ServerHop.retryAt = 0
ServerHop.busy = false
ServerHop.hopAt = os.clock()
ServerHop.noTargetSince = 0

local function rememberVisited(jobId)
	if typeof(jobId) ~= "string" or jobId == "" then
		return
	end
	local n = 0
	for _ in pairs(ServerHop.visited) do
		n = n + 1
	end
	if n >= 300 then
		ServerHop.visited = {}
	end
	ServerHop.visited[jobId] = true
end

function ServerHop.hopNow(reason)
	if ServerHop.busy then
		return false
	end
	ServerHop.busy = true
	notify("Server Hop", "Hopping: " .. tostring(reason or "requested"))
	if getFlag("WebhookEnabled", false) == true then
		Webhook.sendSummary()
		task.wait(0.6)
	end
	local ok = false
	for round = 1, 3 do
		local targets = GameAPI.pickServerTargets(ServerHop.visited)
		if #targets == 0 then
			ServerHop.retryAt = os.clock() + 30
			notify("Server Hop", "No candidates, retrying in 30s", "warning")
			ServerHop.busy = false
			return false
		end
		local n = math.min(#targets, 10)
		for i = 1, n do
			rememberVisited(targets[i].id)
			if GameAPI.teleportToJob(targets[i].id) then
				ok = true
				ServerHop.hopAt = os.clock()
				ServerHop.busy = false
				return true
			end
			task.wait(0.5)
		end
	end
	ServerHop.retryAt = os.clock() + 10
	notify("Server Hop", "Hop failed, retrying in 10s", "warning")
	ServerHop.busy = false
	return false
end
ServerHop.hopNow = ServerHop.hopNow

function ServerHop.playersHopStep()
	if getFlag("AutoServerHop", false) ~= true or ServerHop.busy then
		return
	end
	if os.clock() < ServerHop.retryAt then
		return
	end
	local mode = getDropdownValue("HopMode", "No Matching Eggs")
	local value = tonumber(getFlag("HopValue", 15)) or 15
	if mode == "No Matching Eggs" then
		World.refreshAllEggs()
		local found = false
		for _, info in pairs(World.eggs) do
			if typeof(info.model) == "Instance" and info.pos and Farm.passesFilters(info) then
				found = true
				break
			end
		end
		if found then
			ServerHop.noTargetSince = 0
			return
		end
		if ServerHop.noTargetSince == 0 then
			ServerHop.noTargetSince = os.clock()
			return
		end
		if os.clock() - ServerHop.noTargetSince >= value then
			ServerHop.noTargetSince = 0
			ServerHop.hopNow("No matching eggs in this server")
		end
	elseif mode == "Timed Interval" then
		if os.clock() - ServerHop.hopAt >= value * 60 then
			ServerHop.hopNow("Interval reached")
		end
	else
		if Farm.stats.steals >= value then
			Farm.stats.steals = 0
			ServerHop.hopNow("Steal count reached")
		end
	end
end
ServerHop.playersHopStep = ServerHop.playersHopStep

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
GameAPI.initV2()

Esp.boxes = {}
Esp.labels = {}
Esp.tracers = {}
Esp.folder = nil
local MAX_ESP_TARGETS = 60

local RARITY_COLORS = {
	Common = Color3.fromRGB(160, 160, 160),
	Uncommon = Color3.fromRGB(110, 195, 255),
	Rare = Color3.fromRGB(110, 195, 255),
	Epic = Color3.fromRGB(110, 195, 255),
	Legendary = Color3.fromRGB(255, 190, 80),
	Mythic = Color3.fromRGB(255, 190, 80),
	Cosmic = Color3.fromRGB(255, 90, 90),
	Secret = Color3.fromRGB(255, 90, 90),
	Eternal = Color3.fromRGB(255, 120, 255),
	Divine = Color3.fromRGB(255, 120, 255),
}
local function rarityColor(r)
	return RARITY_COLORS[r] or Color3.fromRGB(190, 200, 215)
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
	local guardOn = getFlag("GuardEsp", false) == true
	local petOn = getFlag("PetEsp", false) == true
	local playerOn = getFlag("PlayerEsp", false) == true
	if not (eggOn or plotOn or guardOn or petOn or playerOn) then
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
	if guardOn then
		for model, info in pairs(World.scanGuards()) do
			if typeof(model) == "Instance" and info.pos then
				local color = info.state == "Chasing"
					and Color3.fromRGB(255, 90, 90)
					or Color3.fromRGB(255, 190, 80)
				local box = ensureBox(model, color, keep)
				if box then
					local label = ensureLabel(model)
					if label then
						label.text.Text = "GUARD " .. tostring(info.state or "?")
					end
				end
			end
		end
	end
	if petOn then
		local folder = World.plotInfo()
		if folder then
			for _, d in ipairs(folder:GetDescendants()) do
				if d:IsA("Model") then
					local owner = d:GetAttribute("OwnerUserId")
					if type(owner) == "number" then
						local own = owner == (client and client.UserId)
						local color = own and Color3.fromRGB(90, 220, 90) or Color3.fromRGB(255, 120, 255)
						local box = ensureBox(d, color, keep)
						if box then
							local label = ensureLabel(d)
							if label then
								local rarity = d:GetAttribute("Rarity")
								label.text.Text = (own and "PET " or "PET? ") .. tostring(rarity or d.Name)
							end
						end
					end
				end
			end
		end
	end
	if playerOn then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= client and typeof(player.Character) == "Instance" then
				local box = ensureBox(player.Character, Color3.fromRGB(110, 195, 255), keep)
				if box then
					local label = ensureLabel(player.Character)
					if label then
						label.text.Text = player.Name
					end
				end
			end
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
	if not Farm.stealEnabled() then
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
local function antiAfkLoop()
	while true do
		task.wait(2)
		if getFlag("AntiAfk", false) == true and tick() - lastAfkTap >= 60 then
			pcall(ConfigMod.antiAfkTap)
		end
	end
end
local function setAntiAfk(enabled)
	if antiAfkConn then
		antiAfkConn:Disconnect()
		antiAfkConn = nil
	end
	if enabled and client then
		antiAfkConn = track(task.spawn(antiAfkLoop), "Core")
	end
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

-- fly / noclip (frame-driven, idle cost = one flag check)
local moveConn = RunService.Heartbeat:Connect(function(dt)
	if getFlag("Fly", false) == true then
		local hum = getHumanoid()
		local hrp = getHRP()
		local cam = Workspace.CurrentCamera
		if not hum or not hrp or not cam then
			return
		end
		pcall(function() hum.PlatformStand = true end)
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			dir = dir + cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			dir = dir - cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			dir = dir - cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			dir = dir + cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			dir = dir + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			dir = dir - Vector3.new(0, 1, 0)
		end
		if dir.Magnitude > 0 then
			local speed = tonumber(getFlag("FlySpeed", 60)) or 60
			pcall(function()
				hrp.CFrame = hrp.CFrame + dir.Unit * (speed * math.min(dt, 0.1))
			end)
		end
	elseif getFlag("NoClip", false) == true then
		local char = client and client.Character
		if typeof(char) == "Instance" then
			for _, d in ipairs(char:GetDescendants()) do
				if d:IsA("BasePart") and d.CanCollide then
					pcall(function() d.CanCollide = false end)
				end
			end
		end
	end
end)
track(moveConn, "Core")

ConfigMod.waypoints = {
	["Base"] = function()
		return World.basePosition()
	end,
	["Pet Area"] = function()
		return World.petAreaStand()
	end,
	["Treadmill"] = function()
		return World.treadmillStand()
	end,
	["Fuse Machine"] = function()
		local folder = World.plotInfo()
		if folder then
			for _, d in ipairs(folder:GetDescendants()) do
				local n = string.lower(d.Name)
				if string.find(n, "fuse", 1, true) then
					if d:IsA("BasePart") then
						return d.Position
					elseif d:IsA("Model") then
						local part = d.PrimaryPart or d:FindFirstChildOfClass("BasePart")
						if part then
							return part.Position
						end
					end
				end
			end
		end
		return World.basePosition()
	end,
	["Lobby Entry"] = function()
		return World.entryPosition()
	end,
}
for _, name in ipairs(World.areaNames) do
	ConfigMod.waypoints[name] = (function(areaName)
		return function()
			return World.zoneCenter(areaName)
		end
	end)(name)
end

function ConfigMod.resolveWaypoint(name)
	local fn = ConfigMod.waypoints[name]
	if type(fn) == "function" then
		local ok, pos = pcall(fn)
		if ok and typeof(pos) == "Vector3" then
			return pos
		end
	end
	return nil
end

function ConfigMod.teleportToWaypoint()
	local name = getDropdownValue("WaypointTarget", "Base")
	task.spawn(function()
		local dest = ConfigMod.resolveWaypoint(name)
		if not dest then
			notify("Waypoint", "That waypoint is not available right now", "warning")
			return
		end
		local result = Movement.moveTo(dest, { timeout = 90, speed = 800 })
		if result ~= "arrived" then
			notify("Waypoint", "Travel failed: " .. result, "danger")
		end
	end)
end

function ConfigMod.antiPauseStep()
	if getFlag("AntiGameplayPause", true) ~= true then
		return
	end
	local vu = svc("VirtualUser")
	if vu then
		pcall(function()
			vu:MouseMovement(2, 0)
		end)
	end
end

-- performance rendering mode + 2D stats overlay
local renderOverlay = nil
local renderLabels = {}
local function buildRenderOverlay()
	if renderOverlay and renderOverlay.Parent then
		return
	end
	local ok, gui = pcall(function()
		local g = Instance.new("ScreenGui")
		g.Name = "SAEStatOverlay"
		g.ResetOnSpawn = false
		g.DisplayOrder = 999
		return g
	end)
	if not ok then
		return
	end
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(260, 150)
	frame.Position = UDim2.fromOffset(10, 10)
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	frame.BackgroundTransparency = 0.25
	frame.CornerRadius = UDim.new(0.08, 0)
	frame.Parent = gui
	local rows = { "money", "speed", "pets", "eggs", "stolen", "session" }
	for i, key in ipairs(rows) do
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -16, 0, 20)
		lbl.Position = UDim2.new(0, 8, 0, 8 + (i - 1) * 22)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = Color3.fromRGB(232, 163, 77)
		lbl.Text = key:upper() .. "  -"
		lbl.Parent = frame
		renderLabels[key] = lbl
	end
	renderOverlay = gui
	gui.Parent = CoreGui
end

local function updateRenderOverlay()
	if not renderOverlay or not renderOverlay.Parent then
		return
	end
	local save = GameAPI.saveData()
	if not save then
		return
	end
	local sec = math.floor(os.clock() - Watchdog.sessionStart)
	local text
	if sec < 60 then
		text = sec .. "s"
	elseif sec < 3600 then
		text = string.format("%dm %ds", math.floor(sec / 60), sec % 60)
	else
		text = string.format("%dh %dm", math.floor(sec / 3600), math.floor(sec / 3600) % 60)
	end
	local values = {
		money = Webhook.fmtMoney(save.Money),
		speed = Webhook.fmtMoney(save.SpeedPower),
		pets = tostring(GameAPI.eggInventoryCount() and 0 or 0),
		eggs = tostring(GameAPI.eggInventoryCount()),
		stolen = tostring(Farm.stats.steals),
		session = text,
	}
	local petCount = 0
	if type(save.Inventory) == "table" then
		for _ in pairs(save.Inventory) do
			petCount = petCount + 1
		end
	end
	values.pets = tostring(petCount)
	for key, lbl in pairs(renderLabels) do
		if lbl and lbl.Parent then
			lbl.Text = key:upper() .. "  " .. tostring(values[key] or "-")
		end
	end
end

function ConfigMod.setDisableRendering(enabled)
	if enabled then
		buildRenderOverlay()
		pcall(function() Lighting.GlobalShadows = false end)
		pcall(function()
			if type(syn) == "table" and type(syn.set_render_scale) == "function" then
				syn.set_render_scale(0.5)
			end
		end)
	else
		if renderOverlay and renderOverlay.Parent then
			renderOverlay:Destroy()
			renderOverlay = nil
		end
		renderLabels = {}
		pcall(function() Lighting.GlobalShadows = true end)
	end
end

local function renderOverlayStep()
	if getFlag("DisableRendering", false) == true then
		pcall(updateRenderOverlay)
	elseif renderOverlay and renderOverlay.Parent then
		renderOverlay:Destroy()
		renderOverlay = nil
		renderLabels = {}
	end
end

local function registerCoreTasks()
	CoreTasks.register("Auto Steal Egg", {
		interval = 0.2,
		ready = function()
			-- farmStep handles the carrying case itself (return + place)
			return Farm.stealEnabled() and not GameAPI.eggInventoryFull()
		end,
		run = Farm.step,
	})
	CoreTasks.register("Auto Place Egg", {
		interval = 2,
		ready = function()
			local placing = getFlag("AutoPlace", false) == true
				or getFlag("AutoPlaceSelected", false) == true
				or getFlag("AutoPlaceAll", false) == true
			if not placing or World.carrying or Farm.plotFull() then
				return false
			end
			return #GameAPI.unplacedEggUids(nil, nil) > 0
		end,
		run = Farm.placeStep,
	})
	CoreTasks.register("Auto Hatch", {
		interval = 2,
		ready = function()
			return getFlag("AutoHatch", false) == true and not World.carrying
		end,
		run = Farm.hatchStep,
	})
	CoreTasks.register("Auto Treadmill", {
		interval = 4,
		ready = function()
			return getFlag("AutoTreadmill", false) == true and not World.carrying
		end,
		run = Progress.treadmillStep,
	})
end

World.onCarryChange = function(carrying, rec)
	if not carrying then
		return
	end
	Watchdog.lastProgressAt = os.clock()
	if type(rec) == "table" and typeof(rec.Uid) == "string" then
		Webhook.session.stolen = Webhook.session.stolen + 1
		Webhook.eggLogEntry(rec)
		local rarity = GameAPI.resolveRarity(rec.AssetCategory)
		local minRare = getDropdownValue("WebhookRareMin", "Epic")
		if getFlag("WebhookRare", false) == true and rarity
			and Farm.getRarityRank(rarity) >= Farm.getRarityRank(minRare) then
			local mention = Webhook.mentionForRarity(rarity)
			Webhook.send("Rare Egg Stolen",
				("**%s** in %s"):format(GameAPI.assetName(rec.AssetCategory), tostring(rec.AreaId or "?")),
				0x9b59b6, mention)
		end
	end
end

local function bootDefaults()
	registerCoreTasks()
	toggleTask("SAE_CoreTasks", true, 0.2, CoreTasks.pump)
	toggleTask("SAE_Stability", true, 1, Stability.pump)
	toggleTask("SAE_Webhook", true, 5, Webhook.webhookStep)
	toggleTask("SAE_GroundLock", true, 0.1, Movement.groundedLockStep)
	toggleTask("SAE_StealSpeed", true, 0.35, Movement.applyStealSpeed)
	toggleTask("SAE_TreadmillWatch", true, 1, Progress.treadmillWatchStep)
	toggleTask("SAE_RenderOverlay", true, 1, renderOverlayStep)
	if getFlag("AntiGameplayPause", true) == true then
		toggleTask("SAE_AntiPause", true, 1, ConfigMod.antiPauseStep)
	end
	if getFlag("AutoSell", false) == true then
		toggleTask("SAE_Sell", true, 6, Farm.sellStep)
	end
	if getFlag("AutoFavorite", false) == true then
		toggleTask("SAE_Fav", true, 10, Farm.favoriteStep)
	end
	if getFlag("AutoSellPets", false) == true then
		toggleTask("SAE_SellPets", true, tonumber(getFlag("SellInterval", 6)) or 6, Progress.sellPetsStep)
	end
	if getFlag("AutoSellEggs", false) == true then
		toggleTask("SAE_SellEggs", true, tonumber(getFlag("SellEggInterval", 8)) or 8, Progress.sellEggsStep)
	end
	if getFlag("AutoClaimIndex", false) == true then
		toggleTask("SAE_Claim", true, 8, Progress.claimStep)
	end
	if getFlag("AutoClaimOffline", false) == true then
		toggleTask("SAE_ClaimOffline", true, 15, Progress.claimStep)
	end
	if getFlag("AutoClaimGroupReward", false) == true then
		toggleTask("SAE_ClaimGroup", true, 20, Progress.claimStep)
	end
	if getFlag("AutoTreadmillUpgrade", false) == true then
		toggleTask("SAE_TreadmillUp", true, 15, Progress.treadmillUpgradeStep)
	end
	if getFlag("AutoBaseUpgrade", false) == true then
		toggleTask("SAE_BaseUp", true, 15, Progress.baseUpgradeStep)
	end
	if getFlag("AutoEquipBest", false) == true
		or getFlag("AutoEquipBestGear", false) == true
		or getFlag("AutoEquipBestTrail", false) == true
		or getFlag("AutoEquipTrail", false) == true
		or getFlag("AutoEquipBatBest", false) == true then
		toggleTask("SAE_Equip", true, 5, Progress.equipBestStep)
	end
	if getFlag("AutoBuyTrail", false) == true then
		toggleTask("SAE_BuyTrail", true, 6, Progress.buyTrailStep)
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
	-- safety is self-gating per-flag
	toggleTask("SAE_Safety", true, 0.2, Protection.safetyStep)
	if getFlag("AutoDispute", false) == true then
		toggleTask("SAE_Dispute", true, 1, Dispute.step)
	end
	-- ESP is self-gating: always-on loop, clears itself when no category is enabled
	toggleTask("SAE_Esp", true, 0.4, Esp.step)
	if getFlag("AutoFuse", false) == true then
		toggleTask("SAE_Fusion", true, tonumber(getFlag("FuseInterval", 8)) or 8, Fusion.step)
	end
	if getFlag("EventMonitor", false) == true then
		toggleTask("SAE_Event", true, 3, EventMod.step)
	end
	if getFlag("AutoServerHop", false) == true then
		toggleTask("SAE_PlayersHop", true, 3, ServerHop.playersHopStep)
	end
	if getFlag("AutoHopTarget", false) == true then
		toggleTask("SAE_TargetHop", true, 25, ServerHop.step)
	end
	if getFlag("Watchdog", false) == true then
		toggleTask("SAE_Watchdog", true, 2, watchdogStep)
	end
end
bootDefaults()
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
FarmSection:createToggle({
	Name = "Auto Steal",
	Flag = false,
	flagName = "AutoSteal",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Auto Steal All",
	Description = "steal every egg in range, ignores rarity/mutation filters",
	Flag = false,
	flagName = "AutoStealAll",
	Callback = function() end,
})
FarmSection:createSlider({
	Name = "Steal Speed",
	flagName = "StealSpeed",
	value = 300,
	minValue = 50,
	maxValue = 1000,
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Steal Big Eggs",
	Flag = false,
	flagName = "StealBigEggs",
	Callback = function() end,
})
FarmSection:createSlider({
	Name = "Big Egg Min Size (x)",
	flagName = "StealBigEggScale",
	value = 1.5,
	minValue = 1,
	maxValue = 50,
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Auto Place",
	Flag = false,
	flagName = "AutoPlace",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Place Selected Only",
	Flag = false,
	flagName = "AutoPlaceSelected",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Place All",
	Flag = false,
	flagName = "AutoPlaceAll",
	Callback = function() end,
})
FarmSection:createDropdown({
	Name = "Lifecycle Rarities",
	Description = "for Place Selected — which rarities to place",
	flagName = "LifecycleRarities",
	Flag = { "All" },
	List = RARITY_MULTI,
	multi = true,
	Callback = function() end,
})
FarmSection:createDropdown({
	Name = "Lifecycle Mutations",
	flagName = "LifecycleMutations",
	Flag = { "All" },
	List = MUTATION_OPTIONS,
	multi = true,
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Auto Hatch",
	Flag = false,
	flagName = "AutoHatch",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Auto Return to Base",
	Description = "return with the carried egg and place it",
	Flag = true,
	flagName = "AutoReturn",
	Callback = function() end,
})
FarmSection:createLabel({
	Name = "Priority System",
	Special = true,
})
FarmSection:createDropdown({
	Name = "Priority 1",
	flagName = "PrioritySlot1",
	Flag = { "Auto Steal Egg" },
	List = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill" },
	Callback = function() end,
})
FarmSection:createDropdown({
	Name = "Priority 2",
	flagName = "PrioritySlot2",
	Flag = { "Auto Place Egg" },
	List = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill" },
	Callback = function() end,
})
FarmSection:createDropdown({
	Name = "Priority 3",
	flagName = "PrioritySlot3",
	Flag = { "Auto Hatch" },
	List = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill" },
	Callback = function() end,
})
FarmSection:createDropdown({
	Name = "Priority 4",
	flagName = "PrioritySlot4",
	Flag = { "Auto Treadmill" },
	List = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill" },
	Callback = function() end,
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
FarmSection:createSlider({
	Name = "Sell Max Scale (x)",
	Description = "only sell pets at or under this scale",
	flagName = "SellMaxScale",
	value = 10,
	minValue = 0,
	maxValue = 10,
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Never Sell Mutated",
	Flag = true,
	flagName = "SellKeepMutated",
	Callback = function() end,
})
FarmSection:createToggle({
	Name = "Never Sell Equipped",
	Flag = true,
	flagName = "SellKeepEquipped",
	Callback = function() end,
})
addIntervalToggle(FarmSection, {
	Name = "Auto Sell Pets",
	flagName = "AutoSellPets",
	tag = "SAE_SellPets",
	delay = 6,
	Step = Progress.sellPetsStep,
	Flag = false,
})
FarmSection:createSlider({
	Name = "Sell Interval (s)",
	flagName = "SellInterval",
	value = 6,
	minValue = 1,
	maxValue = 120,
	Callback = function() end,
})
addIntervalToggle(FarmSection, {
	Name = "Auto Sell Eggs",
	flagName = "AutoSellEggs",
	tag = "SAE_SellEggs",
	delay = 8,
	Step = Progress.sellEggsStep,
	Flag = false,
})
FarmSection:createDropdown({
	Name = "Sell Egg Rarities",
	flagName = "SellEggRarities",
	Flag = { "All" },
	List = RARITY_MULTI,
	multi = true,
	Callback = function() end,
})
FarmSection:createSlider({
	Name = "Sell Egg Interval (s)",
	flagName = "SellEggInterval",
	value = 8,
	minValue = 1,
	maxValue = 120,
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
	List = { "Rarest", "Nearest", "Furthest", "Biggest Size" },
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
ProgressSection:createToggle({
	Name = "AFK Treadmill",
	Flag = false,
	flagName = "AutoTreadmill",
	Callback = function() end,
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
	delay = 15,
	Step = Progress.baseUpgradeStep,
})
ProgressSection:createDropdown({
	Name = "Upgrade Types",
	Description = "which upgrades auto-buy covers",
	flagName = "UpgradeTypes",
	Flag = { "Base", "Treadmill" },
	List = { "Base", "Treadmill" },
	multi = true,
	Callback = function() end,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Claim Group Reward",
	flagName = "AutoClaimGroupReward",
	tag = "SAE_ClaimGroup",
	delay = 20,
	Step = Progress.claimStep,
	Flag = false,
})
ProgressSection:createLabel({
	Name = "Utility",
	Special = true,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Equip Best Pets",
	flagName = "AutoEquipBest",
	tag = "SAE_Equip",
	delay = 5,
	Step = Progress.equipBestStep,
})
addIntervalToggle(ProgressSection, {
	Name = "Buy and Equip Best Trail",
	flagName = "AutoEquipTrail",
	tag = "SAE_Equip",
	delay = 5,
	Step = Progress.equipBestStep,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Equip Best Bat",
	flagName = "AutoEquipBatBest",
	tag = "SAE_Equip",
	delay = 5,
	Step = Progress.equipBestStep,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Equip Best Trail",
	flagName = "AutoEquipBestTrail",
	tag = "SAE_Equip",
	delay = 5,
	Step = Progress.equipBestStep,
	Flag = false,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Equip Best Gear",
	flagName = "AutoEquipBestGear",
	tag = "SAE_Equip",
	delay = 5,
	Step = Progress.equipBestStep,
	Flag = false,
})
ProgressSection:createLabel({
	Name = "Trails",
	Special = true,
})
addIntervalToggle(ProgressSection, {
	Name = "Auto Buy Trail",
	flagName = "AutoBuyTrail",
	tag = "SAE_BuyTrail",
	delay = 6,
	Step = Progress.buyTrailStep,
	Flag = false,
})
do
	local trailNames = { "All" }
	local names = GameAPI.trailData()
	local count = 0
	for name in pairs(names) do
		count = count + 1
		if count <= 40 then
			table.insert(trailNames, name)
		end
	end
	table.sort(trailNames, function(a, b)
		if a == "All" then return true end
		if b == "All" then return false end
		return a < b
	end)
	ProgressSection:createDropdown({
		Name = "Trail Wanted",
		Description = "trails to auto-buy when you can afford them",
		flagName = "TrailWanted",
		Flag = { "All" },
		List = trailNames,
		multi = true,
		Callback = function() end,
	})
end

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
ProtectionSection:createToggle({
	Name = "Anti Ragdoll / Anti Hit",
	Flag = false,
	flagName = "AntiRagdoll",
	Callback = function() end,
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
EspSection:createToggle({
	Name = "Enable ESP",
	Flag = false,
	flagName = "EggEsp",
	Callback = function() end,
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
EspSection:createToggle({
	Name = "Guard ESP",
	Flag = false,
	flagName = "GuardEsp",
	Callback = function() end,
})
EspSection:createToggle({
	Name = "Pet ESP",
	Flag = false,
	flagName = "PetEsp",
	Callback = function() end,
})
EspSection:createToggle({
	Name = "Player ESP",
	Flag = false,
	flagName = "PlayerEsp",
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
FusionSection:createDropdown({
	Name = "Pick Group By",
	flagName = "FuseTarget",
	Flag = { "Highest Rarity" },
	List = { "Highest Rarity", "Lowest Rarity", "Most Duplicates" },
	Callback = function() end,
})
FusionSection:createSlider({
	Name = "Keep Per Pet Type",
	Description = "keep this many smallest pets of each type unfused",
	flagName = "FuseKeepPerCategory",
	value = 0,
	minValue = 0,
	maxValue = 20,
	Callback = function() end,
})
FusionSection:createSlider({
	Name = "Fuse Max Scale (x)",
	flagName = "FuseMaxScale",
	value = 10,
	minValue = 0,
	maxValue = 10,
	Callback = function() end,
})
FusionSection:createToggle({
	Name = "Never Fuse Mutated",
	Flag = true,
	flagName = "FuseKeepMutated",
	Callback = function() end,
})
FusionSection:createToggle({
	Name = "Never Fuse Equipped",
	Flag = true,
	flagName = "FuseKeepEquipped",
	Callback = function() end,
})
FusionSection:createToggle({
	Name = "Auto Complete Reveal",
	Flag = true,
	flagName = "FuseAutoReveal",
	Callback = function() end,
})
FusionSection:createSlider({
	Name = "Fuse Interval (s)",
	flagName = "FuseInterval",
	value = 8,
	minValue = 1,
	maxValue = 120,
	Callback = function() end,
})
addIntervalToggle(FusionSection, {
	Name = "Auto Fuse",
	flagName = "AutoFuse",
	tag = "SAE_Fusion",
	delay = 8,
	Step = Fusion.step,
	Flag = false,
})
FusionSection:createButton({
	Name = "Fuse Now",
	Callback = function()
		task.spawn(function()
			Fusion.step(true)
		end)
	end,
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
addIntervalToggle(HopSection, {
	Name = "Auto Server Hop",
	Description = "hop by player count / interval / steal count",
	flagName = "AutoServerHop",
	tag = "SAE_PlayersHop",
	delay = 3,
	Step = ServerHop.playersHopStep,
	Flag = false,
})
HopSection:createDropdown({
	Name = "Hop When",
	flagName = "HopMode",
	Flag = { "No Matching Eggs" },
	List = { "No Matching Eggs", "Timed Interval", "After Steal Count" },
	Callback = function() end,
})
HopSection:createSlider({
	Name = "Hop Threshold",
	Description = "No Matching Eggs: seconds | Timed Interval: minutes | After Steal Count: eggs",
	flagName = "HopValue",
	value = 15,
	minValue = 1,
	maxValue = 200,
	Callback = function() end,
})
HopSection:createButton({
	Name = "Hop Now",
	Callback = function()
		task.spawn(function()
			ServerHop.hopNow("Manual hop")
		end)
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
WebhookSection:createInputBox({
	Name = "Ping User ID",
	Description = "numeric Discord user id to mention in alerts",
	flagName = "WebhookPingId",
	Flag = "",
	Callback = function() end,
})
WebhookSection:createToggle({
	Name = "List Spawned Eggs",
	Flag = true,
	flagName = "WebhookEggSpawns",
	Callback = function() end,
})
WebhookSection:createSlider({
	Name = "Summary Interval (min)",
	flagName = "WebhookSummaryInterval",
	value = 15,
	minValue = 1,
	maxValue = 180,
	Callback = function() end,
})
WebhookSection:createButton({
	Name = "Send Summary Now",
	Callback = function()
		task.spawn(function()
			local ok = Webhook.sendSummary()
			notify("Webhook", ok and "Summary sent" or "Webhook send failed", ok and "info" or "danger")
		end)
	end,
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
	Name = "Fly",
	Flag = false,
	flagName = "Fly",
	Callback = function() end,
})
ConfigSection:createSlider({
	Name = "Fly Speed",
	flagName = "FlySpeed",
	value = 60,
	minValue = 10,
	maxValue = 400,
	Callback = function() end,
})
ConfigSection:createToggle({
	Name = "No Clip",
	Flag = false,
	flagName = "NoClip",
	Callback = function() end,
})
ConfigSection:createDropdown({
	Name = "Waypoint",
	flagName = "WaypointTarget",
	Flag = { "Base" },
	List = { "Base", "Pet Area", "Treadmill", "Fuse Machine", "Lobby Entry",
		"Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic" },
	Callback = function() end,
})
ConfigSection:createButton({
	Name = "Travel to Waypoint",
	Callback = function()
		ConfigMod.teleportToWaypoint()
	end,
})
ConfigSection:createToggle({
	Name = "Performance Overlay",
	Description = "disable 3D rendering for FPS, shows live stats",
	Flag = false,
	flagName = "DisableRendering",
	Callback = function() end,
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
addIntervalToggle(ConfigSection, {
	Name = "No Gameplay Paused",
	Description = "keeps sending input so the game never pauses",
	flagName = "AntiGameplayPause",
	tag = "SAE_AntiPause",
	delay = 1,
	Step = ConfigMod.antiPauseStep,
	Flag = true,
})
ConfigSection:createToggle({
	Name = "Auto Reconnect",
	Description = "rejoins when Roblox shows an error/disconnect prompt",
	Flag = false,
	flagName = "AutoReconnect",
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

