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
-- services not covered by the bypass head
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local WorkspaceRef = Workspace
local CameraRef = Workspace.CurrentCamera or Camera

-- game modules (pcall + fallback stubs so the hub degrades gracefully)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
pcall(function()
	local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
	pcall(function() require(SharedFolder.Globals.Constants) end)
	pcall(function() Save = require(SharedFolder.Save) end)
	pcall(function() require(SharedFolder.Types.Eggs) end)
	pcall(function() require(SharedFolder.Util.AssetItems) end)
	pcall(function() require(SharedFolder.Util.FuseKernel) end)
	pcall(function() require(SharedFolder.Util.AreaEggSlotIdentity) end)
end)
pcall(function() require(ReplicatedStorage.Client.BaseUpgrade) end)
pcall(function() require(ReplicatedStorage.Client.EggState) end)
pcall(function() require(ReplicatedStorage.Client.PlotState) end)
pcall(function() require(ReplicatedStorage.Client.AssetRoster) end)
pcall(function() require(ReplicatedStorage.Data.Areas) end)
pcall(function() require(ReplicatedStorage.Data.Assets) end)
pcall(function() require(ReplicatedStorage.Data.Gears) end)
pcall(function() require(ReplicatedStorage.Data.Trails) end)
pcall(function() require(ReplicatedStorage.Data.Treadmills) end)

local SaveModule = Save
local EggsTypes
do
	local ok, mod = pcall(function()
		return require(Shared.Types.Eggs)
	end)
	EggsTypes = (ok and typeof(mod) == "table") and mod or { MAX_INVENTORY = math.huge }
end
local EggStateModule
local PlotStateModule
local AssetRoster
local BaseUpgradeModule
local TreadmillData
local TrailsData
local AssetItems
local FuseKernel
pcall(function()
	local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
	Remotes = Remotes or require(SharedFolder:WaitForChild("Remotes"))
	pcall(function()
		SaveModule = require(SharedFolder.Save)
	end)
	pcall(function()
		AssetItems = require(SharedFolder.Util.AssetItems)
	end)
	pcall(function()
		FuseKernel = require(SharedFolder.Util.FuseKernel)
	end)
end)
pcall(function()
	EggStateModule = require(ReplicatedStorage.Client.EggState)
end)
pcall(function()
	PlotStateModule = require(ReplicatedStorage.Client.PlotState)
end)
pcall(function()
	AssetRoster = require(ReplicatedStorage.Client.AssetRoster)
end)
pcall(function()
	BaseUpgradeModule = require(ReplicatedStorage.Client.BaseUpgrade)
end)
pcall(function()
	TreadmillData = require(ReplicatedStorage.Data.Treadmills)
end)
pcall(function()
	TrailsData = require(ReplicatedStorage.Data.Trails)
end)

local moduleStub = function() return {} end
local function ensureModule(name, mod, stub)
	if mod == nil then
		return stub
	end
	return mod
end
SaveModule = ensureModule("Save", SaveModule, { Get = function() return nil end })
EggStateModule = ensureModule("EggState", EggStateModule, {
	GetAreaEggSnapshot = function() return nil end,
	RequestAreaEggSnapshot = function() end,
	RequestDropHeldAreaEgg = function() end,
	DropFieldEgg = function() end,
})
PlotStateModule = ensureModule("PlotState", PlotStateModule, {
	GetRespawnPointCFrame = function() end,
	GetPlotData = function() end,
	IsWorldPositionWithinLocalPlotBounds = function() return false end,
})
AssetRoster = ensureModule("AssetRoster", AssetRoster, { Directory = {} })
BaseUpgradeModule = ensureModule("BaseUpgrade", BaseUpgradeModule, {
	IsNextTierAffordable = function() return false end,
	PurchaseNextTier = function() end,
})
TreadmillData = ensureModule("Treadmills", TreadmillData, { GetByUpgradeLevel = function() end })
AssetItems = ensureModule("AssetItems", AssetItems, { Deserialize = function() end })
FuseKernel = ensureModule("FuseKernel", FuseKernel, { CalculateFusePrice = function() end })

-- world folders
local AreasFolder = nil
local GuardAreas = nil
local EggSlotsClient = nil
local EspFolder = Workspace:FindFirstChild("SAEEsp")
if not EspFolder then
	EspFolder = Instance.new("Folder")
	EspFolder.Name = "SAEEsp"
	EspFolder.Parent = Workspace
end
pcall(function()
	local Objects = Workspace:WaitForChild("__OBJECTS", 10)
	AreasFolder = Objects and Objects:WaitForChild("Areas", 10)
	GuardAreas = AreasFolder and AreasFolder:FindFirstChild("GuardAreas")
end)
EggSlotsClient = Workspace:FindFirstChild("AreaEggSlotsClient")

-- constants
local GAME_TITLE = "Steal an Egg"
local ACCENT = "#e8a34d"
local PLACE_ID = 8916037983
local OVERLAY_FIELDS = { "money", "speed", "pets", "eggs", "stolen", "session" }
local HOP_MODES = { "No Matching Eggs", "Timed Interval", "After Steal Count" }
local PRIORITY_SLOTS = { "PrioritySlot1", "PrioritySlot2", "PrioritySlot3", "PrioritySlot4" }
local TASK_NAMES = { "Auto Steal Egg", "Auto Place Egg", "Auto Hatch", "Auto Treadmill" }
local RARITY_RANK = {
	Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5,
	Mythic = 6, Cosmic = 7, Secret = 8, Eternal = 9, Divine = 10,
}
local RARITY_NAMES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine" }
local AREA_NAMES = { "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic" }
local MUTATION_NAMES = { "Golden", "Rainbow", "Silver" }
local STEAL_TIMING = { GrabDelay = 0.55, ReturnPace = 0.12, ArriveDistance = 1.35, MoveTimeout = 14 }
local RETURN_SNAP_PACE = 0.08

-- state
local Carrying = false
local lastAntiAfk = 0
local plotBusyUntil = 0
local busyLock = false
local treadmillEquipped = false
local overlayGui = nil
local overlayLabels = {}
local visitedServers = {}
local lastInputTick = 0
local sessionStart = os.clock()
local stolenCount = 0
local lastEquipAt = 0
local hopsSinceSummary = 0
local petsSinceSummary = 0
local rebirthsSinceSummary = 0
local summaryInitialized = false
local lastSummaryAt = 0
local lastHopClock = 0
local noMatchTimer = 0
local hopCooldownUntil = 0
local hopInFlight = false
local spawnedEggs = {}
local knownPetUids = {}
local knownEggUids = {}
local lastRebirth = 0
local lastStealCount = 0
local obtainedEggLines = {}
local moneyDisplay = nil
local taskLastRun = {}
local executorName = "unknown"
local disconnectHandled = false
local trailNames = {}
local trailPrices = {}
local trailIds = {}

if identifyexecutor then
	pcall(function()
		local name, ver = identifyexecutor()
		if typeof(name) == "string" and name ~= "" then
			executorName = name
			if typeof(ver) == "string" and ver ~= "" then
				executorName = name .. " " .. ver
			end
		end
	end)
end

-- UI library (single source, retried)
local librarySource = nil
for _ = 1, 3 do
	local ok, src = pcall(function()
		return game:HttpGet("https://versusairlines.top/scripts/NewLibrary.lua")
	end)
	if ok and typeof(src) == "string" and #src > 1000 then
		librarySource = src
		break
	end
	task.wait(2)
end
if not librarySource then
	error("Failed to load the UI library")
end
local Library = loadstring(librarySource)()

local FN = {}

-- core helpers (versus NewLibrary stores every element value in Library.Flags[flagName])
function FN.isOn(name)
	local flags = Library and Library.Flags
	if type(flags) ~= "table" then
		return false
	end
	return flags[name] == true
end

function FN.optionValue(name, fallback)
	local flags = Library and Library.Flags
	if type(flags) ~= "table" then
		return fallback
	end
	local value = flags[name]
	if value == nil then
		return fallback
	end
	return value
end

function FN.firstSelected(name, fallback)
	local raw = FN.optionValue(name, nil)
	if typeof(raw) == "table" then
		return raw[1] or fallback
	end
	if typeof(raw) == "string" and raw ~= "" then
		return raw
	end
	return fallback
end

function FN.multiSelected(name)
	local raw = FN.optionValue(name, {})
	if typeof(raw) ~= "table" then
		return {}
	end
	local set = {}
	for key, value in pairs(raw) do
		if typeof(key) == "number" then
			set[value] = true
		elseif value == true then
			set[key] = true
		end
	end
	return set
end

function FN.multiHasAny(name)
	return next(FN.multiSelected(name)) ~= nil
end

function FN.selectionAllows(name, value)
	if not FN.multiHasAny(name) then
		return true
	end
	return FN.multiSelected(name)[value] == true
end

function FN.countTable(t)
	if typeof(t) ~= "table" then
		return 0
	end
	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end
	return n
end

function FN.getSave()
	local ok, save = pcall(function()
		return SaveModule.Get()
	end)
	if ok then
		return save
	end
	return nil
end

function FN.getRoot()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

function FN.getHumanoid()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

function FN.isCarrying()
	return Carrying
end

function FN.resolveRarity(assetId)
	if typeof(assetId) ~= "string" then
		return nil
	end
	local rec = AssetRoster.Directory[assetId]
	if not rec or not rec.Rarity then
		return nil
	end
	return rec.Rarity._id or rec.Rarity.DisplayName
end

function FN.assetName(id)
	id = id or ""
	local rec = AssetRoster.Directory[id]
	if rec and rec.DisplayName then
		return rec.DisplayName
	end
	if id ~= "" then
		return tostring(id)
	end
	return "Unknown"
end

function FN.gearBaseName(name)
	return (tostring(name):gsub("%s*%[X%d+%]%s*$", ""))
end

function FN.formatNumber(n)
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

function FN.formatElapsed(sec)
	local total = math.max(0, math.floor(sec))
	local h = math.floor(total / 3600)
	local m = math.floor(total % 3600 / 60)
	if h > 0 then
		return string.format("%dh %dm", h, m)
	end
	return string.format("%dm", m)
end

function FN.formatSession(sec)
	sec = math.max(0, math.floor(sec))
	if sec < 60 then
		return sec .. "s"
	end
	if sec < 3600 then
		return string.format("%dm %ds", sec // 60, sec % 60)
	end
	return string.format("%dh %dm", sec // 3600, sec // 3600 // 60)
end

function FN.colored(text, hex)
	return string.format('<font color="%s">%s</font>', hex, text)
end

function FN.field(name, value, hex)
	return string.format("<b>%s</b> %s %s", name, FN.colored("-", "#5a6070"), FN.colored(value, hex))
end

function FN.embedField(name, value, inline)
	return { name = name, value = value, inline = inline ~= false }
end

local toastGui = nil

function FN.toast(msg)
	local ok = pcall(function()
		if not toastGui or not toastGui.Parent then
			local gui = Instance.new("ScreenGui")
			gui.Name = "SAEToasts"
			gui.ResetOnSpawn = false
			gui.DisplayOrder = 2147483000
			gui.IgnoreGuiInset = true
			gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			gui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5)
			toastGui = gui
		end
		for _, old in ipairs(toastGui:GetChildren()) do
			pcall(function()
				old:Destroy()
			end)
		end
		local label = Instance.new("TextLabel")
		label.Name = "Toast"
		label.Size = UDim2.new(0, 340, 0, 34)
		label.Position = UDim2.new(0.5, -170, 0, 10)
		label.BackgroundColor3 = Color3.fromRGB(28, 31, 36)
		label.BackgroundTransparency = 0
		label.BorderSizePixel = 0
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.TextWrapped = true
		label.Text = tostring(msg)
		label.TextColor3 = Color3.fromRGB(235, 240, 250)
		label.TextStrokeTransparency = 0.25
		label.ZIndex = 1
		label.Parent = toastGui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = label
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(82, 171, 255)
		stroke.Thickness = 1.5
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = label
		task.spawn(function()
			task.wait(2.4)
			for _ = 1, 10 do
				label.TextTransparency = label.TextTransparency + 0.1
				label.BackgroundTransparency = label.BackgroundTransparency + 0.1
				stroke.Transparency = stroke.Transparency + 0.1
				task.wait(0.08)
			end
			pcall(function()
				label:Destroy()
			end)
		end)
	end)
	if not ok then
		warn("toast failed: " .. tostring(ok))
	end
end

function FN.notify(msg)
	FN.toast(msg)
end

function FN.copyText(text, msg)
	if setclipboard then
		setclipboard(text)
	elseif toclipboard then
		toclipboard(text)
	end
	FN.notify(msg)
end

function FN.copyJoinScript()
	local script = string.format(
		'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)',
		game.PlaceId, tostring(game.JobId)
	)
	FN.copyText(script, "Copied join script to clipboard")
end

-- trail catalog from Data.Trails
pcall(function()
	if typeof(TrailsData) ~= "table" then
		return
	end
	local function catalog(entries)
		for _, entry in entries do
			if typeof(entry) == "table" then
				local name = entry.Name or entry.DisplayName or entry._id
				local id = entry.Id or entry._id or name
				local price = tonumber(entry.Price or entry.Cost)
				if typeof(name) == "string" and name ~= "" then
					table.insert(trailNames, name)
					trailIds[name] = id
					if price then
						trailPrices[name] = price
					end
				end
			end
		end
	end
	if typeof(TrailsData) == "table" then
		if typeof(TrailsData.Trails) == "table" then
			catalog(TrailsData.Trails)
		elseif typeof(next(TrailsData)) == "string" then
			catalog(TrailsData)
		end
	end
	if #trailNames == 0 and typeof(AssetRoster.Directory) == "table" then
		for id, rec in pairs(AssetRoster.Directory) do
			if typeof(rec) == "table" and (rec.Category == "Trail" or rec.Type == "Trail") then
				table.insert(trailNames, rec.DisplayName or id)
				trailIds[rec.DisplayName or id] = id
			end
		end
		table.sort(trailNames)
	end
end)
-- world geometry
function FN.getZoneModel(name)
	if not GuardAreas then
		return nil
	end
	return GuardAreas:FindFirstChild(name)
end

function FN.getZoneLaneCenter(name)
	local model = FN.getZoneModel(name)
	local pos
	if model then
		local bounds = model:FindFirstChild("Bounds")
		pos = (bounds and bounds:IsA("BasePart")) and bounds.Position or (model:IsA("BasePart") and model.Position)
	end
	if not pos then
		return nil
	end
	local laneY = FN.getLaneY()
	local laneZ = FN.getLaneZ()
	return Vector3.new(pos.X, laneY, laneZ)
end

function FN.getZoneIndex(name)
	for i, area in ipairs(AREA_NAMES) do
		if area == name then
			return i
		end
	end
	return nil
end

function FN.getZoneIndexByX(x)
	local bestDist = math.huge
	local bestIdx = 1
	for i, name in ipairs(AREA_NAMES) do
		local center = FN.getZoneLaneCenter(name)
		if center then
			local dist = math.abs(center.X - x)
			if dist < bestDist then
				bestDist = dist
				bestIdx = i
			end
		end
	end
	return bestIdx
end

function FN.getLaneZ()
	local part = AreasFolder and AreasFolder:FindFirstChild("GameplayZ")
	if part and part:IsA("BasePart") then
		return part.Position.Z
	end
	part = AreasFolder and AreasFolder:FindFirstChild("SeparationLine")
	if part and part:IsA("BasePart") then
		return part.Position.Z
	end
	return -365.5
end

function FN.getLaneY()
	local part = AreasFolder and AreasFolder:FindFirstChild("GameplayZ")
	if part and part:IsA("BasePart") then
		return part.Position.Y + 3
	end
	local root = FN.getRoot()
	if root then
		return root.Position.Y
	end
	return 70
end

function FN.getEntryPosition()
	local part = AreasFolder and AreasFolder:FindFirstChild("StartArea")
	if part and part:IsA("BasePart") then
		return Vector3.new(part.Position.X, FN.getLaneY(), FN.getLaneZ())
	end
	part = AreasFolder and AreasFolder:FindFirstChild("SeparationLine")
	if part and part:IsA("BasePart") then
		return Vector3.new(part.Position.X, FN.getLaneY(), FN.getLaneZ())
	end
	return Vector3.new(543.5, FN.getLaneY(), FN.getLaneZ())
end

function FN.getCorridorBounds()
	local xMin, xMax, zMin, zMax = math.huge, -math.huge, math.huge, -math.huge
	for _, name in ipairs(AREA_NAMES) do
		local model = FN.getZoneModel(name)
		if model then
			local part = model:FindFirstChild("Bounds")
			if part then
				model = part
			end
			if model:IsA("BasePart") then
				local hx = model.Size.X * 0.5
				local hz = model.Size.Z * 0.5
				xMin = math.min(xMin, model.Position.X - hx)
				xMax = math.max(xMax, model.Position.X + hx)
				zMin = math.min(zMin, model.Position.Z - hz)
				zMax = math.max(zMax, model.Position.Z + hz)
			end
		end
	end
	local entry = FN.getEntryPosition()
	xMin = math.min(xMin, entry.X - 20)
	return xMin, xMax, zMin, zMax
end

function FN.clampToCorridor(pos, skip)
	if skip then
		return pos
	end
	local xMin, xMax, zMin, zMax = FN.getCorridorBounds()
	return Vector3.new(math.clamp(pos.X, xMin, xMax), pos.Y, math.clamp(pos.Z, zMin, zMax))
end

function FN.groundedY(x, z, hint)
	local laneY = FN.getLaneY()
	local root = FN.getRoot()
	local humanoid = FN.getHumanoid()
	if typeof(hint) == "number" then
		return math.clamp(hint, laneY - 2, laneY + 5)
	end
	local offset = 0
	if root then
		offset = root.Size.Y * 0.5
	end
	if humanoid and humanoid.HipHeight > 0 then
		offset = humanoid.HipHeight
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	if LocalPlayer.Character then
		table.insert(exclude, LocalPlayer.Character)
	end
	params.FilterDescendantsInstances = exclude
	for _ = 1, 20 do
		local hit = WorkspaceRef:Raycast(Vector3.new(x, laneY + 40, z), Vector3.new(0, -160, 0), params)
		if not hit then
			break
		end
		local isGround = string.find(string.lower(hit.Instance.Name), "ground", 1, true) ~= nil
		if isGround or hit.Position.Y <= laneY + 1.5 then
			return math.clamp(hit.Position.Y + offset, laneY - 2, laneY + 5)
		end
		table.insert(exclude, hit.Instance)
	end
	return laneY + 3
end

function FN.getBasePosition()
	local cf = PlotStateModule.GetRespawnPointCFrame()
	if cf then
		return cf.Position
	end
	local plot = PlotStateModule.GetPlotData()
	if plot and plot.CenterPoint then
		return plot.CenterPoint.Position
	end
	if plot and plot.PetArea then
		return plot.PetArea.Position
	end
	return nil
end

function FN.getPetAreaStandPosition()
	local plot = PlotStateModule.GetPlotData()
	if plot and plot.PetArea then
		return plot.PetArea.Position + Vector3.new(0, 4, 0)
	end
	return FN.getBasePosition()
end

function FN.getTreadmillStand()
	local plot = PlotStateModule.GetPlotData()
	local folder = plot and plot.PlotFolder
	if not folder then
		return nil
	end
	local part = folder:FindFirstChild("TreadmillBottom")
	if part and part:IsA("BasePart") then
		return part.Position + Vector3.new(0, 4, 0)
	end
	return nil
end

function FN.getFuseMachinePosition()
	local plot = PlotStateModule.GetPlotData()
	local folder = plot and plot.PlotFolder
	if not folder then
		return nil
	end
	for _, name in ipairs({ "FuseMachine", "Fuse", "FusionMachine" }) do
		local part = folder:FindFirstChild(name)
		if part then
			if part:IsA("BasePart") then
				return part.Position + Vector3.new(0, 4, 0)
			end
			local model = part:FindFirstChildOfClass("BasePart")
			if model then
				return model.Position + Vector3.new(0, 4, 0)
			end
		end
	end
	return FN.getPetAreaStandPosition()
end

function FN.getPlacementLocalCFrames()
	local plot = PlotStateModule.GetPlotData()
	if not plot or not plot.PetArea or not plot.CenterPoint then
		return {}
	end
	local size = plot.PetArea.Size
	local frames = {}
	local step = 7
	local xStart = -size.X * 0.5 + 5
	local xEnd = size.X * 0.5 - 5
	local zStart = -size.Z * 0.5 + 5
	local zEnd = size.Z * 0.5 - 5
	for x = xStart, xEnd, step do
		for z = zStart, zEnd, step do
			local world = plot.PetArea.CFrame:PointToWorldSpace(Vector3.new(x, 1, z))
			table.insert(frames, plot.PetArea.CFrame:ToObjectSpace(CFrame.new(world)))
		end
	end
	return frames
end

function FN.getSlotEggPosition(inst)
	local part = inst:FindFirstChild("Hitbox")
		or inst:FindFirstChild("CustomBoundingBox")
		or inst:FindFirstChildOfClass("BasePart")
	if part then
		return part.Position
	end
	return inst:GetPivot().Position
end

function FN.getEggPosition(rec)
	local cf = rec.BottomCFrame or rec.BoundsCFrame
	if not cf then
		return nil
	end
	local p = cf.Position
	local _, _, zMin, zMax = FN.getCorridorBounds()
	return Vector3.new(p.X, p.Y + 2, math.clamp(p.Z, zMin, zMax))
end

function FN.isNearPlot()
	local root = FN.getRoot()
	if not root then
		return false
	end
	if PlotStateModule.IsWorldPositionWithinLocalPlotBounds(root.Position) then
		return true
	end
	local stand = FN.getPetAreaStandPosition()
	if not stand then
		return false
	end
	return (root.Position - stand).Magnitude <= 30
end

function FN.isPlotFull()
	return os.clock() < plotBusyUntil
end

function FN.markPlotFull()
	if FN.isPlotFull() then
		return
	end
	plotBusyUntil = os.clock() + 30
	FN.notify("Farm has no free egg spots left")
end

function FN.ensureAtPlot(still)
	if still and not still() then
		return false
	end
	if FN.isNearPlot() then
		return true
	end
	local stand = FN.getPetAreaStandPosition()
	if not stand then
		return false
	end
	return FN.travelTo(stand, true)
end

function FN.withinEspRange(pos)
	local root = FN.getRoot()
	if not root then
		return false
	end
	return (root.Position - pos).Magnitude <= FN.espDistanceLimit()
end

function FN.espDistanceLimit()
	return tonumber(FN.optionValue("EspDistance", 2000)) or 2000
end

function FN.resolveWaypoint(name)
	if typeof(name) ~= "string" or name == "" then
		return nil
	end
	if name == "Base" then
		return FN.getBasePosition()
	end
	if name == "Pet Area" then
		return FN.getPetAreaStandPosition()
	end
	if name == "Treadmill" then
		return FN.getTreadmillStand()
	end
	if name == "Fuse Machine" then
		return FN.getFuseMachinePosition()
	end
	if name == "Lobby Entry" then
		return FN.getEntryPosition()
	end
	local zoneIdx = FN.getZoneIndex(name)
	if zoneIdx then
		local model = FN.getZoneModel(name)
		if model then
			local part = model:FindFirstChild("Bounds")
			local pos = (part and part:IsA("BasePart")) and part.Position or (model:IsA("BasePart") and model.Position)
			if pos then
				return Vector3.new(pos.X, FN.getLaneY(), FN.getLaneZ())
			end
		end
	end
	return nil
end
-- area egg snapshot
function FN.getAreaEggs()
	local snapshot = EggStateModule.GetAreaEggSnapshot()
	if typeof(snapshot) ~= "table" then
		pcall(function()
			EggStateModule.RequestAreaEggSnapshot()
		end)
		snapshot = EggStateModule.GetAreaEggSnapshot()
	end
	if typeof(snapshot) ~= "table" or typeof(snapshot.Records) ~= "table" then
		return {}
	end
	local list = {}
	for _, rec in pairs(snapshot.Records) do
		if typeof(rec) == "table" and typeof(rec.Uid) == "string" then
			table.insert(list, rec)
		end
	end
	return list
end

function FN.findAreaEggRecord(uid)
	for _, rec in ipairs(FN.getAreaEggs()) do
		if rec.Uid == uid then
			return rec
		end
	end
	return nil
end

function FN.getCarryState()
	local me = LocalPlayer
	local ok, states = pcall(function()
		return EggStateModule.GetPlayerCarryStates()
	end)
	if ok and typeof(states) == "table" then
		local mine = states[me.UserId] or states[tostring(me.UserId)] or states[me.Name]
		if typeof(mine) == "table" then
			return mine
		end
	end
	local ok2, single = pcall(function()
		return EggStateModule.GetCarryState()
	end)
	if ok2 and typeof(single) == "table" then
		return single
	end
	for _, rec in ipairs(FN.getAreaEggs()) do
		if rec.State == "Carried" then
			local owner = rec.Owner or rec.OwnerName or rec.OwnerId or rec.OwnerUserId
			if owner == me.Name or owner == me.UserId or tostring(owner) == tostring(me.UserId) then
				return { IsCarrying = true, Uid = rec.Uid }
			end
		end
	end
	-- held egg/pet tool fallback (tools carry the UID attribute)
	local containers = { LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack") }
	for _, container in ipairs(containers) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") then
					local uid = child:GetAttribute("UID")
					if typeof(uid) == "string" and uid ~= "" then
						return { IsCarrying = true, Uid = uid }
					end
				end
			end
		end
	end
	return { IsCarrying = false }
end

-- egg inventory
function FN.eggInventoryCount()
	local save = FN.getSave()
	local inv = save and save.EggInventory
	if typeof(inv) ~= "table" then
		return 0
	end
	return FN.countTable(inv)
end

function FN.eggInventoryFull()
	local cap = tonumber(EggsTypes.MAX_INVENTORY) or math.huge
	return FN.eggInventoryCount() >= cap
end

function FN.eggScore(egg)
	local rarity = FN.resolveRarity(egg.AssetCategory) or "Common"
	return RARITY_RANK[rarity] or 0
end

-- mutations
function FN.recordMutations(rec)
	local out = {}
	if typeof(rec) ~= "table" then
		return out
	end
	if typeof(rec.Mutations) == "table" then
		for _, m in pairs(rec.Mutations) do
			if typeof(m) == "string" then
				table.insert(out, m)
			end
		end
	end
	if typeof(rec.BaseMutation) == "string" then
		table.insert(out, rec.BaseMutation)
	end
	return out
end

function FN.matchesMutationFilter(mutKey, egg)
	if not FN.multiHasAny(mutKey) then
		return true
	end
	local selected = FN.multiSelected(mutKey)
	for _, m in ipairs(FN.recordMutations(egg)) do
		if selected[m] then
			return true
		end
	end
	return false
end

function FN.matchesEggFilters(egg, zoneKey, rarityKey, mutKey)
	if zoneKey then
		local area = egg.AreaId
		if typeof(area) ~= "string" then
			return false
		end
		if not FN.selectionAllows(zoneKey, area) then
			return false
		end
	end
	local rarity = FN.resolveRarity(egg.AssetCategory)
	if typeof(rarity) == "string" and not FN.selectionAllows(rarityKey, rarity) then
		return false
	end
	return FN.matchesMutationFilter(mutKey, egg)
end

-- steal candidate
function FN.isBigEgg(egg)
	if not FN.isOn("StealBigEggs") then
		return false
	end
	local scale = tonumber(egg.AssetScale)
	if not scale then
		return false
	end
	local minScale = tonumber(FN.optionValue("StealBigEggScale", 1.5)) or 1.5
	return scale >= minScale
end

function FN.isStealCandidate(egg, stealAll)
	if typeof(egg) ~= "table" or typeof(egg.Uid) ~= "string" then
		return false
	end
	if egg.State ~= "Slot" and egg.State ~= "Dropped" then
		return false
	end
	if stealAll then
		return true
	end
	if FN.isBigEgg(egg) then
		return FN.selectionAllows("StealZones", egg.AreaId)
	end
	if not FN.isOn("AutoStealSelected") then
		return false
	end
	return FN.matchesEggFilters(egg, "StealZones", "StealRarities", "StealMutations")
end

-- pet item data
function FN.getPetItemData(item)
	local ok, data = pcall(AssetItems.Deserialize, item)
	if not ok or typeof(data) ~= "table" then
		return nil
	end
	return data
end

function FN.isOwnRenderedPet(inst)
	return inst:GetAttribute("OwnerUserId") == LocalPlayer.UserId
end

-- sellable pets
function FN.getSellablePets()
	local save = FN.getSave()
	if not save then
		return {}
	end
	local inventory = save.Inventory
	if typeof(inventory) ~= "table" then
		return {}
	end
	local maxScale = tonumber(FN.optionValue("SellMaxScale", 10))
	if not maxScale then
		maxScale = 10
	end
	local keepMutated = FN.isOn("SellKeepMutated")
	local keepEquipped = FN.isOn("SellKeepEquipped")
	local equipped = save.EquippedAssets
	local raritySel = FN.multiSelected("SellRarities")
	local mutSel = FN.multiSelected("SellMutations")
	local mutsEnabled = FN.multiHasAny("SellMutations")
	local out = {}
	for uid, pet in pairs(inventory) do
		if typeof(uid) == "string" and typeof(pet) == "table" then
			local rarity = FN.resolveRarity(pet.Category)
			local pass = true
			if FN.multiHasAny("SellRarities") then
				pass = raritySel[rarity] == true
			end
			if pass then
				local scale = tonumber(pet.Scale)
				pass = scale ~= nil and scale <= maxScale
			end
			if pass and keepMutated then
				pass = #FN.recordMutations(pet) == 0
			end
			if pass and keepEquipped then
				pass = not (typeof(equipped) == "table" and (equipped[uid] or (pet.Equipped == true)))
			end
			if pass then
				pass = pet.IsFavorite ~= true
			end
			if pass then
				pass = pet.InFuse ~= true
			end
			if pass and mutsEnabled then
				pass = false
				for _, m in ipairs(FN.recordMutations(pet)) do
					if mutSel[m] then
						pass = true
						break
					end
				end
			end
			if pass then
				table.insert(out, uid)
			end
		end
	end
	return out
end

-- sellable eggs
function FN.getSellableEggUids()
	local save = FN.getSave()
	local inventory = save and save.EggInventory
	if typeof(inventory) ~= "table" then
		return {}
	end
	local out = {}
	for uid, item in pairs(inventory) do
		if typeof(uid) == "string" and typeof(item) == "table" and item.Placement == nil then
			local pass = true
			if FN.multiHasAny("SellEggRarities") then
				local rarity = FN.resolveRarity(item.AssetCategory)
				pass = FN.multiSelected("SellEggRarities")[rarity] == true
			end
			if pass then
				table.insert(out, uid)
			end
		end
	end
	return out
end

-- unplaced eggs for auto place
function FN.getUnplacedEggUids()
	local save = FN.getSave()
	local inventory = save and save.EggInventory
	if typeof(inventory) ~= "table" then
		return {}
	end
	local placeAll = FN.isOn("AutoPlaceAll")
	local out = {}
	for uid, item in pairs(inventory) do
		if typeof(uid) == "string" and typeof(item) == "table" and item.Placement == nil then
			local pass = placeAll
			if not pass then
				pass = FN.matchesEggFilters(item, nil, "LifecycleRarities", "LifecycleMutations")
			end
			if pass then
				table.insert(out, uid)
			end
		end
	end
	return out
end

function FN.placingEnabled()
	return FN.isOn("AutoPlaceSelected") or FN.isOn("AutoPlaceAll")
end

-- find tool by UID attribute
function FN.findToolByUid(uid)
	local containers = { LocalPlayer.Character, LocalPlayer:FindFirstChildOfClass("Backpack") }
	for _, container in ipairs(containers) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") then
					if child:GetAttribute("UID") == uid then
						return child
					end
				end
			end
		end
	end
	return nil
end

-- fuse
function FN.fusePrice(uids)
	local save = FN.getSave()
	local inventory = save and save.Inventory
	if typeof(inventory) ~= "table" then
		return nil
	end
	local items = {}
	for _, uid in ipairs(uids) do
		local raw = inventory[uid]
		if raw then
			items[uid] = FN.getPetItemData(raw)
		end
	end
	local ok, price = pcall(FuseKernel.CalculateFusePrice, items)
	if not ok then
		return nil
	end
	return tonumber(price)
end

function FN.fuseGroups()
	local save = FN.getSave()
	local inventory = save and save.Inventory
	if typeof(inventory) ~= "table" then
		return {}
	end
	local maxScale = tonumber(FN.optionValue("FuseMaxScale", 10)) or 10
	local keepMutated = FN.isOn("FuseKeepMutated")
	local keepEquipped = FN.isOn("FuseKeepEquipped")
	local equipped = save.EquippedAssets
	local groups = {}
	for uid, pet in pairs(inventory) do
		if typeof(uid) == "string" and typeof(pet) == "table" then
			local rarity = FN.resolveRarity(pet.Category)
			local pass = true
			if rarity and FN.multiHasAny("FuseRarities") then
				pass = FN.multiSelected("FuseRarities")[rarity] == true
			end
			if pass and FN.multiHasAny("FuseMutations") then
				pass = FN.matchesMutationFilter("FuseMutations", pet)
			end
			if pass then
				local scale = tonumber(pet.Scale)
				pass = scale ~= nil and scale <= maxScale
			end
			if pass and keepMutated then
				pass = #FN.recordMutations(pet) == 0
			end
			if pass and keepEquipped then
				pass = not (typeof(equipped) == "table" and (equipped[uid] or (pet.Equipped == true)))
			end
			if pass then
				pass = pet.InFuse ~= true
			end
			if pass then
				local key = rarity or "Unknown"
				groups[key] = groups[key] or {}
				table.insert(groups[key], { uid = uid, scale = scale or 0, category = key })
			end
		end
	end
	return groups
end

function FN.pickFuseGroup()
	local groups = FN.fuseGroups()
	local keepPerCategory = tonumber(FN.optionValue("FuseKeepPerCategory", 0))
	if not keepPerCategory then
		keepPerCategory = 0
	end
	local target = FN.firstSelected("FuseTarget", "Highest Rarity")
	local bestKey, bestScore = nil, -math.huge
	for key, list in pairs(groups) do
		table.sort(list, function(a, b)
			return a.scale < b.scale
		end)
		if #list - keepPerCategory >= 3 then
			local score
			if target == "Most Duplicates" then
				score = #list
			elseif target == "Lowest Rarity" then
				local rank = RARITY_RANK[key]
				score = rank and -rank or 0
			else
				local rank = RARITY_RANK[key]
				score = rank or 0
			end
			if score > bestScore then
				bestScore = score
				bestKey = key
			end
		end
	end
	if not bestKey then
		return nil
	end
	local chosen = {}
	for i = 1, math.min(3, #groups[bestKey]) do
		chosen[i] = groups[bestKey][i].uid
	end
	return chosen
end
-- remote resolver: Shared.Remotes wrapper first, then Packages.Networking RF/<Group>/<Name>
local function findRemote(group, name)
	if typeof(Remotes) == "table" then
		local bag = Remotes[group]
		if typeof(bag) == "table" then
			local r = bag[name]
			if typeof(r) == "Instance" and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
				return r
			end
		end
	end
	local networking = ReplicatedStorage:FindFirstChild("Packages")
	if networking then
		local rf = networking:FindFirstChild("Networking")
		if rf then
			local r = rf:FindFirstChild("RF/" .. group .. "/" .. name)
			if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
				return r
			end
		end
	end
	return nil
end

function FN.netCall(group, name, ...)
	local r = findRemote(group, name)
	if not r then
		return false
	end
	if r:IsA("RemoteEvent") then
		local ok = pcall(r.FireServer, r, ...)
		return ok
	end
	return false
end

function FN.netInvoke(group, name, ...)
	local r = findRemote(group, name)
	if not r then
		return nil
	end
	if r:IsA("RemoteFunction") then
		local ok, res = pcall(r.InvokeServer, r, ...)
		if ok then
			return res
		end
	end
	return nil
end

-- carry / place / drop / hatch / equip
function FN.tryCarryEgg(target)
	local uid
	if typeof(target) == "Instance" then
		uid = target.Name
	elseif typeof(target) == "table" then
		uid = target.Uid
	else
		uid = target
	end
	if typeof(uid) ~= "string" or uid == "" then
		return false
	end
	local ok = FN.netCall("EggWorld", "AskFieldEggCarry", { Uid = uid })
	if ok then
		return true
	end
	local ok2 = pcall(function()
		return EggStateModule.CarryFieldEgg(uid)
	end)
	return ok2
end

function FN.dropHeldEgg()
	local ok = FN.netCall("EggWorld", "AskFieldEggDrop", { Reason = "PlayerRequest" })
	if ok then
		return true
	end
	local ok2 = pcall(function()
		return EggStateModule.DropFieldEgg("PlayerRequest")
	end)
	if not ok2 then
		ok2 = pcall(function()
			return EggStateModule.RequestDropHeldAreaEgg()
		end)
	end
	return ok2
end

function FN.placeEgg(uid, localCFrame)
	local ok = FN.netCall("EggWorld", "AskPlaceEgg", { Uid = uid, LocalCFrame = localCFrame })
	if ok then
		return true
	end
	local ok2 = pcall(function()
		return EggStateModule.PlantEgg(uid, localCFrame)
	end)
	return ok2
end

function FN.hatchEgg(uid)
	return FN.netCall("EggWorld", "AskHatch", uid)
end

function FN.finishHatch(uid)
	return FN.netCall("EggWorld", "AskFinishHatch", uid)
end

function FN.equipTool(uid)
	local ok = FN.netCall("EggWorld", "AskWearTool", uid)
	if ok then
		return true
	end
	local tool = FN.findToolByUid(uid)
	if tool and LocalPlayer.Character then
		local ok2 = pcall(function()
			tool.Parent = LocalPlayer.Character
		end)
		return ok2
	end
	return false
end

function FN.holdUid(uid)
	local tool = FN.findToolByUid(uid)
	if not tool then
		return false
	end
	if not tool:IsDescendantOf(LocalPlayer.Character) then
		pcall(function()
			tool.Parent = LocalPlayer.Character
		end)
		task.wait(0.1)
	end
	return true
end

function FN.sellUid(uid)
	if not FN.holdUid(uid) then
		return false
	end
	FN.netCall("AssetInventory", "SELL_ASSET", uid)
	local untilt = os.clock() + 2
	while os.clock() < untilt do
		local save = FN.getSave()
		if save then
			local gone = save[uid] == nil
			local eggInv = save.EggInventory
			if typeof(eggInv) == "table" then
				gone = gone and eggInv[uid] == nil
			end
			local petInv = save.Inventory
			if typeof(petInv) == "table" then
				gone = gone and petInv[uid] == nil
			end
			if gone then
				return true
			end
		end
		task.wait(0.1)
	end
	return false
end

-- economy tasks
function FN.runAutoClaimIndex()
	FN.netCall("Index", "REQUEST_CLAIM_ALL")
	local ok = FN.netCall("Codex", "AskRedeemAll", {})
	if not ok then
		task.wait(0.2)
		FN.netCall("Index", "REQUEST_CLAIM_ALL")
	end
end

function FN.runAutoClaimGroupReward()
	FN.netCall("GroupPerk", "RedeemPerk", false)
end

function FN.runClaimOfflineEarnings()
	local summary = FN.netInvoke("OfflineAssets", "GET_SUMMARY")
	local amount = summary and tonumber(summary.ClaimableAmount) or 0
	if amount > 0 then
		FN.netCall("OfflineAssets", "REQUEST_REDEEM")
		return
	end
	local fetch = FN.netInvoke("AwayEarnings", "FetchSummary", {})
	if typeof(fetch) == "table" and (tonumber(fetch.ClaimableAmount) or 0) > 0 then
		FN.netCall("AwayEarnings", "AskCollect", { Kind = "Claim" })
	end
end

function FN.runAutoUpgrades()
	local types = FN.multiSelected("UpgradeTypes")
	if not FN.multiHasAny("UpgradeTypes") then
		types = { Base = true, Treadmill = true }
	end
	local save = FN.getSave()
	if not save then
		return
	end
	if types.Base then
		local affordable = false
		local ok, res = pcall(BaseUpgradeModule.IsNextTierAffordable, save)
		if ok then
			affordable = res == true
		end
		if affordable then
			local called = FN.netCall("Plots", "REQUEST_BASE_UPGRADE")
			if not called then
				pcall(function()
					BaseUpgradeModule.PurchaseNextTier()
				end)
			end
			task.wait(0.35)
		end
	end
	if types.Treadmill then
		local level = tonumber(save.TreadmillUpgradeLevel) or 0
		for _ = 1, 5 do
			local nextLevel = TreadmillData.GetByUpgradeLevel(level + 1)
			if not nextLevel then
				break
			end
			local price = tonumber(nextLevel.Price) or math.huge
			if (tonumber(save.Money) or 0) < price then
				break
			end
			FN.netCall("Treadmills", "REQUEST_UPGRADE", nextLevel._id)
			task.wait(0.35)
			level = level + 1
			save = FN.getSave()
			if not save then
				break
			end
		end
	end
end

function FN.runAutoBuyTrail()
	local save = FN.getSave()
	if not save then
		return
	end
	local wanted = FN.multiSelected("TrailWanted")
	if not next(wanted) then
		return
	end
	for _, name in ipairs(trailNames) do
		if wanted[name] then
			local id = trailIds[name]
			local function owned()
				local inv = save and save.TrailInventory
				return typeof(inv) == "table" and inv[id] ~= nil
			end
			if not owned() then
				local price = trailPrices[name]
				if price and (tonumber(save.Money) or 0) >= price then
					FN.netCall("Trails", "REQUEST_PURCHASE", id)
					task.wait(0.35)
					save = FN.getSave()
					if not save then
						return
					end
				end
			end
		end
	end
end

function FN.runAutoEquipBest()
	local now = Workspace:GetServerTimeNow()
	if now - lastEquipAt < 5 then
		return
	end
	lastEquipAt = now
	FN.netCall("Backpack", "EQUIP_BEST")
	if not FN.netCall("Haul", "WearBest", {}) then
		task.wait(0.1)
		FN.netCall("Backpack", "EQUIP_BEST")
	end
end

function FN.runAutoEquipBestTrail()
	local save = FN.getSave()
	local inventory = save and save.TrailInventory
	if typeof(inventory) ~= "table" then
		return
	end
	local bestLevel, bestId = -1, nil
	for _, name in ipairs(trailNames) do
		local id = trailIds[name]
		local level = 0
		if id then
			level = tonumber(inventory[id]) or 0
		end
		if level > bestLevel then
			bestLevel = level
			bestId = id
		end
	end
	if bestId == nil then
		return
	end
	local worn = FN.netInvoke("Trails", "WORN_SNAPSHOT")
	if typeof(worn) == "table" then
		if worn[tostring(LocalPlayer.UserId)] == bestId then
			return
		end
	end
	FN.netInvoke("Trails", "REQUEST_SELECT", bestId)
end

function FN.runAutoEquipBestGear()
	local save = FN.getSave()
	local inventory = save and save.Inventory
	if typeof(inventory) ~= "table" then
		return
	end
	local best = nil
	for uid, pet in pairs(inventory) do
		if typeof(pet) == "table" then
			local scale = tonumber(pet.Scale) or 0
			if not best or scale > (tonumber(best.scale) or 0) then
				best = { uid = uid, scale = scale, data = pet }
			end
		end
	end
	if best and FN.equipTool(best.uid) then
		return true
	end
	return false
end

function FN.runAutoDropEgg()
	if not FN.isCarrying() then
		return
	end
	FN.dropHeldEgg()
end

function FN.runAutoSellPets()
	for _, uid in ipairs(FN.getSellablePets()) do
		if Library and Library.Unloaded then
			return
		end
		if not FN.isOn("AutoSellPets") then
			return
		end
		if not FN.isCarrying() then
			FN.sellUid(uid)
			task.wait(0.15)
		end
	end
end

function FN.runAutoSellEggs()
	for _, uid in ipairs(FN.getSellableEggUids()) do
		if Library and Library.Unloaded then
			return
		end
		if not FN.isOn("AutoSellEggs") then
			return
		end
		if not FN.isCarrying() then
			FN.sellUid(uid)
			task.wait(0.15)
		end
	end
end

-- place eggs on the plot
function FN.runAutoPlaceEggs()
	if not FN.placingEnabled() then
		return false
	end
	if FN.isCarrying() then
		return false
	end
	if FN.isPlotFull() then
		return false
	end
	local uids = FN.getUnplacedEggUids()
	if #uids == 0 then
		return false
	end
	if not FN.ensureAtPlot(FN.placingEnabled) then
		return false
	end
	local frames = FN.getPlacementLocalCFrames()
	if #frames == 0 then
		FN.markPlotFull()
		return false
	end
	local placed = false
	for i, frame in ipairs(frames) do
		local uid = uids[i]
		if not uid then
			break
		end
		if not FN.placeEgg(uid, frame) then
			break
		end
		placed = true
		task.wait(0.15)
		local untilt = os.clock() + 3
		local confirmed = false
		while os.clock() < untilt do
			local save = FN.getSave()
			local item = save and save.EggInventory and save.EggInventory[uid]
			if typeof(item) == "table" and item.Placement ~= nil then
				confirmed = true
				break
			end
			task.wait(0.1)
		end
		if not confirmed then
			FN.markPlotFull()
			break
		end
	end
	return placed
end

-- hatch ready eggs
function FN.runAutoOpenReadyEggs()
	if not FN.isOn("AutoOpenReadyEggs") then
		return false
	end
	if FN.isCarrying() then
		return false
	end
	local save = FN.getSave()
	local inventory = save and save.EggInventory
	if typeof(inventory) ~= "table" then
		return false
	end
	for uid, item in pairs(inventory) do
		if typeof(item) == "table" and item.Placement ~= nil then
			local pass = true
			if FN.multiHasAny("LifecycleRarities") then
				local rarity = FN.resolveRarity(item.AssetCategory)
				pass = FN.multiSelected("LifecycleRarities")[rarity] == true
			end
			if pass and FN.multiHasAny("LifecycleMutations") then
				pass = FN.matchesMutationFilter("LifecycleMutations", item)
			end
			if pass then
				local ok = FN.hatchEgg(uid)
				if ok then
					task.wait(0.4)
					FN.finishHatch(uid)
					return true
				end
			end
		end
	end
	return false
end

-- fuse
function FN.runAutoFusePets(manual)
	if not manual and not FN.isOn("AutoFusePets") then
		return
	end
	if FN.isCarrying() then
		return
	end
	local group = FN.pickFuseGroup()
	if not group or #group < 3 then
		return
	end
	local ok = FN.netCall("Fusions", "FUSE_BY_ID", group[1], group[2], group[3])
	if not ok then
		ok = FN.netCall("Fusions", "FUSE_BY_ID", { group[1], group[2], group[3] })
	end
	if not ok then
		ok = FN.netCall("Fusery", "BeginFuse")
	end
	if not ok then
		FN.notify("No fuse remote available")
		return
	end
	if FN.isOn("FuseAutoReveal") then
		task.wait(1.5)
		local revealed = false
		for _, args in ipairs({ { group[1] }, { group[1], group[2], group[3] }, {} }) do
			if FN.netCall("Fusions", "REVEAL_FUSE", table.unpack(args)) then
				revealed = true
				break
			end
			if FN.netCall("Fusery", "CompleteFuse", table.unpack(args)) then
				revealed = true
				break
			end
		end
		if not revealed then
			local gui = LocalPlayer:FindFirstChild("PlayerGui")
			if gui then
				for _, obj in ipairs(gui:GetDescendants()) do
					if obj:IsA("TextButton") and string.find(obj.Name, "Reveal", 1, true) then
						pcall(function()
							obj:Click()
						end)
						revealed = true
						break
					end
				end
			end
		end
	end
end

-- delete own pet renders from the workspace
function FN.deleteOwnPetRenders()
	local removed = 0
	local function sweep(container)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Model") or child:IsA("BasePart") then
				if pcall(function()
					return FN.isOwnRenderedPet(child)
				end) then
					pcall(function()
						child:Destroy()
					end)
					removed = removed + 1
				end
			end
		end
	end
	sweep(Workspace:FindFirstChild("Pets"))
	sweep(Workspace:FindFirstChild("RenderedPets"))
	sweep(Workspace:FindFirstChild("Plots"))
	return removed
end
-- movement: raw snaps for steal/return (1:1), glide for long travel
function FN.rawTeleport(pos)
	local root = FN.getRoot()
	if not root or typeof(pos) ~= "Vector3" then
		return false
	end
	root.CFrame = CFrame.new(pos) * (root.CFrame - root.CFrame.Position)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	return true
end

function FN.anchorStealRoot(root, cf)
	root.CFrame = cf
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

function FN.stealSpeed()
	return math.clamp(tonumber(FN.optionValue("StealSpeed", 300)) or 300, 50, 1000)
end

function FN.stealingEnabled()
	return FN.isOn("AutoStealSelected") or FN.isOn("AutoStealAll") or FN.isOn("StealBigEggs")
end

-- smooth glide to a point (no raw teleports for travel)
function FN.glideTo(pos, speed, arriveDist, timeout, still)
	if typeof(pos) ~= "Vector3" then
		return false
	end
	speed = speed or FN.stealSpeed()
	arriveDist = arriveDist or STEAL_TIMING.ArriveDistance
	timeout = timeout or STEAL_TIMING.MoveTimeout
	local deadline = os.clock() + timeout
	local lastGroundProbe = 0
	local groundY = nil
	while os.clock() < deadline do
		local root = FN.getRoot()
		if not root then
			return false
		end
		if still and not still() then
			return false
		end
		if Library and Library.Unloaded then
			return false
		end
		local p = root.Position
		if (p - pos).Magnitude <= arriveDist then
			return true
		end
		local now = os.clock()
		if now - lastGroundProbe > 0.15 then
			lastGroundProbe = now
			groundY = FN.groundedY(p.X, p.Z)
		end
		local targetY = groundY or pos.Y
		local flat = Vector3.new(p.X, 0, p.Z)
		local destFlat = Vector3.new(pos.X, 0, pos.Z)
		local dir = destFlat - flat
		local dist = dir.Magnitude
		if dist < 0.5 then
			return true
		end
		dir = dir.Unit
		local step = math.min(speed * (1 / 60), dist)
		local np = flat + dir * step
		local ny = math.clamp(targetY, p.Y - 12, p.Y + 12)
		root.CFrame = CFrame.new(np.X, ny, np.Z) * (root.CFrame - root.CFrame.Position)
		task.wait(1 / 60)
	end
	local root = FN.getRoot()
	if not root then
		return false
	end
	return (root.Position - pos).Magnitude <= arriveDist * 2
end

function FN.travelTo(pos, skipCorridor)
	if typeof(pos) ~= "Vector3" or (Library and Library.Unloaded) then
		return false
	end
	local dest = FN.clampToCorridor(pos, skipCorridor == true)
	if not dest then
		return false
	end
	return FN.glideTo(dest, FN.stealSpeed(), STEAL_TIMING.ArriveDistance, STEAL_TIMING.MoveTimeout, nil)
end

function FN.travelAlong(path, still, lastSkipCorridor)
	for i, pt in ipairs(path) do
		if i == #path and still and not still() then
			return false
		end
		if not FN.travelTo(pt, lastSkipCorridor) then
			return false
		end
	end
	return true
end

-- lane L-path to an egg
function FN.buildStealPath(fromPos, toPos)
	local laneZ = FN.getLaneZ()
	local laneY = FN.getLaneY()
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

-- multi-zone lane path (zigzag between zone lane centers)
function FN.buildLaneWaypoints(fromPos, toZoneIdx)
	local path = {}
	local laneZ = FN.getLaneZ()
	local laneY = FN.getLaneY()
	if math.abs(fromPos.Z - laneZ) > 8 then
		table.insert(path, Vector3.new(fromPos.X, laneY, laneZ))
	end
	local startIdx = FN.getZoneIndexByX(fromPos.X)
	if startIdx > toZoneIdx then
		return path
	end
	local dir = 1
	for idx = startIdx, toZoneIdx do
		local center = FN.getZoneLaneCenter(AREA_NAMES[idx])
		if center then
			table.insert(path, center)
		end
	end
	return path
end

function FN.stealMoveTo(x, z, still)
	local target = Vector3.new(x, FN.groundedY(x, z), z)
	return FN.glideTo(target, FN.stealSpeed(), STEAL_TIMING.ArriveDistance, STEAL_TIMING.MoveTimeout, still)
end

function FN.stealAlong(path, still)
	for _, pt in ipairs(path) do
		if still and not still() then
			return false
		end
		if not FN.stealMoveTo(pt.X, pt.Z, still) then
			return false
		end
	end
	return true
end

-- humanoid management for steal mode
function FN.swapStealHumanoid()
	local hum = FN.getHumanoid()
	if not hum then
		return
	end
	local stealing = FN.stealingEnabled()
	local marked = hum:GetAttribute("SAEStealHum") == true
	if stealing and not marked then
		hum:SetAttribute("SAEStealHum", true)
		hum.WalkSpeed = math.min(FN.stealSpeed(), 500)
	elseif not stealing and marked then
		hum:SetAttribute("SAEStealHum", false)
		hum.WalkSpeed = 16
	end
end

-- the steal sequence (1:1 decompile: glide approach, snap to egg, grab window, snap home)
function FN.stealEgg(target)
	FN.swapStealHumanoid()
	local eggPos = FN.getSlotEggPosition(target)
	local root = FN.getRoot()
	if not eggPos or not root then
		return false
	end
	local homeX = root.Position.X
	local homeZ = root.Position.Z
	local homeY = FN.groundedY(homeX, homeZ, root.Position.Y)
	local still = FN.stealingEnabled
	if not FN.stealAlong(FN.buildStealPath(root.Position, eggPos), still) then
		return false
	end
	root = FN.getRoot()
	if root then
		local gy = FN.groundedY(eggPos.X, eggPos.Z, eggPos.Y)
		FN.anchorStealRoot(root, CFrame.new(eggPos.X, gy, eggPos.Z))
	end
	if not FN.stealingEnabled() then
		return false
	end
	local t0 = tick()
	while tick() - t0 < STEAL_TIMING.GrabDelay do
		if not FN.stealingEnabled() then
			break
		end
		FN.tryCarryEgg(target)
		if FN.isCarrying() then
			task.wait(0.08)
			break
		end
		task.wait(0.04)
	end
	root = FN.getRoot()
	if not root then
		return FN.isCarrying()
	end
	FN.stealAlong(FN.buildStealPath(root.Position, Vector3.new(homeX, homeY, homeZ)), still)
	root = FN.getRoot()
	if root then
		FN.anchorStealRoot(root, CFrame.new(homeX, homeY, homeZ))
	end
	task.wait(STEAL_TIMING.ReturnPace)
	return FN.isCarrying()
end

function FN.stealBlockedByInventory()
	return FN.eggInventoryFull()
end

-- return to base (1:1 raw snaps through the two gate points)
function FN.returnToBase(still)
	local base = FN.getBasePosition()
	local root = FN.getRoot()
	if not base or not root then
		return false
	end
	if still and not still() then
		return false
	end
	local z = root.Position.Z
	FN.rawTeleport(Vector3.new(558, 71, z))
	task.wait(RETURN_SNAP_PACE)
	if still and not still() then
		return false
	end
	FN.rawTeleport(Vector3.new(546, 71, z))
	task.wait(RETURN_SNAP_PACE)
	if still and not still() then
		return false
	end
	FN.rawTeleport(Vector3.new(base.X, base.Y + 5, base.Z))
	task.wait(0.12)
	return true
end

function FN.runAutoReturn()
	if not FN.isCarrying() then
		return
	end
	FN.returnToBase(function()
		return FN.isOn("AutoReturn") and FN.isCarrying()
	end)
	local root = FN.getRoot()
	if not root or not PlotStateModule.IsWorldPositionWithinLocalPlotBounds(root.Position) then
		return
	end
	local untilt = os.clock() + 4
	while os.clock() < untilt do
		if not FN.isCarrying() or not FN.isOn("AutoReturn") then
			break
		end
		task.wait(0.15)
	end
end

-- treadmill
function FN.isDoubleSpeedVisible()
	local ok, visible = pcall(function()
		local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
		if not playerGui then
			return false
		end
		for _, containerName in ipairs({ "Elements", "Left" }) do
			local container = playerGui:FindFirstChild(containerName)
			if container then
				local tools = container:FindFirstChild("Tools")
				if tools then
					local buff = tools:FindFirstChild("DoubleYourSpeed")
					if buff then
						return buff.Visible == true
					end
				end
			end
		end
		return false
	end)
	return ok and visible == true
end

function FN.dismountTreadmill()
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
		task.wait(0.05)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
	end)
	local hum = FN.getHumanoid()
	if hum then
		hum.Jump = true
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

function FN.runAutoTreadmillTraining()
	local stand = FN.getTreadmillStand()
	if not stand then
		return false
	end
	local root = FN.getRoot()
	if not root then
		return false
	end
	if (root.Position - stand).Magnitude > 12 then
		if not FN.travelTo(stand, true) then
			return false
		end
	end
	FN.netInvoke("Treadmills", "REQUEST_EQUIP_STATIC")
	treadmillEquipped = true
	return true
end

function FN.stopTreadmillTraining()
	treadmillEquipped = false
	FN.netInvoke("Treadmills", "REQUEST_UNEQUIP")
	if FN.isDoubleSpeedVisible() then
		FN.dismountTreadmill()
		task.wait(0.1)
		if FN.isDoubleSpeedVisible() then
			FN.dismountTreadmill()
		end
	end
end
-- core tasks
function FN.runAutoSteal()
	if FN.isCarrying() then
		return false
	end
	if FN.stealBlockedByInventory() then
		return false
	end
	local target = FN.pickStealTarget()
	if not target then
		return false
	end
	return FN.stealEgg(target)
end

-- target selection from the egg slot folder (slot.Name == egg uid)
function FN.pickStealTarget()
	local slots
	local uidMap = {}
	for _, rec in ipairs(FN.getAreaEggs()) do
		if typeof(rec.Uid) == "string" then
			uidMap[rec.Uid] = rec
		end
	end
	local slotsClient = EggSlotsClient or Workspace:FindFirstChild("AreaEggSlotsClient")
	if slotsClient then
		slots = slotsClient:GetChildren()
	else
		return nil
	end
	local stealAll = FN.isOn("AutoStealAll")
	local root = FN.getRoot()
	local priority = FN.firstSelected("StealPriority", "Rarest")
	local best, bestScore = nil, -math.huge
	for _, slot in ipairs(slots) do
		local rec = uidMap[slot.Name]
		if rec and FN.isStealCandidate(rec, stealAll) then
			local pos = FN.getSlotEggPosition(slot)
			local score
			if not root or not pos then
				score = 0
			elseif priority == "Nearest" then
				score = -(root.Position - pos).Magnitude
			elseif priority == "Furthest" then
				score = (root.Position - pos).Magnitude
			elseif priority == "Biggest Size" then
				score = tonumber(rec.AssetScale) or 0
			else
				local dist = (root.Position - pos).Magnitude
				score = (FN.eggScore(rec) * 100000) - math.min(dist, 99999)
			end
			if score > bestScore then
				bestScore = score
				best = slot
			end
		end
	end
	return best
end

function FN.hasMatchingEgg()
	return FN.pickStealTarget() ~= nil
end

local TASK_LOOKUP = {}
for _, name in ipairs(TASK_NAMES) do
	TASK_LOOKUP[name] = true
end

function FN.priorityOrder()
	local ordered = {}
	local seen = {}
	for _, slotName in ipairs(PRIORITY_SLOTS) do
		local value = FN.firstSelected(slotName, nil)
		if typeof(value) == "string" and TASK_LOOKUP[value] and not seen[value] then
			seen[value] = true
			table.insert(ordered, value)
		end
	end
	for _, name in ipairs(TASK_NAMES) do
		if not seen[name] then
			seen[name] = true
			table.insert(ordered, name)
		end
	end
	return ordered
end

-- task registry (names, intervals, ready gates, runs)
local TASKS = {
	["Auto Steal Egg"] = {
		Interval = 0.2,
		Ready = function()
			return FN.stealingEnabled() and not FN.isCarrying() and not FN.stealBlockedByInventory()
		end,
		Run = function()
			return FN.runAutoSteal()
		end,
	},
	["Auto Place Egg"] = {
		Interval = 2,
		Ready = function()
			if not FN.placingEnabled() then
				return false
			end
			if FN.isCarrying() then
				return false
			end
			if FN.isPlotFull() then
				return false
			end
			return #FN.getUnplacedEggUids() > 0
		end,
		Run = function()
			return FN.runAutoPlaceEggs()
		end,
	},
	["Auto Hatch"] = {
		Interval = 2,
		Ready = function()
			return FN.isOn("AutoOpenReadyEggs") and not FN.isCarrying()
		end,
		Run = function()
			return FN.runAutoOpenReadyEggs()
		end,
	},
	["Auto Treadmill"] = {
		Interval = 4,
		Ready = function()
			return FN.isOn("AutoTreadmill") and not FN.isCarrying()
		end,
		Run = function()
			return FN.runAutoTreadmillTraining()
		end,
	},
}

local loopStealTravel = function()
	while not (Library and Library.Unloaded) do
		task.wait(0.2)
		if not busyLock then
			for _, name in ipairs(FN.priorityOrder()) do
				local entry = TASKS[name]
			local last = taskLastRun[name] or 0
			if entry.Ready() and os.clock() - last >= entry.Interval then
				local onTreadmill = FN.isDoubleSpeedVisible()
				busyLock = true
				local ok, res = pcall(entry.Run)
				busyLock = false
				if ok then
					if not onTreadmill and treadmillEquipped then
						pcall(FN.stopTreadmillTraining)
					end
					taskLastRun[name] = os.clock()
				end
		elseif not entry.Ready() and treadmillEquipped and os.clock() - last >= entry.Interval then
			pcall(FN.stopTreadmillTraining)
		end
		end
	end
end
end
-- ESP system
local espEntries = {}
local espAlive = {}

function FN.ensureEspEntry(id, color)
	local entry = espEntries[id]
	if entry then
		return entry
	end
	local anchor = Instance.new("Part")
	anchor.Name = "EspAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Parent = EspFolder
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EspLabel"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(220, 34)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.Adornee = anchor
	billboard.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextStrokeTransparency = 0.4
	label.TextColor3 = color
	label.RichText = false
	label.Parent = billboard
	entry = { anchor = anchor, billboard = billboard, label = label, highlight = nil }
	espEntries[id] = entry
	return entry
end

function FN.espColorFor(rarity)
	rarity = rarity or ""
	local rank = RARITY_RANK[rarity] or 0
	if rank >= 9 then
		return Color3.fromRGB(255, 120, 255)
	elseif rank >= 7 then
		return Color3.fromRGB(255, 90, 90)
	elseif rank >= 5 then
		return Color3.fromRGB(255, 190, 80)
	elseif rank >= 3 then
		return Color3.fromRGB(110, 195, 255)
	end
	return Color3.fromRGB(190, 200, 215)
end

function FN.drawEspAt(id, pos, text, color, adornee)
	local entry = FN.ensureEspEntry(id, color)
	entry.anchor.CFrame = CFrame.new(pos)
	entry.label.Text = text
	entry.label.TextColor3 = color
	if adornee then
		if not entry.highlight then
			local highlight = Instance.new("Highlight")
			highlight.FillTransparency = 0.6
			highlight.OutlineTransparency = 0
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = EspFolder
			entry.highlight = highlight
		end
		entry.highlight.Adornee = adornee
		entry.highlight.FillColor = color
		entry.highlight.OutlineColor = color
	else
		if entry.highlight then
			entry.highlight:Destroy()
			entry.highlight = nil
		end
	end
	espAlive[id] = true
end

function FN.releaseEsp(id)
	local entry = espEntries[id]
	if not entry then
		return
	end
	if entry.highlight then
		entry.highlight:Destroy()
	end
	if entry.billboard then
		entry.billboard:Destroy()
	end
	if entry.anchor then
		entry.anchor:Destroy()
	end
	espEntries[id] = nil
end

function FN.clearAllEsp()
	for id in pairs(espEntries) do
		FN.releaseEsp(id)
	end
	espAlive = {}
end

function FN.collectEggEsp()
	local showWorld = FN.isOn("EspWorldEggs")
	local showCarried = FN.isOn("EspCarriedEggs")
	if not showWorld and not showCarried then
		return
	end
	for _, rec in ipairs(FN.getAreaEggs()) do
		local state = rec.State
		local isSlot = state == "Slot"
		local isDropped = state == "Dropped"
		local isCarried = state == "Carried"
		if not (isCarried and not showCarried or isSlot and not showWorld) then
			local rarity = FN.resolveRarity(rec.AssetCategory)
			local displayName = "?"
			local dirRec = AssetRoster.Directory[rec.AssetCategory]
			if dirRec and dirRec.DisplayName then
				displayName = dirRec.DisplayName
			end
			local line = displayName
			if isSlot then
				line = string.format("%s [%s]", displayName, tostring(rarity or ""))
			elseif isDropped then
				line = string.format("%s\nDropped", line)
			end
			local pos = nil
			local cf = rec.BottomCFrame or rec.BoundsCFrame
			if cf then
				pos = cf.Position
			end
			if pos and FN.withinEspRange(pos) then
				local color
				if isDropped then
					color = Color3.fromRGB(255, 120, 120)
				else
					color = FN.espColorFor(rarity)
				end
				FN.drawEspAt("egg_" .. rec.Uid, pos, line, color, nil)
			end
		end
	end
end

function FN.collectGuardEsp()
	if not FN.isOn("EspGuards") or not GuardAreas then
		return
	end
	for _, zone in ipairs(GuardAreas:GetChildren()) do
		for _, child in ipairs(zone:GetChildren()) do
			if child:IsA("Model") and child.Name == "Guard" then
				local state = child:GetAttribute("GuardState")
				local part = child:FindFirstChildOfClass("BasePart")
				if part then
					local pos = part.Position
					if FN.withinEspRange(pos) then
						local color = state == "Chasing" and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(190, 200, 215)
						local guardName = tostring(child:GetAttribute("GuardId") or (child.Name .. "_" .. tostring(pos.X)))
						FN.drawEspAt("guard_" .. guardName, pos, string.format("Guard\n%s", tostring(state or "?")), color, child)
					end
				end
			end
		end
	end
end

function FN.collectPetEsp()
	if not FN.isOn("EspPets") then
		return
	end
	local containers = { Workspace:FindFirstChild("Pets"), Workspace:FindFirstChild("RenderedPets") }
	for _, container in ipairs(containers) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Model") then
					local part = child:FindFirstChildOfClass("BasePart")
					if part then
						local pos = part.Position
						if FN.withinEspRange(pos) then
							local mine = pcall(function()
								return FN.isOwnRenderedPet(child)
							end)
							local name = child:GetAttribute("Name") or child:GetAttribute("DisplayName") or child.Name
							local color = mine and Color3.fromRGB(125, 212, 127) or Color3.fromRGB(190, 200, 215)
							local petOwner = child:GetAttribute("OwnerUserId")
							FN.drawEspAt("pet_" .. tostring(petOwner or child.Name), pos, tostring(name or "Pet"), color, child)
						end
					end
				end
			end
		end
	end
end

function FN.collectPlayerEsp()
	if not FN.isOn("EspPlayers") then
		return
	end
	local me = FN.getRoot()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local pos = root.Position
				if FN.withinEspRange(pos) then
					local dist = 0
					if me then
						dist = (me.Position - pos).Magnitude
					end
					local text = string.format("%s\n%d studs", player.DisplayName, math.floor(dist))
					FN.drawEspAt("player_" .. player.Name, pos, text, Color3.fromRGB(120, 190, 255), nil)
				end
			end
		end
	end
end

function FN.collectMachineEsp()
	if not FN.isOn("EspMachines") then
		return
	end
	local plot = PlotStateModule.GetPlotData()
	local folder = plot and plot.PlotFolder
	if not folder then
		return
	end
	local wanted = { "TreadmillBottom", "FuseMachine", "Fuse", "FusionMachine", "PlotUpgrade", "TreadmillUpgrade" }
	for _, name in ipairs(wanted) do
		local part = folder:FindFirstChild(name)
		if part then
			if not part:IsA("BasePart") then
				part = part:FindFirstChildOfClass("BasePart")
			end
			if part then
				local pos = part.Position
				if FN.withinEspRange(pos) then
					FN.drawEspAt("machine_" .. name, pos, name, Color3.fromRGB(110, 195, 255), nil)
				end
			end
		end
	end
end

function FN.collectPlotEsp()
	if not FN.isOn("EspPlots") then
		return
	end
	local plot = PlotStateModule.GetPlotData()
	local folder = plot and plot.PlotFolder
	if not folder then
		return
	end
	local center = plot.CenterPoint or folder:FindFirstChild("CenterPoint")
	if center and center:IsA("BasePart") then
		local pos = center.Position
		if FN.withinEspRange(pos) then
			FN.drawEspAt("plot_local", pos, "Your Plot", Color3.fromRGB(125, 212, 127), nil)
		end
	end
end

function FN.runEsp()
	espAlive = {}
	FN.collectEggEsp()
	FN.collectGuardEsp()
	FN.collectPetEsp()
	FN.collectPlayerEsp()
	FN.collectMachineEsp()
	FN.collectPlotEsp()
	for id in pairs(espEntries) do
		if not espAlive[id] then
			FN.releaseEsp(id)
		end
	end
end

local loopEsp = function()
	while not (Library and Library.Unloaded) do
		task.wait(0.4)
		local any = FN.isOn("EspWorldEggs") or FN.isOn("EspCarriedEggs") or FN.isOn("EspGuards")
			or FN.isOn("EspPets") or FN.isOn("EspPlayers") or FN.isOn("EspMachines") or FN.isOn("EspPlots")
		if any then
			pcall(FN.runEsp)
		elseif next(espEntries) ~= nil then
			pcall(FN.clearAllEsp)
		end
	end
end
-- http
function FN.httpPost(payload)
	local url = FN.optionValue("WebhookUrl", "")
	if typeof(url) ~= "string" or url == "" then
		return false
	end
	local body = HttpService:JSONEncode(payload)
	local ok, err = pcall(function()
		local response = HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
		return response
	end)
	if not ok and typeof(request) == "function" then
		local ok2, res = pcall(request, url, {
			method = "POST",
			headers = { ["Content-Type"] = "application/json" },
			body = body,
		})
		ok = ok2
		err = res and res.status
	end
	return ok
end

-- server hop
function FN.fetchServerPage(cursor)
	local ok, res = pcall(function()
		if typeof(cursor) == "string" and cursor ~= "" then
			return Players:GetServersAsync({ PlaceId = game.PlaceId }, 100, cursor)
		end
		return Players:GetServersAsync({ PlaceId = game.PlaceId })
	end)
	if not ok or typeof(res) ~= "table" then
		return nil
	end
	return res
end

function FN.rememberVisited(jobId)
	if typeof(jobId) ~= "string" or jobId == "" then
		return
	end
	local n = 0
	for _ in pairs(visitedServers) do
		n = n + 1
	end
	if n >= 300 then
		visitedServers = {}
	end
	visitedServers[jobId] = true
end

function FN.pickHopTargets()
	local out = {}
	local cursor = nil
	for page = 1, 4 do
		local data = FN.fetchServerPage(cursor)
		if not data then
			break
		end
		if typeof(data.data) == "table" then
			for _, server in ipairs(data.data) do
				if typeof(server) == "table" and typeof(server.id) == "string" then
					if server.id ~= game.JobId then
						local playing = tonumber(server.playing)
						local maxPlayers = tonumber(server.maxPlayers)
						if maxPlayers and playing and playing < maxPlayers then
							if not visitedServers[server.id] then
								table.insert(out, { id = server.id, playing = playing })
							end
						end
					end
				end
			end
		end
		cursor = typeof(data.nextPageCursor) == "string" and data.nextPageCursor or nil
		if #out >= 40 then
			break
		end
		task.wait(0.25)
	end
	if #out == 0 then
		return out
	end
	table.sort(out, function(a, b)
		return a.playing < b.playing
	end)
	return out
end

function FN.tryTeleportTo(jobId)
	return pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
	end)
end

function FN.rejoinServer()
	local ok = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end)
	if not ok then
		pcall(function()
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end)
	end
end

function FN.serverHop(reason)
	if hopInFlight then
		return false
	end
	if os.clock() < hopCooldownUntil then
		return false
	end
	hopInFlight = true
	FN.notify(string.format("Server hopping: %s", tostring(reason or "requested")))
	if FN.isOn("WebhookEnabled") then
		FN.sendSummary()
		task.wait(0.6)
	end
	local success = false
	for attempt = 1, 3 do
		if Library and Library.Unloaded then
			hopInFlight = false
			return false
		end
		local targets = FN.pickHopTargets()
		if typeof(targets) ~= "table" or #targets == 0 then
			hopCooldownUntil = os.clock() + 30
			hopInFlight = false
			FN.notify("Server hop found no candidates, retrying in 30s")
			return false
		end
		local count = math.min(#targets, 10)
		for i = 1, count do
			if Library and Library.Unloaded then
				hopInFlight = false
				return false
			end
			local target = targets[i]
			FN.rememberVisited(target.id)
			if FN.tryTeleportTo(target.id) then
				hopInFlight = false
				return true
			end
			task.wait(0.5)
		end
	end
	hopCooldownUntil = os.clock() + 10
	hopInFlight = false
	FN.notify("Server hop failed, retrying in 10s")
	return false
end

function FN.runServerHop()
	if FN.isCarrying() then
		return
	end
	local mode = FN.firstSelected("HopMode", HOP_MODES[1])
	local value = tonumber(FN.optionValue("HopValue", 15))
	if not value then
		value = 15
	end
	if mode == "Timed Interval" then
		if os.clock() - lastHopClock >= value * 60 then
			lastHopClock = os.clock()
			FN.serverHop("Interval reached")
		end
		return
	end
	if mode == "After Steal Count" then
		if stolenCount >= value then
			FN.serverHop(string.format("Stole %d eggs", stolenCount))
		end
		return
	end
	-- No Matching Eggs
	if FN.hasMatchingEgg() then
		noMatchTimer = 0
		return
	end
	if noMatchTimer == 0 then
		noMatchTimer = os.clock()
		return
	end
	if os.clock() - noMatchTimer >= value then
		noMatchTimer = 0
		FN.serverHop("No matching eggs in this server")
	end
end

-- webhook
function FN.webhookPing()
	local raw = FN.optionValue("WebhookPingId", "") or ""
	local id = tostring(raw):gsub("%D", "")
	if id == "" then
		return nil
	end
	return string.format("<@%s>", id)
end

function FN.sendWebhookEmbed(embed, ping)
	if not FN.isOn("WebhookEnabled") then
		return false
	end
	local payload = { username = GAME_TITLE, embeds = { embed } }
	if ping then
		local mention = FN.webhookPing()
		if mention then
			payload.content = mention
		end
	end
	return FN.httpPost(payload)
end

function FN.buildSummaryEmbed()
	local fields = {}
	local save = FN.getSave()
	if save then
		table.insert(fields, FN.embedField("Money", "`" .. FN.formatNumber(save.Money) .. "`"))
		table.insert(fields, FN.embedField("Speed Power", "`" .. FN.formatNumber(save.SpeedPower) .. "`"))
		if save.Rebirth then
			table.insert(fields, FN.embedField("Rebirth", "`" .. tostring(save.Rebirth) .. "`"))
		end
		if save.BaseUpgradeLevel then
			table.insert(fields, FN.embedField("Base Level", "`" .. tostring(save.BaseUpgradeLevel) .. "`"))
		end
		if save.TreadmillUpgradeLevel then
			table.insert(fields, FN.embedField("Treadmill Level", "`" .. tostring(save.TreadmillUpgradeLevel) .. "`"))
		end
		table.insert(fields, FN.embedField("Pets Owned", "`" .. tostring(FN.countTable(save.Inventory)) .. "`"))
	end
	table.insert(fields, FN.embedField("Since Last Summary", table.concat({
		string.format("Eggs stolen: **%d**", hopsSinceSummary),
		string.format("Pets obtained: **%d**", petsSinceSummary),
		string.format("Rebirths: **%d**", rebirthsSinceSummary),
	}, "\n")))
	if #obtainedEggLines > 0 then
		local lines = {}
		local total = 0
		for i, line in ipairs(obtainedEggLines) do
			if total + #line + 1 > 900 then
				break
			end
			table.insert(lines, line)
			total = total + #line + 1
			if i >= 15 then
				break
			end
		end
		local text = table.concat(lines, "\n")
		if #obtainedEggLines > #lines then
			text = text .. string.format("\n... and %d more", #obtainedEggLines - #lines)
		end
		table.insert(fields, FN.embedField(string.format("Eggs Obtained (%d)", #obtainedEggLines), text, false))
	end
	if #spawnedEggs > 0 then
		local sorted = table.clone(spawnedEggs)
		table.sort(sorted, function(a, b)
			if a.rank == b.rank then
				return a.order < b.order
			end
			return a.rank > b.rank
		end)
		local shown = math.min(#sorted, 15)
		local lines = {}
		for i = 1, shown do
			table.insert(lines, sorted[i].text)
		end
		if #sorted > 15 then
			table.insert(lines, string.format("... and %d more", #sorted - 15))
		end
		table.insert(fields, FN.embedField(string.format("Eggs Spawned (%d)", #sorted), table.concat(lines, "\n"), false))
	end
	return {
		author = { name = GAME_TITLE },
		title = "Session Summary",
		description = string.format("**Player** `%s`\n**Server** `%s`\n**Runtime** `%s`",
			LocalPlayer.Name, tostring(game.JobId), FN.formatElapsed(os.clock() - sessionStart)),
		color = 5793266,
		fields = fields,
		footer = { text = GAME_TITLE },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
end

function FN.sendSummary()
	local embed = FN.buildSummaryEmbed()
	local ok = FN.sendWebhookEmbed(embed, true)
	if ok then
		hopsSinceSummary = 0
		petsSinceSummary = 0
		rebirthsSinceSummary = 0
		spawnedEggs = {}
		obtainedEggLines = {}
	end
	return ok
end

function FN.runWebhookSummary()
	local mins = tonumber(FN.optionValue("WebhookInterval", 15)) or 15
	if os.clock() - lastSummaryAt < mins * 60 then
		return
	end
	lastSummaryAt = os.clock()
	FN.sendSummary()
end

function FN.spawnPassesFilter(rarity)
	return FN.selectionAllows("WebhookRarities", rarity or "")
end

function FN.trackWebhookEvents()
	local save = FN.getSave()
	if not save then
		return
	end
	if not summaryInitialized then
		summaryInitialized = true
		knownPetUids = {}
		knownEggUids = {}
		if typeof(save.Inventory) == "table" then
			for uid in pairs(save.Inventory) do
				knownPetUids[uid] = true
			end
		end
		for _, rec in ipairs(FN.getAreaEggs()) do
			knownEggUids[rec.Uid] = true
		end
		lastRebirth = tonumber(save.Rebirth) or 0
		return
	end
	-- new pets
	if typeof(save.Inventory) == "table" then
		for uid in pairs(save.Inventory) do
			if not knownPetUids[uid] then
				knownPetUids[uid] = true
				petsSinceSummary = petsSinceSummary + 1
			end
		end
	end
	-- rebirths
	local rebirth = tonumber(save.Rebirth) or 0
	if rebirth > lastRebirth then
		rebirthsSinceSummary = rebirthsSinceSummary + rebirth - lastRebirth
	end
	lastRebirth = rebirth
	-- steals
	local delta = math.max(0, stolenCount - lastStealCount)
	hopsSinceSummary = hopsSinceSummary + delta
	lastStealCount = stolenCount
	-- egg spawns
	local stillPresent = {}
	local watchSpawns = FN.isOn("WebhookEggSpawns")
	for _, rec in ipairs(FN.getAreaEggs()) do
		stillPresent[rec.Uid] = true
		if watchSpawns and not knownEggUids[rec.Uid] then
			knownEggUids[rec.Uid] = true
			if #spawnedEggs < 60 then
				local rarity = FN.resolveRarity(rec.AssetCategory)
				if FN.spawnPassesFilter(rarity) then
					table.insert(spawnedEggs, {
						rank = (rarity and RARITY_RANK[rarity]) or 0,
						order = #spawnedEggs + 1,
						text = string.format("**%s** `%s` in %s", FN.assetName(rec.AssetCategory), tostring(rarity or "?"), tostring(rec.AreaId or "?")),
					})
				end
			end
		end
	end
	for uid in pairs(knownEggUids) do
		if not stillPresent[uid] then
			knownEggUids[uid] = nil
		end
	end
end

function FN.handleDisconnect(reason)
	if disconnectHandled then
		return
	end
	disconnectHandled = true
	if FN.isOn("WebhookDisconnectAlerts") then
		FN.sendWebhookEmbed({
			author = { name = GAME_TITLE },
			title = "Disconnected",
			description = string.format("**Player** `%s`\n**Reason** %s", LocalPlayer.Name, tostring(reason or "Connection lost")),
			color = 15158332,
			footer = { text = GAME_TITLE },
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		}, true)
	end
	if FN.isOn("AutoReconnect") then
		task.delay(2, FN.rejoinServer)
	end
end

local loopServerHop = function()
	while not (Library and Library.Unloaded) do
		task.wait(3)
		if FN.isOn("AutoServerHop") and not busyLock then
			pcall(FN.runServerHop)
		end
	end
end

local loopWebhooks = function()
	while not (Library and Library.Unloaded) do
		task.wait(5)
		if FN.isOn("WebhookEnabled") then
			pcall(FN.trackWebhookEvents)
			pcall(FN.runWebhookSummary)
		end
	end
end

local loopAntiPause = function()
	while not (Library and Library.Unloaded) do
		task.wait(1)
		if FN.isOn("AutoReconnect") or FN.isOn("WebhookDisconnectAlerts") then
			local promptGui = CoreGui:FindFirstChild("RobloxPromptGui")
			if promptGui then
				local overlay = promptGui:FindFirstChild("promptOverlay")
				if overlay then
					for _, child in ipairs(overlay:GetChildren()) do
						if child.Visible and child.Name:find("ErrorPrompt") then
							FN.handleDisconnect("Roblox error prompt")
							break
						end
					end
				end
			end
		end
	end
end
-- fps
local fpsBoostOn = false

function FN.enableFpsBoost()
	fpsBoostOn = true
	if typeof(setfps) == "function" then
		pcall(setfps, 240)
	elseif syn and syn.set_fps_cap then
		pcall(syn.set_fps_cap, 240)
	end
end

function FN.disableFpsBoost()
	fpsBoostOn = false
end

function FN.applyFpsBoost(enable)
	if enable then
		FN.enableFpsBoost()
	else
		FN.disableFpsBoost()
	end
end

local fpsCapWarned = false

function FN.applyFpsCap(value)
	local cap = setfpscap
	if typeof(cap) ~= "function" then
		cap = syn and syn.set_fps_cap
	end
	if typeof(cap) ~= "function" then
		if not fpsCapWarned then
			fpsCapWarned = true
			FN.notify("FPS cap is not supported by your executor")
		end
		return
	end
	local n = tonumber(value) or 60
	pcall(cap, math.clamp(n, 15, 360))
end

-- render overlay (Disable 3D Rendering)
local hiddenGuis = {}

function FN.applyRendering(enable)
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if enable then
		if playerGui then
			for _, child in ipairs(playerGui:GetChildren()) do
				if child.Visible and not child:GetAttribute("SAEOwn") then
					table.insert(hiddenGuis, { gui = child, visible = child.Visible })
					child.Visible = false
				end
			end
		end
		FN.buildRenderOverlay()
	else
		FN.destroyRenderOverlay()
		for _, entry in ipairs(hiddenGuis) do
			pcall(function()
				if entry.gui and entry.gui.Parent then
					entry.gui.Visible = entry.visible
				end
			end)
		end
		hiddenGuis = {}
	end
end

function FN.buildRenderOverlay()
	if overlayGui then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "SAERenderInfo"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 500
	gui:SetAttribute("SAEOwn", true)
	local parent
	if typeof(gethui) == "function" then
		parent = gethui()
	else
		parent = CoreGui
	end
	gui.Parent = parent
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 1)
	title.Position = UDim2.fromScale(0.5, 0.5)
	title.Size = UDim2.fromOffset(400, 30)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamMedium
	title.TextSize = 24
	title.TextColor3 = Color3.fromRGB(226, 230, 238)
	title.Text = "Steal An Egg"
	title.Parent = frame
	local statsFrame = Instance.new("Frame")
	statsFrame.AnchorPoint = Vector2.new(0, 1)
	statsFrame.Position = UDim2.new(0, 28, 1, -28)
	statsFrame.Size = UDim2.fromOffset(240, #OVERLAY_FIELDS * 19)
	statsFrame.BackgroundTransparency = 1
	statsFrame.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = statsFrame
	for i, field in ipairs(OVERLAY_FIELDS) do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 17)
		label.Font = Enum.Font.Code
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = Color3.fromRGB(120, 124, 134)
		label.Text = field
		label.LayoutOrder = i
		label.Parent = statsFrame
		overlayLabels[field] = label
	end
	overlayGui = gui
end

function FN.updateRenderOverlay()
	if not overlayGui or not overlayGui.Parent then
		FN.buildRenderOverlay()
	end
	local save = FN.getSave()
	if not save then
		return
	end
	local session = FN.formatSession(os.clock() - sessionStart)
	local values = {
		money = FN.formatNumber(save.Money),
		speed = FN.formatNumber(save.SpeedPower),
		pets = tostring(FN.countTable(save.Inventory)),
		eggs = tostring(FN.countTable(save.EggInventory)),
		stolen = tostring(stolenCount),
		session = session,
	}
	for field, label in pairs(overlayLabels) do
		if label and label.Parent then
			local value = values[field]
			label.Text = string.format("%-8s %s", field, tostring(value or "-"))
		end
	end
end

function FN.destroyRenderOverlay()
	if overlayGui then
		pcall(function()
			overlayGui:Destroy()
		end)
	end
	overlayGui = nil
	overlayLabels = {}
end

local loopRenderOverlay = function()
	while not (Library and Library.Unloaded) do
		task.wait(1)
		if FN.isOn("DisableRendering") or FN.isOn("AutoHideUi") then
			pcall(FN.updateRenderOverlay)
		elseif overlayGui then
			pcall(FN.destroyRenderOverlay)
		end
	end
end

-- anti gameplay pause
local antiPauseConn = nil
local antiPauseTick = 0

function FN.applyAntiGameplayPause(enable)
	if enable and antiPauseConn then
		return
	end
	if antiPauseConn then
		antiPauseConn:Disconnect()
		antiPauseConn = nil
	end
	if not enable then
		return
	end
	antiPauseConn = RunService.Heartbeat:Connect(function()
		antiPauseTick = antiPauseTick + 1
		if antiPauseTick % 600 == 0 then
			task.spawn(function()
				pcall(function()
					local cam = WorkspaceRef.CurrentCamera
					if cam then
						VirtualInputManager:Button1Down(Vector2.new(0, 0), cam.CFrame)
						task.wait(0.05)
						VirtualInputManager:Button1Up(Vector2.new(0, 0), cam.CFrame)
					end
				end)
			end)
		end
	end)
end

local loopMiscD = function()
	while not (Library and Library.Unloaded) do
		task.wait(1)
		if FN.isOn("AntiGameplayPause") then
			FN.applyAntiGameplayPause(true)
		end
	end
end

-- anti afk
function FN.antiAfkTap()
	local cam = WorkspaceRef.CurrentCamera
	if not cam then
		return
	end
	VirtualInputManager:Button2Down(Vector2.new(0, 0), cam.CFrame)
	task.wait(0.1)
	VirtualInputManager:Button2Up(Vector2.new(0, 0), cam.CFrame)
	lastAntiAfk = tick()
end

local loopAntiAfk = function()
	while not (Library and Library.Unloaded) do
		task.wait(2)
		if FN.isOn("AntiAfk") and tick() - lastAntiAfk >= 60 then
			pcall(FN.antiAfkTap)
		end
	end
end

-- detection counter
local function detectionCounter()
	local count = 0
	local getUp = debug.getupvalues or getupvalues
	local setMeta = setrawmetatable
	if not setMeta and debug then
		setMeta = debug.setmetatable
	end
	local candidates = nil
	if typeof(filtergc) == "function" then
		local ok, res = pcall(filtergc, "function", { Constants = { "gmatch", "GetFullName" } })
		if ok then
			candidates = res
		end
	end
	if typeof(candidates) ~= "table" and typeof(getUp) == "function" then
		return 0
	end
	if typeof(candidates) == "table" then
		for _, fn in ipairs(candidates) do
			if type(fn) == "function" and typeof(getUp) == "function" then
				local ok, ups = pcall(getUp, fn)
				if ok and typeof(ups) == "table" then
					for _, up in pairs(ups) do
						if typeof(up) == "table" then
							pcall(function()
								setMeta(up, { __newindex = function(_, k, v)
									warn(("[Bypass] Blocked detection %s %s"):format(tostring(k), tostring(v)))
								end })
							end)
							count = count + 1
						end
					end
				end
			end
		end
	end
	return count
end
-- UI (versus NewLibrary, GAG2 pattern: few emoji tabs + Special label separators)
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

local ui = Library:Setup({
	Location = resolveUiParent(),
	OpenCloseLocation = "Top Center",
})

task.defer(function()
	local ok = pcall(function()
		local gui = Library and Library.UI
		local button = gui and gui:FindFirstChild("OpenCloseButton")
		local title = button and button:FindFirstChild("Title")
		if title then
			title.Text = GAME_TITLE
		end
	end)
end)

local function setLabelText(ctrl, text)
	if not ctrl then
		return
	end
	pcall(function()
		if ctrl.Set then
			ctrl:Set(text)
		elseif ctrl.updateText then
			ctrl:updateText(text)
		end
	end)
end

local function header(sec, text)
	sec:createLabel({
		Name = text,
		Special = true,
	})
end

local Home = ui:CreateSection("🏠 Home")
local Farm = ui:CreateSection("🥚 Farm")
local Pets = ui:CreateSection("🐾 Pets")
local Shop = ui:CreateSection("🛒 Shop")
local Hop = ui:CreateSection("🔄 Hop")
local Visual = ui:CreateSection("👁️ Visual")
local Webhook = ui:CreateSection("📡 Webhook")
local Settings = ui:CreateSection("⚙️ Settings")

local SessionLabel = nil

-- Home: Account
header(Home, "Account")
Home:createLabel({
	Name = "User: " .. LocalPlayer.Name,
	Special = true,
})
Home:createLabel({
	Name = "Executor: " .. executorName,
	Special = true,
})

-- Home: Game Info
header(Home, "Game Info")
Home:createLabel({
	Name = "Steal an Egg [" .. PLACE_ID .. "]",
	Special = true,
})
Home:createLabel({
	Name = "Server: " .. string.sub(tostring(game.JobId), 1, 18) .. "...",
	Special = true,
})
SessionLabel = Home:createLabel({
	Name = "Session time: 0s",
	Special = true,
	flagName = "saeSessionTime",
})
Home:createButton({
	Name = "Copy Join Script (Job ID)",
	Description = "Copies a join script for this server.",
	Callback = function()
		FN.copyJoinScript()
	end,
})

-- Farm: Steal Eggs
header(Farm, "Steal Eggs")
Farm:createDropdown({
	Name = "Areas",
	flagName = "StealZones",
	Flag = {},
	List = AREA_NAMES,
	multi = true,
	Callback = function() end,
})
Farm:createDropdown({
	Name = "Rarities",
	flagName = "StealRarities",
	Flag = {},
	List = RARITY_NAMES,
	multi = true,
	Callback = function() end,
})
Farm:createDropdown({
	Name = "Mutations",
	flagName = "StealMutations",
	Flag = {},
	List = MUTATION_NAMES,
	multi = true,
	Callback = function() end,
})
Farm:createDropdown({
	Name = "Target Priority",
	flagName = "StealPriority",
	Flag = { "Rarest" },
	List = { "Rarest", "Nearest", "Furthest", "Biggest Size" },
	multi = true,
	Callback = function() end,
})
Farm:createToggle({
	Name = "Auto Steal Selected",
	Description = "Steal eggs matching the filters above.",
	Flag = false,
	flagName = "AutoStealSelected",
	Callback = function() end,
})
Farm:createToggle({
	Name = "Auto Steal All",
	Description = "Steal every egg in the world.",
	Flag = false,
	flagName = "AutoStealAll",
	Callback = function() end,
})
Farm:createSlider({
	Name = "Steal Speed",
	flagName = "StealSpeed",
	value = 300,
	minValue = 50,
	maxValue = 1000,
	Callback = function() end,
})
Farm:createToggle({
	Name = "Steal Big Eggs",
	Description = "Also steal eggs at or above the minimum size.",
	Flag = false,
	flagName = "StealBigEggs",
	Callback = function() end,
})
Farm:createSlider({
	Name = "Big Egg Minimum Size",
	flagName = "StealBigEggScale",
	value = 1.5,
	minValue = 1,
	maxValue = 50,
	Callback = function() end,
})
Farm:createToggle({
	Name = "Auto Drop Held Egg",
	Flag = false,
	flagName = "AutoDropEgg",
	Callback = function() end,
})
Farm:createToggle({
	Name = "Auto Return To Base",
	Description = "Return to base after stealing an egg.",
	Flag = true,
	flagName = "AutoReturn",
	Callback = function() end,
})

-- Farm: Egg Handling
header(Farm, "Egg Handling")
Farm:createDropdown({
	Name = "Rarities",
	flagName = "LifecycleRarities",
	Flag = {},
	List = RARITY_NAMES,
	multi = true,
	Callback = function() end,
})
Farm:createDropdown({
	Name = "Mutations",
	flagName = "LifecycleMutations",
	Flag = {},
	List = MUTATION_NAMES,
	multi = true,
	Callback = function() end,
})
Farm:createToggle({
	Name = "Auto Place Selected",
	Flag = false,
	flagName = "AutoPlaceSelected",
	Callback = function() end,
})
Farm:createToggle({
	Name = "Auto Place All",
	Flag = false,
	flagName = "AutoPlaceAll",
	Callback = function() end,
})
Farm:createToggle({
	Name = "Auto Hatch Ready",
	Flag = false,
	flagName = "AutoOpenReadyEggs",
	Callback = function() end,
})
Farm:createButton({
	Name = "Drop Held Egg",
	Callback = function()
		FN.dropHeldEgg()
	end,
})

-- Pets: Pets
header(Pets, "Pets")
Pets:createToggle({
	Name = "Auto Equip Best Pets",
	Flag = false,
	flagName = "AutoEquipBest",
	Callback = function() end,
})

-- Pets: Auto Fuse
header(Pets, "Auto Fuse")
Pets:createToggle({
	Name = "Auto Fuse Pets [Beta]",
	Flag = false,
	flagName = "AutoFusePets",
	Callback = function() end,
})
Pets:createDropdown({
	Name = "Fuse Rarities",
	flagName = "FuseRarities",
	Flag = {},
	List = RARITY_NAMES,
	multi = true,
	Callback = function() end,
})
Pets:createDropdown({
	Name = "Fuse Mutations",
	flagName = "FuseMutations",
	Flag = {},
	List = MUTATION_NAMES,
	multi = true,
	Callback = function() end,
})
Pets:createDropdown({
	Name = "Pick Group By",
	flagName = "FuseTarget",
	Flag = { "Highest Rarity" },
	List = { "Highest Rarity", "Lowest Rarity", "Most Duplicates" },
	multi = true,
	Callback = function() end,
})
Pets:createToggle({
	Name = "Never Fuse Mutated",
	Flag = true,
	flagName = "FuseKeepMutated",
	Callback = function() end,
})
Pets:createToggle({
	Name = "Never Fuse Equipped",
	Flag = true,
	flagName = "FuseKeepEquipped",
	Callback = function() end,
})
Pets:createToggle({
	Name = "Auto Complete Reveal",
	Flag = true,
	flagName = "FuseAutoReveal",
	Callback = function() end,
})
Pets:createSlider({
	Name = "Maximum Scale To Fuse",
	flagName = "FuseMaxScale",
	value = 10,
	minValue = 0,
	maxValue = 10,
	Callback = function() end,
})
Pets:createSlider({
	Name = "Keep Per Pet Type",
	flagName = "FuseKeepPerCategory",
	value = 0,
	minValue = 0,
	maxValue = 20,
	Callback = function() end,
})
Pets:createSlider({
	Name = "Fuse Interval (s)",
	flagName = "FuseInterval",
	value = 8,
	minValue = 1,
	maxValue = 120,
	Callback = function() end,
})
Pets:createButton({
	Name = "Fuse Now",
	Callback = function()
		task.spawn(function()
			FN.runAutoFusePets(true)
		end)
	end,
})

-- Pets: Auto Sell Pets
header(Pets, "Auto Sell Pets")
Pets:createToggle({
	Name = "Auto Sell Pets",
	Flag = false,
	flagName = "AutoSellPets",
	Callback = function() end,
})
Pets:createDropdown({
	Name = "Sell Rarities",
	flagName = "SellRarities",
	Flag = {},
	List = RARITY_NAMES,
	multi = true,
	Callback = function() end,
})
Pets:createDropdown({
	Name = "Sell Mutations",
	flagName = "SellMutations",
	Flag = {},
	List = MUTATION_NAMES,
	multi = true,
	Callback = function() end,
})
Pets:createToggle({
	Name = "Never Sell Mutated",
	Flag = true,
	flagName = "SellKeepMutated",
	Callback = function() end,
})
Pets:createToggle({
	Name = "Never Sell Equipped",
	Flag = true,
	flagName = "SellKeepEquipped",
	Callback = function() end,
})
Pets:createSlider({
	Name = "Maximum Scale To Sell",
	flagName = "SellMaxScale",
	value = 10,
	minValue = 0,
	maxValue = 10,
	Callback = function() end,
})
Pets:createSlider({
	Name = "Sell Interval (s)",
	flagName = "SellInterval",
	value = 6,
	minValue = 1,
	maxValue = 120,
	Callback = function() end,
})

-- Pets: Auto Sell Eggs
header(Pets, "Auto Sell Eggs")
Pets:createToggle({
	Name = "Auto Sell Eggs",
	Flag = false,
	flagName = "AutoSellEggs",
	Callback = function() end,
})
Pets:createDropdown({
	Name = "Sell Rarities",
	flagName = "SellEggRarities",
	Flag = {},
	List = RARITY_NAMES,
	multi = true,
	Callback = function() end,
})
Pets:createSlider({
	Name = "Sell Interval (s)",
	flagName = "SellEggInterval",
	value = 8,
	minValue = 1,
	maxValue = 120,
	Callback = function() end,
})

-- Pets: Earnings
header(Pets, "Earnings")
Pets:createToggle({
	Name = "Claim Offline Earnings",
	Flag = false,
	flagName = "AutoClaimOffline",
	Callback = function() end,
})

-- Shop: Upgrades
header(Shop, "Upgrades")
Shop:createToggle({
	Name = "Auto Buy Upgrades",
	Flag = false,
	flagName = "AutoUpgrades",
	Callback = function() end,
})
Shop:createDropdown({
	Name = "Upgrades",
	flagName = "UpgradeTypes",
	Flag = { "Base", "Treadmill" },
	List = { "Base", "Treadmill" },
	multi = true,
	Callback = function() end,
})

-- Shop: Index
header(Shop, "Index")
Shop:createToggle({
	Name = "Auto Claim Index",
	Flag = false,
	flagName = "AutoClaimIndex",
	Callback = function() end,
})
Shop:createToggle({
	Name = "Auto Claim Group Reward",
	Flag = false,
	flagName = "AutoClaimGroupReward",
	Callback = function() end,
})

-- Shop: Trails
header(Shop, "Trails")
Shop:createToggle({
	Name = "Auto Buy Trail",
	Flag = false,
	flagName = "AutoBuyTrail",
	Callback = function() end,
})
Shop:createDropdown({
	Name = "Trails",
	flagName = "TrailWanted",
	Flag = {},
	List = trailNames,
	multi = true,
	Callback = function() end,
})
Shop:createToggle({
	Name = "Auto Equip Best Trail",
	Flag = false,
	flagName = "AutoEquipBestTrail",
	Callback = function() end,
})

-- Shop: Training
header(Shop, "Training")
Shop:createToggle({
	Name = "Auto Treadmill Training",
	Flag = false,
	flagName = "AutoTreadmill",
	Callback = function() end,
})

-- Shop: Gear
header(Shop, "Gear")
Shop:createToggle({
	Name = "Auto Equip Best Gear",
	Flag = false,
	flagName = "AutoEquipBestGear",
	Callback = function() end,
})

-- Hop: Server Hop
header(Hop, "Server Hop")
Hop:createToggle({
	Name = "Auto Server Hop",
	Flag = false,
	flagName = "AutoServerHop",
	Callback = function() end,
})
Hop:createDropdown({
	Name = "Hop When",
	flagName = "HopMode",
	Flag = { HOP_MODES[1] },
	List = HOP_MODES,
	multi = true,
	Callback = function() end,
})
Hop:createSlider({
	Name = "Threshold (s / min / steals)",
	flagName = "HopValue",
	value = 15,
	minValue = 1,
	maxValue = 200,
	Callback = function() end,
})
Hop:createButton({
	Name = "Hop Now",
	Callback = function()
		task.spawn(function()
			hopCooldownUntil = 0
			FN.serverHop("Manual hop")
		end)
	end,
})

-- Hop: Task Order
header(Hop, "Task Order")
Hop:createDropdown({
	Name = "Priority 1",
	flagName = "PrioritySlot1",
	Flag = {default},
	List = TASK_NAMES,
	multi = true,
	Callback = function() end,
})
Hop:createDropdown({
	Name = "Priority 2",
	flagName = "PrioritySlot2",
	Flag = {default},
	List = TASK_NAMES,
	multi = true,
	Callback = function() end,
})
Hop:createDropdown({
	Name = "Priority 3",
	flagName = "PrioritySlot3",
	Flag = {default},
	List = TASK_NAMES,
	multi = true,
	Callback = function() end,
})
Hop:createDropdown({
	Name = "Priority 4",
	flagName = "PrioritySlot4",
	Flag = {default},
	List = TASK_NAMES,
	multi = true,
	Callback = function() end,
})

-- Visual: ESP
header(Visual, "ESP")
Visual:createToggle({
	Name = "World Egg ESP",
	Flag = false,
	flagName = "EspWorldEggs",
	Callback = function() end,
})
Visual:createToggle({
	Name = "Carried And Dropped Egg ESP",
	Flag = false,
	flagName = "EspCarriedEggs",
	Callback = function() end,
})
Visual:createToggle({
	Name = "Guard ESP",
	Flag = false,
	flagName = "EspGuards",
	Callback = function() end,
})
Visual:createToggle({
	Name = "Pet ESP",
	Flag = false,
	flagName = "EspPets",
	Callback = function() end,
})
Visual:createToggle({
	Name = "Player ESP",
	Flag = false,
	flagName = "EspPlayers",
	Callback = function() end,
})
Visual:createToggle({
	Name = "Machine ESP",
	Flag = false,
	flagName = "EspMachines",
	Callback = function() end,
})
Visual:createToggle({
	Name = "Plot ESP",
	Flag = false,
	flagName = "EspPlots",
	Callback = function() end,
})
Visual:createSlider({
	Name = "Render Distance",
	flagName = "EspDistance",
	value = 2000,
	minValue = 100,
	maxValue = 6000,
	Callback = function() end,
})

-- Visual: Movement
header(Visual, "Movement")
Visual:createToggle({
	Name = "Walk Speed Override",
	Flag = false,
	flagName = "WalkSpeedEnabled",
	Callback = function() end,
})
Visual:createSlider({
	Name = "Walk Speed",
	flagName = "WalkSpeed",
	value = 32,
	minValue = 16,
	maxValue = 500,
	Callback = function() end,
})
Visual:createToggle({
	Name = "Jump Power Override",
	Flag = false,
	flagName = "JumpPowerEnabled",
	Callback = function() end,
})
Visual:createSlider({
	Name = "Jump Power",
	flagName = "JumpPower",
	value = 50,
	minValue = 10,
	maxValue = 500,
	Callback = function() end,
})
Visual:createToggle({
	Name = "Infinite Jump",
	Flag = false,
	flagName = "InfJump",
	Callback = function() end,
})
Visual:createToggle({
	Name = "NoClip",
	Flag = false,
	flagName = "NoClip",
	Callback = function() end,
})

-- Visual: Fly
header(Visual, "Fly")
Visual:createToggle({
	Name = "Fly",
	Flag = false,
	flagName = "Fly",
	Callback = function() end,
})
Visual:createSlider({
	Name = "Fly Speed",
	flagName = "FlySpeed",
	value = 60,
	minValue = 10,
	maxValue = 400,
	Callback = function() end,
})

-- Visual: Waypoint Teleport
header(Visual, "Waypoint Teleport")
local WAYPOINT_VALUES = { "Base", "Pet Area", "Treadmill", "Fuse Machine", "Lobby Entry" }
for _, name in ipairs(AREA_NAMES) do
	table.insert(WAYPOINT_VALUES, name)
end
Visual:createDropdown({
	Name = "Waypoint",
	flagName = "WaypointTarget",
	Flag = { "Base" },
	List = WAYPOINT_VALUES,
	multi = true,
	Callback = function() end,
})
Visual:createButton({
	Name = "Teleport To Waypoint",
	Callback = function()
		task.spawn(function()
			local dest = FN.resolveWaypoint(FN.firstSelected("WaypointTarget", nil))
			if not dest then
				FN.notify("That waypoint is not available right now")
				return
			end
			if not FN.travelTo(dest, true) then
				FN.notify("Teleport failed")
			end
		end)
	end,
})

-- Webhook: Webhook
header(Webhook, "Webhook")
Webhook:createToggle({
	Name = "Enable Webhooks",
	Flag = false,
	flagName = "WebhookEnabled",
	Callback = function() end,
})
Webhook:createInputBox({
	Name = "Webhook URL",
	flagName = "WebhookUrl",
	Flag = "",
	Callback = function() end,
})
Webhook:createInputBox({
	Name = "Ping User ID",
	flagName = "WebhookPingId",
	Flag = "",
	Callback = function() end,
})
Webhook:createSlider({
	Name = "Summary Interval (min)",
	flagName = "WebhookInterval",
	value = 15,
	minValue = 1,
	maxValue = 180,
	Callback = function() end,
})
Webhook:createToggle({
	Name = "List Spawned Eggs",
	Flag = true,
	flagName = "WebhookEggSpawns",
	Callback = function() end,
})
Webhook:createDropdown({
	Name = "Rarities",
	flagName = "WebhookRarities",
	Flag = {},
	List = RARITY_NAMES,
	multi = true,
	Callback = function() end,
})
Webhook:createToggle({
	Name = "Disconnect Alerts",
	Flag = false,
	flagName = "WebhookDisconnectAlerts",
	Callback = function() end,
})
Webhook:createButton({
	Name = "Send Summary Now",
	Callback = function()
		task.spawn(function()
			local ok = FN.sendSummary()
			FN.notify(ok and "Summary sent" or "Webhook send failed")
		end)
	end,
})

-- Settings: Menu
header(Settings, "Menu")
Settings:createToggle({
	Name = "Anti-AFK",
	Flag = true,
	flagName = "AntiAfk",
	Callback = function() end,
})
Settings:createToggle({
	Name = "No Gameplay Paused",
	Flag = true,
	flagName = "AntiGameplayPause",
	Callback = function(enabled)
		FN.applyAntiGameplayPause(enabled)
	end,
})
Settings:createToggle({
	Name = "Auto Hide UI",
	Flag = false,
	flagName = "AutoHideUi",
	Callback = function(enabled)
		FN.applyRendering(enabled)
	end,
})
Settings:createToggle({
	Name = "Auto Reconnect",
	Flag = false,
	flagName = "AutoReconnect",
	Callback = function() end,
})
Settings:createToggle({
	Name = "Auto Execute",
	Flag = false,
	flagName = "AutoExecute",
	Callback = function() end,
})
Settings:createToggle({
	Name = "Disable 3D Rendering",
	Flag = false,
	flagName = "DisableRendering",
	Callback = function(enabled)
		FN.applyRendering(enabled)
	end,
})
Settings:createKeybind({
	Name = "Menu Keybind",
	flagName = "MenuKeybind",
	Flag = "LeftAlt",
	Callback = function() end,
})
Settings:createButton({
	Name = "Unload",
	Callback = function()
		task.spawn(function()
			pcall(FN.unload)
		end)
	end,
})

-- Settings: Performance
header(Settings, "Performance")
Settings:createToggle({
	Name = "FPS Boost",
	Flag = false,
	flagName = "FpsBoost",
	Callback = function(enabled)
		FN.applyFpsBoost(enabled)
	end,
})
Settings:createToggle({
	Name = "Auto Delete Own Pets",
	Flag = false,
	flagName = "AutoDeleteOwnPets",
	Callback = function() end,
})
Settings:createSlider({
	Name = "FPS Cap",
	flagName = "FpsCap",
	value = 60,
	minValue = 15,
	maxValue = 360,
	Callback = function(value)
		FN.applyFpsCap(value)
	end,
})
-- carry state (poll the egg state module; the decompile's connection was lost)
local function recordObtainedEgg(rec)
	if #obtainedEggLines >= 100 then
		return
	end
	local parts = { string.format("**%s** `%s`", FN.assetName(rec.AssetCategory), tostring(FN.resolveRarity(rec.AssetCategory) or "?")) }
	if typeof(rec.AreaId) == "string" then
		table.insert(parts, rec.AreaId)
	end
	local scale = tonumber(rec.AssetScale)
	if scale then
		table.insert(parts, string.format("x%.2f", scale))
	end
	local muts = FN.recordMutations(rec)
	if #muts > 0 then
		table.insert(parts, table.concat(muts, ", "))
	end
	table.insert(obtainedEggLines, table.concat(parts, " | "))
end

local function onCarryChange(data)
	local nowCarrying = data ~= nil and data.IsCarrying == true
	if nowCarrying and not Carrying then
		Carrying = true
		stolenCount = stolenCount + 1
		if typeof(data.Uid) == "string" then
			local rec = FN.findAreaEggRecord(data.Uid)
			if rec then
				recordObtainedEgg(rec)
			end
		end
	end
	if not nowCarrying then
		Carrying = false
	end
end

local loopCarryState = function()
	while not (Library and Library.Unloaded) do
		task.wait(0.5)
		local ok, state = pcall(FN.getCarryState)
		if ok and state then
			onCarryChange(state)
		end
	end
end

-- heartbeat: walk speed, jump power, inf jump, noclip, fly
local heartbeatConn = RunService.Heartbeat:Connect(function(dt)
	if FN.isOn("WalkSpeedEnabled") then
		local hum = FN.getHumanoid()
		if hum then
			hum.WalkSpeed = tonumber(FN.optionValue("WalkSpeed", 32)) or 32
		end
	end
	if FN.isOn("JumpPowerEnabled") then
		local hum = FN.getHumanoid()
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = tonumber(FN.optionValue("JumpPower", 50)) or 50
		end
	end
	if FN.isOn("InfJump") then
		local hum = FN.getHumanoid()
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
	if FN.isOn("NoClip") then
		local character = LocalPlayer.Character
		if character then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
	end
	if FN.isOn("Fly") then
		local hum = FN.getHumanoid()
		local root = FN.getRoot()
		if hum then
			hum.PlatformStand = true
		end
		if root then
			local dir = Vector3.zero
			local cam = WorkspaceRef.CurrentCamera
			if cam then
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
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				dir = dir + Vector3.new(0, 1, 0)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				dir = dir - Vector3.new(0, 1, 0)
			end
			if dir.Magnitude > 0 then
				local speed = tonumber(FN.optionValue("FlySpeed", 60)) or 60
				root.CFrame = root.CFrame + dir.Unit * speed * dt
			else
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	else
		local hum = FN.getHumanoid()
		if hum then
			hum.PlatformStand = false
		end
	end
end)

-- ground lock while stealing (decompile loopMiscA)
local loopGroundLock = function()
	while not (Library and Library.Unloaded) do
		task.wait(0.1)
		if FN.stealingEnabled() then
			local root = FN.getRoot()
			local hum = FN.getHumanoid()
			if root and hum and hum:GetAttribute("SAEStealHum") == true then
				local laneY = FN.getLaneY()
				if root.Position.Y > laneY + 12 then
					local gy = FN.groundedY(root.Position.X, root.Position.Z)
					root.CFrame = CFrame.new(root.Position.X, gy, root.Position.Z)
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
				elseif math.abs(root.AssemblyLinearVelocity.Y) > 4 then
					root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
				end
			end
		end
	end
end

-- keep the steal humanoid in sync (decompile loopMiscB)
local loopStealHumanoid = function()
	while not (Library and Library.Unloaded) do
		task.wait(0.2)
		if FN.stealingEnabled() then
			FN.swapStealHumanoid()
		end
	end
end

-- drop / return handling (decompile loopMiscC)
local loopCarryActions = function()
	while not (Library and Library.Unloaded) do
		task.wait(0.2)
		if not busyLock then
			if FN.isOn("AutoDropEgg") and FN.isCarrying() then
				busyLock = true
				pcall(FN.runAutoDropEgg)
				busyLock = false
			elseif FN.isOn("AutoReturn") and FN.isCarrying() then
				busyLock = true
				pcall(FN.runAutoReturn)
				busyLock = false
			end
		end
	end
end

local loopStopTreadmillIfOff = function()
	while not (Library and Library.Unloaded) do
		task.wait(1)
		if (treadmillEquipped or FN.isDoubleSpeedVisible()) and not FN.isOn("AutoTreadmill") then
			pcall(FN.stopTreadmillTraining)
		end
	end
end

local loopAutoSellPets = function()
	while not (Library and Library.Unloaded) do
		task.wait(tonumber(FN.optionValue("SellInterval", 6)) or 6)
		if FN.isOn("AutoSellPets") and not busyLock and not FN.isCarrying() then
			pcall(FN.runAutoSellPets)
		end
	end
end

local loopAutoSellEggs = function()
	while not (Library and Library.Unloaded) do
		task.wait(tonumber(FN.optionValue("SellEggInterval", 8)) or 8)
		if FN.isOn("AutoSellEggs") and not busyLock and not FN.isCarrying() then
			busyLock = true
			pcall(FN.runAutoSellEggs)
			busyLock = false
		end
	end
end

local loopAutoFusePets = function()
	while not (Library and Library.Unloaded) do
		task.wait(tonumber(FN.optionValue("FuseInterval", 8)) or 8)
		if FN.isOn("AutoFusePets") and not busyLock and not FN.isCarrying() then
			busyLock = true
			pcall(FN.runAutoFusePets)
			busyLock = false
		end
	end
end

local loopAutoEquipBest = function()
	while not (Library and Library.Unloaded) do
		task.wait(5)
		if FN.isOn("AutoEquipBest") and not busyLock then
			pcall(FN.runAutoEquipBest)
		end
	end
end

local loopAutoEquipBestGear = function()
	while not (Library and Library.Unloaded) do
		task.wait(5)
		if FN.isOn("AutoEquipBestTrail") then
			pcall(FN.runAutoEquipBestTrail)
		end
		if FN.isOn("AutoEquipBestGear") then
			pcall(FN.runAutoEquipBestGear)
		end
	end
end

local loopAutoClaimOffline = function()
	while not (Library and Library.Unloaded) do
		task.wait(15)
		if FN.isOn("AutoClaimOffline") then
			pcall(FN.runClaimOfflineEarnings)
		end
	end
end

local loopAutoClaimIndex = function()
	while not (Library and Library.Unloaded) do
		task.wait(8)
		if FN.isOn("AutoClaimIndex") then
			pcall(FN.runAutoClaimIndex)
		end
	end
end

local loopAutoClaimGroupReward = function()
	while not (Library and Library.Unloaded) do
		task.wait(20)
		if FN.isOn("AutoClaimGroupReward") then
			pcall(FN.runAutoClaimGroupReward)
		end
	end
end

local loopAutoUpgrades = function()
	while not (Library and Library.Unloaded) do
		task.wait(2)
		if FN.isOn("AutoUpgrades") and not FN.isCarrying() then
			pcall(FN.runAutoUpgrades)
		end
	end
end

local loopAutoBuyTrail = function()
	while not (Library and Library.Unloaded) do
		task.wait(6)
		if FN.isOn("AutoBuyTrail") and not FN.isCarrying() then
			pcall(FN.runAutoBuyTrail)
		end
	end
end

local loopAutoDeleteOwnPets = function()
	while not (Library and Library.Unloaded) do
		task.wait(1)
		if FN.isOn("AutoDeleteOwnPets") then
			pcall(FN.deleteOwnPetRenders)
		end
	end
end

local loopSessionTimer = function()
	while not (Library and Library.Unloaded) do
		task.wait(1)
		setLabelText(SessionLabel, "Session time: " .. FN.formatSession(os.clock() - sessionStart))
	end
end

-- afk input tracking
local afkInputConn = UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Gamepad1 then
		lastInputTick = tick()
	end
end)

-- menu keybind (toggles the library window through its own open/close button)
local menuKeyConn = UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	if Library and Library._capturingKeybind == true then
		return
	end
	if UserInputService:GetFocusedTextBox() then
		return
	end
	local keyName = FN.optionValue("MenuKeybind", "LeftAlt")
	local keyCode = Enum.KeyCode[keyName]
	if not keyCode or input.KeyCode ~= keyCode then
		return
	end
	pcall(function()
		local gui = Library and Library.UI
		local button = gui and gui:FindFirstChild("OpenCloseButton")
		if button then
			button:Activate()
		end
	end)
end)

-- respawn: restore humanoid state
local characterConn = LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	FN.swapStealHumanoid()
end)

-- leaderstats money
local statsConns = {}
pcall(function()
	local function watchStats(stats)
		if not stats then
			return
		end
		for _, child in ipairs(stats:GetChildren()) do
			local ok, conn = pcall(function()
				return child:GetPropertyChangedSignal("Value"):Connect(function()
					moneyDisplay = child.Value
				end)
			end)
			if ok and conn then
				table.insert(statsConns, conn)
			end
		end
	end
	watchStats(LocalPlayer:FindFirstChild("LeaderStats"))
	table.insert(statsConns, LocalPlayer.ChildAdded:Connect(function(child)
		if child.Name == "LeaderStats" then
			task.wait(0.5)
			watchStats(child)
		end
	end))
end)

-- boot: apply state for toggles that were already ON (library callbacks fire on click only)
pcall(function()
	if FN.isOn("AntiGameplayPause") then
		FN.applyAntiGameplayPause(true)
	end
end)
pcall(function()
	if FN.isOn("DisableRendering") or FN.isOn("AutoHideUi") then
		FN.applyRendering(true)
	end
end)
pcall(function()
	if FN.isOn("FpsBoost") then
		FN.applyFpsBoost(true)
	end
	local cap = FN.optionValue("FpsCap", nil)
	if typeof(cap) == "number" then
		FN.applyFpsCap(cap)
	end
end)
pcall(function()
	if FN.stealingEnabled() then
		FN.swapStealHumanoid()
	end
end)
pcall(detectionCounter)
if FN.isOn("AutoExecute") then
	task.delay(3, function()
		pcall(FN.runAutoClaimIndex)
		pcall(FN.runClaimOfflineEarnings)
		pcall(FN.runAutoClaimGroupReward)
	end)
end

-- unload (the library exposes no unload API: stop loops, cut connections, destroy the window)
function FN.unload()
	Library.Unloaded = true
	local function cut(conn)
		pcall(function()
			if conn then
				conn:Disconnect()
			end
		end)
	end
	cut(heartbeatConn)
	cut(afkInputConn)
	cut(menuKeyConn)
	cut(characterConn)
	for _, conn in ipairs(statsConns) do
		cut(conn)
	end
	pcall(function()
		FN.applyAntiGameplayPause(false)
	end)
	pcall(function()
		if Library.CleanupConnections then
			Library:CleanupConnections()
		end
	end)
	pcall(function()
		if Library.UI and Library.UI.Parent then
			Library.UI:Destroy()
		end
	end)
	FN.toast("Unloaded")
end

-- start all background loops
task.spawn(loopCarryState)
task.spawn(loopStealTravel)
task.spawn(loopEsp)
task.spawn(loopGroundLock)
task.spawn(loopStealHumanoid)
task.spawn(loopCarryActions)
task.spawn(loopAutoSellPets)
task.spawn(loopAutoSellEggs)
task.spawn(loopAutoFusePets)
task.spawn(loopAutoEquipBest)
task.spawn(loopAutoEquipBestGear)
task.spawn(loopAutoClaimOffline)
task.spawn(loopAutoClaimIndex)
task.spawn(loopAutoClaimGroupReward)
task.spawn(loopAutoUpgrades)
task.spawn(loopAutoBuyTrail)
task.spawn(loopAutoDeleteOwnPets)
task.spawn(loopStopTreadmillIfOff)
task.spawn(loopServerHop)
task.spawn(loopWebhooks)
task.spawn(loopAntiPause)
task.spawn(loopRenderOverlay)
task.spawn(loopMiscD)
task.spawn(loopAntiAfk)
task.spawn(loopSessionTimer)
