if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Lumin Hub | Tap Simulator Reborn
-- Single-file automation hub on the Lumin UI library. Feature modules are plain
-- tables; two schedulers (one mover, one background) drive them off save changes.

local Config = {
    Title = "Lumin Hub",
    Footer = "Tap Simulator Reborn",
    Folder = "LuminHub",
    SubFolder = "TapSimReborn",
    ThemeFolder = "LuminTheme",
    LibraryUrl = "https://luminon.top/testing/new_lib.lua",
    LoaderUrl = "http://luminon.top/loader.lua",
    IconUrl = "http://luminon.top/A7.png",
    IconFile = "A7.png",
    IconFallback = "rbxassetid://73375080218088",
    GameId = 10629695169,
}

if game.GameId ~= Config.GameId then
    return
end

local Library = loadstring(game:HttpGet(Config.LibraryUrl))()
Library.NotifyOnError = true
Library.ForceCheckbox = true

local ThemeManager = Library.ThemeManager
local SaveManager = Library.SaveManager
local Options = Library.Options
local Toggles = Library.Toggles

-- Automation code reads settings as Library.Flags.<name>; route that to the
-- live Lumin toggle/option values so reads always see the current UI state.
-- Augment whatever table the library already keeps here instead of replacing it:
-- some builds own Library.Flags and resolve element.Value out of it, so a fresh
-- empty proxy misses every read, bounces back through element.Value and overflows
-- the C stack on the first flag the hub reads. Keeping the library's own table also
-- leaves its save/restore bookkeeping intact, and its own writes land as real keys
-- that answer later reads directly. The hub only ever reads this table; values are
-- set through element:SetValue, so no __newindex is installed.
do
    local flags = rawget(Library, "Flags")
    if type(flags) ~= "table" then
        flags = {}
        Library.Flags = flags
    end

    local resolving = {}

    -- Looked up live: the registries are rebuilt by some library versions.
    local function elementFor(name)
        local toggles, options = Library.Toggles, Library.Options
        return (type(toggles) == "table" and toggles[name])
            or (type(options) == "table" and options[name])
            or nil
    end

    setmetatable(flags, {
        __index = function(_, name)
            if resolving[name] then
                return nil
            end
            local el = elementFor(name)
            if el == nil then
                return nil
            end
            local stored = rawget(el, "Value")
            if stored ~= nil then
                return stored
            end
            resolving[name] = true
            local ok, value = pcall(function()
                return el.Value
            end)
            resolving[name] = nil
            return ok and value or nil
        end,
    })
end
-- The hub inherited BigFroot-style notifications that carry Type = "success" /
-- "warning"; Lumin takes Title/Description/Time instead. Normalise that here, in a
-- helper the hub calls, and leave Library.Notify itself alone.
--
-- It used to be done by replacing Library.Notify with a wrapper, which is unsafe on
-- two counts. The wrapper mutated the caller's table (data.Type = nil), so it also
-- stripped fields from tables the library passed in and may reuse. Worse, every
-- notification the library raises for itself went through it too: with
-- NotifyOnError = true a failing notify is reported by calling notify again, which
-- fails again, and that loop re-prefixes one error string forever -- the endless
-- "LPH:3908: LPH:3908: ..." console flood.
local Toast
do
    local rawNotify = Library.Notify
    Toast = function(data)
        if type(rawNotify) ~= "function" then
            return
        end
        if type(data) ~= "table" then
            pcall(rawNotify, Library, data)
            return
        end
        -- Copy, never mutate what the caller handed us.
        local payload = {}
        for key, value in pairs(data) do
            payload[key] = value
        end
        payload.Time = payload.Time or 3
        payload.Type = nil
        if pcall(rawNotify, Library, payload) then
            return
        end
        -- Last resort: the keys every build accepts. Still pcall'd, so a notify
        -- that cannot be delivered stays silent instead of restarting the loop.
        pcall(rawNotify, Library, {
            Title = payload.Title,
            Description = payload.Description,
            Time = payload.Time,
        })
    end
end

local function hubIcon()
    if not (writefile and isfile and getcustomasset) then
        return Config.IconFallback
    end
    local ok, asset = pcall(function()
        if not isfile(Config.IconFile) then
            writefile(Config.IconFile, game:HttpGet(Config.IconUrl))
        end
        return getcustomasset(Config.IconFile)
    end)
    return ok and asset or Config.IconFallback
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Version = "1.1.0"
local GameName = "Tap Simulator Reborn"
local News = {
    { Title = "v1.1.0", Date = "2026-10-26", Text = "+ Everything is back: Activities tab with Pet Defense, Memory Match, Dig, Mining, Hallow Lord, Trick-or-Treat, Candy Witch, Blood Moon, Halloween Shop and Fusion Eggs\n+ Enchanting, Auto Index, Golden Mastery and Mastery Relic are back\n+ Island Mobs, Lucky Ducky, Shrine, Balloon Party and the Honey Pot are back\n/ Auto Click always taps with the hub's own clicker; the game auto clicker is left alone\n/ Minigames, enchanting, index, mining, seasonal and wild events moved into this release" },
    { Title = "v1.0.0", Date = "2026-10-25", Text = "+ First Lumin release: tap loop, hatching, rebirth, buys, claims, crafting, boosts, potions, totems, unlocks, ESP, webhook\n+ Every groupbox carries its own tabbox" },
}

-- Re-executing takes the previous copy down through its own unload hook.
do
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.LuminTapSimRebornUnload) == "function" then
        pcall(env.LuminTapSimRebornUnload)
    end
    env.LuminTapSimRebornUnload = function()
        if not Library.Unloaded then
            pcall(Library.Unload, Library)
        end
    end
end

-- Spy-tool guard: refuse to run alongside remote spies.
do
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local kicked = false
    local function foundSpy()
        for flag in pairs({ IY_LOADED = true, SimpleSpyExecuted = true }) do
            local ok, v = pcall(rawget, env, flag)
            if ok and v ~= nil and v ~= false then
                return true
            end
        end
        local holders = {}
        pcall(function()
            table.insert(holders, game:GetService("CoreGui"))
        end)
        pcall(function()
            local hidden = type(gethui) == "function" and gethui()
            if typeof(hidden) == "Instance" then
                table.insert(holders, hidden)
            end
        end)
        for _, holder in holders do
            local ok, kids = pcall(holder.GetChildren, holder)
            for _, kid in (ok and kids or {}) do
                for _, name in { "RemoteSpy", "SimpleSpy", "Cobalt" } do
                    if kid.Name:sub(1, #name) == name then
                        return true
                    end
                end
            end
        end
        return false
    end
    local function kick()
        if kicked then
            return
        end
        kicked = true
        pcall(function()
            LocalPlayer:Kick("no")
        end)
    end
    if foundSpy() then
        kick()
    end
    task.spawn(function()
        while not kicked and not Library.Unloaded do
            task.wait(3)
            if foundSpy() then
                kick()
            end
        end
    end)
end

local Util = {}

function Util.AsIdentity(level)
    if type(setthreadidentity) == "function" then
        pcall(setthreadidentity, level)
    end
end

function Util.Num(value, fallback)
    local n = tonumber(value)
    if n == nil or n ~= n then
        return fallback or 0
    end
    return n
end

Util.Units = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
function Util.Short(value)
    value = Util.Num(value, 0)
    if value == math.huge then
        return "inf"
    end
    local idx = 1
    while math.abs(value) >= 1000 and idx < #Util.Units do
        value /= 1000
        idx += 1
    end
    if math.abs(value) >= 1000 then
        return ("%.2e"):format(value)
    end
    local text = ("%.2f"):format(value):gsub("%.?0+$", "")
    if text == "" or text == "-0" then
        text = "0"
    end
    return text .. Util.Units[idx]
end

function Util.Commas(value)
    local text = tostring(math.floor(Util.Num(value, 0)))
    local out
    repeat
        text, out = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until out == 0
    return text
end

local suffixMult = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, qi = 1e18, sx = 1e21, sp = 1e24, oc = 1e27, no = 1e30, dc = 1e33 }
function Util.Amount(text)
    local clean = tostring(text or ""):lower():gsub("[%s,%$_]", "")
    if clean == "" then
        return 0
    end
    local plain = tonumber(clean)
    if plain then
        return math.max(0, plain)
    end
    local digits, suffix = clean:match("^(%d*%.?%d+)(%a+)$")
    if digits and suffixMult[suffix] then
        return math.max(0, tonumber(digits) * suffixMult[suffix])
    end
    return 0
end

function Util.Clock(seconds)
    seconds = math.max(0, math.floor(Util.Num(seconds, 0)))
    if seconds >= 3600 then
        return ("%dh %02dm"):format(math.floor(seconds / 3600), math.floor(seconds % 3600 / 60))
    elseif seconds >= 60 then
        return ("%dm %02ds"):format(math.floor(seconds / 60), seconds % 60)
    end
    return ("%ds"):format(seconds)
end

function Util.Path(parent, ...)
    local node = parent
    for _, name in { ... } do
        if not node then
            return nil
        end
        node = node:FindFirstChild(name)
    end
    return node
end

function Util.Count(value)
    if type(value) ~= "table" then
        return 0
    end
    local n = 0
    for _ in value do
        n += 1
    end
    return n
end

function Util.Require(node, timeout)
    if not node or not node:IsA("ModuleScript") then
        return nil
    end
    timeout = timeout or 5
    local done, result = false, nil
    task.spawn(function()
        Util.AsIdentity(2)
        local ok, value = pcall(require, node)
        result = ok and value or nil
        done = true
    end)
    local deadline = os.clock() + timeout
    while not done and os.clock() < deadline and not Library.Unloaded do
        task.wait(0.05)
    end
    return done and result or nil
end

function Util.Call(fn, ...)
    if type(fn) ~= "function" then
        return nil
    end
    local packed = table.pack(pcall(fn, ...))
    if not packed[1] then
        return nil
    end
    return table.unpack(packed, 2, packed.n)
end

-- Two shapes live in this game and they are not interchangeable.
--
-- Controllers are real methods: Controller:ClearAuto(), so they take the object.
-- The Shared config modules are plain dot-functions: RebirthConfig.GetPrice(amount,
-- rebirths, save) declares no self. Calling one of those through Util.Method shifts
-- every argument along by one -- amount receives the module table, rebirths receives
-- the amount -- so it errors, the pcall swallows it, and the caller reads nil. For a
-- price that is Util.Num(nil, math.huge), which is why Auto Rebirth sat on
-- "saving for slot 1: inf" while the game offered the same rebirth for 600.
--
-- Util.Method for controllers, Util.Fn for config modules.
function Util.Method(obj, name, ...)
    if type(obj) ~= "table" or type(obj[name]) ~= "function" then
        return nil
    end
    return Util.Call(obj[name], obj, ...)
end

function Util.Fn(obj, name, ...)
    if type(obj) ~= "table" or type(obj[name]) ~= "function" then
        return nil
    end
    return Util.Call(obj[name], ...)
end

function Util.Timed(timeout, fn, ...)
    if type(fn) ~= "function" then
        return nil, "missing"
    end
    timeout = timeout or 10
    local args = table.pack(...)
    local done, packed, failed = false, nil, nil
    local thread = task.spawn(function()
        Util.AsIdentity(2)
        local res = table.pack(pcall(fn, table.unpack(args, 1, args.n)))
        if res[1] then
            packed = res
        else
            failed = res[2]
        end
        done = true
    end)
    local deadline = os.clock() + timeout
    while not done and os.clock() < deadline and not Library.Unloaded do
        task.wait(0.05)
    end
    if not done then
        pcall(task.cancel, thread)
        return nil, "timeout"
    end
    if failed ~= nil then
        return nil, tostring(failed)
    end
    return table.unpack(packed, 2, packed.n)
end

-- Multi-dropdown value as a set; nil means "nothing picked".
function Util.PickSet(flag)
    local value = Library.Flags[flag]
    if type(value) ~= "table" then
        if type(value) == "string" and value ~= "" then
            return { [value] = true }
        end
        return nil
    end
    local set, any = {}, false
    for key, on in value do
        if on == true and type(key) == "string" then
            set[key] = true
            any = true
        elseif type(key) == "number" and type(on) == "string" then
            set[on] = true
            any = true
        end
    end
    return any and set or nil
end

function Util.Picks(flag)
    return Util.PickSet(flag) or {}
end

function Util.Http()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local send = rawget(env, "request") or rawget(env, "http_request")
    if type(send) ~= "function" then
        for _, name in { "syn", "fluxus" } do
            local holder = rawget(env, name)
            if type(holder) == "table" and type(holder.request) == "function" then
                send = holder.request
                break
            end
        end
    end
    if type(send) ~= "function" then
        local http = rawget(env, "http")
        if type(http) == "table" then
            send = http.request
        end
    end
    return type(send) == "function" and send or nil
end

local State = {
    Note = "loading",
    Log = {},
    Taps = 0,
    Hatched = 0,
    Secrets = 0,
    Rebirthed = 0,
    Bought = 0,
    Claimed = 0,
    Crafted = 0,
    Deleted = 0,
    Ducks = 0,
    Played = 0,
    Chests = 0,
    ChestCoins = 0,
    StartedAt = os.clock(),
    StartCoins = nil,
}

local function Note(text)
    text = tostring(text or "")
    State.Note = text
    if text ~= "" then
        table.insert(State.Log, 1, os.date("%H:%M:%S") .. "  " .. text)
        while #State.Log > 6 do
            table.remove(State.Log)
        end
    end
end


-- Forward declarations for the feature modules defined below.
local PaintLink, FrameLink
local Game, Sched, Mover, Bg, Need, Brain, Watch, Lists, Auto
local World, Arena, Memory, Dig, Mine, Hallow
local Tap, Brk, Eggs, Rebirth, Shop, Claims, Pets, Craft, Enchant, Items, Events, Mobs
local Webhook, Boost, Esp, Popup


--== Network, save data, game modules ==--

local Net = { Objects = {}, Sent = 0, Comm = nil, Root = nil }

function Net.Service(name)
    if Net.Objects[name] then
        return Net.Objects[name]
    end
    if not Net.Comm or not Net.Root then
        return nil
    end
    local ok, obj = pcall(function()
        return Net.Comm.new(Net.Root, false, name):BuildObject()
    end)
    if ok and type(obj) == "table" then
        Net.Objects[name] = obj
        return obj
    end
    return nil
end

function Net.Fire(service, event, ...)
    local obj = Net.Service(service)
    local signal = obj and obj[event]
    if type(signal) ~= "table" or type(signal.Fire) ~= "function" then
        return false
    end
    local ok = pcall(signal.Fire, signal, ...)
    if ok then
        Net.Sent += 1
    end
    return ok
end

function Net.Invoke(service, name, ...)
    local obj = Net.Service(service)
    local fn = obj and obj[name]
    if type(fn) ~= "function" then
        return nil, "missing"
    end
    Net.Sent += 1
    return Util.Timed(12, fn, obj, ...)
end

function Net.On(service, event, callback)
    local obj = Net.Service(service)
    local signal = obj and obj[event]
    if type(signal) ~= "table" or type(signal.Connect) ~= "function" then
        return nil
    end
    local ok, link = pcall(signal.Connect, signal, function(...)
        if not Library.Unloaded then
            pcall(callback, ...)
        end
    end)
    return ok and link or nil
end

-- A service reply counts as yes only when it says so.
function Net.Why(result)
    if result == true then
        return true, nil
    end
    if type(result) ~= "table" then
        return false, "no answer"
    end
    if result.Success == true then
        return true, nil
    end
    return false, tostring(result.Reason or result.Error or result.Message or "refused")
end

local Data = { Replica = nil, Save = nil, Listeners = {} }

function Data.Load()
    local controller = Game.C.DataController
    if not controller then
        return
    end
    local replica = Util.Timed(25, controller.GetReplica, controller)
    if type(replica) == "table" and type(replica.Data) == "table" then
        Data.Replica = replica
        Data.Save = replica.Data
    end
end

function Data.Coins()
    return Data.Save and Util.Num(Data.Save.Currencies and Data.Save.Currencies.Coins, 0) or 0
end

function Data.Gems()
    return Data.Save and Util.Num(Data.Save.Currencies and Data.Save.Currencies.Gems, 0) or 0
end

function Data.Rebirths()
    return Data.Save and Util.Num(Data.Save.Statistics and Data.Save.Statistics.Rebirths, 0) or 0
end

function Data.Stat(name)
    return Data.Save and Util.Num(Data.Save.Statistics and Data.Save.Statistics[name], 0) or 0
end

function Data.Islands()
    local save = Data.Save
    return (save and type(save.Progression) == "table" and type(save.Progression.UnlockedIslands) == "table")
        and save.Progression.UnlockedIslands or {}
end

function Data.Zones()
    local save = Data.Save
    return (save and type(save.Progression) == "table" and type(save.Progression.UnlockedZones) == "table")
        and save.Progression.UnlockedZones or {}
end

function Data.Island()
    local attr = LocalPlayer:GetAttribute("CurrentIsland")
    if type(attr) == "string" then
        return attr
    end
    local save = Data.Save
    return tostring((save and save.Progression and save.Progression.Island) or "Spawn")
end

function Data.Watch(keys, callback)
    for _, key in keys do
        Data.Listeners[key] = Data.Listeners[key] or {}
        table.insert(Data.Listeners[key], callback)
    end
end

Game = { Ready = false, C = {}, M = {}, Folder = {} }

local controllerFolders = {
    Core = { "DataController" },
    Game = { "TapController", "RebirthController", "UpgradeController", "SkillTreeController", "PhysicalUpgradeController", "DoubleJumpShopController", "OfflineRewardsController", "ShrineController", "GiveawayController", "IslandController" },
    Pets = { "EggController", "MachineController", "InventoryController" },
    Quests = { "QuestController" },
    Items = { "GiftController", "BoostController", "EventWheelController", "PotionUIController", "HoneyPotController" },
    Minigames = { "DigController", "MemoryMatchController" },
    UI = { "MessageController", "RewardPopupController", "SettingsController", "MenuController" },
}

local configFolders = {
    Minigames = { "DigConfig" },
    Monetization = { "GamepassPerks" },
    Items = { "BoostFormula", "ItemCatalog", "PotionBrewConfig", "BoostConfig", "PotionCraftConfig", "HoneyPotConfig", "HalloweenShopConfig", "TotemConfig" },
    Pets = { "LaunchEggConfig", "PetVisualConfig", "EggPricing", "PetIndexCatalog", "EnchantConfig", "EnchantSpins", "PetOdds", "LaunchPetConfig" },
    Quests = { "QuestConfig", "NpcQuestConfig" },
    Game = { "ShrineConfig", "IslandBreakableConfig", "HallowBossConfig" },
    Progression = { "UpgradeConfig", "SkillTreeFormula", "OnboardingFlow", "RebirthConfig", "IslandLandings", "RebirthButtonConfig", "PhysicalUpgradeConfig", "DoubleJumpConfig", "IslandConfig", "ProgressionConfig", "OnboardingConfig" },
}
for folder, names in configFolders do
    for _, name in names do
        Game.Folder[name] = folder
    end
end

function Game.Module(name)
    local cached = Game.M[name]
    if cached ~= nil then
        return cached or nil
    end
    local folder = Game.Folder[name]
    local node = folder and Util.Path(ReplicatedStorage, "Shared", folder, name) or nil
    local mod = Util.Require(node, 6)
    Game.M[name] = type(mod) == "table" and mod or false
    return Game.M[name] or nil
end

function Game.Load()
    local controllers = ReplicatedStorage:WaitForChild("Controllers", 25)
    local shared = ReplicatedStorage:WaitForChild("Shared", 20)
    if not controllers or not shared then
        Note("the game never finished loading")
        return false
    end
    for folderName, names in controllerFolders do
        local folder = controllers:FindFirstChild(folderName)
        if folder then
            for _, name in names do
                local child = folder:FindFirstChild(name)
                local mod = child and Util.Require(child, 6)
                if type(mod) == "table" then
                    Game.C[name] = mod
                end
            end
        end
    end
    for name in Game.Folder do
        Game.Module(name)
    end
    local comm = Util.Require(Util.Path(ReplicatedStorage, "Packages", "Comm"), 6)
    if type(comm) == "table" then
        Net.Comm = comm.ClientComm
    end
    Net.Root = ReplicatedStorage:FindFirstChild("RemoteServices")
    Data.Load()
    Game.Ready = Data.Replica ~= nil and Net.Comm ~= nil
    if not Game.Ready then
        Note("the save never loaded")
    end
    return Game.Ready
end

--== Character and movement ==--

local Char = { HopAt = 0, Points = {}, Arrived = Instance.new("BindableEvent") }
Char.HOMES = { Golden = "Crystal Cave", Diamond = "Crystal Cave", Rainbow = "Shadow Realm", Enchant = "Shadow Realm", Fusion = "Volcano" }

function Char.Parts()
    local character = LocalPlayer.Character
    if not character then
        return nil, nil, nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, root
end

function Char.Root()
    local _, _, root = Char.Parts()
    return root
end

function Char.Distance(target)
    local root = Char.Root()
    local pos = typeof(target) == "CFrame" and target.Position or target
    if not root or typeof(pos) ~= "Vector3" then
        return math.huge
    end
    return (pos - root.Position).Magnitude
end

function Char.Flat(target)
    local root = Char.Root()
    local pos = typeof(target) == "CFrame" and target.Position or target
    if not root or typeof(pos) ~= "Vector3" then
        return math.huge
    end
    local delta = pos - root.Position
    return Vector3.new(delta.X, 0, delta.Z).Magnitude
end

function Char.Blocked()
    if Arena.Active or LocalPlayer:GetAttribute("ColosseumActive") then
        return "pet defense"
    end
    if LocalPlayer:GetAttribute("MiningActive") then
        return "mining"
    end
    if LocalPlayer:GetAttribute("AtDigsite") or LocalPlayer:GetAttribute("DiggingActive") then
        return "digging"
    end
    local flow = Game.Module("OnboardingFlow")
    if flow and Util.Fn(flow, "IsPending", Data.Save) == true then
        return "tutorial"
    end
    return ""
end

-- The one teleport primitive. Everything that moves the character goes here.
function Char.Hop(target)
    local character, humanoid, root = Char.Parts()
    if not character or not root or (humanoid and humanoid.Health <= 0) then
        return false
    end
    local goal = typeof(target) == "CFrame" and target or CFrame.new(target + Vector3.new(0, 3, 0))
    local waitFor = 0.25 - (os.clock() - Char.HopAt)
    if waitFor > 0 then
        task.wait(waitFor)
    end
    Char.HopAt = os.clock()
    local ok = pcall(function()
        character:PivotTo(goal)
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)
    return ok
end

function Char.Go(target, radius, stand)
    radius = radius or 8
    if Char.Distance(target) <= radius then
        return true
    end
    if not Char.Hop(stand or target) then
        return false
    end
    task.wait(0.15)
    return Char.Distance(target) <= radius + 2
end

-- A stand point beside a target, on the ground, facing it.
function Char.Beside(target, gap, ignore)
    local root = Char.Root()
    local pos = typeof(target) == "CFrame" and target.Position or target
    if typeof(pos) ~= "Vector3" then
        return CFrame.new()
    end
    local dir = root and (root.Position - pos) or Vector3.new(0, 0, 1)
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.1 then
        dir = Vector3.new(0, 0, 1)
    end
    local spot = pos + dir.Unit * (gap or 4)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excluded = {}
    if LocalPlayer.Character then
        table.insert(excluded, LocalPlayer.Character)
    end
    for _, inst in (ignore or {}) do
        table.insert(excluded, inst)
    end
    params.FilterDescendantsInstances = excluded
    local hit = Workspace:Raycast(spot + Vector3.new(0, 10, 0), Vector3.new(0, -40, 0), params)
    local ground = hit and hit.Position or spot
    return CFrame.lookAt(ground + Vector3.new(0, 3, 0), Vector3.new(pos.X, ground.Y + 3, pos.Z))
end

function Char.Point(name)
    local best, bestDist = nil, math.huge
    for inst in Char.Points do
        if inst.Name == name and inst:IsA("BasePart") and inst.Parent then
            local dist = Char.Distance(inst.Position)
            if dist < bestDist then
                best, bestDist = inst, dist
            end
        end
    end
    return best
end

function Char.CanReach(name)
    if Char.Point(name) then
        return true
    end
    local home = Char.HOMES[name]
    return home ~= nil and Data.Islands()[home] == true
end

function Char.Reach(name)
    local point = Char.Point(name)
    if point then
        return point
    end
    local home = Char.HOMES[name]
    if not home or Data.Islands()[home] ~= true then
        return nil
    end
    if Data.Island() ~= home then
        World.Travel(home)
    end
    local fired = false
    local link = Char.Arrived.Event:Connect(function()
        fired = true
    end)
    local deadline = os.clock() + 8
    while not fired and os.clock() < deadline and not Library.Unloaded do
        if Char.Point(name) then
            break
        end
        task.wait(0.1)
    end
    link:Disconnect()
    return Char.Point(name)
end

local Move = { Base = 16, Applying = false, Wrote = nil, Links = {} }

function Move.Humanoid()
    local _, humanoid = Char.Parts()
    return humanoid
end

function Move.ApplySpeed()
    local humanoid = Move.Humanoid()
    if not humanoid then
        return
    end
    local wanted = (Library.Flags.WalkSpeedOn == true and not Library.Unloaded)
        and math.max(Util.Num(Library.Flags.WalkSpeed, 16), 1) or Move.Base
    if humanoid.WalkSpeed == wanted then
        return
    end
    Move.Applying = true
    Move.Wrote = wanted
    pcall(function()
        humanoid.WalkSpeed = wanted
    end)
    Move.Applying = false
end

function Move.Bind(character)
    for _, link in Move.Links do
        pcall(link.Disconnect, link)
    end
    table.clear(Move.Links)
    if not character then
        return
    end
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then
        return
    end
    Move.Base = humanoid.WalkSpeed
    table.insert(Move.Links, humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if Move.Applying or humanoid.WalkSpeed == Move.Wrote then
            return
        end
        Move.Base = humanoid.WalkSpeed
        Move.ApplySpeed()
    end))
    Move.ApplySpeed()
end

function Move.Start()
    table.insert(Move.Links, LocalPlayer.CharacterAdded:Connect(function(character)
        task.spawn(Move.Bind, character)
    end))
    table.insert(Move.Links, game:GetService("UserInputService").JumpRequest:Connect(function()
        if Library.Flags.InfiniteJump ~= true or Library.Unloaded then
            return
        end
        local humanoid = Move.Humanoid()
        if humanoid then
            pcall(humanoid.ChangeState, humanoid, Enum.HumanoidStateType.Jumping)
        end
    end))
    if LocalPlayer.Character then
        task.spawn(Move.Bind, LocalPlayer.Character)
    end
end

function Move.Stop()
    for _, link in Move.Links do
        pcall(link.Disconnect, link)
    end
    table.clear(Move.Links)
    local humanoid = Move.Humanoid()
    if humanoid then
        Move.Applying = true
        pcall(function()
            humanoid.WalkSpeed = Move.Base
        end)
        Move.Applying = false
    end
end

--== Session, servers, anti-AFK ==--

local Session = { Rejoining = false, Watching = false, Note = nil, OnLeave = nil }

local function queueLoaderSource()
    return ('loadstring(game:HttpGet("%s"))()'):format(Config.LoaderUrl)
end

function Session.QueueLoader(notify)
    if Library.Flags.AutoExecute ~= true then
        return false
    end
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local record = rawget(env, "LuminTapSimRebornQueued")
    if type(record) ~= "table" then
        record = {}
        env.LuminTapSimRebornQueued = record
    end
    if record.Done then
        if notify then
            Toast({ Title = "Auto Execute", Description = "the hub will load again after a teleport", Type = "success" })
        end
        return true
    end
    local queuer = rawget(env, "queue_on_teleport") or rawget(env, "queueonteleport")
    if type(queuer) ~= "function" then
        for _, name in { "syn", "fluxus" } do
            local holder = rawget(env, name)
            if type(holder) == "table" and type(holder.queue_on_teleport) == "function" then
                queuer = holder.queue_on_teleport
                break
            end
        end
    end
    if type(queuer) ~= "function" then
        if notify then
            Toast({ Title = "Auto Execute", Description = "this executor has no queue_on_teleport", Type = "warning" })
        end
        return false
    end
    local ok = pcall(queuer, queueLoaderSource())
    if ok then
        record.Done = true
        if notify then
            Toast({ Title = "Auto Execute", Description = "the hub will load again after a teleport", Type = "success" })
        end
    end
    return ok
end

local function isKickMessage(text)
    text = tostring(text or ""):lower()
    if text == "" or text:find("teleport", 1, true) then
        return false
    end
    for _, needle in { "kicked", "disconnected", "lost connection", "suspicious activity", "error code: 267", "shut down" } do
        if text:find(needle, 1, true) then
            return true
        end
    end
    return false
end

function Session.Rejoin()
    if Session.Rejoining then
        return
    end
    Session.Rejoining = true
    Session.Note = "kicked, rejoining"
    if Session.OnLeave then
        pcall(Session.OnLeave)
    end
    task.spawn(function()
        task.wait(0.35)
        while Session.Rejoining and not Library.Unloaded do
            Session.QueueLoader(false)
            pcall(TeleportService.Teleport, TeleportService, game.PlaceId, LocalPlayer)
            task.wait(2)
        end
    end)
end

function Session.OnError()
    if Library.Flags.AutoReconnect ~= true or Session.Rejoining then
        return
    end
    local ok, message = pcall(function()
        return game:GetService("GuiService"):GetErrorMessage()
    end)
    if ok and isKickMessage(message) then
        Session.Rejoin()
    end
end

function Session.Watch()
    Session.Watching = true
    Session.OnError()
end

function Session.OnExecute(value)
    if value then
        Session.QueueLoader(true)
    end
end

function Session.OnReconnect(value)
    if value then
        Session.Watch()
    end
end

local Server = { JoinTarget = "" }

function Server.Join()
    if Server.JoinTarget == "" then
        Toast({ Title = "Server", Description = "paste a Job ID first", Type = "warning" })
        return
    end
    if Server.JoinTarget == tostring(game.JobId) then
        Toast({ Title = "Server", Description = "you are already in that server", Type = "warning" })
        return
    end
    Session.QueueLoader(false)
    local ok, err = pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, Server.JoinTarget, LocalPlayer)
    Toast({ Title = "Server", Description = ok and ("joining " .. Server.JoinTarget:sub(1, 8) .. "...") or ("teleport failed: " .. tostring(err)), Type = ok and "success" or "warning" })
end

function Server.Rejoin()
    Session.QueueLoader(false)
    pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, tostring(game.JobId), LocalPlayer)
end

function Server.OnJobId(value)
    Server.JoinTarget = tostring(value or ""):gsub("%s+", "")
end

function Server.CopyJobId()
    local clip = rawget((type(getgenv) == "function" and getgenv()) or _G, "setclipboard") or (type(setclipboard) == "function" and setclipboard)
    if type(clip) == "function" and pcall(clip, tostring(game.JobId)) then
        Toast({ Title = "Server", Description = "Job ID copied", Type = "success" })
    else
        Toast({ Title = "Server", Description = "this executor has no clipboard", Type = "warning" })
    end
end

function Server.HopRun()
    Util.AsIdentity(2)
    local http = Util.Http()
    local found = nil
    if http then
        local ok, response = pcall(http, { Url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId), Method = "GET" })
        if ok and type(response) == "table" and type(response.Body) == "string" then
            local decoded = Util.Call(HttpService.JSONDecode, HttpService, response.Body)
            if type(decoded) == "table" and type(decoded.data) == "table" then
                for _, entry in decoded.data do
                    if entry.id ~= game.JobId and Util.Num(entry.playing, 0) < Util.Num(entry.maxPlayers, 0) then
                        found = entry.id
                        break
                    end
                end
            end
        end
    end
    if not found then
        Toast({ Title = "Server", Description = "no other server found", Type = "warning" })
        return
    end
    Session.QueueLoader(false)
    pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, found, LocalPlayer)
end

function Server.Hop()
    task.spawn(Server.HopRun)
end

local AntiAfk = { Connection = nil }

function AntiAfk.Pulse()
    pcall(function()
        VirtualUser:CaptureController()
        local camera = Workspace.CurrentCamera
        local frame = camera and camera.CFrame or CFrame.new()
        VirtualUser:Button2Down(Vector2.new(0, 0), frame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0, 0), frame)
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
    local humanoid = Move.Humanoid()
    if humanoid then
        pcall(function()
            humanoid.Jump = true
        end)
    end
end

function AntiAfk.Bind()
    if AntiAfk.Connection and AntiAfk.Connection.Connected then
        return
    end
    AntiAfk.Connection = LocalPlayer.Idled:Connect(function()
        if Library.Flags.AntiAfk ~= false then
            AntiAfk.Pulse()
        end
    end)
end
AntiAfk.Bind()


--== Tapping, world chests, hatching, rebirths ==--

Tap = { Kick = Instance.new("BindableEvent"), Gap = 0.115, Blocked = "", LastArm = 0 }

function Tap.On()
    return Library.Flags.AutoTap == true and Game.Ready
end

function Tap.Once()
    local controller = Game.C.TapController
    if not controller then
        return
    end
    if pcall(controller.Tap, controller) then
        State.Taps += 1
    end
end

function Tap.Loop()
    Util.AsIdentity(2)
    while not Library.Unloaded do
        if Tap.On() then
            Tap.Blocked = Char.Blocked()
            if Tap.Blocked == "" then
                local started = os.clock()
                Tap.Once()
                local spent = os.clock() - started
                if spent < Tap.Gap then
                    task.wait(Tap.Gap - spent)
                end
            else
                task.wait(0.25)
            end
        else
            Tap.Blocked = ""
            Tap.Kick.Event:Wait()
        end
    end
end


Brk = { Live = {}, Target = nil, Note = "" }

function Brk.Add(model)
    Brk.Live[model] = true
    if Mobs then
        Mobs.Arrived:Fire()
    end
    Mover:Wake("move")
end

function Brk.Remove(model)
    Brk.Live[model] = nil
end

function Brk.Usable(model)
    if typeof(model) ~= "Instance" or not model.Parent then
        return false
    end
    if model:GetAttribute("BreakableBroken") == true then
        return false
    end
    if Util.Num(model:GetAttribute("BreakableHealth"), 1) <= 0 then
        return false
    end
    local owner = model:GetAttribute("BreakableOwner")
    return owner == nil or owner == 0 or owner == LocalPlayer.UserId
end

function Brk.Spot(model)
    local rest = model:GetAttribute("BreakableRest")
    if typeof(rest) == "CFrame" then
        return rest.Position
    end
    return model:GetPivot().Position
end

-- Keep chests on the island band we are standing on; higher bands belong to
-- islands the tap chain cannot pay out from yet.
function Brk.Band()
    local landings = Game.Module("IslandLandings") or {}
    local entry = landings[Data.Island()]
    local low = entry and entry.Position and entry.Position.Y - 60 or -560
    local high = math.huge
    for _, other in landings do
        if other.From and other.From.Y > low + 100 then
            high = math.min(high, other.From.Y - 10)
        end
    end
    return low, high
end

function Brk.Pick()
    local low, high = Brk.Band()
    local best, bestDist = nil, math.huge
    for model in Brk.Live do
        if not model.Parent then
            Brk.Live[model] = nil
        elseif Brk.Usable(model) then
            local spot = Brk.Spot(model)
            if spot.Y >= low and spot.Y <= high then
                local dist = Char.Distance(spot)
                if dist < bestDist then
                    best, bestDist = model, dist
                end
            end
        end
    end
    return best
end

function Brk.On()
    return Library.Flags.AutoChests == true
end

function Brk.Break(model)
    Brk.Target = model
    local spot = Brk.Spot(model)
    local size = model:GetAttribute("BreakableSize")
    local half = typeof(size) == "Vector3" and math.max(size.X, size.Z) / 2 or 5
    if Char.Flat(spot) > half + 10 or math.abs(spot.Y - (Char.Root() and Char.Root().Position.Y or spot.Y)) > 10 then
        Char.Hop(Char.Beside(spot, half + 4, { model }))
        task.wait(0.2)
    end
    local started = os.clock()
    while Brk.On() and not Library.Unloaded and Brk.Usable(model) and os.clock() - started < 6 do
        local blocked = Char.Blocked()
        if blocked ~= "" then
            Brk.Note = "paused (" .. blocked .. ")"
            Brk.Target = nil
            return false
        end
        if Tap.On() then
            task.wait(0.1)
        else
            Tap.Once()
            task.wait(Tap.Gap)
        end
    end
    Brk.Target = nil
    if not Brk.Usable(model) then
        State.Chests += 1
        return true
    end
    return false
end

Eggs = { AUTO = "Best Affordable", Note = "", Recent = {}, Hidden = nil, Holds = 0 }

function Eggs.Config(name)
    local config = Game.Module("LaunchEggConfig")
    return config and config[name] or nil
end

function Eggs.Names()
    local config = Game.Module("LaunchEggConfig") or {}
    local names = {}
    for name, entry in config do
        if type(entry) == "table" and Util.Num(entry.Price, 0) > 0 then
            table.insert(names, name)
        end
    end
    table.sort(names, function(a, b)
        return config[a].Price < config[b].Price
    end)
    return names
end

function Eggs.Open(name)
    if name == "Basic" then
        return true
    end
    local entry = Eggs.Config(name)
    if not entry then
        return false
    end
    local save = Data.Save
    if save and save.Eggs and save.Eggs.Unlocked and save.Eggs.Unlocked[name] == true then
        return true
    end
    if entry.Island and Data.Islands()[entry.Island] ~= true then
        return false
    end
    if entry.Zone and entry.Zone ~= "Spawn" and Data.Zones()[entry.Zone] ~= true then
        return false
    end
    return save ~= nil and save.Eggs ~= nil and save.Eggs.Unlocked ~= nil and save.Eggs.Unlocked[name] == true
end

function Eggs.Price(name, count)
    local entry = Eggs.Config(name)
    if not entry then
        return math.huge
    end
    local pricing = Game.Module("EggPricing")
    if pricing then
        if count and count > 1 then
            local total = Util.Fn(pricing, "GetTotal", Data.Save, name, entry.Price, count)
            if total then
                return Util.Num(total, entry.Price * count)
            end
        end
        local unit = Util.Fn(pricing, "GetUnitPrice", Data.Save, name, entry.Price)
        if unit then
            return Util.Num(unit, entry.Price) * (count or 1)
        end
    end
    return entry.Price * (count or 1)
end

function Eggs.Secrets(name)
    local entry = Eggs.Config(name)
    return entry and type(entry.Secrets) == "table" and #entry.Secrets or 0
end

function Eggs.Best()
    local coins, best, cheapest = Data.Coins(), nil, nil
    for _, name in Eggs.Names() do
        if Eggs.Open(name) then
            cheapest = cheapest or name
            if Eggs.Price(name, 1) <= coins then
                best = name
            end
        end
    end
    return best or cheapest
end

function Eggs.Pick()
    local indexed = Pets.IndexEgg()
    if indexed then
        return indexed
    end
    local want = tostring(Library.Flags.HatchEgg or Eggs.AUTO)
    if want == Eggs.AUTO or want == "" then
        return Eggs.Best()
    end
    return Eggs.Config(want) and want or nil
end

function Eggs.Model(name)
    local folder = Workspace:FindFirstChild("Eggs")
    return folder and folder:FindFirstChild(name) or nil
end

function Eggs.Part(model)
    if not model then
        return nil
    end
    local part = model:FindFirstChild("Egg")
    if part and part:IsA("BasePart") then
        return part
    end
    if model:IsA("Model") and model.PrimaryPart then
        return model.PrimaryPart
    end
    return nil
end

function Eggs.Running()
    local controller = Game.C.EggController
    return controller and Util.Method(controller, "GetAutoHatchEgg") or nil
end

function Eggs.Toggle(name)
    local controller = Game.C.EggController
    if controller then
        Util.Method(controller, "ToggleAutoHatch", name)
    end
end

function Eggs.Stop()
    local running = Eggs.Running()
    if running then
        Eggs.Toggle(running)
    end
end

function Eggs.Slots()
    local want = Eggs.Pick()
    if not want then
        return 1
    end
    local perks = Game.Module("GamepassPerks")
    local boosts = Game.Module("BoostFormula")
    local octo = (perks and Util.Fn(perks, "Has", Data.Save, "x8Egg") == true)
        or (boosts and Util.Fn(boosts, "HasType", Data.Save, "OctoHatch") == true)
    local coins = Data.Coins()
    if octo and coins >= Eggs.Price(want, 8) then
        return 8
    end
    if coins >= Eggs.Price(want, 3) then
        return 3
    end
    return 1
end

function Eggs.Full()
    local count, limit = Pets.Count()
    return count + Eggs.Slots() > limit, count, limit
end

function Eggs.On()
    return Library.Flags.AutoHatch == true
end

function Eggs.CanRun()
    if not Eggs.On() or World.Saving() then
        return false
    end
    if Eggs.Full() then
        return false
    end
    local want = Eggs.Pick()
    if not want or not Eggs.Open(want) then
        return false
    end
    return Eggs.Running() == want or Data.Coins() >= Eggs.Price(want, 3)
end

function Eggs.Step()
    local savingFor, goal = World.Saving()
    if savingFor then
        Eggs.Stop()
        Eggs.Note = "saving coins for " .. savingFor
        Need.Set("move", "Coins", goal)
        return false
    end
    local want = Eggs.Pick()
    if not want then
        Eggs.Note = "no egg picked"
        return false
    end
    if not Eggs.Open(want) then
        Eggs.Note = want .. " is locked"
        return false
    end
    local entry = Eggs.Config(want)
    local island = entry.Island or "Spawn"
    if Data.Island() ~= island and Data.Islands()[island] == true or (island == "Spawn" and Data.Island() ~= "Spawn" and not entry.Island) then
        World.Travel(island)
        return true
    end
    if entry.Island and Data.Island() ~= entry.Island then
        World.Travel(entry.Island)
        return true
    end
    local model = Eggs.Model(want)
    local part = Eggs.Part(model)
    if not part then
        Eggs.Note = "waiting for " .. want .. " to stream in"
        Mover:Later("move", 3)
        return false
    end
    if Char.Distance(part.Position) > 13 then
        Char.Hop(Char.Beside(part.Position, 4, { model }))
        task.wait(0.2)
    end
    if Eggs.Full() then
        Eggs.Stop()
        local count, limit = Pets.Count()
        Eggs.Note = ("storage full (%d/%d)"):format(count, limit)
        return false
    end
    local running = Eggs.Running()
    if running == want then
        Eggs.Note = "hatching " .. want
        return false
    end
    if running then
        Eggs.Toggle(running)
        task.wait(0.1)
    end
    if Data.Coins() < Eggs.Price(want, 3) then
        Eggs.Note = "saving for " .. want
        Need.Set("move", "Coins", Eggs.Price(want, 3))
        return false
    end
    Eggs.Toggle(want)
    Eggs.Note = Eggs.Running() == want and ("hatching " .. want) or "starting " .. want
    Bg:Wake("boosts", 0.5)
    return true
end

function Eggs.OnResult(result)
    if type(result) ~= "table" or result.Success ~= true then
        if Eggs.On() then
            Mover:Wake("move", 0.5)
        end
        return
    end
    for _, pet in (type(result.Pets) == "table" and result.Pets or {}) do
        State.Hatched += 1
        local rarity = tostring(pet.Rarity or "")
        local tier = Pets.TierName(pet.Tier)
        if rarity:match("^Secret") then
            State.Secrets += 1
        end
        if rarity:match("^Secret") or tier ~= "Normal" or rarity == "Legendary" or rarity == "Mythical" or rarity == "Mythic" then
            table.insert(Eggs.Recent, 1, { os.date("%H:%M"), tostring(pet.Name or "?"), rarity:match("^Secret") and "Secret" or rarity, tier })
            while #Eggs.Recent > 8 do
                table.remove(Eggs.Recent)
            end
        end
        Webhook.Hatch(pet, result.Egg)
    end
end

function Eggs.HoldRun(screen)
    Util.AsIdentity(2)
    if Library.Flags.AutoHoldSecret ~= true then
        return
    end
    local client = Util.Path(ReplicatedStorage, "Modules", "Client", "Pets")
    local renderer = client and Util.Require(client:FindFirstChild("SecretHatchRenderer"), 5)
    local tries = 0
    while tries < 3 and Library.Flags.AutoHoldSecret == true and not Library.Unloaded do
        if screen:GetAttribute("TS2SecretHatchStage") ~= "AwaitingHold" then
            return
        end
        task.wait(0.4)
        if renderer then
            Util.Method(renderer, "BeginHold")
        end
        Eggs.Holds += 1
        tries += 1
        task.wait(1)
    end
end

function Eggs.HoldBind()
    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local screen = gui and gui:FindFirstChild("HatchScreen", true)
    if not screen then
        return nil
    end
    return screen:GetAttributeChangedSignal("TS2SecretHatchStage"):Connect(function()
        if screen:GetAttribute("TS2SecretHatchStage") == "AwaitingHold" then
            task.spawn(Eggs.HoldRun, screen)
        end
    end)
end

function Eggs.Renderer()
    local client = Util.Path(ReplicatedStorage, "Modules", "Client", "Pets")
    return client and Util.Require(client:FindFirstChild("HatchRenderer"), 5) or nil
end

function Eggs.HideRun()
    Util.AsIdentity(2)
    local renderer = Eggs.Renderer()
    if Library.Flags.HideHatch == true and not Library.Unloaded then
        if renderer and not Eggs.Hidden then
            Eggs.Hidden = { Play = renderer.Play, IsPlaying = renderer.IsPlaying, GetEndsAt = renderer.GetEndsAt }
            renderer.Play = function(_, _, done)
                if type(done) == "function" then
                    task.defer(done)
                end
            end
            renderer.IsPlaying = function()
                return false
            end
            renderer.GetEndsAt = function()
                return nil
            end
        end
    elseif Eggs.Hidden and renderer then
        renderer.Play = Eggs.Hidden.Play
        renderer.IsPlaying = Eggs.Hidden.IsPlaying
        renderer.GetEndsAt = Eggs.Hidden.GetEndsAt
        Eggs.Hidden = nil
    end
end

function Eggs.Hide()
    task.spawn(Eggs.HideRun)
end

function Eggs.Rows()
    local rows = {}
    local pick = Eggs.Pick()
    for _, name in Eggs.Names() do
        table.insert(rows, {
            { Text = name, Color = name == pick and "Accent" or nil },
            Util.Short(Eggs.Price(name, 1)),
            tostring(Eggs.Secrets(name)),
            Eggs.Open(name) and (Eggs.Price(name, 1) <= Data.Coins() and "ready" or "saving") or "locked",
        })
    end
    return rows
end

function Eggs.PityRows()
    local save = Data.Save
    local rows = {}
    if save and type(save.Eggs) == "table" then
        for egg, pity in (save.Eggs.Pity or {}) do
            local count = type(pity) == "table" and Util.Num(pity.Secret or pity.Count or pity[1], 0) or Util.Num(pity, 0)
            local dry = save.Eggs.SecretDroughtSeconds and Util.Num(save.Eggs.SecretDroughtSeconds[egg], 0) or 0
            table.insert(rows, { tostring(egg), Util.Commas(count), Util.Clock(dry) })
        end
    end
    table.sort(rows, function(a, b)
        return Util.Amount(a[2]) > Util.Amount(b[2])
    end)
    return rows
end

Rebirth = { Last = 0, Note = "", AUTO = { "Best Unlocked", "Best Affordable" } }

function Rebirth.Slots()
    local config = Game.Module("RebirthButtonConfig")
    local save = Data.Save
    local world = save and save.Progression and save.Progression.World or "Main"
    local count = config and Util.Fn(config, "GetOptionCount", save and save.Upgrades and save.Upgrades.RebirthButtons, world) or 1
    return math.max(1, math.floor(Util.Num(count, 1)))
end

function Rebirth.Price(slot)
    local config = Game.Module("RebirthConfig")
    if not config then
        return math.huge, 0
    end
    local amount = Util.Fn(config, "GetAmountFromIndex", slot) or 5 ^ (slot - 1)
    local price = Util.Fn(config, "GetPrice", amount, Data.Rebirths(), Data.Save)
    return Util.Num(price, math.huge), Util.Num(amount, 0)
end

function Rebirth.Target()
    local pick = tostring(Library.Flags.RebirthPick or "Best Unlocked")
    local slots = Rebirth.Slots()
    if pick == "Best Affordable" then
        local coins, best = Data.Coins(), 1
        for slot = 1, slots do
            if Rebirth.Price(slot) <= coins then
                best = slot
            end
        end
        return best
    end
    local numbered = tonumber(pick:match("^Slot (%d+)"))
    if numbered then
        return math.clamp(numbered, 1, slots)
    end
    return slots
end

function Rebirth.Labels()
    local labels = { "Best Unlocked", "Best Affordable" }
    local config = Game.Module("RebirthButtonConfig")
    local max = 14
    if config and type(config.MaximumOptionsByWorld) == "table" then
        max = Util.Num(config.MaximumOptionsByWorld.Main, 14)
    end
    for slot = 1, max do
        table.insert(labels, ("Slot %d (+%s)"):format(slot, Util.Short(5 ^ (slot - 1))))
    end
    return labels
end

function Rebirth.Owns()
    local formula = Game.Module("SkillTreeFormula")
    return formula ~= nil and Util.Fn(formula, "HasAutoRebirth", Data.Save) == true
end

function Rebirth.On()
    return Library.Flags.AutoRebirth == true
end

function Rebirth.Step()
    if Arena.Active then
        Bg:Later("rebirth", 5)
        return
    end
    local savingFor, goal = World.Saving()
    local controller = Game.C.RebirthController
    if savingFor then
        if Rebirth.Owns() and controller and Util.Method(controller, "GetAutoIndex") ~= nil then
            Util.Method(controller, "ClearAuto")
        end
        Rebirth.Note = "saving coins for " .. savingFor
        Need.Set("rebirth", "Coins", goal)
        return
    end
    if Rebirth.Owns() and controller and Util.Method(controller, "GetAutoIndex") ~= nil then
        Util.Method(controller, "ClearAuto")
    end
    local slot = Rebirth.Target()
    local price, amount = Rebirth.Price(slot)
    if Data.Coins() < price then
        Rebirth.Note = ("saving for slot %d: %s"):format(slot, Util.Short(price))
        Need.Set("rebirth", "Coins", price)
        return
    end
    local since = os.clock() - Rebirth.Last
    if since < 1.6 then
        Bg:Later("rebirth", 1.6 - since)
        return
    end
    Rebirth.Last = os.clock()
    if Net.Fire("RebirthService", "RebirthRequested", { Index = slot }) then
        State.Rebirthed += 1
        Rebirth.Note = ("rebirthed slot %d (+%s)"):format(slot, Util.Short(amount))
    end
    Bg:Later("rebirth", 1.6)
end

function Rebirth.Release()
    local controller = Game.C.RebirthController
    if controller and Rebirth.Owns() then
        Util.Method(controller, "ClearAuto")
    end
end


--== Auto buy and claims ==--

Shop = { Note = "", KINDS = { "Skill Nodes", "Upgrades", "Double Jumps", "Pad Upgrades" }, Rest = {}, NodeRest = {}, Pads = {} }

function Shop.Wants(kind)
    return Util.Picks("AutoBuyPick")[kind] == true
end

function Shop.On()
    return Library.Flags.AutoBuy == true
end

function Shop.NextNode()
    local formula = Game.Module("SkillTreeFormula")
    if not formula or type(formula.Nodes) ~= "table" then
        return nil
    end
    local save = Data.Save
    local unlocked = save and save.SkillTree and save.SkillTree.Unlocked or {}
    local best, bestPrice = nil, math.huge
    for id, node in formula.Nodes do
        if unlocked[id] ~= true and (node.Parent == nil or unlocked[node.Parent] == true) then
            local tree = node.Tree
            if tree == nil or tree == "Origin" or unlocked[tree] == true or formula.Nodes[tree] == nil then
                if os.clock() >= (Shop.NodeRest[id] or 0) then
                    local price = Util.Fn(formula, "GetPrice", save, id)
                    if price and Util.Num(price, math.huge) < bestPrice then
                        best, bestPrice = id, Util.Num(price, math.huge)
                    end
                end
            end
        end
    end
    return best, bestPrice
end

function Shop.NextUpgrade()
    local config = Game.Module("UpgradeConfig")
    if not config or type(config.Order) ~= "table" then
        return nil
    end
    local save = Data.Save
    local levels = save and save.Upgrades or {}
    local zones = Data.Zones()
    local best, bestPrice = nil, math.huge
    for _, name in config.Order do
        local entry = Util.Fn(config, "Get", name)
        if type(entry) == "table" and entry.SkillTreeNode == nil then
            local level = Util.Num(levels[name], 0)
            local cap = entry.LaunchTotal or entry.Total
            if not cap or level < cap then
                local zone = Util.Fn(config, "GetRetainedRequirement", name, level)
                if zone == nil or zone == "Spawn" or zones[zone] == true then
                    local price = Util.Fn(config, "GetPrice", name, level + 1)
                    if price and Util.Num(price, math.huge) < bestPrice then
                        best, bestPrice = name, Util.Num(price, math.huge)
                    end
                end
            end
        end
    end
    return best, bestPrice
end

function Shop.NextJump()
    local config = Game.Module("DoubleJumpConfig")
    if not config then
        return nil
    end
    local world = config.World or "Main"
    local save = Data.Save
    local owned = math.floor(Util.Num(save and save.DoubleJumps and save.DoubleJumps[world], 0))
    local max = Util.Num(config.MaximumLaunchPurchaseIndex, 6)
    if owned > max then
        return nil
    end
    local zone = Util.Fn(config, "GetRetainedRequirement", owned)
    if zone ~= nil and zone ~= "Spawn" and Data.Zones()[zone] ~= true then
        return nil
    end
    local price = Util.Fn(config, "GetPrice", owned)
    return price and world or nil, Util.Num(price, math.huge)
end

function Shop.Refused(kind, why)
    Shop.Note = ("%s: %s"):format(kind, tostring(why or "refused"))
    Shop.Rest[kind] = os.clock() + 60
end

function Shop.Step()
    local gems = Data.Gems()
    local lowest = math.huge
    if Shop.Wants("Skill Nodes") then
        local id, price = Shop.NextNode()
        if id then
            if price <= gems then
                local result = Net.Invoke("SkillTreeService", "Unlock", { Name = id })
                local ok, why = Net.Why(result)
                if ok then
                    State.Bought += 1
                    Shop.Note = "bought node " .. tostring(id)
                    Bg:Wake("shop", 0.3)
                else
                    Shop.NodeRest[id] = os.clock() + 300
                    Shop.Note = ("%s: %s"):format(tostring(id), tostring(why))
                    Bg:Wake("shop", 1)
                end
                return
            end
            lowest = math.min(lowest, price)
        end
    end
    if Shop.Wants("Upgrades") and os.clock() >= (Shop.Rest.upgrades or 0) then
        local name, price = Shop.NextUpgrade()
        if name then
            if price <= gems then
                local ok, why = Net.Why(Net.Invoke("UpgradeService", "Purchase", { Name = name }))
                if ok then
                    State.Bought += 1
                    Shop.Note = "bought upgrade " .. tostring(name)
                    Bg:Wake("shop", 0.3)
                else
                    Shop.Refused("upgrades", why)
                    Bg:Wake("shop", 1)
                end
                return
            end
            lowest = math.min(lowest, price)
        end
    end
    if Shop.Wants("Double Jumps") and os.clock() >= (Shop.Rest.jumps or 0) then
        local world, price = Shop.NextJump()
        if world then
            if price <= gems then
                local ok, why = Net.Why(Net.Invoke("DoubleJumpService", "Purchase", { World = world }))
                if ok then
                    State.Bought += 1
                    Shop.Note = "bought double jump"
                    Bg:Wake("shop", 0.3)
                else
                    Shop.Refused("jumps", why)
                    Bg:Wake("shop", 1)
                end
                return
            end
            lowest = math.min(lowest, price)
        end
    end
    if lowest < math.huge then
        if Shop.Note == "" then
            Shop.Note = "next buy at " .. Util.Short(lowest) .. " gems"
        end
        Need.Set("shop", "Gems", lowest)
    end
end

function Shop.NextPad()
    if not Shop.Wants("Pad Upgrades") or os.clock() < (Shop.Rest.pads or 0) then
        return nil
    end
    local config = Game.Module("PhysicalUpgradeConfig")
    if not config then
        return nil
    end
    local gems = Data.Gems()
    local best, bestIndex, bestPrice = nil, nil, math.huge
    for model in Shop.Pads do
        if not model.Parent then
            Shop.Pads[model] = nil
        else
            local key = model:GetAttribute("UpgradeName")
            local line = key and Util.Fn(config, "Get", key)
            if type(line) == "table" then
                local index = Util.Num(Util.Fn(config, "GetOwned", Data.Save, line), 0) + 1
                if Util.Fn(config, "GetLockedIsland", Data.Save, line, index) == nil then
                    local price = Util.Num(Util.Fn(config, "GetPrice", line, index), math.huge)
                    if price <= gems and price < bestPrice then
                        best, bestIndex, bestPrice = model, index, price
                    end
                end
            end
        end
    end
    return best, bestIndex
end

function Shop.BuyPad(model, index)
    local config = Game.Module("PhysicalUpgradeConfig")
    if not config or not model.Parent then
        return false
    end
    local key = model:GetAttribute("UpgradeName")
    Char.Go(model:GetPivot().Position, 20)
    Char.Hop(Char.Beside(model:GetPivot().Position, 6, { model }))
    local ok, why = Net.Why(Net.Invoke("PhysicalUpgradeService", "Purchase", { Upgrade = key, Index = index }))
    if ok then
        State.Bought += 1
        Shop.Note = ("bought %s step %d"):format(tostring(key), index)
        return true
    end
    Shop.Rest.pads = os.clock() + 60
    Shop.Note = ("pad: %s"):format(tostring(why))
    return false
end

Claims = {
    KINDS = { "Quests", "Index Rewards", "Gifts", "Offline Rewards", "Shiny Stars", "Tap Chests", "NPC Quest" },
    GIFTS = { "New Years Gift", "Valentines Gift", "St. Patrick Gift", "Release Gift" },
    Note = "", Tried = {}, Rest = {}, Stars = {}, Chests = {}, NpcModel = nil,
}

Claims.STAR_SPOTS = {
    Spawn1 = Vector3.new(53.6, -513.3, -2015.7), Spawn2 = Vector3.new(-4.4, -513.3, -1699.5), Spawn3 = Vector3.new(-98.3, -387.5, -1534.2),
    SkyIsland1 = Vector3.new(-79.7, -49.1, -1930.4), SkyIsland2 = Vector3.new(-61.9, -53.6, -1791.1),
    Autumn1 = Vector3.new(-125.5, 905.1, -1978.3), Autumn2 = Vector3.new(23.6, 882.8, -1947.9),
    Mushroom1 = Vector3.new(78.9, 2034.5, -1996.0), Mushroom2 = Vector3.new(-124.1, 2032.5, -2067.9),
    Desert1 = Vector3.new(13.2, 3643.3, -2165.9), Desert2 = Vector3.new(59.1, 3636.4, -1979.1),
    CrystalCave1 = Vector3.new(-235.0, 5444.9, -2050.9), CrystalCave2 = Vector3.new(19.7, 5446.5, -2033.5),
    ShadowRelm1 = Vector3.new(13.2, 7692.2, -2106.3), ShadowRelm2 = Vector3.new(197.8, 7698.4, -1858.6),
}
Claims.CORES = {
    Dock = Vector3.new(-37, -516, -2088), Boards = Vector3.new(-161, -523.3, -2020), Honey = Vector3.new(12, -517, -1925),
    Log = Vector3.new(31, -513.5, -1974), Cloud = Vector3.new(29, -450.5, -1874),
}
Claims.STAR_ISLANDS = { SkyIsland = "Sky Island", Autumn = "Autumn", Mushroom = "Mushroom", Desert = "Desert",
    CrystalCave = "Crystal Cave", ShadowRelm = "Shadow Realm" }

function Claims.On()
    return Library.Flags.AutoClaim == true or Library.Flags.AutoIndex == true
end

function Claims.Wants(kind)
    if kind == "Index Rewards" then
        return Library.Flags.AutoIndex == true
    end
    return Library.Flags.AutoClaim == true and Util.Picks("ClaimPick")[kind] == true
end

function Claims.Once(key, window)
    if os.clock() - (Claims.Tried[key] or 0) < (window or 5) then
        return false
    end
    Claims.Tried[key] = os.clock()
    return true
end

function Claims.Quests()
    if not Claims.Wants("Quests") or not Claims.Once("quest", 10) then
        return
    end
    local config = Game.Module("QuestConfig")
    local definitions = config and (config.Definitions or config.Quests) or {}
    local save = Data.Save
    for name, quest in (save and save.Quests or {}) do
        if type(quest) == "table" and quest.Claimed ~= true then
            local def = definitions[name]
            if not (type(def) == "table" and def.AutoClaim) then
                local done = quest.Completed == true or (def and def.Goal and Util.Num(quest.Amount, 0) >= Util.Num(def.Goal, 0))
                if done then
                    local ok, why = Net.Why(Net.Invoke("QuestService", "ClaimQuest", { Quest = name }))
                    if ok then
                        State.Claimed += 1
                        Claims.Note = "claimed quest " .. tostring(name)
                    else
                        Claims.Note = ("quest: %s"):format(tostring(why))
                    end
                end
            end
        end
    end
end

function Claims.Index()
    if not Claims.Wants("Index Rewards") or not Claims.Once("index", 30) then
        return
    end
    local catalog = Game.Module("PetIndexCatalog")
    if not catalog then
        return
    end
    local claimables = Util.Fn(catalog, "Claimables", Data.Save and Data.Save.Pets)
    for _, entry in (type(claimables) == "table" and claimables or {}) do
        if entry.Kind == "Egg" and type(entry.Name) == "string" then
            if Net.Fire("PetIndexService", "RewardClaimRequested", entry.Name) then
                State.Claimed += 1
                Claims.Note = "claimed index reward " .. entry.Name
            end
        end
    end
end

function Claims.Gifts()
    if not Claims.Wants("Gifts") or not Claims.Once("gift", 6) then
        return
    end
    local save = Data.Save
    for _, name in Claims.GIFTS do
        local owned = save and save.Items and save.Items.Owned and Util.Num(save.Items.Owned[name], 0) or 0
        if owned > 0 then
            local ok, why = Net.Why(Net.Invoke("GiftService", "OpenGift", { Gift = name, Amount = math.min(owned, 10) }))
            if ok then
                State.Claimed += 1
                Claims.Note = "opened " .. name
            else
                Claims.Note = ("gift: %s"):format(tostring(why))
            end
        end
    end
end

function Claims.Offline()
    if not Claims.Wants("Offline Rewards") or not Claims.Once("offline", 30) then
        return
    end
    local save = Data.Save
    local pending = save and save.Offline and save.Offline.Pending
    local coins = type(pending) == "table" and Util.Num(pending.Coins, 0) or 0
    if coins <= 0 then
        return
    end
    local ok, why = Net.Why(Net.Invoke("OfflineRewardsService", "Claim"))
    if ok then
        State.Claimed += 1
        Claims.Note = "claimed offline " .. Util.Short(coins) .. " coins"
    else
        Claims.Note = ("offline: %s"):format(tostring(why))
    end
end

function Claims.Step()
    Claims.Quests()
    Claims.Index()
    Claims.Gifts()
    Claims.Offline()
end

function Claims.StarOpen(id)
    local prefix = tostring(id):match("^([%a]+)")
    local island = prefix and Claims.STAR_ISLANDS[prefix]
    if not island then
        return true
    end
    return Data.Islands()[island] == true
end

function Claims.NextStar()
    if not Claims.Wants("Shiny Stars") then
        return nil
    end
    local save = Data.Save
    local found = save and save.ShinyStars and save.ShinyStars.Found or {}
    local best, bestDist = nil, math.huge
    for star in Claims.Stars do
        if not star.Parent then
            Claims.Stars[star] = nil
        else
            local id = star:GetAttribute("ShinyStarId")
            if id and found[id] ~= true and os.clock() >= (Claims.Rest["s" .. tostring(id)] or 0) then
                local center = star:GetAttribute("ShinyStarCenter")
                local spot = typeof(center) == "Vector3" and center or star:GetPivot().Position
                local dist = Char.Distance(spot)
                if dist < bestDist then
                    best, bestDist = { Id = id, Spot = spot }, dist
                end
            end
        end
    end
    if best then
        return best
    end
    local fallback, fallbackScore = nil, math.huge
    for id, spot in Claims.STAR_SPOTS do
        if found[id] ~= true and Claims.StarOpen(id) and os.clock() >= (Claims.Rest["s" .. id] or 0) then
            local island = Claims.STAR_ISLANDS[id:match("^([%a]+)")]
            local score = (island and Data.Island() ~= island and 1e6 or 0) + Char.Distance(spot)
            if score < fallbackScore then
                fallback, fallbackScore = { Id = id, Spot = spot, Island = island }, score
            end
        end
    end
    return fallback
end

function Claims.Star(work)
    if work.Island and Data.Island() ~= work.Island then
        World.Travel(work.Island)
    end
    Char.Hop(work.Spot)
    task.wait(1)
    local save = Data.Save
    if save and save.ShinyStars and save.ShinyStars.Found and save.ShinyStars.Found[work.Id] == true then
        Claims.Note = "star already found"
        return
    end
    local ok, why = Net.Why(Net.Invoke("ShinyStarService", "Collect", work.Id))
    if ok then
        Claims.Note = "collected a shiny star"
    else
        Claims.Rest["s" .. tostring(work.Id)] = os.clock() + 600
        Claims.Note = ("star: %s"):format(tostring(why))
    end
end

function Claims.NextChest()
    if not Claims.Wants("Tap Chests") then
        return nil
    end
    local save = Data.Save
    local now = Workspace:GetServerTimeNow()
    for chest in Claims.Chests do
        if not chest.Parent then
            Claims.Chests[chest] = nil
        else
            local id = chest:GetAttribute("TapChestId")
            local readyAt = id and save and save.TapChests and Util.Num(save.TapChests[id], 0) or 0
            if id and readyAt <= now and os.clock() >= (Claims.Rest["c" .. tostring(id)] or 0) then
                local front = chest:GetAttribute("TapChestFront")
                local spot = typeof(front) == "CFrame" and front.Position or chest:GetPivot().Position
                return { Id = id, Spot = spot, Model = chest }
            end
        end
    end
    return nil
end

function Claims.Chest(work)
    Char.Hop(Char.Beside(work.Spot, 5, { work.Model }))
    task.wait(0.4)
    local result = Net.Invoke("TapChestService", "Claim", work.Id)
    local ok, why = Net.Why(result)
    if ok then
        State.Claimed += 1
        Claims.Note = "tap chest +" .. Util.Short(type(result) == "table" and result.Coins or 0) .. " coins"
    else
        Claims.Rest["c" .. tostring(work.Id)] = os.clock() + 600
        Claims.Note = ("chest: %s"):format(tostring(why))
    end
end

function Claims.Boingo()
    local model = Claims.NpcModel
    if model and model.Parent then
        return model:GetPivot().Position, model
    end
    return nil, nil
end

function Claims.NpcWork()
    if not Claims.Wants("NPC Quest") or os.clock() < (Claims.Rest.npc or 0) then
        return nil
    end
    local save = Data.Save
    local line = save and save.NpcQuests and save.NpcQuests.BouncyBall
    if type(line) ~= "table" or line.Done == true or Data.Island() ~= "Spawn" then
        return nil
    end
    local step = Util.Num(line.Step, 0)
    if step == 3 then
        for name, spot in Claims.CORES do
            if not (type(line.Found) == "table" and line.Found[name] == true) then
                return { Kind = "core", Core = name, Spot = spot }
            end
        end
        return nil
    end
    if step == 0 then
        local config = Game.Module("NpcQuestConfig")
        if config and Util.Fn(config, "IsAvailable", save, "BouncyBall") == false then
            return nil
        end
        if not Claims.Boingo() then
            Claims.Rest.npc = os.clock() + 300
            return nil
        end
    end
    if step == 0 or step == 1 or step == 6 then
        return { Kind = "talk" }
    end
    return nil
end

function Claims.Npc(work)
    if work.Kind == "core" then
        Char.Hop(work.Spot)
        task.wait(0.4)
        local ok = Net.Why(Net.Invoke("NpcQuestService", "Collect", { Line = "BouncyBall", Core = work.Core }))
        if not ok then
            Claims.Rest.npc = os.clock() + 120
        end
        return
    end
    local spot, model = Claims.Boingo()
    if not spot then
        Claims.Rest.npc = os.clock() + 60
        return
    end
    Char.Hop(Char.Beside(spot, 6, { model }))
    task.wait(0.4)
    local ok = Net.Why(Net.Invoke("NpcQuestService", "Talk", { Line = "BouncyBall" }))
    if not ok then
        Claims.Rest.npc = os.clock() + 120
    end
end


--== Pets, crafting, enchanting ==--

Pets = {
    Note = "", DeleteNote = "", IndexNote = "", IndexAt = 0, IndexBest = nil, Batch = 0,
    MODES = { "Clicks", "Gems", "Luck" },
    RARITIES = { "Common", "Rare", "Epic", "Legendary", "Mythical", "Secret" },
    TIERS = { "Normal", "Golden", "Diamond", "Rainbow" },
    MUTATIONS = { "Shiny", "Void", "Galaxy" },
    INDEX_TIERS = { "Normal", "Golden", "Diamond", "Shiny" },
    NEXT_TIER = { Normal = "Golden", Golden = "Diamond", Diamond = "Shiny" },
    RELICS = { "SecretRing", "HatchRing", "GoldenRing", "EnchantRing", "TapRing" },
    Species = {},
    NativeSet = {},
    LastEquip = 0,
}

function Pets.TierName(tier)
    if tier == "Shiny" then
        return "Rainbow"
    end
    return tostring(tier or "Normal")
end

function Pets.Owned()
    local save = Data.Save
    return (save and type(save.Pets) == "table" and type(save.Pets.Owned) == "table") and save.Pets.Owned or {}
end

function Pets.Held()
    local save = Data.Save
    local held = {}
    if save and type(save.Pets) == "table" then
        for _, id in (save.Pets.Equipped or {}) do
            held[id] = true
        end
        for _, team in (save.PetTeams or {}) do
            if type(team) == "table" then
                for _, id in team do
                    held[id] = true
                end
            end
        end
    end
    return held
end

function Pets.Count()
    local save = Data.Save
    local limit = save and save.Pets and Util.Num(save.Pets.StorageLimit, 150) or 150
    return Util.Count(Pets.Owned()), math.max(1, limit)
end

-- A pet is spare when nothing about it is worth keeping on its own: not held,
-- not locked, no enchant, no mutation, no signature, never a Secret.
function Pets.Spare(id, entry, held)
    entry = entry or Pets.Owned()[id]
    if type(entry) ~= "table" then
        return false
    end
    held = held or Pets.Held()
    if held[id] or entry.Locked == true or entry.Frozen == true then
        return false
    end
    if entry.Enchant ~= nil or entry.Enchant2 ~= nil or entry.Mutation ~= nil or entry.Signature ~= nil then
        return false
    end
    return not tostring(entry.Rarity or ""):match("^Secret")
end

function Pets.OneIn(name, tier, mutation)
    local odds = Game.Module("PetOdds")
    if not odds then
        return math.huge
    end
    local base = Util.Fn(odds, "OneIn", name)
    if not base then
        return math.huge
    end
    local variant = Util.Fn(odds, "Variant", base, tier, mutation)
    return Util.Num(variant or base, math.huge)
end

function Pets.RarityOf(name)
    local config = Game.Module("LaunchPetConfig")
    local entry = config and config[name]
    return entry and tostring(entry.Rarity or "") or ""
end

function Pets.EquipStep()
    if os.clock() - Pets.LastEquip < 8 then
        Bg:Later("equip", 8 - (os.clock() - Pets.LastEquip))
        return
    end
    Pets.LastEquip = os.clock()
    if Net.Fire("PetService", "PetActionRequested", { Action = "EquipBest", Mode = tostring(Library.Flags.EquipMode or "Clicks") }) then
        Pets.Note = "equipped best (" .. tostring(Library.Flags.EquipMode or "Clicks") .. ")"
    end
end

function Pets.Deletable(id, entry)
    if not Pets.Spare(id, entry) then
        -- Mutated spares lose their protection only when their mutation is picked for deletion.
        if type(entry) == "table" and entry.Mutation ~= nil then
            local picks = Util.PickSet("DeleteMutations")
            if picks and picks[tostring(entry.Mutation)] then
                local clone = {}
                for key, value in entry do
                    clone[key] = value
                end
                clone.Mutation = nil
                if Pets.Spare(id, clone) then
                    return true
                end
            end
        end
        if type(entry) == "table" and Enchant.Rolled[id] then
            local clone = {}
            for key, value in entry do
                clone[key] = value
            end
            clone.Enchant, clone.Enchant2 = nil, nil
            return Pets.Spare(id, clone)
        end
        return false
    end
    return true
end

function Pets.Doomed()
    local rarities = Util.PickSet("DeleteRarities")
    local tiers = Util.PickSet("DeleteTiers")
    local below = Util.Amount(Library.Flags.DeleteBelow)
    if not rarities and below <= 0 then
        return {}
    end
    local held = Pets.Held()
    local doomed = {}
    for id, entry in Pets.Owned() do
        if Pets.Deletable(id, entry) and not held[id] then
            local rarityOk = not rarities or rarities[tostring(entry.Rarity or "")] == true
            local tierOk = not tiers or tiers[Pets.TierName(entry.Tier)] == true
            local oddsOk = below <= 0 or Pets.OneIn(entry.Name, entry.Tier, nil) < below
            if rarityOk and tierOk and oddsOk then
                table.insert(doomed, id)
            end
        end
    end
    return doomed
end

function Pets.DeleteStep()
    Pets.NativeSync()
    local doomed = Pets.Doomed()
    if #doomed == 0 then
        Pets.DeleteNote = "nothing to delete"
        return
    end
    local first = math.min(#doomed, 400)
    local batch = {}
    for i = 1, first do
        batch[i] = doomed[i]
    end
    Pets.Batch += 1
    if Pets.Batch > 3 then
        task.wait(1.05)
    end
    if Net.Fire("PetService", "PetActionRequested", { Action = "Delete", PetIds = batch, Batch = Pets.Batch }) then
        State.Deleted += #batch
        Pets.DeleteNote = ("deleted %d pets"):format(#batch)
    end
    if #doomed > first then
        Bg:Later("delete", 3)
    end
end

function Pets.IndexFound(name, tier)
    local catalog = Game.Module("PetIndexCatalog")
    if not catalog then
        return false
    end
    local save = Data.Save
    return Util.Fn(catalog, "Discovered", save and save.Pets, name, tier) == true
end

function Pets.Hold(id, entry)
    local count, limit = Pets.Count()
    if count >= limit * 0.9 then
        return false
    end
    entry = entry or Pets.Owned()[id]
    if type(entry) ~= "table" then
        return false
    end
    if Library.Flags.GoldenMastery == true and Pets.TierName(entry.Tier) == "Normal" then
        return true
    end
    if Library.Flags.AutoIndex ~= true then
        return false
    end
    local nextTier = Pets.NEXT_TIER[Pets.TierName(entry.Tier)]
    return nextTier ~= nil and not Pets.IndexFound(entry.Name, nextTier)
end

function Pets.NativeHold(id, entry)
    if Pets.Hold(id, entry) then
        return true
    end
    return false
end

function Pets.NativeEntries()
    if Library.Flags.AutoDelete ~= true then
        return nil
    end
    local mutations = Util.PickSet("DeleteMutations")
    local hatchMutations = { "Shiny", "Ghost", "Bloodmoon", "Void", "Galaxy" }
    if mutations then
        for _, name in hatchMutations do
            if not mutations[name] then
                return nil
            end
        end
    else
        return nil
    end
    local egg = Eggs.Pick()
    local entry = egg and Eggs.Config(egg)
    if not entry or type(entry.Pets) ~= "table" then
        return nil
    end
    local rarities = Util.PickSet("DeleteRarities")
    local tiers = Util.PickSet("DeleteTiers")
    local below = Util.Amount(Library.Flags.DeleteBelow)
    local craftSpecies = (Library.Flags.AutoCraft == true or Craft.Full()) and Util.PickSet("CraftSpecies") or nil
    local entries, seen = {}, {}
    local function add(name)
        if type(name) ~= "string" or seen[name] or name:match("^Secret") then
            return
        end
        seen[name] = true
        local rarity = Pets.RarityOf(name)
        if rarities and not rarities[rarity] then
            return
        end
        if craftSpecies and craftSpecies[name] then
            return
        end
        for _, tier in { "", "_Golden", "_Diamond", "_Shiny" } do
            local tierName = tier == "" and "Normal" or tier:sub(2)
            if (not tiers or tiers[Pets.TierName(tierName)] == true)
                and (below <= 0 or Pets.OneIn(name, tierName, nil) < below) then
                table.insert(entries, name .. tier)
            end
        end
    end
    for _, name in entry.Pets do
        add(name)
    end
    for _, name in (entry.Secrets or {}) do
        add(name)
    end
    return #entries > 0 and { Egg = egg, Entries = entries } or nil
end

function Pets.NativeSync()
    local wanted = Pets.NativeEntries()
    local save = Data.Save
    if Library.Flags.AutoDelete ~= true then
        -- Only clear what this session wrote.
        for egg in Pets.NativeSet do
            Net.Fire("EggService", "AutoDeleteRequested", { Egg = egg, Entries = {} })
            Pets.NativeSet[egg] = nil
        end
        return
    end
    if not wanted then
        return
    end
    local current = save and save.Eggs and save.Eggs.AutoDelete and save.Eggs.AutoDelete[wanted.Egg]
    local same = type(current) == "table" and #current == #wanted.Entries
    if same then
        for i, name in wanted.Entries do
            if current[i] ~= name then
                same = false
                break
            end
        end
    end
    if not same then
        if Net.Fire("EggService", "AutoDeleteRequested", wanted) then
            Pets.NativeSet[wanted.Egg] = true
        end
    end
end

function Pets.Reserved()
    local reserved = {}
    local count, limit = Pets.Count()
    if count >= limit * 0.9 and Library.Flags.CraftWhenFull ~= true
        and Library.Flags.AutoIndex ~= true and Library.Flags.GoldenMastery ~= true then
        return reserved
    end
    for _, machine in Craft.MACHINES do
        if Craft.On(machine) then
            local size = machine == "Rainbow" and Craft.RainbowCount() or Craft.FULL[machine]
            for _, ids in Craft.Groups(machine) do
                local keep = machine == "Rainbow" and math.min(#ids, size) or math.floor(#ids / size) * size
                for i = 1, keep do
                    reserved[ids[i]] = true
                end
            end
        end
    end
    return reserved
end

function Pets.IndexEgg()
    if Library.Flags.AutoIndex ~= true then
        return nil
    end
    if os.clock() - Pets.IndexAt < 10 and Pets.IndexBest then
        return Pets.IndexBest
    end
    Pets.IndexAt = os.clock()
    local catalog = Game.Module("PetIndexCatalog")
    if not catalog then
        return nil
    end
    local skip = Util.Amount(Library.Flags.IndexMaxOdds)
    if skip <= 0 then
        skip = 10000
    end
    local coins = Data.Coins()
    local best, bestScore = nil, 0
    for _, egg in Eggs.Names() do
        if Eggs.Open(egg) and Eggs.Price(egg, 1) <= coins then
            local entry = Eggs.Config(egg)
            local names = {}
            for _, name in (entry.Pets or {}) do
                names[name] = true
            end
            for _, name in (entry.Secrets or {}) do
                names[name] = true
            end
            local score = 0
            for name in names do
                for _, tier in Pets.INDEX_TIERS do
                    if not Pets.IndexFound(name, tier) then
                        local oneIn = Pets.OneIn(name, tier, nil)
                        if oneIn <= skip then
                            score += 1 / math.max(oneIn, 1)
                        end
                    end
                end
            end
            if score > bestScore then
                best, bestScore = egg, score
            end
        end
    end
    Pets.IndexBest = best
    Pets.IndexNote = best and ("index: " .. best) or "index complete"
    return best
end

function Pets.MasteryText()
    local save = Data.Save
    local config = Game.Module("MasteryConfig")
    local parts = {}
    if save and type(save.Mastery) == "table" and type(save.Mastery.Categories) == "table" then
        for name, category in save.Mastery.Categories do
            table.insert(parts, ("%s %d"):format(tostring(name), Util.Num(category.Level, 0)))
        end
    end
    table.sort(parts)
    local max = config and Util.Num(config.MaxLevel, 50) or 50
    return #parts > 0 and ("Mastery (max %d): %s"):format(max, table.concat(parts, ", ")) or "No mastery yet"
end

function Pets.RelicStep()
    if Library.Flags.AutoRelic ~= true then
        return
    end
    local save = Data.Save
    if not save or type(save.Mastery) ~= "table" then
        return
    end
    if save.Mastery.EquippedRelic then
        return
    end
    for _, name in Pets.RELICS do
        if type(save.Mastery.RelicInventory) == "table" and save.Mastery.RelicInventory[name] == true then
            local ok = Net.Why(Net.Invoke("MasteryService", "EquipRelic", { Name = name }))
            if ok then
                Pets.Note = "equipped relic " .. name
            end
            return
        end
    end
end

function Pets.LoadSpecies()
    local config = Game.Module("LaunchEggConfig") or {}
    local seen, list = {}, {}
    for _, entry in config do
        if type(entry) == "table" then
            for _, name in (entry.Pets or {}) do
                if not seen[name] then
                    seen[name] = true
                    table.insert(list, name)
                end
            end
            for _, name in (entry.Secrets or {}) do
                if not seen[name] then
                    seen[name] = true
                    table.insert(list, name)
                end
            end
        end
    end
    table.sort(list)
    Pets.Species = list
end

Craft = {
    Note = "", Rest = {}, LastTrip = 0, LastSent = 0, SentAt = 0, Waiting = 0, NotNear = false,
    Answered = Instance.new("BindableEvent"),
    MACHINES = { "Golden", "Diamond", "Rainbow" },
    SOURCE = { Golden = "Normal", Diamond = "Golden", Rainbow = "Diamond" },
    KEY = { Golden = "Golden", Diamond = "Diamond", Rainbow = "Shiny" },
    FULL = { Golden = 6, Diamond = 5, Rainbow = 5 },
    RAINBOW = { "5 Pets (30 s)", "4 Pets (1 h)", "3 Pets (2.5 h)", "2 Pets (5 h)" },
    MUTATION_POWER = { Bloodmoon = 1.75, Ghost = 1.5, Galaxy = 1.5, Void = 1.5, Haunted = 1.5, Electric = 1.35, Shiny = 1.3 },
    TRIP = 180,
}

function Craft.RainbowCount()
    local text = tostring(Library.Flags.RainbowPets or "5")
    return math.clamp(Util.Num(text:match("^(%d)"), 5), 2, 5)
end

function Craft.Full()
    if Library.Flags.CraftWhenFull ~= true then
        return false
    end
    local count, limit = Pets.Count()
    return count >= limit * 0.9 or Eggs.Full()
end

function Craft.Picked(machine)
    return (Library.Flags.AutoCraft == true or Craft.Full()) and Util.Picks("CraftPick")[machine] == true
end

function Craft.Mastery(machine)
    return machine == "Golden" and Library.Flags.GoldenMastery == true
end

function Craft.On(machine)
    if os.clock() < (Craft.Rest[machine] or 0) then
        return false
    end
    return Craft.Picked(machine) or Library.Flags.AutoIndex == true or Craft.Mastery(machine)
end

function Craft.Groups(machine)
    local source = Craft.SOURCE[machine]
    local keyTier = Craft.KEY[machine]
    local species = Util.PickSet("CraftSpecies")
    if Craft.Full() then
        species = nil
    end
    local held = Pets.Held()
    local groups, mutated = {}, {}
    for id, entry in Pets.Owned() do
        if Pets.TierName(entry.Tier) == source then
            local wantedSpecies = not species or species[entry.Name] == true
            local forIndex = Library.Flags.AutoIndex == true and not Pets.IndexFound(entry.Name, keyTier)
            local forMastery = Craft.Mastery(machine)
            if Pets.Spare(id, entry, held) and (wantedSpecies or forIndex or forMastery) then
                groups[entry.Name] = groups[entry.Name] or {}
                table.insert(groups[entry.Name], id)
            elseif Library.Flags.CraftMutated == true and type(entry.Mutation) == "string" and Pets.Spare(id, entry, held) then
                mutated[entry.Name] = mutated[entry.Name] or {}
                table.insert(mutated[entry.Name], { Id = id, Power = Craft.MUTATION_POWER[entry.Mutation] or 1 })
            end
        end
    end
    if Library.Flags.CraftMutated == true then
        for name, list in mutated do
            table.sort(list, function(a, b)
                return a.Power > b.Power
            end)
            groups[name] = groups[name] or {}
            -- Leader plus weakest fodder keeps the strong pets out of the machine.
            local ordered = { list[1].Id }
            for i = #list, 2, -1 do
                table.insert(ordered, list[i].Id)
            end
            for _, id in ordered do
                table.insert(groups[name], id)
            end
        end
    end
    return groups
end

function Craft.Ready()
    local machine, queue = nil, 0
    local save = Data.Save
    if save and type(save.Machines) == "table" and type(save.Machines.Shiny) == "table" then
        queue = Util.Count(save.Machines.Shiny.Queue)
    end
    for _, name in Craft.MACHINES do
        if Craft.On(name) then
            machine = machine or name
        end
    end
    return machine, queue
end

function Craft.Errand()
    local any = false
    for _, machine in Craft.MACHINES do
        if Craft.On(machine) then
            any = true
            break
        end
    end
    if not any then
        return nil
    end
    if Eggs.Running() and not Craft.Full() and os.clock() - Craft.LastTrip < Craft.TRIP and Craft.LastTrip > 0 then
        return nil
    end
    for _, machine in Craft.MACHINES do
        if Craft.On(machine) and Char.CanReach(machine) then
            local groups = Craft.Groups(machine)
            local needed = machine == "Rainbow" and Craft.RainbowCount() or Craft.FULL[machine]
            for _, ids in groups do
                if #ids >= needed then
                    local point = Char.Point(machine)
                    if point then
                        return { Machine = machine, Point = point }
                    end
                end
            end
            if machine == "Rainbow" then
                local save = Data.Save
                local queue = save and save.Machines and save.Machines.Shiny and save.Machines.Shiny.Queue or {}
                local now = Workspace:GetServerTimeNow()
                for _, slot in queue do
                    if type(slot) == "table" and Util.Num(slot.EndTime, math.huge) <= now then
                        local point = Char.Point(machine)
                        if point then
                            return { Machine = machine, Point = point }
                        end
                    end
                end
            end
        end
    end
    Craft.Note = "no full craft group ready"
    return nil
end

function Craft.Run(work)
    local machine, point = work.Machine, work.Point
    Craft.LastTrip = os.clock()
    local wasIsland = Data.Island()
    Char.Go(point.Position + Vector3.new(0, 2, 0), 8)
    task.wait(Data.Island() ~= wasIsland and 2 or 1)
    local lag = 0
    pcall(function()
        lag = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)
    task.wait(math.clamp(lag * 2, 0, 2))
    local save = Data.Save
    if machine == "Rainbow" then
        local queue = save and save.Machines and save.Machines.Shiny and save.Machines.Shiny.Queue or {}
        local now = Workspace:GetServerTimeNow()
        for craftId, slot in queue do
            if type(slot) == "table" and Util.Num(slot.EndTime, math.huge) <= now then
                Net.Fire("MachineService", "MachineCraftRequested", { Machine = "Shiny", Action = "Claim", CraftId = craftId })
                State.Crafted += 1
                task.wait(0.4)
            end
        end
        local groups = Craft.Groups(machine)
        local started = Util.Count(queue)
        for _, ids in groups do
            if started >= 3 then
                break
            end
            if #ids >= Craft.RainbowCount() then
                local batch = {}
                for i = 1, Craft.RainbowCount() do
                    batch[i] = ids[i]
                end
                Craft.SentAt = os.clock()
                if Net.Fire("MachineService", "MachineCraftRequested", { Machine = "Shiny", Action = "Start", PetIds = batch }) then
                    State.Crafted += 1
                    started += 1
                end
                task.wait(0.6)
            end
        end
        return
    end
    local groups = Craft.Groups(machine)
    local key = Craft.KEY[machine]
    local sent = 0
    Craft.Waiting = 0
    for _, ids in groups do
        local size = Craft.FULL[machine]
        while #ids >= size and sent < 20 do
            local batch = {}
            for i = 1, size do
                batch[i] = table.remove(ids, 1)
            end
            Craft.SentAt = os.clock()
            Craft.Waiting += 1
            if Net.Fire("MachineService", "MachineCraftRequested", { Machine = key, Action = "Craft", PetIds = batch }) then
                State.Crafted += 1
                sent += 1
            end
            task.wait(0.5)
        end
        if sent >= 20 then
            break
        end
    end
    local deadline = os.clock() + 4
    while Craft.Waiting > 0 and os.clock() < deadline and not Library.Unloaded do
        task.wait(0.1)
    end
    Craft.Rest[machine] = math.max(Craft.Rest[machine] or 0, os.clock() + 5)
end

function Craft.OnResult(result)
    if type(result) ~= "table" then
        return
    end
    Craft.Waiting = math.max(0, Craft.Waiting - 1)
    Craft.Answered:Fire()
    if result.Success == true then
        if os.clock() - Craft.SentAt < 15 then
            Popup.Crafted()
        end
        return
    end
    local why = tostring(result.Reason or "refused")
    Craft.Note = "craft: " .. why
    local machine = result.Machine == "Shiny" and "Rainbow" or result.Machine
    local near = why:lower():find("near", 1, true) ~= nil
    Craft.NotNear = near
    if machine and Craft.Rest[machine] then
        Craft.Rest[machine] = os.clock() + (near and 6 or 60)
    elseif machine then
        Craft.Rest[machine] = os.clock() + (near and 6 or 60)
    end
end

Enchant = {
    Note = "", Rest = 0, Stop = nil, Work = nil, Rolled = {},
    Kick = Instance.new("BindableEvent"),
    TARGETS = { "First Equipped", "All Equipped", "Legendary +", "Mythical +", "Secrets", "Spare Pets (Mastery)" },
    FIRST = "First Equipped",
    SPARE = "Spare Pets (Mastery)",
    Names = {},
}
Enchant.RANK = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythical = 5, Mythic = 5, Secret = 7 }
Enchant.FLOOR = { ["Legendary +"] = 4, ["Mythical +"] = 5, Secrets = 7 }
Enchant.TIER_ORDER = { Normal = 0, Golden = 1, Diamond = 2, Rainbow = 3, Shiny = 3 }

function Enchant.Candidates()
    local target = tostring(Library.Flags.EnchantPet or Enchant.FIRST)
    local save = Data.Save
    local owned = Pets.Owned()
    local equipped = save and save.Pets and save.Pets.Equipped or {}
    local out = {}
    if target == "First Equipped" then
        if equipped[1] and owned[equipped[1]] then
            table.insert(out, equipped[1])
        end
        return out
    end
    if target == "All Equipped" then
        for _, id in equipped do
            if owned[id] then
                table.insert(out, id)
            end
        end
        return out
    end
    if target == Enchant.SPARE then
        local held = Pets.Held()
        local reserved = {}
        for _, machine in Craft.MACHINES do
            for _, ids in Craft.Groups(machine) do
                for _, id in ids do
                    reserved[id] = true
                end
            end
        end
        for id, entry in owned do
            if (Enchant.RANK[tostring(entry.Rarity or "")] or 0) <= 3 and Pets.Spare(id, entry, held)
                and not reserved[id] and not Pets.Hold(id, entry) then
                table.insert(out, id)
            end
        end
        table.sort(out, function(a, b)
            local ea, eb = owned[a], owned[b]
            local ra, rb = Enchant.RANK[tostring(ea.Rarity or "")] or 0, Enchant.RANK[tostring(eb.Rarity or "")] or 0
            if ra ~= rb then
                return ra < rb
            end
            return (Enchant.TIER_ORDER[Pets.TierName(ea.Tier)] or 0) < (Enchant.TIER_ORDER[Pets.TierName(eb.Tier)] or 0)
        end)
        local top = {}
        for i = 1, math.min(5, #out) do
            top[i] = out[i]
        end
        return top
    end
    local floorRank = Enchant.FLOOR[target]
    for id, entry in owned do
        if (floorRank and (Enchant.RANK[tostring(entry.Rarity or "")] or 0) >= floorRank) or entry.Name == target then
            table.insert(out, id)
        end
    end
    local held = Pets.Held()
    table.sort(out, function(a, b)
        if held[a] ~= held[b] then
            return held[a] == true
        end
        local ea, eb = owned[a], owned[b]
        local ta, tb = Enchant.TIER_ORDER[Pets.TierName(ea.Tier)] or 0, Enchant.TIER_ORDER[Pets.TierName(eb.Tier)] or 0
        if ta ~= tb then
            return ta > tb
        end
        return (Enchant.RANK[tostring(ea.Rarity or "")] or 0) > (Enchant.RANK[tostring(eb.Rarity or "")] or 0)
    end)
    return out
end

function Enchant.Cap()
    local cap = Util.Amount(Library.Flags.EnchantMaxPrice)
    if cap <= 0 and tostring(Library.Flags.EnchantPet) == Enchant.SPARE then
        return 30000
    end
    return cap
end

function Enchant.Due()
    if Library.Flags.AutoEnchant ~= true or os.clock() < Enchant.Rest then
        return nil
    end
    local wants = Util.PickSet("EnchantWants")
    if not wants then
        Enchant.Note = "pick enchants to stop on"
        return nil
    end
    if not Char.CanReach("Enchant") then
        Enchant.Note = "enchant machine not reachable"
        Enchant.Rest = os.clock() + 60
        return nil
    end
    local config = Game.Module("EnchantConfig")
    local spins = Game.Module("EnchantSpins")
    local save = Data.Save
    local spinCount = spins and Util.Fn(spins, "Count", save and save.Enchanting) or 0
    local cheapest = math.huge
    for _, id in Enchant.Candidates() do
        local entry = Pets.Owned()[id]
        if entry then
            local slot = Util.Num(Library.Flags.EnchantSlot, 1)
            if slot == 2 and config and Util.Num(Util.Fn(config, "GetSlotCount", entry), 1) < 2 then
                slot = 1
            end
            local current = slot == 2 and entry.Enchant2 or entry.Enchant
            if not (type(current) == "string" and wants[current]) then
                local price = config and Util.Fn(config, "GetRollPrice", entry)
                price = price and Util.Num(price, math.huge) or math.huge
                local rolls = config and Util.Num(Util.Fn(config, "GetRollCount", entry), 0) or 0
                if price <= Enchant.Cap() or spinCount > 0 then
                    if Data.Gems() >= price or spinCount > 0 then
                        return { Id = id, Slot = slot, Name = entry.Name, Rolls = rolls, Wanted = wants }
                    end
                    cheapest = math.min(cheapest, price)
                end
            end
        end
    end
    if cheapest < math.huge then
        Enchant.Note = "saving gems for a roll"
        Need.Set("move", "Gems", cheapest)
    else
        Enchant.Note = "all candidates already enchanted"
        Enchant.Rest = os.clock() + 60
    end
    return nil
end

function Enchant.Run(work)
    Enchant.Work = work
    local point = Char.Reach("Enchant")
    if not point then
        Enchant.Rest = os.clock() + 60
        return
    end
    Char.Go(point.Position, 8)
    local wanted = {}
    for name in work.Wanted do
        table.insert(wanted, name)
    end
    local filterResult = Net.Invoke("EnchantService", "SetFilters", wanted)
    if not Net.Why(filterResult) then
        Enchant.Rest = os.clock() + 300
        Enchant.Note = "enchant filters refused"
        return
    end
    task.wait(1)
    Enchant.Stop = nil
    local result = Net.Invoke("EnchantService", "AutoStart", { PetId = work.Id, Slot = work.Slot })
    local ok, why = Net.Why(result)
    if not ok and tostring(why) == "VisitEnchantMachine" then
        Char.Hop(Char.Beside(point.Position, 5))
        task.wait(1.5)
        result = Net.Invoke("EnchantService", "AutoStart", { PetId = work.Id, Slot = work.Slot })
        ok, why = Net.Why(result)
    end
    if not ok then
        Enchant.Rest = os.clock() + 120
        Enchant.Note = "enchant: " .. tostring(why)
        return
    end
    if tostring(Library.Flags.EnchantPet) == Enchant.SPARE then
        Enchant.Rolled[work.Id] = true
    end
    local deadline = os.clock() + 900
    while Enchant.Stop == nil and Library.Flags.AutoEnchant == true and not Library.Unloaded and os.clock() < deadline do
        Enchant.Kick.Event:Wait()
    end
    if Enchant.Stop == nil then
        Net.Invoke("EnchantService", "AutoStop")
    end
    Net.Invoke("EnchantService", "Claim")
    local stopInfo = Enchant.Stop
    if stopInfo and stopInfo.Reason == "Gems" then
        Enchant.Rest = os.clock() + 300
    elseif not ok then
        Enchant.Rest = os.clock() + 120
    else
        Enchant.Rest = os.clock() + 20
    end
    Enchant.Work = nil
end

function Enchant.OnEvent(info)
    if type(info) ~= "table" then
        return
    end
    if info.Kind == "Stop" then
        Enchant.Stop = info
        State.Rolls = (State.Rolls or 0) + Util.Num(info.Rolls, 0)
        Enchant.Kick:Fire()
    elseif info.Kind == "Roll" then
        local work = Enchant.Work
        if work then
            local config = Game.Module("EnchantConfig")
            if config then
                local base = Util.Num(config.RollPrice, 0)
                local growth = Util.Num(config.RollPriceGrowth, 1)
                local nextPrice = base * growth ^ (Util.Num(work.Rolls, 0) + Util.Num(info.Rolls, 0))
                local spins = Game.Module("EnchantSpins")
                local hasSpin = spins and Util.Num(Util.Fn(spins, "Count", Data.Save and Data.Save.Enchanting), 0) > 0
                if nextPrice > Enchant.Cap() and not hasSpin then
                    work.Capped = true
                    task.spawn(function()
                        Net.Invoke("EnchantService", "AutoStop")
                    end)
                end
            end
        end
    end
end


--== Items, world events, island mobs ==--

Items = { Note = "", BoostNote = "", PotionNote = "", HoneyNote = "", Rest = {}, Boosts = {}, Brewable = {}, Recipes = {}, PetItems = {} }

function Items.BoostStep()
    if Library.Flags.AutoBoosts ~= true then
        return
    end
    if Library.Flags.BoostsWhileHatching == true and not Eggs.Running() then
        Bg:Later("boosts", 30)
        return
    end
    local picks = Util.PickSet("BoostPick")
    if not picks then
        return
    end
    local save = Data.Save
    local soonest = math.huge
    for name in picks do
        local owned = save and save.Boosts and Util.Num(save.Boosts[name], 0) or 0
        local active = save and save.ActiveBoosts and Util.Num(save.ActiveBoosts[name], 0) or 0
        if owned > 0 and active <= 0 and os.clock() >= (Items.Rest["b" .. name] or 0) then
            local result = Net.Invoke("BoostService", "Use", name)
            local ok, why = Net.Why(result)
            if ok then
                local left = type(result) == "table" and Util.Num(result.TimeLeft, 0) or 0
                soonest = math.min(soonest, left + 1)
                Items.BoostNote = "drank " .. name
            else
                Items.Rest["b" .. name] = os.clock() + 60
                Items.BoostNote = ("boost: %s"):format(tostring(why))
            end
        end
    end
    if soonest < math.huge then
        Bg:Later("boosts", math.max(soonest, 5))
    end
end

function Items.PetItemStep()
    if Library.Flags.AutoPetItems ~= true then
        return
    end
    local picks = Util.PickSet("PetItemPick")
    if not picks then
        return
    end
    local save = Data.Save
    local equipped = save and save.Pets and save.Pets.Equipped or {}
    local target = equipped[1]
    if not target then
        Items.Note = "equip a pet first"
        return
    end
    for name in picks do
        local owned = save and save.Items and save.Items.Owned and Util.Num(save.Items.Owned[name], 0) or 0
        if owned > 0 and os.clock() >= (Items.Rest["i" .. name] or 0) then
            local ok, why = Net.Why(Net.Invoke("ItemService", "UseOnPet", { Item = name, PetId = target, Amount = 1 }))
            if ok then
                Items.Note = "fed " .. name
                Bg:Wake("items", 0.3)
            else
                Items.Rest["i" .. name] = os.clock() + 120
                Items.Note = ("item: %s"):format(tostring(why))
            end
            return
        end
    end
end

function Items.Machine(name)
    local map = Workspace:FindFirstChild("Map1")
    if not map then
        return nil
    end
    if name == "Potion" then
        return map:FindFirstChild("PotionMachine")
    end
    local area = map:FindFirstChild("HoneyPotArea")
    return area and area:FindFirstChild("HoneyPotMachine") or nil
end

function Items.MachineSpot(model)
    if not model then
        return nil
    end
    local marker = model:FindFirstChild("Circle", true) or model:FindFirstChild("Marker", true)
    if marker and marker:IsA("BasePart") then
        return marker.Position
    end
    return model:GetPivot().Position
end

function Items.Slots(kind)
    local save = Data.Save
    local out = {}
    local raw = kind == "Potion" and (save and save.PotionMachine and save.PotionMachine.Slots)
        or (save and save.HoneyPot and save.HoneyPot.Slots)
    for i = 1, 3 do
        local slot = type(raw) == "table" and (raw[tostring(i)] or raw[i]) or nil
        out[i] = type(slot) == "table" and slot or {}
    end
    return out
end

function Items.SlotReady(slot)
    local now = Workspace:GetServerTimeNow()
    for _, key in { "ReadyAt", "EndsAt", "EndTime" } do
        if slot[key] ~= nil then
            return Util.Num(slot[key], math.huge) <= now
        end
    end
    return slot.Brewing ~= true and slot.Active ~= true and Util.Count(slot) > 0
end

function Items.SlotBusy(slot)
    return Util.Count(slot) > 0 and not Items.SlotReady(slot)
end

function Items.PotionWork()
    if Library.Flags.AutoBrew ~= true and Library.Flags.AutoMerge ~= true then
        return nil
    end
    local work = { Claim = false, Brew = {}, Craft = {} }
    local slots = Items.Slots("Potion")
    local anyBusy = false
    for _, slot in slots do
        if Items.SlotReady(slot) and Util.Count(slot) > 0 then
            work.Claim = true
        elseif Items.SlotBusy(slot) then
            anyBusy = true
        end
    end
    if Library.Flags.AutoBrew == true then
        local brew = Game.Module("PotionBrewConfig")
        local want = tostring(Library.Flags.BrewPick or "")
        if brew and want ~= "" then
            local price = Util.Num(Util.Fn(brew, "GetPrice", 1, Data.Rebirths()), math.huge)
            for _, slot in slots do
                if Util.Count(slot) == 0 then
                    table.insert(work.Brew, want)
                end
            end
            if #work.Brew > 0 and Data.Gems() < price then
                work.Brew = {}
                Need.Set("move", "Gems", price)
            end
        end
    end
    if Library.Flags.AutoMerge == true then
        local recipes = Game.Module("PotionCraftConfig")
        local save = Data.Save
        for _, recipe in (recipes and recipes.Recipes or {}) do
            local have = save and save.Boosts and Util.Num(save.Boosts[recipe.Input], 0) or 0
            local times = math.floor(have / math.max(Util.Num(recipe.Required, 3), 1))
            if times > 0 then
                table.insert(work.Craft, { Output = recipe.Output, Amount = times })
            end
        end
    end
    if work.Claim or #work.Brew > 0 or #work.Craft > 0 then
        return work
    end
    if anyBusy then
        Mover:Later("move", 30)
    end
    return nil
end

function Items.Potion(work)
    local model = Items.Machine("Potion")
    local spot = Items.MachineSpot(model)
    if not spot then
        Items.Rest.potion = os.clock() + 60
        return
    end
    if Char.Flat(spot) > 6 then
        Char.Hop(spot)
        task.wait(0.3)
    end
    if work.Claim then
        Net.Invoke("PotionMachineService", "ClaimAll")
    end
    for _, name in work.Brew do
        local slot = 1
        local ok, why = Net.Why(Net.Invoke("PotionMachineService", "Brew", name, slot))
        if not ok then
            Items.Rest.potion = os.clock() + 120
            Items.PotionNote = ("brew: %s"):format(tostring(why))
            return
        end
        State.Crafted += 1
    end
    for _, craft in work.Craft do
        local ok, why = Net.Why(Net.Invoke("PotionMachineService", "Craft", craft.Output, craft.Amount))
        if not ok then
            Items.Rest.potion = os.clock() + 120
            Items.PotionNote = ("merge: %s"):format(tostring(why))
            return
        end
        State.Crafted += 1
    end
    Items.PotionNote = "potions tended"
end

function Items.HoneyWork()
    if Library.Flags.AutoHoney ~= true then
        return nil
    end
    local work = { Claim = {}, Craft = nil }
    local slots = Items.Slots("Honey")
    local free = nil
    for i, slot in slots do
        if Items.SlotReady(slot) and Util.Count(slot) > 0 then
            table.insert(work.Claim, i)
        elseif Util.Count(slot) == 0 and not free then
            free = i
        end
    end
    if free then
        local config = Game.Module("HoneyPotConfig")
        local key = nil
        local want = tostring(Library.Flags.HoneyPick or "")
        if config and type(config.ByKey) == "table" then
            for candidate, recipe in config.ByKey do
                if candidate == want or (type(recipe) == "table" and (recipe.Name == want or recipe.DisplayName == want)) then
                    key = candidate
                    break
                end
            end
            key = key or (config.ByKey[want] and want or nil)
        end
        if key then
            local maxCraft = config and Util.Fn(config, "MaxCraftable", Data.Save, key) or 0
            local amount = math.min(Util.Num(maxCraft, 0), 100)
            if amount > 0 then
                work.Craft = { Key = key, Amount = amount }
            end
        end
    end
    if #work.Claim > 0 or work.Craft then
        return work
    end
    return nil
end

function Items.Honey(work)
    local model = Items.Machine("Honey")
    local spot = Items.MachineSpot(model)
    if not spot then
        Items.Rest.honey = os.clock() + 60
        return
    end
    if Char.Flat(spot) > 6 then
        Char.Hop(spot)
        task.wait(0.3)
    end
    for _, index in work.Claim do
        Net.Invoke("HoneyPotService", "Claim", index)
        task.wait(0.2)
    end
    if work.Craft then
        local ok, why = Net.Why(Net.Invoke("HoneyPotService", "Craft", work.Craft.Key, work.Craft.Amount))
        if not ok then
            Items.Rest.honey = os.clock() + 120
            Items.HoneyNote = ("honey: %s"):format(tostring(why))
            return
        end
        State.Crafted += 1
    end
    Items.HoneyNote = "honey pot tended"
end

Events = { Note = "", ShrineNote = "", BalloonNote = "", Rest = {}, NudgeAt = 0, Balloons = {}, Popped = 0, BalloonKick = Instance.new("BindableEvent"), Blessings = {}, LastDuck = 0 }
Events.NudgeAt = os.clock() + 310

function Events.OnDuck(info)
    if Library.Flags.AutoDucky ~= true or type(info) ~= "table" or type(info.Id) ~= "string" then
        return
    end
    local id = info.Id
    task.spawn(function()
        Util.AsIdentity(2)
        task.wait(0.6 + math.random() * 0.8)
        if Library.Flags.AutoDucky ~= true or Library.Unloaded then
            return
        end
        local ok = Net.Why(Net.Invoke("LuckyDuckyService", "Claim", id))
        if ok then
            State.Ducks += 1
            Events.Note = ("caught %d ducks"):format(State.Ducks)
        end
    end)
end

function Events.DuckStep()
    if os.clock() < Events.NudgeAt then
        Bg:Later("ducky", Events.NudgeAt - os.clock())
        return
    end
    Net.Invoke("LuckyDuckyService", "Nudge", "Lull", { Signs = { "Lull", "Fatigue", "Stall" }, Score = 64 })
    Events.NudgeAt = os.clock() + 905
    Bg:Later("ducky", 906)
end

function Events.ShrineWork()
    if Library.Flags.AutoShrine ~= true or os.clock() < (Events.Rest.shrine or 0) then
        return nil
    end
    local want = tostring(Library.Flags.ShrinePick or "")
    local key = nil
    for _, blessing in Events.Blessings do
        if blessing.Name == want or blessing.Key == want then
            key = blessing.Key
            break
        end
    end
    if not key then
        return nil
    end
    if LocalPlayer:GetAttribute("ShrineBlessing") == key then
        Events.ShrineNote = "holding " .. want
        return nil
    end
    if Data.Islands()["Autumn"] ~= true then
        Events.ShrineNote = "needs the Autumn island"
        return nil
    end
    return { Key = key }
end

function Events.Shrine(work)
    Events.Rest.shrine = os.clock() + 30
    if Data.Island() ~= "Autumn" then
        World.Travel("Autumn")
    end
    local shrine = Util.Path(Workspace, "Ts2Islands", "Autumn", "Shrine", "Circle", "PromptAttachment")
    local spot = shrine and shrine.WorldPosition
    if spot then
        Char.Hop(spot)
        task.wait(0.5)
    end
    local ok, why = Net.Why(Net.Invoke("ShrineService", "Choose", work.Key))
    if ok then
        Events.ShrineNote = "blessing taken"
    else
        Events.Rest.shrine = os.clock() + 300
        Events.ShrineNote = ("shrine: %s"):format(tostring(why))
    end
end

function Events.OnBalloon(info)
    if type(info) ~= "table" or info.Uid == nil then
        return
    end
    Events.Balloons[info.Uid] = info
    Events.BalloonKick:Fire()
end

function Events.OnPopped(info)
    local uid = type(info) == "table" and info.Uid or info
    if uid ~= nil and Events.Balloons[uid] then
        Events.Balloons[uid] = nil
        Events.Popped += 1
    end
end

function Events.BalloonMods()
    local shared = Util.Path(ReplicatedStorage, "Shared", "Admin")
    local flight = shared and Util.Require(shared:FindFirstChild("BalloonFlight"), 5)
    local config = Game.Module("WorldEventConfig")
    return flight, config and config.Balloon or nil
end

function Events.BalloonIn()
    local now = os.time()
    local nextAt = Util.Num(Workspace:GetAttribute("Event_BalloonParty_NextStartAt"), 0)
    if Workspace:GetAttribute("Event_BalloonParty_Active") == true then
        return 0
    end
    return math.max(0, nextAt - now)
end

function Events.BalloonLoop()
    Util.AsIdentity(2)
    local flight, config = Events.BalloonMods()
    local lifetime = flight and Util.Num(flight.Lifetime, 25) or 25
    local hitRange = config and Util.Num(config.HitRange, 150) or 150
    local hitCooldown = config and Util.Num(config.HitCooldown, 0.1) or 0.1
    local order = { Golden = 5, Giant = 4, Big = 3, Medium = 2, Small = 1 }
    local lastHit = {}
    while not Library.Unloaded do
        if Library.Flags.AutoBalloons ~= true or next(Events.Balloons) == nil then
            Events.BalloonKick.Event:Wait()
        end
        if Library.Unloaded then
            break
        end
        local root = Char.Root()
        if root and Library.Flags.AutoBalloons == true then
            local now = os.clock()
            local best, bestScore, bestPos = nil, -1, nil
            for uid, balloon in Events.Balloons do
                local age = now - Util.Num(balloon.LaunchedAt and (os.clock() - (os.time() - balloon.LaunchedAt)) or now, now)
                local launchedAgo = os.time() - Util.Num(balloon.LaunchedAt, os.time())
                if launchedAgo >= lifetime then
                    Events.Balloons[uid] = nil
                elseif now - (lastHit[uid] or 0) >= math.max(hitCooldown + 0.02, 0.12) then
                    local pos = flight and Util.Fn(flight, "Position", balloon, launchedAgo) or balloon.Origin
                    if typeof(pos) == "Vector3" and (pos - root.Position).Magnitude <= hitRange - 5 then
                        local score = (order[balloon.Size] or 1) * 100 + launchedAgo
                        if score > bestScore then
                            best, bestScore, bestPos = uid, score, pos
                        end
                    end
                end
            end
            if best then
                lastHit[best] = now
                Net.Fire("BalloonPartyService", "Hit", best)
            end
        end
        task.wait(0.1)
    end
end

Mobs = { Note = "", Rest = {}, Killed = 0, Arrived = Instance.new("BindableEvent"), Titles = {} }

function Mobs.Config()
    return Game.Module("IslandBreakableConfig")
end

function Mobs.LoadTitles()
    local config = Mobs.Config()
    local titles = {}
    if config and type(config.Spots) == "table" then
        for _, spot in config.Spots do
            if spot.Title then
                table.insert(titles, spot.Title)
            end
        end
    end
    table.sort(titles)
    Mobs.Titles = titles
    return titles
end

function Mobs.Needed()
    local needed = {}
    if Library.Flags.AutoHoney ~= true then
        return needed
    end
    local config = Game.Module("HoneyPotConfig")
    local want = tostring(Library.Flags.HoneyPick or "")
    local recipe = config and type(config.ByKey) == "table" and config.ByKey[want] or nil
    if type(recipe) == "table" and type(recipe.Inputs) == "table" then
        local save = Data.Save
        for _, input in recipe.Inputs do
            local owned = save and save.Items and save.Items.Owned and Util.Num(save.Items.Owned[input.Key], 0) or 0
            if owned < Util.Num(input.Amount, 0) then
                needed[input.Key] = true
            end
        end
    end
    return needed
end

function Mobs.Due()
    if Library.Flags.AutoMobs ~= true then
        return nil
    end
    local config = Mobs.Config()
    if not config or type(config.Spots) ~= "table" then
        return nil
    end
    local spotsNode = Workspace:FindFirstChild("IslandBreakableSpots")
    if not spotsNode then
        return nil
    end
    local picks = Util.PickSet("MobPick")
    local needed = Mobs.Needed()
    local now = Workspace:GetServerTimeNow()
    local best, bestScore = nil, -1
    for id, spot in config.Spots do
        if (not picks or picks[spot.Title]) and Data.Islands()[spot.Island] == true and os.clock() >= (Mobs.Rest[id] or 0) then
            local readyAt = Util.Fn(config, "GetReadyAt", Data.Save, id)
            if readyAt == nil or Util.Num(readyAt, 0) <= now then
                local center = spotsNode:GetAttribute(id)
                if typeof(center) == "Vector3" then
                    local score = (spot.Ingredient and needed[spot.Ingredient] and 100 or 0) + (Data.Island() == spot.Island and 10 or 0)
                    if score > bestScore then
                        best, bestScore = { Id = id, Spot = center, Info = spot }, score
                    end
                end
            end
        end
    end
    return best
end

function Mobs.Find(mobType)
    for model in Brk.Live do
        if model:GetAttribute("BreakableType") == mobType
            and model:GetAttribute("BreakableOwner") == LocalPlayer.UserId
            and Brk.Usable(model) then
            return model
        end
    end
    return nil
end

function Mobs.Run(work)
    Mobs.Rest[work.Id] = os.clock() + 60
    if Data.Island() ~= work.Info.Island then
        World.Travel(work.Info.Island)
    end
    Char.Hop(work.Spot)
    local deadline = os.clock() + 6
    local model = Mobs.Find(work.Info.Type)
    while not model and os.clock() < deadline and not Library.Unloaded do
        Mobs.Arrived.Event:Wait()
        model = Mobs.Find(work.Info.Type)
    end
    if not model then
        Mobs.Note = work.Info.Title .. " did not show up"
        return
    end
    local started = os.clock()
    while Brk.Usable(model) and Library.Flags.AutoMobs == true and not Library.Unloaded and os.clock() - started < 45 do
        local blocked = Char.Blocked()
        if blocked ~= "" then
            Mobs.Note = "paused (" .. blocked .. ")"
            return
        end
        local spot = model:GetPivot().Position
        if Char.Flat(spot) > 9 or math.abs(spot.Y - Char.Root().Position.Y) > 10 then
            Char.Hop(Char.Beside(spot, 4, { model }))
        end
        if Tap.On() then
            task.wait(0.1)
        else
            Tap.Once()
            task.wait(Tap.Gap)
        end
    end
    if not Brk.Usable(model) then
        Mobs.Killed += 1
        Mobs.Rest[work.Id] = os.clock() + Util.Num(work.Info.Cooldown, 300)
        Mobs.Note = ("killed %s (+%s %s)"):format(work.Info.Title, tostring(work.Info.Amount or ""), tostring(work.Info.Ingredient or ""))
    end
end


--== World travel and unlocks, minigames ==--

World = { Note = "", Asked = {}, Samples = {}, CoinRate = 0, Result = Instance.new("BindableEvent") }

function World.Islands()
    local config = Game.Module("IslandConfig")
    local list = { "Spawn" }
    if config and type(config.Islands) == "table" then
        local rest = {}
        for name in config.Islands do
            table.insert(rest, name)
        end
        table.sort(rest, function(a, b)
            return Util.Num(config.Islands[a].Order, 0) < Util.Num(config.Islands[b].Order, 0)
        end)
        for _, name in rest do
            table.insert(list, name)
        end
    end
    return list
end

function World.Zones()
    local config = Game.Module("ProgressionConfig")
    local list = {}
    if config and type(config.Zones) == "table" then
        for name in config.Zones do
            table.insert(list, name)
        end
        table.sort(list, function(a, b)
            return Util.Num(config.Zones[a].Order, 0) < Util.Num(config.Zones[b].Order, 0)
        end)
    end
    return list
end

function World.Travel(island)
    if island ~= "Spawn" and Data.Islands()[island] ~= true then
        return false
    end
    if Data.Island() == island then
        return true
    end
    local ok = Net.Why(Net.Invoke("IslandService", "Travel", { Island = island, Source = "Menu" }))
    if not ok then
        return false
    end
    local deadline = os.clock() + 4
    while Data.Island() ~= island and os.clock() < deadline and not Library.Unloaded do
        task.wait(0.1)
    end
    task.wait(0.4)
    return Data.Island() == island
end

function World.TravelZone(zone)
    if Data.Zones()[zone] ~= true and zone ~= "Spawn" then
        return false
    end
    local ok = Net.Why(Net.Invoke("WorldService", "Travel", { Zone = zone, Source = "Menu" }))
    task.wait(0.4)
    return ok
end

function World.Best()
    local config = Game.Module("IslandConfig")
    local best, bestMult = "Spawn", 1
    if config and type(config.Islands) == "table" then
        for name, entry in config.Islands do
            if Data.Islands()[name] == true and Util.Num(entry.Multiplier, 1) > bestMult then
                best, bestMult = name, Util.Num(entry.Multiplier, 1)
            end
        end
    end
    return best
end

function World.NextIsland()
    local config = Game.Module("IslandConfig")
    if not config or type(config.Islands) ~= "table" then
        return nil
    end
    for _, name in World.Islands() do
        local entry = config.Islands[name]
        if entry and Data.Islands()[name] ~= true then
            return name, Util.Num(entry.Price, 0), entry.PortalName
        end
    end
    return nil
end

function World.NextZone()
    local config = Game.Module("ProgressionConfig")
    if not config or type(config.Zones) ~= "table" then
        return nil
    end
    for _, name in World.Zones() do
        local entry = config.Zones[name]
        if entry and Data.Zones()[name] ~= true and Util.Num(entry.Price, 0) > 0 then
            return name, Util.Num(entry.Price, 0)
        end
    end
    return nil
end

function World.Rate()
    local now = os.clock()
    table.insert(World.Samples, { At = now, Total = Data.Stat("LifetimeCoins") })
    while #World.Samples > 1 and now - World.Samples[1].At > 60 do
        table.remove(World.Samples, 1)
    end
    local first, last = World.Samples[1], World.Samples[#World.Samples]
    if first and last and last.At - first.At > 5 then
        World.CoinRate = math.max(0, (last.Total - first.Total) / (last.At - first.At))
    end
    return World.CoinRate
end

function World.Saving()
    if Library.Flags.AutoUnlock ~= true or Library.Flags.SaveForUnlock ~= true then
        return nil
    end
    local name, price = World.NextIsland()
    if not name then
        return nil
    end
    if Data.Coins() >= price then
        return nil
    end
    if price <= math.max(Data.Coins(), World.CoinRate * 600) then
        return name, price
    end
    return nil
end

function World.Portal(kind, name, portalName, waitFor)
    local root = Workspace:FindFirstChild("Portals")
    if kind == "Island" then
        local portals = root and root:FindFirstChild("Portals")
        local portal = portals and portalName and portals:FindFirstChild(portalName)
        return portal and portal:FindFirstChild("Portal"), portal
    end
    local zones = root and root:FindFirstChild("Zones")
    local zoneFolder = zones and zones:FindFirstChild("Portals")
    local entry = zoneFolder and zoneFolder:FindFirstChild(name)
    if entry then
        local part = entry:FindFirstChild("Portal", true)
        return part, entry
    end
    return nil
end

function World.Answer(service, event, payload)
    task.spawn(function()
        Util.AsIdentity(2)
        local controller = Game.C.MessageController
        local deadline = os.clock() + 1.5
        local opened = false
        while os.clock() < deadline do
            if controller and Util.Method(controller, "IsOpen") == true then
                opened = true
                break
            end
            task.wait(0.1)
        end
        if opened and controller then
            Util.Method(controller, "Confirm")
        else
            Net.Fire(service, event, payload)
        end
    end)
end

function World.OnIsland(info)
    if type(info) ~= "table" or info.Action ~= "Purchase" or Library.Flags.AutoUnlock ~= true then
        return
    end
    World.Answer("IslandService", "IslandUnlockRequested", { Action = "Purchase", Island = info.Island })
end

function World.OnZone(info)
    if type(info) ~= "table" or Library.Flags.AutoUnlock ~= true then
        return
    end
    World.Answer("WorldService", "ZoneUnlockRequested", { Action = "Purchase", Zone = info.Zone })
end

function World.OnResult()
    World.Result:Fire()
end

function World.Errand()
    if Library.Flags.AutoUnlock ~= true then
        return nil
    end
    local now = os.clock()
    local zone, zonePrice = World.NextZone()
    if zone and Data.Coins() >= zonePrice and now >= (World.Asked["z" .. zone] or 0) then
        local part = World.Portal("Zone", zone)
        if part then
            return { Kind = "Zone", Name = zone }
        end
    end
    local island, price, portalName = World.NextIsland()
    if island then
        if Data.Coins() < price then
            World.Note = "next unlock at " .. Util.Short(price) .. " coins"
            Need.Set("move", "Coins", price)
            return nil
        end
        if now >= (World.Asked["i" .. island] or 0) then
            return { Kind = "Island", Name = island, Portal = portalName }
        end
    end
    return nil
end

function World.Unlock(kind, name, portalName)
    World.Asked[(kind == "Zone" and "z" or "i") .. name] = os.clock() + 30
    if kind == "Island" then
        World.Travel("Spawn")
    end
    local part = nil
    local deadline = os.clock() + 8
    while not part and os.clock() < deadline and not Library.Unloaded do
        part = World.Portal(kind, name, portalName)
        if not part then
            task.wait(0.25)
        end
    end
    if not part then
        World.Note = name .. " portal not streamed in"
        return false
    end
    local pos = part:IsA("BasePart") and part.Position or part:GetPivot().Position
    -- Stand in front first, then step in: the server only registers the entry.
    local stand = Char.Beside(pos, 12, { part })
    Char.Hop(stand)
    task.wait(0.6)
    World.ResultDone = false
    Char.Hop(typeof(part) == "Instance" and part:IsA("BasePart") and CFrame.new(pos) or part:GetPivot())
    local waitDeadline = os.clock() + 6
    local answered = false
    local link = World.Result.Event:Connect(function()
        answered = true
    end)
    while not answered and os.clock() < waitDeadline and not Library.Unloaded do
        task.wait(0.1)
    end
    link:Disconnect()
    task.wait(0.5)
    local owned = kind == "Zone" and Data.Zones()[name] == true or Data.Islands()[name] == true
    if owned then
        State.Bought += 1
        World.Note = "unlocked " .. name
    end
    return owned
end

function World.BridgeDue()
    if Library.Flags.AutoUnlock ~= true or os.clock() < (World.Asked.bridge or 0) then
        return false
    end
    local save = Data.Save
    if not save or save.Progression.BridgeLowered == true then
        return false
    end
    local config = Game.Module("OnboardingConfig")
    if not config then
        return false
    end
    return Util.Fn(config, "BridgeFightUnlocked", save) == true
        and Util.Fn(config, "BridgeChallengeReady", save) == true
end

function World.Bridge()
    World.Asked.bridge = os.clock() + 120
    World.Travel("Spawn")
    local ring = Workspace:FindFirstChild("BridgeStandRing", true)
    if ring and ring:IsA("BasePart") then
        Char.Hop(ring.Position + Vector3.new(0, 3, 0))
    end
    local save = Data.Save
    local started = os.clock()
    while save and save.Progression.BridgeLowered ~= true and Library.Flags.AutoUnlock == true
        and not Library.Unloaded and os.clock() - started < 75 do
        if Library.Flags.AutoTap == true then
            task.wait(0.3)
        else
            Tap.Once()
            task.wait(Tap.Gap)
        end
        save = Data.Save
    end
end

Arena = {
    Note = "", Foes = {}, Over = nil, Wave = 0, Hearts = 0, Active = false, Inflight = 0,
    Count = { Sent = 0, Killed = 0, Refused = 0 }, RewardRest = 0, Links = {},
    RELICS = { "Take Better Relic", "Take New Relic", "Keep Current Relic", "Leave It" },
}

function Arena.ReadyIn()
    local save = Data.Save
    local cooldown = save and save.Colosseum and Util.Num(save.Colosseum.Cooldown, 0) or 0
    return math.max(0, cooldown + 1800 - Workspace:GetServerTimeNow())
end

function Arena.Due()
    if Library.Flags.AutoArena ~= true then
        return false
    end
    if Hallow.BossSoon(600) then
        return false
    end
    local wait = Arena.ReadyIn()
    if wait > 0 then
        Mover:At("move", wait + 1)
        return false
    end
    return true
end

function Arena.Bind()
    local links = {}
    local function on(event, fn)
        local link = Net.On("ColosseumService", event, fn)
        if link then
            table.insert(links, link)
        end
    end
    on("WaveDefenseOpponentSpawned", function(info)
        if type(info) == "table" and type(info.Foe) == "table" and info.Foe.Id ~= nil then
            Arena.Foes[info.Foe.Id] = Util.Num(info.Foe.ArrivalTime, math.huge)
        end
    end)
    on("WaveDefenseOpponentDefeated", function(info)
        if type(info) == "table" and info.OpponentId ~= nil then
            Arena.Foes[info.OpponentId] = nil
            Arena.Count.Killed += 1
        end
    end)
    on("WaveDefenseHeartLost", function(info)
        if type(info) ~= "table" then
            return
        end
        if info.OpponentId ~= nil then
            Arena.Foes[info.OpponentId] = nil
        end
        Arena.Hearts = Util.Num(info.Hearts, Arena.Hearts)
    end)
    on("WaveDefenseWaveStarting", function(info)
        if type(info) ~= "table" then
            return
        end
        Arena.Wave = Util.Num(info.Wave, Arena.Wave)
        for _, spawn in (type(info.PendingSpawns) == "table" and info.PendingSpawns or {}) do
            if type(spawn) == "table" and spawn.Id ~= nil then
                Arena.Foes[spawn.Id] = Util.Num(spawn.ArrivalTime, math.huge)
            end
        end
    end)
    on("WaveDefenseGameOver", function(info)
        Arena.Over = type(info) == "table" and info or {}
    end)
    Arena.Links = links
    return links
end

function Arena.Unbind()
    for _, link in Arena.Links do
        pcall(link.Disconnect, link)
    end
    Arena.Links = {}
end

function Arena.Urgent()
    local best, bestAt = nil, math.huge
    for id, at in Arena.Foes do
        if at < bestAt then
            best, bestAt = id, at
        end
    end
    return best
end

function Arena.Strike(critical, id)
    Arena.Inflight += 1
    task.spawn(function()
        Util.AsIdentity(2)
        local result = critical and Net.Invoke("ColosseumService", "CriticalAttackOpponent", id)
            or Net.Invoke("ColosseumService", "AttackOpponent", id)
        Arena.Inflight = math.max(0, Arena.Inflight - 1)
        if type(result) == "table" then
            if result.Error then
                Arena.Count.Refused += 1
            elseif result.Defeated then
                Arena.Foes[id] = nil
                Arena.Count.Killed += 1
            elseif result.NewArrivalTime then
                Arena.Foes[id] = Util.Num(result.NewArrivalTime, math.huge)
            end
        end
    end)
end

function Arena.Run()
    local point = Char.Point("Colosseum")
    if not point then
        Arena.Note = "arena entrance not here"
        return
    end
    Char.Hop(point.Position + Vector3.new(0, 3, 0))
    task.wait(0.8)
    local message = Game.C.MessageController
    if message and Util.Method(message, "IsOpen") == true then
        Util.Method(message, "Cancel")
    end
    Arena.Foes, Arena.Over, Arena.Wave, Arena.Hearts = {}, nil, 0, 0
    Arena.Active = true
    Arena.Bind()
    local start = Net.Invoke("ColosseumService", "StartWaveDefense")
    if type(start) ~= "table" or start.Error or start.OnCooldown then
        Arena.Note = "pet defense refused"
        Arena.Active = false
        Arena.Unbind()
        Mover:Later("move", 60)
        return
    end
    Arena.Hearts = Util.Num(start.Hearts, 0)
    Arena.Wave = Util.Num(start.CurrentWave, 0)
    for _, spawn in (type(start.PendingSpawns) == "table" and start.PendingSpawns or {}) do
        if type(spawn) == "table" and spawn.Id ~= nil then
            Arena.Foes[spawn.Id] = Util.Num(spawn.ArrivalTime, math.huge)
        end
    end
    local started = os.clock()
    local lastCrit = 0
    while Arena.Over == nil and Library.Flags.AutoArena == true and not Library.Unloaded and os.clock() - started < 600 do
        local target = Arena.Urgent()
        if target ~= nil and Arena.Inflight < 4 then
            local critical = os.clock() - lastCrit >= 5 + math.random() * 4
            if critical then
                lastCrit = os.clock()
            end
            Arena.Count.Sent += 1
            Arena.Strike(critical, target)
        end
        Arena.Note = ("wave %d  %d hearts"):format(Arena.Wave, Arena.Hearts)
        task.wait(0.15 + math.random() * 0.03)
    end
    if Arena.Over == nil then
        Net.Invoke("ColosseumService", "EndWaveDefense")
        Arena.Note = "left the run"
    else
        Arena.Note = ("run over: %s waves%s"):format(tostring(Arena.Over.WavesCompleted or 0), Arena.Over.NewBest and " (new best)" or "")
    end
    State.Played += 1
    Webhook.Push({ Kind = "arena", Title = "Pet Defense", Name = Arena.Note })
    Arena.Active = false
    Arena.Unbind()
    task.wait(1)
    Net.Invoke("ColosseumService", "ReturnFromArena")
    Popup.WaveHud()
    task.wait(1.5)
    Arena.Reward()
end

function Arena.Pending()
    local save = Data.Save
    return save ~= nil and save.Colosseum ~= nil and save.Colosseum.PendingReward ~= nil
        and not Arena.Active and os.clock() >= Arena.RewardRest
        and tostring(Library.Flags.ArenaRelic or "") ~= "Leave It"
end

function Arena.RelicScore(relic)
    local config = Game.Module("ColosseumRelicConfig")
    if not config or type(relic) ~= "table" or type(relic.Boosts) ~= "table" then
        return 0
    end
    local maxByType = {}
    for _, slot in (config.Slots or {}) do
        for _, ring in (slot.Relics or {}) do
            for _, boost in (ring.Boosts or {}) do
                local value = type(boost.Value) == "table" and Util.Num(boost.Value[2], 0) or Util.Num(boost.Value, 0)
                maxByType[boost.Type] = math.max(maxByType[boost.Type] or 0, value)
            end
        end
    end
    local score = 0
    for _, boost in relic.Boosts do
        local value = type(boost.Value) == "table" and Util.Num(boost.Value[1], 0) or Util.Num(boost.Value, 0)
        local max = maxByType[boost.Type] or 0
        if max > 0 then
            score += value / max
        end
    end
    return score
end

function Arena.Reward()
    if not Arena.Pending() then
        return false
    end
    local save = Data.Save
    local pending = save.Colosseum.PendingReward
    local choice = tostring(Library.Flags.ArenaRelic or "Take Better Relic")
    local take = choice == "Take New Relic"
        or (choice == "Take Better Relic" and Arena.RelicScore(pending.NewRelic) > Arena.RelicScore(save.Colosseum.Relic))
    local ok = Net.Why(Net.Invoke("ColosseumService", "ClaimMinigameReward", take and "replace" or "keep"))
    Arena.RewardRest = os.clock() + 30
    Arena.Note = ok and (take and "took the new relic" or "kept the current relic") or "relic offer refused"
    return ok
end

Memory = { Note = "" }

function Memory.ReadyIn()
    local save = Data.Save
    local nextPlay = save and save.MemoryMatch and Util.Num(save.MemoryMatch.NextPlay, 0) or 0
    return math.max(0, nextPlay - Workspace:GetServerTimeNow())
end

function Memory.Due()
    if Library.Flags.AutoMemory ~= true then
        return false
    end
    local wait = Memory.ReadyIn()
    if wait > 0 then
        Mover:At("move", wait + 1)
        return false
    end
    return true
end

function Memory.Run()
    local pad = Util.Path(Workspace, "MemoryMatch", "TouchToPlay")
    if not pad then
        Memory.Note = "memory board not here"
        return
    end
    Char.Hop(pad.Position + Vector3.new(0, 4, 6))
    task.wait(0.8)
    local board = Net.Invoke("MemoryMatchService", "Open", true)
    if type(board) ~= "table" or board.Error or board.Outcome ~= "Playing" then
        Memory.Note = "memory match refused"
        Mover:Later("move", 60)
        return
    end
    local seen, matched = {}, {}
    local function learn(state)
        if type(state.Cards) == "table" then
            for index, card in state.Cards do
                if type(card) == "table" then
                    if card.Pet then
                        seen[index] = card.Pet
                    end
                    if card.Matched then
                        matched[index] = true
                    end
                end
            end
        end
    end
    learn(board)
    local id = board.Id
    local rounds = 0
    while type(board) == "table" and board.Outcome == "Playing" and rounds < 40 and not Library.Unloaded do
        rounds += 1
        local first, second = nil, nil
        for i = 1, 12 do
            if seen[i] and not matched[i] then
                for j = i + 1, 12 do
                    if seen[j] == seen[i] and not matched[j] then
                        first, second = i, j
                        break
                    end
                end
            end
            if first then
                break
            end
        end
        local function flip(index)
            local unlockAt = Util.Num(board.UnlockAt, 0)
            local waitFor = unlockAt - Workspace:GetServerTimeNow()
            if waitFor > 0 then
                task.wait(waitFor)
            end
            task.wait(0.3 + math.random() * 0.2)
            board = Net.Invoke("MemoryMatchService", "Flip", id, index)
            if type(board) == "table" then
                learn(board)
            end
        end
        if first then
            flip(first)
            if type(board) == "table" and board.Outcome == "Playing" then
                flip(second)
            end
        else
            for i = 1, 12 do
                if not seen[i] and not matched[i] then
                    first = i
                    break
                end
            end
            if not first then
                break
            end
            flip(first)
            if type(board) ~= "table" or board.Outcome ~= "Playing" then
                break
            end
            local mate = nil
            for j = 1, 12 do
                if j ~= first and seen[j] == seen[first] and not matched[j] then
                    mate = j
                    break
                end
            end
            if mate then
                flip(mate)
            else
                for j = 1, 12 do
                    if j ~= first and not seen[j] and not matched[j] then
                        flip(j)
                        break
                    end
                end
            end
        end
    end
    State.Played += 1
    if type(board) == "table" and board.Outcome ~= "Playing" then
        Memory.Note = board.Reward and ("won: " .. tostring(board.Reward)) or tostring(board.Outcome)
    else
        Memory.Note = "board unfinished"
    end
end

Dig = { Note = "", Until = 0 }

function Dig.Zone()
    local zone = Util.Path(Workspace, "Ts2Islands", "Autumn", "Digsite", "DigZone")
    return zone and zone:IsA("BasePart") and zone or nil
end

function Dig.Due()
    if Library.Flags.AutoDig ~= true or os.clock() < Dig.Until then
        return false
    end
    if Data.Islands()["Autumn"] ~= true then
        return false
    end
    local config = Game.Module("DigConfig")
    local save = Data.Save
    if config and type(config.Allowance) == "function" then
        local left, waitFor = Util.Fn(config, "Allowance", save and save.Digging, Workspace:GetServerTimeNow())
        if left ~= nil and Util.Num(left, 0) <= 0 then
            Dig.Until = os.clock() + math.max(30, Util.Num(waitFor, 30))
            return false
        end
    end
    return true
end

-- Closed-form scan for the next hit window; one wait to its middle, no frame polling.
function Dig.Window(config, round, from)
    if type(config.IsHit) ~= "function" then
        return nil
    end
    local start = math.max(from, Util.Num(round.Epoch, 0) + 0.02)
    local steps = 0
    local hitStart = nil
    local t = start
    while steps < 800 do
        steps += 1
        if Util.Call(config.IsHit, round, t) == true then
            hitStart = hitStart or t
            if t - hitStart >= 3 then
                break
            end
        elseif hitStart then
            return (hitStart + t) / 2
        end
        t += 0.01
    end
    if hitStart then
        return (hitStart + t) / 2
    end
    return nil
end

function Dig.Run()
    if Data.Island() ~= "Autumn" then
        World.Travel("Autumn")
    end
    local zone = Dig.Zone()
    if not zone then
        Dig.Note = "digsite not here"
        return
    end
    Char.Hop(zone.Position + Vector3.new(0, zone.Size.Y / 2 + 3, 0))
    task.wait(0.8)
    local state = Net.Invoke("DigService", "Begin")
    if type(state) ~= "table" or state.Error then
        local why = type(state) == "table" and tostring(state.Error or "refused") or "refused"
        if why == "Cooldown" and type(state) == "table" then
            Dig.Until = os.clock() + Util.Num(state.Remaining, 60)
        else
            Dig.Until = os.clock() + 60
        end
        Dig.Note = "dig: " .. why
        return
    end
    local config = Game.Module("DigConfig")
    local id, round = state.Id, state.Round
    local last = 0
    local hits = 0
    while type(state) == "table" and not state.Complete and round and hits < 60 and not Library.Unloaded do
        local now = Workspace:GetServerTimeNow()
        local from = math.max(now + 0.05, last + Util.Num(config and config.MinHitInterval, 0.16) + 0.02)
        local at = config and Dig.Window(config, round, from) or nil
        if not at then
            break
        end
        local delay = at - Workspace:GetServerTimeNow()
        if delay > 0 then
            task.wait(delay)
        end
        local reply = Net.Invoke("DigService", "Hit", id, round.Sequence, at)
        hits += 1
        if type(reply) ~= "table" then
            break
        end
        if reply.Error then
            if reply.Error == "TooSoon" or reply.Error == "Busy" or reply.Error == "ClockSync" then
                last = Workspace:GetServerTimeNow()
                state = reply
                round = reply.Round or round
                continue
            end
            Dig.Note = "dig: " .. tostring(reply.Error)
            break
        end
        last = at
        state = reply
        round = reply.Round or round
    end
    if type(state) == "table" and state.Complete then
        State.Played += 1
        Dig.Note = "dug up " .. tostring(state.Reward or "a reward")
    end
end


--== Mining (Crystal Cave) ==--

Mine = {
    Note = "", Until = 0, Skip = {}, Changed = Instance.new("BindableEvent"), M = nil, Hooks = nil,
    Id = nil, Seed = nil, Goal = nil, BestAt = 0, DailyNames = {}, DailyIds = {},
    Session = 180, WORTH = 0.025, MOVED_FLAGS = {},
}

function Mine.On()
    return Library.Flags.AutoMine == true and not Library.Unloaded
end

function Mine.Due()
    if not Mine.On() or os.clock() < Mine.Until then
        return false
    end
    return Data.Islands()["Crystal Cave"] == true
end

function Mine.Mods()
    if Mine.M then
        return Mine.M
    end
    local base = Util.Path(ReplicatedStorage, "Shared", "Minigames", "Mining")
    if not base then
        return nil
    end
    local mods = {
        Config = Util.Require(base:FindFirstChild("MiningConfig"), 6),
        Sight = Util.Require(base:FindFirstChild("MiningSight"), 6),
        World = Util.Require(base:FindFirstChild("MiningWorld"), 6),
        DailyShop = Util.Require(base:FindFirstChild("DailyShop"), 6),
    }
    if not mods.Config then
        return nil
    end
    Mine.M = mods
    return mods
end

function Mine.Ctrl()
    local folder = Util.Path(ReplicatedStorage, "Controllers", "Minigames")
    local ctrl = folder and folder:FindFirstChild("MiningController")
    return ctrl and Util.Require(ctrl, 6) or nil
end

-- The live mine state only exists in the controller's closures; find the
-- removeCell function and read its upvalues by shape.
function Mine.HooksFrom(ctrl)
    if Mine.Hooks then
        return Mine.Hooks
    end
    if not ctrl or type(ctrl.Init) ~= "function" or type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then
        return nil
    end
    local ok, upvalues = pcall(debug.getupvalues, ctrl.Init)
    if not ok or type(upvalues) ~= "table" then
        return nil
    end
    local removeFn = nil
    for _, value in upvalues do
        if type(value) == "function" then
            local ok2, inner = pcall(debug.getupvalues, value)
            if ok2 and type(inner) == "table" then
                local hasMarker, hasRemoved = false, false
                for _, innerValue in inner do
                    if typeof(innerValue) == "Instance" and innerValue:IsA("BasePart") then
                        hasMarker = true
                    elseif type(innerValue) == "table" and innerValue ~= inner then
                        local allTrue = true
                        for _, flag in innerValue do
                            if flag ~= true then
                                allTrue = false
                                break
                            end
                        end
                        if allTrue then
                            hasRemoved = true
                        end
                    end
                end
                if hasMarker and hasRemoved then
                    removeFn = value
                    break
                end
            end
        end
    end
    if not removeFn then
        return nil
    end
    local ok3, cells = pcall(debug.getupvalues, removeFn)
    if not ok3 or type(cells) ~= "table" then
        return nil
    end
    local hooks = { Remove = removeFn }
    for _, value in cells do
        if typeof(value) == "Instance" and value:IsA("BasePart") then
            hooks.Marker = value
        elseif type(value) == "table" then
            local vectorKeys, trueValues = 0, 0
            for key, flag in value do
                if typeof(key) == "Vector3" then
                    vectorKeys += 1
                end
                if flag == true then
                    trueValues += 1
                end
            end
            if vectorKeys > 0 then
                hooks.Exposed = value
            elseif trueValues > 0 then
                hooks.Removed = value
            end
        end
    end
    if hooks.Marker and hooks.Removed then
        Mine.Hooks = hooks
        return hooks
    end
    return nil
end

function Mine.Live()
    if LocalPlayer:GetAttribute("MiningActive") ~= true then
        return nil
    end
    local ctrl = Mine.Ctrl()
    if not ctrl then
        return nil
    end
    local state = Util.Method(ctrl, "GetState")
    if type(state) ~= "table" then
        return nil
    end
    if state.Id ~= nil then
        Mine.Id = state.Id
    end
    if state.Seed ~= nil then
        Mine.Seed = state.Seed
    end
    local hooks = Mine.HooksFrom(ctrl)
    if not hooks then
        return nil
    end
    return { Ctrl = ctrl, State = state, Hooks = hooks, Mods = Mine.Mods() }
end

function Mine.Bag()
    local save = Data.Save
    local mining = save and save.Mining
    if type(mining) ~= "table" then
        return 0, 0
    end
    local count = 0
    for _, amount in (mining.Bag or {}) do
        count += Util.Num(amount, 0)
    end
    local mods = Mine.Mods()
    local capacity = math.huge
    if mods and mods.Config and type(mods.Config.Bags) == "table" then
        local bag = mods.Config.Bags[Util.Num(mining.Backpack, 1)]
        if bag then
            capacity = Util.Num(bag.Capacity or bag.Size, math.huge)
        end
    end
    return count, capacity
end

function Mine.Portal()
    local islands = Workspace:FindFirstChild("Ts2Islands")
    local cave = islands and islands:FindFirstChild("Crystal Cave")
    local decor = cave and cave:FindFirstChild("Decor")
    local trees = decor and decor:FindFirstChild("Trees")
    if not trees then
        return nil
    end
    local function search(node)
        if node.Name == "Teleport" and node:IsA("BasePart") then
            return node
        end
        for _, child in node:GetChildren() do
            local hit = search(child)
            if hit then
                return hit
            end
        end
        return nil
    end
    return search(trees)
end

function Mine.Enter()
    if LocalPlayer:GetAttribute("MiningActive") == true then
        return Mine.Live() ~= nil
    end
    if Data.Island() ~= "Crystal Cave" then
        World.Travel("Crystal Cave")
    end
    local portal = Mine.Portal()
    if not portal then
        Mine.Note = "mine portal not streamed in"
        return false
    end
    Char.Hop(portal.CFrame)
    local deadline = os.clock() + 25
    while LocalPlayer:GetAttribute("MiningActive") ~= true and os.clock() < deadline and not Library.Unloaded do
        task.wait(0.25)
    end
    if LocalPlayer:GetAttribute("MiningActive") ~= true then
        return false
    end
    local liveDeadline = os.clock() + 8
    while os.clock() < liveDeadline and not Library.Unloaded do
        if Mine.Live() then
            return true
        end
        task.wait(0.25)
    end
    return false
end

function Mine.Rarity(live, x, y, z)
    local config = live.Mods.Config
    local ore = Util.Fn(config, "Ore", live.Seed, x, y, z)
    if type(ore) ~= "table" then
        return nil
    end
    return ore
end

-- Rarest reachable ore worth chasing; cache the scan briefly.
function Mine.Target(live)
    if os.clock() - Mine.BestAt < 4 and Mine.Goal then
        return Mine.Goal
    end
    local config = live.Mods.Config
    local dims = config.Dimensions
    if type(dims) ~= "table" then
        return nil
    end
    local toolIndex = Util.Num(Data.Save and Data.Save.Mining and Data.Save.Mining.Tool, 1)
    local tool = type(config.Tools) == "table" and config.Tools[toolIndex] or nil
    local power = tool and Util.Num(tool.Power, 0) or 0
    local best, bestRarity, bestDepth = nil, -1, math.huge
    local size = Util.Num(dims.X or dims[1], 0)
    local height = Util.Num(dims.Y or dims[2], 0)
    local depthSize = Util.Num(dims.Z or dims[3], 0)
    for x = 0, size - 1 do
        for y = 0, height - 1 do
            for z = 0, depthSize - 1 do
                local key = Util.Fn(config, "Key", x, y, z)
                if not (live.Hooks.Removed and key and live.Hooks.Removed[key]) and os.clock() >= (Mine.Skip[key or ""] or 0) then
                    local ore = Mine.Rarity(live, x, y, z)
                    if ore then
                        local need = config.Stats and config.Stats.pickaxeRequirement and Util.Num(config.Stats.pickaxeRequirement[ore.rarity], 0) or 0
                        if need <= power then
                            local rarity = Util.Num(ore.rarity, 0)
                            if rarity > bestRarity or (rarity == bestRarity and y < bestDepth) then
                                best, bestRarity, bestDepth = { X = x, Y = y, Z = z, Key = key, Ore = ore }, rarity, y
                            end
                        end
                    end
                end
            end
        end
    end
    Mine.BestAt = os.clock()
    Mine.Goal = best
    return best
end

function Mine.PositionOf(live, cell)
    local config = live.Mods.Config
    local pos = Util.Fn(config, "Position", cell.X, cell.Y, cell.Z)
    return typeof(pos) == "Vector3" and pos or nil
end

function Mine.Stand(live, cell)
    -- On top when the two cells above are open, else an open floored side cell.
    local config = live.Mods.Config
    local removed = live.Hooks.Removed or {}
    local function open(x, y, z)
        local key = Util.Fn(config, "Key", x, y, z)
        return key and removed[key] == true
    end
    local base = Mine.PositionOf(live, cell)
    if not base then
        return nil
    end
    local block = Util.Num(config.BlockSize, 4)
    if open(cell.X, cell.Y + 1, cell.Z) and open(cell.X, cell.Y + 2, cell.Z) then
        return base + Vector3.new(0, block, 0)
    end
    for _, delta in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
        local sx, sz = cell.X + delta[1], cell.Z + delta[2]
        if open(sx, cell.Y, sz) and open(sx, cell.Y + 1, sz) and not open(sx, cell.Y - 1, sz) then
            local side = Mine.PositionOf(live, { X = sx, Y = cell.Y, Z = sz })
            if side then
                return side
            end
        end
    end
    return base + Vector3.new(0, block, 0)
end

function Mine.CanHit(live, cell, eye)
    local config = live.Mods.Config
    local toolIndex = Util.Num(Data.Save and Data.Save.Mining and Data.Save.Mining.Tool, 1)
    local tool = type(config.Tools) == "table" and config.Tools[toolIndex] or nil
    local range = tool and Util.Num(tool.Range, 12) or 12
    local pos = Mine.PositionOf(live, cell)
    if not pos or (pos - eye).Magnitude > range - 1 then
        return false
    end
    local sight = live.Mods.Sight
    if sight and type(sight.CanSee) == "function" then
        return Util.Fn(sight, "CanSee", live.Hooks.Marker, live.Hooks.Removed, eye, cell.X, cell.Y, cell.Z) == true
    end
    return true
end

function Mine.Pick(live)
    local root = Char.Root()
    if not root then
        return nil
    end
    local eye = root.Position + Vector3.new(0, 1.5, 0)
    local exposed = live.Hooks.Exposed or {}
    local target = Mine.Target(live)
    local seen, seenCount = {}, 0
    for pos in exposed do
        if typeof(pos) == "Vector3" then
            seenCount += 1
            if seenCount <= 24 then
                table.insert(seen, pos)
            end
        end
    end
    -- Exposed cells are keyed by position in the hook table; map back to cells
    -- through the config key of the target column when possible.
    if target then
        local stand = Mine.Stand(live, target)
        if stand and Mine.CanHit(live, target, stand + Vector3.new(0, 1.5, 0)) then
            return target, stand
        end
        if stand then
            return nil, stand, target
        end
    end
    return nil, nil, target
end

function Mine.Swing(live, cell)
    local result = Net.Invoke("MiningService", "Hit", Mine.Id, cell.X, cell.Y, cell.Z)
    if type(result) ~= "table" then
        return false
    end
    if result.Error then
        if cell.Key then
            Mine.Skip[cell.Key] = os.clock() + 30
        end
        return false
    end
    if result.Broken then
        if live.Hooks.Remove and cell.Key then
            pcall(live.Hooks.Remove, cell.Key)
        end
        local folder = Util.Path(ReplicatedStorage, "Controllers", "Minigames")
        local dropCtrl = folder and folder:FindFirstChild("MiningPresentation")
        if result.Drop and dropCtrl then
            local presentation = Util.Require(dropCtrl, 5)
            local dropController = presentation and presentation.DropController
            if dropController then
                Util.Method(dropController, "Add", result.Drop)
            end
        end
        State.Mined = (State.Mined or 0) + 1
        local config = live.Mods.Config
        local toolIndex = Util.Num(Data.Save and Data.Save.Mining and Data.Save.Mining.Tool, 1)
        local tool = type(config.Tools) == "table" and config.Tools[toolIndex] or nil
        task.wait((tool and Util.Num(tool.Interval, 0.3) or 0.3) + 0.03)
    end
    return true
end

function Mine.Sell(live)
    local world = live.Mods.World
    local pad = world and Util.Fn(world, "Part", "Sell")
    if pad and pad:IsA("BasePart") then
        Char.Hop(pad.Position + Vector3.new(0, 3, 0))
    end
    local before = Data.Save and Data.Save.Mining and Util.Num(Data.Save.Mining.Coins, 0) or 0
    local deadline = os.clock() + 4
    local sold = false
    while os.clock() < deadline and not Library.Unloaded do
        local now = Data.Save and Data.Save.Mining and Util.Num(Data.Save.Mining.Coins, 0) or 0
        if now ~= before then
            sold = true
            break
        end
        task.wait(0.2)
    end
    if not sold then
        Net.Invoke("MiningService", "Sell")
    end
    Mine.Note = "sold the backpack"
    Mine.Gear(live)
    Mine.Daily(live)
    return true
end

function Mine.Gear(live)
    if Library.Flags.MineGear ~= true then
        return
    end
    local world = live.Mods.World
    local pad = world and Util.Fn(world, "Part", "Shop")
    if pad and pad:IsA("BasePart") then
        Char.Hop(pad.Position + Vector3.new(0, 3, 0))
        task.wait(0.3)
    end
    local config = live.Mods.Config
    local mining = Data.Save and Data.Save.Mining
    if not mining then
        return
    end
    local coins = Util.Num(mining.Coins, 0)
    local function buy(kind, list, current)
        if type(list) ~= "table" then
            return
        end
        local bestOwned, bestAffordable = current, nil
        for index, entry in list do
            if type(entry) == "table" then
                local price = Util.Num(entry.Price, math.huge)
                if entry.Owned == true or price <= 0 then
                    bestOwned = math.max(bestOwned, index)
                elseif price <= coins then
                    bestAffordable = index
                end
            end
        end
        local want = bestAffordable or (bestOwned > current and bestOwned or nil)
        if want and want ~= current then
            local entry = list[want]
            local action = entry.Owned and ("Equip" .. kind) or ("Buy" .. kind)
            local result = Net.Invoke("MiningService", "Purchase", action, entry.Name)
            if type(result) == "table" and result.Error then
                Mine.Until = os.clock() + 10
            end
            task.wait(0.4)
        end
    end
    buy("Tool", config.Tools, Util.Num(mining.Tool, 1))
    buy("Storage", config.Bags, Util.Num(mining.Backpack, 1))
end

function Mine.LoadDaily()
    local base = Util.Path(ReplicatedStorage, "Shared", "Minigames", "Mining")
    local shop = base and Util.Require(base:FindFirstChild("DailyShop"), 6)
    Mine.DailyNames, Mine.DailyIds = {}, {}
    if shop and type(shop.Pool) == "table" then
        for _, item in shop.Pool do
            if type(item) == "table" then
                local name = tostring(item.Name or item.Id or "")
                if name ~= "" then
                    table.insert(Mine.DailyNames, name)
                    Mine.DailyIds[name] = item.Id or name
                end
            end
        end
    end
    return Mine.DailyNames
end

function Mine.Daily(live)
    if Library.Flags.MineDaily ~= true then
        return
    end
    local shop = live.Mods.DailyShop
    if not shop then
        return
    end
    local day = Util.Fn(shop, "Day", Workspace:GetServerTimeNow())
    local offers = Util.Fn(shop, "Offers", day)
    if type(offers) ~= "table" then
        return
    end
    local picks = Util.PickSet("MineDailyPick")
    local sorted = {}
    for _, offer in offers do
        table.insert(sorted, offer)
    end
    table.sort(sorted, function(a, b)
        return Util.Num(a.Price, 0) > Util.Num(b.Price, 0)
    end)
    local world = live.Mods.World
    local pad = world and Util.Fn(world, "Part", "Daily")
    local mining = Data.Save and Data.Save.Mining
    local coins = mining and Util.Num(mining.Coins, 0) or 0
    local hopped = false
    for _, offer in sorted do
        local name = tostring(offer.Name or offer.Id or "")
        if name ~= "" and (not picks or picks[name]) then
            local isTitle = offer.Title == true or offer.Kind == "Title"
            local ownedTitles = Data.Save and Data.Save.Titles and Data.Save.Titles.Owned or {}
            if not (isTitle and ownedTitles[name]) then
                local left = Util.Fn(shop, "Left", Data.Save, day, offer)
                local count = math.min(Util.Num(left, isTitle and 1 or 5), isTitle and 1 or 5)
                local price = Util.Num(offer.Price, math.huge)
                while count > 0 and coins >= price do
                    if not hopped and pad and pad:IsA("BasePart") then
                        Char.Hop(pad.Position + Vector3.new(0, 3, 0))
                        hopped = true
                        task.wait(0.3)
                    end
                    local result = Net.Invoke("MiningService", "DailyBuy", offer.Id or name)
                    if type(result) == "table" and result.Error then
                        return
                    end
                    coins -= price
                    count -= 1
                    task.wait(0.4)
                end
            end
        end
    end
end

function Mine.DailyShop()
    local live = Mine.Live()
    if live then
        Mine.Daily(live)
    end
end

function Mine.Shared()
    for flag in { "AutoHatch", "AutoChests", "AutoCraft", "AutoEnchant", "AutoArena", "AutoMine" } do
        if flag ~= "AutoMine" and Library.Flags[flag] == true then
            return true
        end
    end
    return false
end

function Mine.Run()
    if not Mine.Enter() then
        Mine.Until = os.clock() + 30
        return
    end
    local live = Mine.Live()
    if not live then
        Mine.Until = os.clock() + 30
        return
    end
    local started = os.clock()
    local shared = Mine.Shared()
    local stuckAt, stuckSpot = os.clock(), nil
    while Mine.On() and not Library.Unloaded do
        if Hallow.BossDue() or Arena.Due() or Memory.Due() or Dig.Due() then
            break
        end
        if shared and os.clock() - started > Mine.Session then
            break
        end
        live = Mine.Live() or live
        local count, capacity = Mine.Bag()
        if capacity ~= math.huge and count >= capacity then
            if Library.Flags.MineSell ~= true then
                Mine.Note = "backpack full"
                Mine.Until = os.clock() + 120
                break
            end
            Mine.Sell(live)
        end
        local cell, stand, target = Mine.Pick(live)
        if cell then
            Mine.Note = "mining " .. tostring(cell.Ore and cell.Ore.name or "ore")
            Mine.Swing(live, cell)
            stuckAt = os.clock()
        elseif stand then
            if stuckSpot == stand and os.clock() - stuckAt > 12 then
                if target and target.Key then
                    Mine.Skip[target.Key] = os.clock() + 120
                end
                Mine.Until = os.clock() + 60
                break
            end
            if stuckSpot ~= stand then
                stuckSpot, stuckAt = stand, os.clock()
            end
            Char.Hop(stand)
            task.wait(0.35)
        else
            Mine.Note = "nothing to mine"
            Mine.Until = os.clock() + 300
            break
        end
        task.wait(0.05)
    end
    if shared or not Mine.On() then
        Net.Invoke("MiningService", "Leave")
        if Library.Flags.AutoHatch == true or Library.Flags.AutoChests == true then
            Mine.Until = os.clock() + 120
        end
    end
end


--== Halloween events, webhook, visuals ==--

Hallow = {
    Note = "", ShopNote = "", MoonNote = "", TotemNote = "", Rest = {}, Changed = Instance.new("BindableEvent"),
    Fighting = false, Ended = false, Candy = 0, BossDone = {}, ShopNames = {}, ShopIds = {}, TotemUntil = {},
    CENTER = Vector3.new(-1740, -510, -1950),
    WITCH = Vector3.new(-1649.8, -506.4, -2029.9),
    BOSS = Vector3.new(-1680.8, -515.7, -2317.3),
}
Hallow.HOUSES = {
    House01 = Vector3.new(-1682.0, -509.5, -1741.7), House02 = Vector3.new(-1716.2, -509.5, -1784.2),
    House03 = Vector3.new(-1647.0, -509.8, -1808.6), House04 = Vector3.new(-1712.1, -509.7, -1868.0),
    House05 = Vector3.new(-1646.9, -509.5, -1881.9), House06 = Vector3.new(-1745.8, -509.5, -1939.4),
    House07 = Vector3.new(-1604.3, -509.8, -1951.8), House08 = Vector3.new(-1811.0, -510.1, -1973.3),
    House09 = Vector3.new(-1823.8, -509.5, -2047.3), House10 = Vector3.new(-1754.1, -509.6, -2089.3),
    House11 = Vector3.new(-1614.8, -509.5, -2091.9),
}

function Hallow.Now()
    return Workspace:GetServerTimeNow()
end

function Hallow.Here()
    return Char.Distance(Hallow.CENTER) < 600
end

function Hallow.Go()
    if Hallow.Here() then
        return true
    end
    Net.Invoke("IslandService", "Travel", { Island = "Halloween", Source = "Menu" })
    local deadline = os.clock() + 6
    while not Hallow.Here() and os.clock() < deadline and not Library.Unloaded do
        task.wait(0.25)
    end
    return Hallow.Here()
end

function Hallow.HouseReady(id)
    local save = Data.Save
    local readyAt = save and save.TrickOrTreat and Util.Num(save.TrickOrTreat[id], 0) or 0
    return readyAt <= Hallow.Now()
end

function Hallow.TrickDue()
    if Library.Flags.AutoTrick ~= true or os.clock() < (Hallow.Rest.trick or 0) then
        return nil
    end
    for id in Hallow.HOUSES do
        if Hallow.HouseReady(id) then
            return true
        end
    end
    return nil
end

function Hallow.Trick()
    Hallow.Rest.trick = os.clock() + 30
    if not Hallow.Go() then
        return
    end
    local left = {}
    for id in Hallow.HOUSES do
        if Hallow.HouseReady(id) then
            left[id] = true
        end
    end
    while next(left) and Library.Flags.AutoTrick == true and not Library.Unloaded do
        local best, bestDist = nil, math.huge
        for id in left do
            local dist = Char.Distance(Hallow.HOUSES[id])
            if dist < bestDist then
                best, bestDist = id, dist
            end
        end
        if not best then
            break
        end
        Char.Hop(Hallow.HOUSES[best])
        local deadline = os.clock() + 3
        while Hallow.HouseReady(best) and os.clock() < deadline and not Library.Unloaded do
            task.wait(0.2)
        end
        if Hallow.HouseReady(best) then
            Net.Invoke("TrickOrTreatService", "Knock", best)
            task.wait(0.3)
        end
        if not Hallow.HouseReady(best) then
            left[best] = nil
            Hallow.Note = "trick-or-treated " .. best
        else
            left[best] = nil
        end
    end
end

function Hallow.BossTimes()
    local config = Game.Module("HallowBossConfig") or {}
    local interval = Util.Num(config.IntervalSeconds, 3600)
    local offset = Util.Num(config.OffsetSeconds, 0)
    local fight = Util.Num(config.FightSeconds, 420)
    local intro = Util.Num(config.IntroSeconds, 4)
    local now = Hallow.Now()
    local start = math.floor((now - offset) / interval) * interval + offset
    if now >= start + fight then
        start += interval
    end
    return start, fight, intro
end

function Hallow.BossIn()
    local start = Hallow.BossTimes()
    return math.max(0, start - Hallow.Now())
end

function Hallow.BossSoon(seconds)
    return Hallow.BossIn() <= seconds
end

function Hallow.BossDue()
    if Library.Flags.AutoBoss ~= true then
        return false
    end
    local start, fight = Hallow.BossTimes()
    local now = Hallow.Now()
    return now >= start - 45 and now < start + fight - 10 and not Hallow.BossDone[start]
end

function Hallow.OnAttack(info)
    if not Hallow.Fighting or Library.Flags.BossDodge ~= true or type(info) ~= "table" or type(info.Targets) ~= "table" then
        return
    end
    local root = Char.Root()
    if not root then
        return
    end
    local threatened = false
    for _, target in info.Targets do
        if typeof(target) == "Vector3" and Char.Flat(target) <= Util.Num(info.Radius, 0) + 3 then
            threatened = true
            break
        end
    end
    if not threatened then
        return
    end
    task.spawn(function()
        Util.AsIdentity(2)
        local best, bestMin = nil, -1
        for i = 1, 12 do
            local angle = (i / 12) * math.pi * 2
            local spot = Hallow.BOSS + Vector3.new(math.cos(angle) * 26, 3.5, math.sin(angle) * 26)
            local minDist = math.huge
            for _, target in info.Targets do
                if typeof(target) == "Vector3" then
                    local delta = spot - target
                    minDist = math.min(minDist, Vector3.new(delta.X, 0, delta.Z).Magnitude)
                end
            end
            if minDist > bestMin then
                best, bestMin = spot, minDist
            end
        end
        if best then
            Char.Hop(best)
        end
    end)
end

function Hallow.OnReward(info)
    if type(info) == "table" then
        Hallow.Candy += Util.Num(info.Candy, 0)
    end
end

function Hallow.OnEnded()
    Hallow.Ended = true
end

function Hallow.Boss()
    local start, fight, intro = Hallow.BossTimes()
    Hallow.BossDone[start] = true
    if not Hallow.Go() then
        return
    end
    Char.Hop(Hallow.BOSS + Vector3.new(0, 3.5, 0))
    local beginAt = start + intro + 0.5
    local waitFor = beginAt - Hallow.Now()
    if waitFor > 0 then
        task.wait(waitFor)
    end
    Hallow.Fighting = true
    Hallow.Ended = false
    local fightEnd = start + fight
    while not Hallow.Ended and Hallow.Now() < fightEnd and Library.Flags.AutoBoss == true and not Library.Unloaded do
        local root = Char.Root()
        if root and (Char.Flat(Hallow.BOSS) > 40 or math.abs(root.Position.Y - Hallow.BOSS.Y) > 12) then
            Char.Hop(Hallow.BOSS + Vector3.new(0, 3.5, 0))
        end
        if Library.Flags.AutoTap == true then
            task.wait(0.3)
        else
            Tap.Once()
            task.wait(Tap.Gap)
        end
    end
    Hallow.Fighting = false
    Hallow.Note = "boss fight over (+" .. Util.Short(Hallow.Candy) .. " candy)"
end

function Hallow.WitchDue()
    if Library.Flags.AutoWitch ~= true or os.clock() < (Hallow.Rest.witch or 0) then
        return false
    end
    local save = Data.Save
    local day = save and save.HalloweenDailies and Util.Num(save.HalloweenDailies.Day, -1) or -1
    return day ~= math.floor(os.time() / 86400)
end

function Hallow.Witch()
    Hallow.Rest.witch = os.clock() + 600
    if not Hallow.Go() then
        return
    end
    local spot = nil
    local deadline = os.clock() + 5
    while not spot and os.clock() < deadline and not Library.Unloaded do
        for inst in Char.Points do
            -- Candy Witch is an Interactable-tagged model, tracked via Watch tags.
        end
        local tagged = CollectionService:GetTagged("Interactable")
        for _, node in tagged do
            if node:GetAttribute("InteractableId") == "CandyWitch" then
                spot = node:GetPivot().Position
                break
            end
        end
        if not spot then
            task.wait(0.25)
        end
    end
    spot = spot or Hallow.WITCH
    Char.Hop(Char.Beside(spot, 6))
    local lag = 0
    pcall(function()
        lag = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)
    task.wait(math.clamp(1 + lag * 2, 1, 2.5))
    local result = Net.Invoke("HalloweenDailyService", "Accept")
    local ok, why = Net.Why(result)
    if not ok and tostring(why) == "TooFar" then
        Char.Hop(Char.Beside(spot, 6))
        task.wait(1)
        result = Net.Invoke("HalloweenDailyService", "Accept")
        ok, why = Net.Why(result)
    end
    if ok then
        Hallow.Rest.witch = 0
        Hallow.Note = "witch quest accepted"
    elseif tostring(why) == "Closed" then
        Hallow.Rest.witch = os.clock() + 3600
    else
        Hallow.Note = "witch: " .. tostring(why)
    end
end

function Hallow.LoadShop()
    local config = Game.Module("HalloweenShopConfig")
    Hallow.ShopNames, Hallow.ShopIds = {}, {}
    if config and type(config.Items) == "table" then
        for _, item in config.Items do
            if type(item) == "table" then
                local name = tostring(item.DisplayName or item.Name or item.Id or "")
                if name ~= "" then
                    table.insert(Hallow.ShopNames, name)
                    Hallow.ShopIds[name] = item.Id
                end
            end
        end
    end
    return Hallow.ShopNames
end

function Hallow.Left(name)
    local config = Game.Module("HalloweenShopConfig")
    if not config or type(config.Items) ~= "table" then
        return 0
    end
    local id = Hallow.ShopIds[name]
    local entry = nil
    for _, item in config.Items do
        if item.Id == id then
            entry = item
            break
        end
    end
    if not entry then
        return 0
    end
    local save = Data.Save
    local shop = save and save.HalloweenShop or {}
    if entry.Daily then
        local today = type(shop.Today) == "table" and shop.Today or {}
        local day = math.floor(Hallow.Now() / 86400)
        local bought = Util.Num(today.Day, -1) == day and Util.Num(today.Bought and today.Bought[id], 0) or 0
        return math.max(0, Util.Num(entry.Limit, 0) - bought)
    end
    return math.max(0, Util.Num(entry.Limit, 0) - Util.Num(shop[id], 0))
end

function Hallow.ShopStep()
    if Library.Flags.AutoHallowShop ~= true then
        return
    end
    local picks = Util.PickSet("HallowShopPick")
    if not picks then
        return
    end
    local config = Game.Module("HalloweenShopConfig")
    if not config or type(config.Items) ~= "table" then
        return
    end
    local save = Data.Save
    local candy = save and save.Currencies and Util.Num(save.Currencies.CandyCorn, 0) or 0
    local passes = save and save.Monetization and save.Monetization.Gamepasses or {}
    for _, item in config.Items do
        local name = tostring(item.DisplayName or item.Name or item.Id or "")
        if picks[name] and os.clock() >= (Hallow.Rest["s" .. tostring(item.Id)] or 0) then
            local hidden = (item.HiddenWithPass and passes[item.HiddenWithPass]) or (item.OnlyWithPass and not passes[item.OnlyWithPass])
            if not hidden and Hallow.Left(name) > 0 and candy >= Util.Num(item.Price, math.huge) then
                local ok, why = Net.Why(Net.Invoke("HalloweenShopService", "Purchase", { Id = item.Id }))
                if ok then
                    Hallow.ShopNote = "bought " .. name
                    Bg:Later("hallowshop", 1)
                else
                    Hallow.Rest["s" .. tostring(item.Id)] = os.clock() + 300
                    Hallow.ShopNote = ("shop: %s"):format(tostring(why))
                end
                return
            end
        end
    end
end

function Hallow.MoonOn()
    return Workspace:GetAttribute("Event_BloodMoon_Active") == true
end

function Hallow.MoonIn()
    if Hallow.MoonOn() then
        return 0
    end
    return math.max(0, Util.Num(Workspace:GetAttribute("Event_BloodMoon_NextStartAt"), 0) - os.time())
end

function Hallow.DialStep()
    if Library.Flags.AutoDial ~= true then
        return
    end
    local save = Data.Save
    local owned = save and save.Items and save.Items.Owned and Util.Num(save.Items.Owned["BloodMoonDial"], 0) or 0
    if owned < 1 or Hallow.MoonOn() then
        return
    end
    local soon = Hallow.MoonIn()
    if soon > 0 and soon < 420 then
        Bg:Later("dial", soon + 330)
        return
    end
    if Net.Why(Net.Invoke("WeatherDialService", "Use", "BloodMoon")) then
        Hallow.MoonNote = "blood moon dial used"
    end
end

function Hallow.TotemStep()
    if Library.Flags.AutoTotems ~= true then
        return
    end
    if not Eggs.Running() then
        Bg:Later("totems", 30)
        return
    end
    local root = Char.Root()
    if not root then
        return
    end
    local picks = Util.PickSet("TotemPick")
    if not picks then
        return
    end
    local config = Game.Module("TotemConfig")
    local save = Data.Save
    local soonest = math.huge
    for name in picks do
        local owned = save and save.Items and save.Items.Owned and Util.Num(save.Items.Owned[name], 0) or 0
        local expires = Hallow.TotemUntil[name] or 0
        if owned >= 1 and os.clock() >= expires then
            local ok, why = Net.Why(Net.Invoke("ItemService", "PlaceTotem", { TotemName = name, Position = root.Position - Vector3.new(0, 2.5, 0) }))
            if ok then
                local duration = config and config[name] and Util.Num(config[name].Duration, 900) or 900
                Hallow.TotemUntil[name] = os.clock() + duration
                Hallow.TotemNote = "placed " .. name
            else
                Hallow.TotemUntil[name] = os.clock() + 120
                Hallow.TotemNote = ("totem: %s"):format(tostring(why))
            end
        end
        soonest = math.min(soonest, math.max((Hallow.TotemUntil[name] or 0) - os.clock(), 5))
    end
    if soonest < math.huge then
        Bg:Later("totems", math.clamp(soonest, 5, 60))
    end
end

function Hallow.FusionDue()
    if Library.Flags.AutoFusionClaim ~= true or os.clock() < (Hallow.Rest.fusion or 0) then
        return false
    end
    local save = Data.Save
    local slot = save and save.Machines and save.Machines.Fusion and save.Machines.Fusion.Slot
    return type(slot) == "table" and Util.Num(slot.EndTime, math.huge) <= Hallow.Now()
end

function Hallow.FusionClaim()
    Hallow.Rest.fusion = os.clock() + 120
    local point = Char.Reach("Fusion")
    if not point then
        return
    end
    Char.Go(point.Position, 6)
    task.wait(1)
    local ok, why = Net.Why(Net.Invoke("FusionService", "Claim"))
    Hallow.Note = ok and "claimed the fusion egg" or ("fusion: %s"):format(tostring(why))
end

function Hallow.Focus()
    return Library.Flags.MoonFocus == true and Hallow.MoonOn() and Eggs.CanRun()
end

Webhook = {
    Queue = {}, Posted = 0, Note = "", Kick = Instance.new("BindableEvent"), Images = {}, KickSent = false,
    Logo = "https://i.imgur.com/ykQFi3W.png", Banner = "https://i.imgur.com/4bBNkAb.png",
    RARITIES = { "Common", "Rare", "Epic", "Legendary", "Mythical", "Secret" },
    COLOURS = { Common = 0xB4B4B4, Rare = 0x3C9BFF, Epic = 0xA050FF, Legendary = 0xFFC83C, Mythical = 0xFF3C5A, Secret = 0xFF7A30 },
    Author = {},
}

function Webhook.Family(rarity)
    rarity = tostring(rarity or "")
    return rarity:match("^Secret") and "Secret" or rarity
end

function Webhook.Wants(event)
    local flags = Library.Flags
    if event.Kind == "test" then
        return true
    end
    if event.Kind == "kick" then
        return flags.WhKick ~= false
    end
    if event.Kind == "arena" then
        return flags.WhArena == true
    end
    if flags.WhHatch == false then
        return false
    end
    local rarities = Util.PickSet("WhRarities")
    if rarities and not rarities[Webhook.Family(event.Rarity)] then
        return false
    end
    local tiers = Util.PickSet("WhTiers")
    if tiers and not tiers[event.Tier or "Normal"] then
        return false
    end
    local eggs = Util.PickSet("WhEggs")
    if eggs and not eggs[event.Egg or ""] then
        return false
    end
    local minOdds = Util.Amount(flags.WhMinOdds)
    if minOdds > 0 and Util.Num(event.OneIn, 0) < minOdds then
        return false
    end
    return true
end

function Webhook.Push(event)
    if Library.Flags.Webhook ~= true or not Webhook.Wants(event) then
        return
    end
    event.At = event.At or os.time()
    event.Coins, event.Rebirths, event.Hatched = Data.Coins(), Data.Rebirths(), State.Hatched
    if event.Kind == "kick" then
        table.insert(Webhook.Queue, 1, event)
    else
        table.insert(Webhook.Queue, event)
    end
    while #Webhook.Queue > 30 do
        table.remove(Webhook.Queue)
    end
    Webhook.Kick:Fire()
end

function Webhook.Hatch(pet, egg)
    if Library.Flags.Webhook ~= true then
        return
    end
    local tier = Pets.TierName(pet.Tier)
    local visual = Game.Module("PetVisualConfig")
    local entry = visual and visual[pet.Name]
    local image = type(entry) == "table" and tostring(entry.Image or ""):match("(%d+)") or nil
    Webhook.Push({
        Kind = "hatch", Title = (tier ~= "Normal" and (tier .. " ") or "") .. tostring(pet.Name or "?"),
        Name = pet.Name, Rarity = tostring(pet.Rarity or ""), Tier = tier, Egg = tostring(egg or ""),
        OneIn = pet.OneIn, Mutation = pet.Mutation, Image = image,
    })
end

function Webhook.Image(id, user)
    if id == nil then
        return nil
    end
    local key = (user and "u" or "a") .. tostring(id)
    if Webhook.Images[key] then
        return Webhook.Images[key]
    end
    local http = Util.Http()
    if not http then
        return nil
    end
    local url = user and ("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=150x150&format=Png&isCircular=false"):format(tostring(id))
        or ("https://thumbnails.roblox.com/v1/assets?assetIds=%s&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false"):format(tostring(id))
    local ok, response = pcall(http, { Url = url, Method = "GET" })
    if not ok or type(response) ~= "table" or type(response.Body) ~= "string" then
        return nil
    end
    local decoded = Util.Call(HttpService.JSONDecode, HttpService, response.Body)
    local image = type(decoded) == "table" and type(decoded.data) == "table" and decoded.data[1] and decoded.data[1].imageUrl or nil
    if type(image) ~= "string" or image:find("PrivateImage", 1, true) or image:match("^https?://[^/]+/[^/]+$") then
        return nil
    end
    Webhook.Images[key] = image
    return image
end

function Webhook.Build(event)
    local fields = {}
    local function field(name, value)
        table.insert(fields, { name = name, value = tostring(value), inline = true })
    end
    field("User", "||" .. tostring(LocalPlayer.DisplayName) .. "||")
    if event.Rarity then
        field("Rarity", event.Rarity)
    end
    if event.Egg then
        field("Egg", event.Egg)
    end
    if event.Tier then
        field("Tier", event.Tier)
    end
    if event.OneIn then
        field("Chance", "1 in " .. Util.Commas(event.OneIn))
    end
    field("Coins", Util.Short(event.Coins or Data.Coins()))
    field("Rebirths", Util.Short(event.Rebirths or Data.Rebirths()))
    field("Session", Util.Commas(event.Hatched or State.Hatched) .. " hatched")
    local embed = {
        author = { name = Webhook.Author[event.Kind] or "Lumin Hub", icon_url = Webhook.Image(LocalPlayer.UserId, true) },
        title = tostring(event.Title or event.Name or "Lumin Hub"),
        description = event.Text or (event.Mutation and ("✨ " .. tostring(event.Mutation)) or nil),
        color = event.Kind == "kick" and 0xED4245 or (Webhook.COLOURS[Webhook.Family(event.Rarity)] or 0xFF7A30),
        fields = fields,
        thumbnail = { url = Webhook.Image(event.Image) or Webhook.Logo },
        image = { url = Webhook.Banner },
        footer = { text = "discord.gg/luminhub" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", event.At or os.time()),
    }
    local content, parse = nil, {}
    local ping = tostring(Library.Flags.WebhookUser or ""):match("(%d+)")
    if ping then
        content = "<@" .. ping .. ">"
        table.insert(parse, "users")
    end
    if Library.Flags.WhEveryone == true then
        content = (content and (content .. " ") or "") .. "@everyone"
        table.insert(parse, "everyone")
    end
    return { username = "Lumin Hub | " .. GameName, content = content, allowed_mentions = { parse = parse }, embeds = { embed } }
end

function Webhook.Post(event)
    local url = tostring(Library.Flags.WebhookUrl or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if url == "" then
        return false, "no webhook url"
    end
    local http = Util.Http()
    if not http then
        return false, "no http"
    end
    local body = Util.Call(HttpService.JSONEncode, HttpService, Webhook.Build(event))
    if not body then
        return false, "encode failed"
    end
    local ok, response = pcall(http, {
        Url = url, Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body,
    })
    if not ok then
        return false, tostring(response)
    end
    local code = type(response) == "table" and (response.StatusCode or response.Status) or nil
    if code and code >= 200 and code < 300 then
        return true, nil
    end
    return false, "http " .. tostring(code)
end

function Webhook.Drain()
    Util.AsIdentity(2)
    while not Library.Unloaded do
        local event = table.remove(Webhook.Queue, 1)
        if not event then
            Webhook.Kick.Event:Wait()
        else
            local ok, why = Webhook.Post(event)
            if ok then
                Webhook.Posted += 1
                Webhook.Note = ""
            else
                Webhook.Note = tostring(why)
            end
            task.wait(1)
        end
    end
end

function Webhook.TestRun()
    local event = {
        Kind = "test", Title = "Rainbow Cerberus", Name = "Cerberus", Rarity = "Secret II", Tier = "Rainbow",
        Egg = "Test Egg", OneIn = 2500000, Mutation = "Void", Image = "109003952986650",
        Coins = Data.Coins(), Rebirths = Data.Rebirths(), Hatched = State.Hatched, At = os.time(),
    }
    local ok, why = Webhook.Post(event)
    Webhook.Note = ok and "test post sent" or ("test: " .. tostring(why))
    if ok then
        Webhook.Posted += 1
    end
end

function Webhook.Test()
    task.spawn(function()
        Util.AsIdentity(2)
        Webhook.TestRun()
    end)
end

function Webhook.OnError()
    if Webhook.KickSent then
        return
    end
    local ok, message = pcall(function()
        return game:GetService("GuiService"):GetErrorMessage()
    end)
    if not ok or type(message) ~= "string" or message == "" then
        return
    end
    local lower = message:lower()
    if lower:find("teleport", 1, true) then
        return
    end
    for code = 769, 773 do
        if message:find(tostring(code), 1, true) then
            return
        end
    end
    Webhook.KickSent = true
    Webhook.Push({ Kind = "kick", Title = "Disconnected", Text = message:sub(1, 900) })
end


--== FPS boost, ESP, popups ==--

Boost = { Saved = setmetatable({}, { __mode = "k" }), Connections = {}, Running = false, Quality = nil, PetsWas = nil, Muted = {}, MuteAdded = nil }
Boost.EFFECTS = { Trail = true, Beam = true, Smoke = true, Fire = true, Sparkles = true }
Boost.POST = { BloomEffect = true, BlurEffect = true, ColorCorrectionEffect = true, DepthOfFieldEffect = true, SunRaysEffect = true }
Boost.POPUPS = {
    Popups = true, ScreenGlow = true, TS2CriticalPopups = true, UIClickFX = true, Flash = true,
    HallowBossFlash = true, EventEffects = true, ColosseumEffects = true, IslandNightBlink = true,
    Notifications = true, LocationBanner = true,
}

function Boost.Set(obj, name, value)
    local saved = Boost.Saved[obj]
    if not saved then
        saved = {}
        Boost.Saved[obj] = saved
    end
    if saved[name] == nil then
        local ok, current = pcall(function()
            return obj[name]
        end)
        if not ok then
            return
        end
        saved[name] = current
    end
    pcall(function()
        obj[name] = value
    end)
end

function Boost.Strip(obj)
    if typeof(obj) ~= "Instance" then
        return
    end
    if obj:IsA("ParticleEmitter") or Boost.EFFECTS[obj.ClassName] then
        Boost.Set(obj, "Enabled", false)
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        Boost.Set(obj, "Transparency", 1)
    elseif obj:IsA("Highlight") then
        if obj.Name ~= "LuminEsp" then
            Boost.Set(obj, "Enabled", false)
        end
    elseif obj:IsA("MeshPart") then
        Boost.Set(obj, "TextureID", "")
        Boost.Set(obj, "CastShadow", false)
    elseif obj:IsA("BasePart") then
        Boost.Set(obj, "CastShadow", false)
        if obj.Anchored then
            Boost.Set(obj, "Material", Enum.Material.SmoothPlastic)
            Boost.Set(obj, "Reflectance", 0)
        end
    end
end

function Boost.Light(obj)
    if typeof(obj) ~= "Instance" then
        return
    end
    if Boost.POST[obj.ClassName] then
        Boost.Set(obj, "Enabled", false)
    end
end

function Boost.Stop()
    for _, link in Boost.Connections do
        pcall(link.Disconnect, link)
    end
    table.clear(Boost.Connections)
    for obj, saved in Boost.Saved do
        for name, value in saved do
            pcall(function()
                obj[name] = value
            end)
        end
    end
    table.clear(Boost.Saved)
    if Boost.Quality ~= nil then
        pcall(function()
            settings().Rendering.QualityLevel = Boost.Quality
        end)
        Boost.Quality = nil
    end
    Boost.Running = false
end

function Boost.PetsRun(restore)
    local controller = Game.C.SettingsController
    local save = Data.Save
    if restore == true then
        if Boost.PetsWas ~= nil and controller then
            Util.Method(controller, "Set", "HidePets", Boost.PetsWas)
            Boost.PetsWas = nil
        end
        return
    end
    if Library.Flags.FpsBoost ~= true or not controller or not save or type(save.Settings) ~= "table" then
        return
    end
    if save.Settings.HidePets == 1 then
        Boost.PetsWas = 1
        Util.Method(controller, "Set", "HidePets", 2)
    end
end

function Boost.Apply()
    Boost.PetsRun()
    Boost.Stop()
    if Library.Flags.FpsBoost ~= true or Library.Unloaded then
        return
    end
    Boost.Running = true
    pcall(function()
        Boost.Quality = settings().Rendering.QualityLevel
        settings().Rendering.QualityLevel = Enum.SavedQualitySetting.SavedQualityLevel1
    end)
    pcall(function()
        settings().Rendering.QualityLevel = 1
    end)
    Boost.Set(Lighting, "GlobalShadows", false)
    for _, child in Lighting:GetChildren() do
        Boost.Light(child)
    end
    table.insert(Boost.Connections, Lighting.ChildAdded:Connect(Boost.Light))
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        Boost.Set(terrain, "Decoration", false)
        Boost.Set(terrain, "WaterWaveSize", 0)
        Boost.Set(terrain, "WaterWaveSpeed", 0)
        Boost.Set(terrain, "WaterReflectance", 0)
    end
    table.insert(Boost.Connections, Workspace.DescendantAdded:Connect(Boost.Strip))
end

function Boost.Render()
    pcall(RunService.Set3dRenderingEnabled, RunService, not (Library.Flags.NoRender == true and not Library.Unloaded))
end

function Boost.Mute(gui)
    if Boost.Muted[gui] or not (gui:IsA("ScreenGui") and Boost.POPUPS[gui.Name]) then
        return
    end
    local entry = { Was = gui.Enabled }
    Boost.Muted[gui] = entry
    entry.Link = gui:GetPropertyChangedSignal("Enabled"):Connect(function()
        if Boost.Muted[gui] and gui.Enabled then
            gui.Enabled = false
        end
    end)
    gui.Enabled = false
end

function Boost.Popups()
    if Boost.MuteAdded then
        pcall(Boost.MuteAdded.Disconnect, Boost.MuteAdded)
        Boost.MuteAdded = nil
    end
    for gui, entry in Boost.Muted do
        if entry.Link then
            pcall(entry.Link.Disconnect, entry.Link)
        end
        pcall(function()
            gui.Enabled = entry.Was
        end)
    end
    table.clear(Boost.Muted)
    if Library.Flags.HidePopups ~= true or Library.Unloaded then
        return
    end
    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not gui then
        return
    end
    for _, child in gui:GetChildren() do
        Boost.Mute(child)
    end
    Boost.MuteAdded = gui.ChildAdded:Connect(Boost.Mute)
end

Esp = { Drawn = {}, StepConn = nil, Frame = 0, Reported = false, Want = {}, DrawSet = {} }
Esp.COLORS = { Players = Color3.fromRGB(255, 95, 95), ["Shiny Stars"] = Color3.fromRGB(255, 230, 90), ["World Chests"] = Color3.fromRGB(255, 170, 60), ["Tap Chests"] = Color3.fromRGB(90, 220, 255) }
Esp.ShowNames = { "All", "Players", "Shiny Stars", "World Chests", "Tap Chests" }
Esp.DrawNames = { "Boxes", "Names", "Distance", "Health", "Tracers", "Chams" }

function Esp.Free(obj)
    local tag = Esp.Drawn[obj]
    if not tag then
        return
    end
    Esp.Drawn[obj] = nil
    for _, item in tag.Items do
        pcall(function()
            if type(item) == "table" and item.Destroy then
                item:Destroy()
            elseif typeof(item) == "Instance" then
                item:Destroy()
            end
        end)
    end
end

function Esp.Clear()
    for obj in Esp.Drawn do
        Esp.Free(obj)
    end
end

function Esp.Build(obj, color, adornee)
    local tag = { Items = {}, Frame = Esp.Frame }
    Esp.Drawn[obj] = tag
    local hasDrawing = type(Drawing) == "table" and type(Drawing.new) == "function"
    if hasDrawing then
        tag.Box = Drawing.new("Square")
        tag.Name = Drawing.new("Text")
        tag.Info = Drawing.new("Text")
        tag.Health = Drawing.new("Text")
        tag.Tracer = Drawing.new("Line")
        for _, item in { tag.Box, tag.Name, tag.Info, tag.Health, tag.Tracer } do
            table.insert(tag.Items, item)
        end
    else
        local gui = Instance.new("BillboardGui")
        gui.Name = "LuminEsp"
        gui.Size = UDim2.fromOffset(200, 34)
        gui.StudsOffset = Vector3.new(0, 3, 0)
        gui.AlwaysOnTop = true
        gui.Adornee = adornee or (obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart"))
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3 = color
        label.TextSize = 13
        label.Font = Enum.Font.GothamBold
        label.Parent = gui
        gui.Parent = game:GetService("CoreGui")
        tag.Billboard, tag.Label = gui, label
        table.insert(tag.Items, gui)
    end
    if Esp.DrawSet.Chams and obj:IsA("Model") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "LuminEsp"
        highlight.FillColor = color
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0.1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = obj
        highlight.Parent = game:GetService("CoreGui")
        table.insert(tag.Items, highlight)
    end
    return tag
end

function Esp.Paint(obj, color, label, info, health, maxHealth)
    local tag = Esp.Drawn[obj] or Esp.Build(obj, color, obj)
    tag.Frame = Esp.Frame
    if tag.Label then
        tag.Label.Text = info and (info .. "\n" .. label) or label
        tag.Label.TextColor3 = color
        return
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end
    local rootPos = nil
    if obj:IsA("Model") then
        local pivot = obj:GetPivot()
        rootPos = pivot.Position
    elseif obj:IsA("BasePart") then
        rootPos = obj.Position
    end
    if not rootPos then
        return
    end
    local screen, visible = camera:WorldToViewportPoint(rootPos)
    local function show(item, on)
        if item then
            item.Visible = on and visible
        end
    end
    show(tag.Box, Esp.DrawSet.Boxes)
    show(tag.Name, Esp.DrawSet.Names)
    show(tag.Info, Esp.DrawSet.Names and info ~= nil)
    show(tag.Health, Esp.DrawSet.Health and maxHealth ~= nil)
    show(tag.Tracer, Esp.DrawSet.Tracers)
    if not visible then
        return
    end
    local heightPx = 16
    local topY, bottomY = screen.Y - heightPx, screen.Y + heightPx
    pcall(function()
        local top = camera:WorldToViewportPoint(rootPos + Vector3.new(0, 3, 0))
        local bottom = camera:WorldToViewportPoint(rootPos - Vector3.new(0, 3, 0))
        topY, bottomY = top.Y, bottom.Y
        heightPx = math.abs(bottomY - topY)
    end)
    if tag.Box then
        tag.Box.Size = Vector2.new(heightPx * 0.55, heightPx)
        tag.Box.Position = Vector2.new(screen.X - heightPx * 0.275, topY)
        tag.Box.Color = color
    end
    if tag.Name then
        local text = label
        if Esp.DrawSet.Distance then
            local root = Char.Root()
            if root then
                text = text .. (" [%dm]"):format(math.floor((rootPos - root.Position).Magnitude))
            end
        end
        tag.Name.Text = text
        tag.Name.Position = Vector2.new(screen.X - #text * 3, topY - 16)
        tag.Name.Color = color
    end
    if tag.Info and info then
        tag.Info.Text = info
        tag.Info.Position = Vector2.new(screen.X - #info * 3, topY - 30)
        tag.Info.Color = color
    end
    if tag.Health and maxHealth then
        local frac = math.clamp(Util.Num(health, 0) / math.max(Util.Num(maxHealth, 1), 1), 0, 1)
        tag.Health.Text = ("%s/%s"):format(tostring(health), tostring(maxHealth))
        tag.Health.Position = Vector2.new(screen.X - 10, bottomY + 4)
        tag.Health.Color = Color3.fromHSV(frac * 0.33, 1, 1)
    end
    if tag.Tracer then
        tag.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
        tag.Tracer.To = Vector2.new(screen.X, bottomY)
        tag.Tracer.Color = color
    end
end

function Esp.Paints()
    Esp.Frame += 1
    local want = Esp.Want
    if want["Shiny Stars"] then
        local save = Data.Save
        local found = save and save.ShinyStars and save.ShinyStars.Found or {}
        for star in Claims.Stars do
            local id = star:GetAttribute("ShinyStarId")
            if id and found[id] ~= true then
                Esp.Paint(star, Esp.COLORS["Shiny Stars"], "Shiny Star", nil, nil, nil)
            end
        end
    end
    if want["World Chests"] then
        for model in Brk.Live do
            if Brk.Usable(model) then
                Esp.Paint(model, Esp.COLORS["World Chests"], "Chest", nil, Util.Num(model:GetAttribute("BreakableHealth"), 0), 10)
            end
        end
    end
    if want["Tap Chests"] then
        local save = Data.Save
        local now = Workspace:GetServerTimeNow()
        for chest in Claims.Chests do
            local id = chest:GetAttribute("TapChestId")
            local readyAt = id and save and save.TapChests and Util.Num(save.TapChests[id], math.huge) or math.huge
            if id and readyAt <= now then
                Esp.Paint(chest, Esp.COLORS["Tap Chests"], "Tap Chest", nil, nil, nil)
            end
        end
    end
    if want.Players then
        for _, player in Players:GetPlayers() do
            if player ~= LocalPlayer and player.Character then
                Esp.Paint(player.Character, Esp.COLORS.Players, player.Name, nil, nil, nil)
            end
        end
    end
    for obj, tag in Esp.Drawn do
        if tag.Frame ~= Esp.Frame then
            Esp.Free(obj)
        end
    end
end

function Esp.Apply()
    local show = (Library.Flags.EspOn == true and not Library.Unloaded) and Util.PickSet("EspShow") or {}
    Esp.Want = {}
    for name in show do
        Esp.Want[name] = true
    end
    if Esp.Want.All then
        for _, name in Esp.ShowNames do
            Esp.Want[name] = true
        end
        Esp.Want.All = nil
    end
    Esp.DrawSet = Util.Picks("EspDraw")
    Esp.Clear()
    local any = next(Esp.Want) ~= nil
    if any and not Esp.StepConn then
        Esp.StepConn = RunService.PreRender:Connect(function()
            local ok, err = pcall(Esp.Paints)
            if not ok and not Esp.Reported then
                Esp.Reported = true
                warn("[Lumin] esp: " .. tostring(err))
            end
        end)
    elseif not any and Esp.StepConn then
        Esp.StepConn:Disconnect()
        Esp.StepConn = nil
        Esp.Clear()
    end
end

Popup = { Real = nil, CraftUntil = 0 }

function Popup.On()
    return Library.Flags.AutoClose ~= false and not Library.Unloaded
end

function Popup.ApplyRun()
    Util.AsIdentity(2)
    local controller = Game.C.RewardPopupController
    if not controller then
        return
    end
    if Popup.On() and not Popup.Real then
        local real = controller.Show
        if type(real) ~= "function" then
            return
        end
        Popup.Real = real
        controller.Show = function(self, ...)
            local results = table.pack(real(self, ...))
            task.delay(2, function()
                if Popup.On() then
                    Util.Method(controller, "Close")
                end
            end)
            return table.unpack(results, 1, results.n)
        end
    elseif not Popup.On() and Popup.Real then
        controller.Show = Popup.Real
        Popup.Real = nil
    end
end

function Popup.Apply()
    task.spawn(Popup.ApplyRun)
end

function Popup.WaveHud()
    local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local hud = gui and gui:FindFirstChild("WaveHUD", true)
    if hud and hud:IsA("GuiObject") then
        hud.Visible = false
    end
end

function Popup.Crafted()
    if os.clock() < Popup.CraftUntil then
        return
    end
    Popup.CraftUntil = os.clock() + 4
    task.spawn(function()
        Util.AsIdentity(2)
        local controller = Game.C.MachineController
        local menu = Game.C.MenuController
        local started = os.clock()
        while Popup.On() and os.clock() - started < 20 and not Library.Unloaded do
            local open = menu and Util.Method(menu, "IsOpen", "CraftingRoll") == true
            if os.clock() > Popup.CraftUntil and not open then
                break
            end
            if controller then
                Util.Method(controller, "ContinueRoll")
            end
            task.wait(0.25)
        end
    end)
end


--== Schedulers, brain, wiring ==--

Sched = {}
Sched.__index = Sched

function Sched.new(name)
    return setmetatable({ Name = name, Jobs = {}, Order = {}, Kick = Instance.new("BindableEvent"), Current = "" }, Sched)
end

function Sched:Add(name, enabled, run, fallback)
    local job = { Name = name, Enabled = enabled, Run = run, Fallback = fallback or 60, Due = 0 }
    self.Jobs[name] = job
    table.insert(self.Order, job)
    return job
end

function Sched:Wake(name, delay)
    local job = self.Jobs[name]
    if not job then
        return
    end
    delay = math.max(0, delay or 0)
    local when = os.clock() + delay
    if when < job.Due then
        job.Due = when
    end
    self.Kick:Fire()
    if delay > 0 then
        task.delay(delay, function()
            self.Kick:Fire()
        end)
    end
end

function Sched:At(name, delay)
    local job = self.Jobs[name]
    if not job then
        return
    end
    local when = os.clock() + math.max(0, delay or 0)
    if when < job.Due then
        job.Due = when
        self.Kick:Fire()
    end
end

function Sched:Later(name, delay)
    local job = self.Jobs[name]
    if not job then
        return
    end
    job.Due = os.clock() + math.max(0, delay or 0)
end

function Sched:Loop()
    while not Library.Unloaded do
        for _, job in self.Order do
            if os.clock() >= job.Due then
                local enabledOk, enabled = pcall(job.Enabled)
                if enabledOk and enabled == true then
                    job.Due = os.clock() + job.Fallback
                    self.Current = job.Name
                    local ok, err = pcall(job.Run)
                    self.Current = ""
                    if not ok then
                        Note(job.Name .. " failed: " .. tostring(err))
                    end
                end
            end
        end
        local nextAt = math.huge
        for _, job in self.Order do
            local enabledOk, enabled = pcall(job.Enabled)
            if enabledOk and enabled == true then
                nextAt = math.min(nextAt, job.Due)
            end
        end
        if nextAt == math.huge then
            self.Kick.Event:Wait()
        elseif nextAt > os.clock() then
            local timer = task.delay(math.clamp(nextAt - os.clock(), 0.03, 30), function()
                self.Kick:Fire()
            end)
            self.Kick.Event:Wait()
            pcall(task.cancel, timer)
        else
            task.wait()
        end
    end
end

Mover = Sched.new("mover")
Bg = Sched.new("background")

Need = { List = {} }

function Need.Set(job, currency, amount)
    Need.List[job] = { Currency = currency, Amount = amount }
end

function Need.Check()
    local save = Data.Save
    if not save or type(save.Currencies) ~= "table" then
        return
    end
    for job, need in Need.List do
        if Util.Num(save.Currencies[need.Currency], 0) >= need.Amount then
            Need.List[job] = nil
            if job == "move" then
                Mover:Wake("move")
            else
                Bg:Wake(job)
            end
        end
    end
end

Brain = { Doing = "", Home = nil, TASKS = {} }

function Brain.Leave()
    if Brain.Home == nil and not Eggs.On() and not Brk.On() then
        local root = Char.Root()
        if root then
            Brain.Home = root.CFrame
        end
    end
end

function Brain.Hatch(quiet)
    Brain.Doing = quiet and "hatching (blood moon)" or "hatching"
    if Eggs.Step() then
        Mover:Wake("move", 1)
    end
    if Eggs.Full() then
        Brain.Doing = "storage full"
    end
    if quiet then
        local endsAt = Util.Num(Workspace:GetAttribute("Event_BloodMoon_EndsAt"), 0)
        Mover:At("move", math.max(5, endsAt - os.time() + 1))
    end
end

local function addTask(def)
    table.insert(Brain.TASKS, def)
    return def
end

addTask({ Key = "Boss", Title = "Hallow Lord", Doing = "boss fight", Leave = true, Quiet = true, Wake = 0.5,
    Due = function() return Hallow.BossDue() or nil end,
    Run = function() local ok, err = pcall(Hallow.Boss) Hallow.Fighting = false if not ok then Note("boss: " .. tostring(err)) end end })
addTask({ Key = "Arena", Title = "Pet Defense", Doing = "pet defense", Leave = true, Wake = 0.5,
    Due = function() return Arena.Due() or nil end,
    Run = function() local ok, err = pcall(Arena.Run) Arena.Active = false if not ok then Note("arena: " .. tostring(err)) end end })
addTask({ Key = "Memory", Title = "Memory Match", Doing = "memory match", Leave = true, Wake = 0.5,
    Due = function() return Memory.Due() or nil end, Run = function() Memory.Run() end })
addTask({ Key = "Dig", Title = "Dig", Doing = "digging", Leave = true, Wake = 0.5,
    Due = function() return Dig.Due() or nil end, Run = function() Dig.Run() end })
addTask({ Key = "Stars", Title = "Shiny Stars", Doing = "star hunting", Leave = true, Wake = 0.2,
    Due = function() return Claims.NextStar() end, Run = function(w) Claims.Star(w) end })
addTask({ Key = "TapChests", Title = "Tap Chests", Doing = "tap chests", Leave = true, Wake = 0.2,
    Due = function() return Claims.NextChest() end, Run = function(w) Claims.Chest(w) end })
addTask({ Key = "Npc", Title = "NPC Quest", Doing = "npc quest", Leave = true, Wake = 0.2, Quick = true,
    Due = function() return Claims.NpcWork() end, Run = function(w) Claims.Npc(w) end })
addTask({ Key = "Craft", Title = "Crafting", Doing = "crafting", Leave = true, Wake = 0.2,
    Due = function() return Craft.Errand() end, Run = function(w) Craft.Run(w) end })
addTask({ Key = "Enchant", Title = "Enchanting", Doing = "enchanting", Leave = true, Wake = 0.2,
    Due = function() return Enchant.Due() end, Run = function(w) Enchant.Run(w) end })
addTask({ Key = "Potions", Title = "Potions", Doing = "potions", Leave = true, Wake = 0.2, Quick = true,
    Due = function() return Items.PotionWork() end, Run = function(w) Items.Potion(w) end })
addTask({ Key = "Honey", Title = "Honey Pot", Doing = "honey pot", Leave = true, Wake = 0.2, Quick = true,
    Due = function() return Items.HoneyWork() end, Run = function(w) Items.Honey(w) end })
addTask({ Key = "Shrine", Title = "Shrine", Doing = "shrine", Leave = true, Wake = 0.2, Quick = true,
    Due = function() return Events.ShrineWork() end, Run = function(w) Events.Shrine(w) end })
addTask({ Key = "Mobs", Title = "Island Mobs", Doing = "mob hunting", Leave = true, Wake = 0.2,
    Due = function() return Mobs.Due() end, Run = function(w) Mobs.Run(w) end })
addTask({ Key = "Witch", Title = "Candy Witch", Doing = "candy witch", Leave = true, Wake = 0.2, Quick = true,
    Due = function() return Hallow.WitchDue() or nil end, Run = function() Hallow.Witch() end })
addTask({ Key = "Trick", Title = "Trick-or-Treat", Doing = "trick-or-treat", Leave = true, Wake = 0.2,
    Due = function() return Hallow.TrickDue() end, Run = function() Hallow.Trick() end })
addTask({ Key = "Fusion", Title = "Fusion Egg", Doing = "fusion egg", Leave = true, Wake = 0.2, Quick = true,
    Due = function() return Hallow.FusionDue() or nil end, Run = function() Hallow.FusionClaim() end })
addTask({ Key = "Pads", Title = "Pad Upgrades", Doing = "pad upgrades", Leave = true, Wake = 0.2, Quick = true,
    Due = function()
        if not Shop.On() then
            return nil
        end
        local pad, index = Shop.NextPad()
        return pad and { pad, index } or nil
    end, Run = function(w) Shop.BuyPad(w[1], w[2]) end })
addTask({ Key = "Unlock", Title = "Unlocks", Doing = "unlocking", Leave = true, Wake = 0.2, Quick = true,
    Due = function()
        if World.BridgeDue() then
            return { Bridge = true }
        end
        local errand = World.Errand()
        return errand and { errand.Kind, errand.Name, errand.Portal } or nil
    end,
    Run = function(w)
        if w.Bridge then
            World.Bridge()
        else
            World.Unlock(w[1], w[2], w[3])
        end
    end })
addTask({ Key = "Mine", Title = "Mining", Doing = "mining", Leave = true, Wake = 0.5,
    Due = function() return Mine.Due() or nil end, Run = function() Mine.Run() end })
addTask({ Key = "Hatch", Title = "Hatching", Doing = "hatching", Quiet = true,
    Due = function() return Eggs.CanRun() or nil end,
    Run = function() Brain.Hatch(Hallow.Focus()) end })
addTask({ Key = "BestIsland", Title = "Best Island", Doing = "best island", Wake = 0.5, Quick = true, Before = "Chests",
    Due = function()
        if Library.Flags.TapBestIsland ~= true or Eggs.CanRun() then
            return nil
        end
        local best = World.Best()
        if Data.Island() ~= best and Data.Islands()[best] == true then
            return best
        end
        return nil
    end, Run = function(w) World.Travel(w) end })
addTask({ Key = "Chests", Title = "World Chests", Doing = "breaking chests", Wake = 0.05,
    Due = function()
        if not Brk.On() then
            return nil
        end
        local model = Brk.Pick()
        if not model then
            Brk.Note = "waiting for a chest to spawn"
        end
        return model
    end, Run = function(w) Brk.Break(w) end })

function Brain.Order()
    local trips, index = {}, {}
    for i, def in Brain.TASKS do
        if not def.Quick then
            index[def] = #trips + 1
            table.insert(trips, def)
        end
    end
    local place, taken, any = {}, {}, false
    for _, def in trips do
        local want = math.floor(Util.Num(Library.Flags["Prio" .. def.Key], 0))
        if want >= 1 then
            place[def] = want
            taken[want] = true
            any = true
        end
    end
    if not any then
        return Brain.TASKS
    end
    local free = 1
    for _, def in trips do
        if not place[def] then
            while taken[free] do
                free += 1
            end
            place[def] = free
            taken[free] = true
        end
    end
    table.sort(trips, function(a, b)
        if place[a] ~= place[b] then
            return place[a] < place[b]
        end
        return index[a] < index[b]
    end)
    local out = {}
    for _, def in Brain.TASKS do
        if def.Quick and not def.Before then
            table.insert(out, def)
        end
    end
    for _, def in trips do
        for _, other in Brain.TASKS do
            if other.Before == def.Key then
                table.insert(out, other)
            end
        end
        table.insert(out, def)
    end
    return out
end

function Brain.Step()
    if not Game.Ready or not Char.Root() then
        Mover:Later("move", 2)
        return
    end
    if Library.Flags.AutoBoss == true then
        local startsIn = Hallow.BossIn()
        if startsIn > 45 then
            Mover:At("move", startsIn - 44)
        end
    end
    if Arena.Pending() then
        Brain.Doing = "relic offer"
        Arena.Reward()
        Mover:Wake("move", 0.5)
        return
    end
    local quiet = Hallow.Focus()
    local seen = {}
    for _, def in Brain.Order() do
        seen[def.Key] = true
        if not (quiet and not def.Quiet) then
            local work = def.Due()
            if work then
                if def.Leave then
                    Brain.Leave()
                end
                Brain.Doing = def.Doing
                if def.Key == "Hatch" and Brk.On() and not seen.Chests then
                    Brk.Note = "hatching has the coins: chests wait"
                end
                def.Run(work)
                if def.Wake then
                    Mover:Wake("move", def.Wake)
                end
                return
            end
        end
    end
    if Eggs.On() then
        Brain.Hatch(false)
        return
    end
    local home = Brain.Home
    Brain.Home = nil
    if home and not Brk.On() and Char.Distance(home.Position) > 10 then
        Char.Hop(home)
    end
    Brain.Doing = ""
end

Auto = {}
Auto.MOVER_FLAGS = { "AutoBoss", "AutoTrick", "AutoWitch", "AutoFusionClaim", "AutoArena", "AutoMemory", "AutoDig",
    "AutoMine", "TapBestIsland", "AutoMobs", "AutoClaim", "AutoCraft", "AutoEnchant", "AutoBrew", "AutoMerge",
    "AutoHoney", "AutoShrine", "AutoBuy", "AutoUnlock", "AutoChests", "AutoHatch" }

function Auto.MoverOn()
    for _, flag in Auto.MOVER_FLAGS do
        if Library.Flags[flag] == true then
            return true
        end
    end
    return false
end

function Auto.Flag(name)
    return function()
        return Library.Flags[name] == true
    end
end

function Auto.WakeMove()
    Mover:Wake("move")
end

function Auto.WakeJob(name)
    return function()
        Bg:Wake(name)
    end
end

function Auto.OnTap()
    Tap.Kick:Fire()
end

function Auto.OnHatch(value)
    Mover:Wake("move")
    if not value then
        task.spawn(function()
            Util.AsIdentity(2)
            Eggs.Stop()
        end)
    end
end

function Auto.OnRebirth(value)
    Bg:Wake("rebirth")
    if not value then
        Rebirth.Release()
    end
end

function Auto.StopAll()
    for _, registry in { Toggles, Options } do
        if type(registry) == "table" then
            for flag, element in registry do
                if element.Value == true and flag ~= "AntiAfk" and flag ~= "AutoExecute"
                    and flag ~= "AutoReconnect" and flag ~= "FpsBoost" and flag ~= "NoRender" then
                    pcall(element.SetValue, element, false)
                end
            end
        end
    end
    task.spawn(function()
        Util.AsIdentity(2)
        Eggs.Stop()
        Rebirth.Release()
    end)
    Note("everything stopped")
end

Mover:Add("move", Auto.MoverOn, Brain.Step, 20)
Bg:Add("rebirth", Rebirth.On, Rebirth.Step, 30)
Bg:Add("shop", Shop.On, Shop.Step, 60)
Bg:Add("claims", Claims.On, Claims.Step, 60)
Bg:Add("equip", Auto.Flag("AutoEquip"), Pets.EquipStep, 60)
Bg:Add("delete", function()
    return Library.Flags.AutoDelete == true or next(Pets.NativeSet) ~= nil
end, Pets.DeleteStep, 60)
Bg:Add("boosts", Auto.Flag("AutoBoosts"), Items.BoostStep, 120)
Bg:Add("items", Auto.Flag("AutoPetItems"), Items.PetItemStep, 120)
Bg:Add("hallowshop", Auto.Flag("AutoHallowShop"), Hallow.ShopStep, 120)
Bg:Add("ducky", Auto.Flag("AutoDucky"), Events.DuckStep, 300)
Bg:Add("dial", Auto.Flag("AutoDial"), Hallow.DialStep, 120)
Bg:Add("totems", Auto.Flag("AutoTotems"), Hallow.TotemStep, 60)
Bg:Add("relic", Auto.Flag("AutoRelic"), Pets.RelicStep, 300)

Watch = { Links = {} }

function Watch.On(link)
    if link then
        table.insert(Watch.Links, link)
    end
end

function Watch.Stop()
    for _, link in Watch.Links do
        pcall(link.Disconnect, link)
    end
    table.clear(Watch.Links)
end

function Watch.Tag(tag, add, remove)
    for _, inst in CollectionService:GetTagged(tag) do
        pcall(add, inst)
    end
    Watch.On(CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
        pcall(add, inst)
    end))
    Watch.On(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(inst)
        pcall(remove, inst)
    end))
end

function Watch.Wake(jobs, delay)
    return function()
        for _, job in jobs do
            if job == "move" then
                Mover:Wake("move", delay)
            else
                Bg:Wake(job, delay)
            end
        end
    end
end

function Watch.Bind()
    Data.Watch({ "Currencies" }, Need.Check)
    Data.Watch({ "Currencies" }, Watch.Wake({ "hallowshop" }, 1))
    Data.Watch({ "Statistics", "Upgrades", "Progression" }, Watch.Wake({ "rebirth" }, 0.3))
    Data.Watch({ "SkillTree", "Upgrades", "DoubleJumps", "PhysicalUpgrades" }, Watch.Wake({ "shop", "rebirth" }, 0.5))
    Data.Watch({ "Pets" }, Watch.Wake({ "equip", "delete", "claims", "move" }, 1))
    Data.Watch({ "Quests", "Offline" }, Watch.Wake({ "claims" }, 0.5))
    Data.Watch({ "Mastery" }, Watch.Wake({ "relic" }, 1))
    Data.Watch({ "Items" }, Watch.Wake({ "claims", "items" }, 0.5))
    Data.Watch({ "Items" }, Watch.Wake({ "dial", "totems" }, 1))
    Data.Watch({ "Boosts", "ActiveBoosts" }, Watch.Wake({ "boosts", "move" }, 0.5))
    Data.Watch({ "Progression", "Eggs", "Colosseum", "MemoryMatch", "Digging", "PotionMachine", "HoneyPot", "Machines", "TapChests", "NpcQuests" }, Watch.Wake({ "move" }, 0.5))
    Data.Watch({ "Mining" }, function()
        Mine.Changed:Fire()
    end)
    Data.Watch({ "TrickOrTreat", "TrickOrTreatBag", "HalloweenDailies", "HalloweenShop" }, function()
        Hallow.Changed:Fire()
    end)
    Data.Watch({ "Machines", "TrickOrTreat", "HalloweenDailies" }, Watch.Wake({ "move" }, 1))

    local replica = Data.Replica
    if replica and type(replica.ListenToRaw) == "function" then
        local ok, link = pcall(replica.ListenToRaw, replica, function(_, path)
            if Library.Unloaded then
                return
            end
            local key = type(path) == "table" and path[1] or nil
            for _, callback in (key and Data.Listeners[key] or {}) do
                pcall(callback, path)
            end
        end)
        if ok then
            Watch.On(link)
        end
    end

    Watch.Tag("Breakable", Brk.Add, Brk.Remove)
    Watch.Tag("ShinyStar", function(star)
        Claims.Stars[star] = true
        Mover:Wake("move", 0.5)
    end, function(star)
        Claims.Stars[star] = nil
    end)
    Watch.Tag("TapChest", function(chest)
        Claims.Chests[chest] = true
    end, function(chest)
        Claims.Chests[chest] = nil
    end)
    Watch.Tag("PhysicalUpgrade", function(pad)
        Shop.Pads[pad] = true
    end, function(pad)
        Shop.Pads[pad] = nil
    end)
    Watch.Tag("InteractionPoint", function(point)
        Char.Points[point] = true
        Char.Arrived:Fire()
        Mover:Wake("move", 0.5)
    end, function(point)
        Char.Points[point] = nil
    end)
    Watch.Tag("Interactable", function(node)
        if node:GetAttribute("InteractableId") == "Boingo" then
            Claims.NpcModel = node
        end
    end, function(node)
        if Claims.NpcModel == node then
            Claims.NpcModel = nil
        end
    end)

    Watch.On(Net.On("EggService", "EggHatchResult", Eggs.OnResult))
    Watch.On(Eggs.HoldBind())
    Watch.On(Net.On("MachineService", "MachineCraftResult", Craft.OnResult))
    Watch.On(Net.On("EnchantService", "AutoEvent", Enchant.OnEvent))
    Watch.On(Net.On("LuckyDuckyService", "Spawn", Events.OnDuck))
    Watch.On(Net.On("BalloonPartyService", "Launched", Events.OnBalloon))
    Watch.On(Net.On("BalloonPartyService", "Popped", Events.OnPopped))
    Watch.On(Net.On("HallowBossService", "Attack", Hallow.OnAttack))
    Watch.On(Net.On("HallowBossService", "Reward", Hallow.OnReward))
    Watch.On(Net.On("HallowBossService", "Ended", Hallow.OnEnded))
    Watch.On(Net.On("IslandService", "IslandPortalEncountered", World.OnIsland))
    Watch.On(Net.On("IslandService", "IslandUnlockResult", World.OnResult))
    Watch.On(Net.On("WorldService", "PortalEncountered", World.OnZone))
    Watch.On(Net.On("BreakableService", "Rewarded", function(info)
        if type(info) == "table" then
            State.ChestCoins += Util.Num(info.Coins, 0)
        end
    end))
    Move.Start()
    Watch.On(LocalPlayer.CharacterAdded:Connect(function()
        Mover:Wake("move", 1)
    end))
end

Lists = { Eggs = { Eggs.AUTO }, Islands = { "Spawn" }, Zones = {}, Rebirth = { "Best Unlocked", "Best Affordable" }, Mobs = {} }

function Lists.Load()
    Util.AsIdentity(2)
    Game.Module("LaunchEggConfig")
    Game.Module("IslandConfig")
    Game.Module("ProgressionConfig")
    Lists.Eggs = { Eggs.AUTO }
    for _, name in Eggs.Names() do
        table.insert(Lists.Eggs, name)
    end
    Pets.LoadSpecies()
    Mine.LoadDaily()
    local odds = Game.Module("PetOdds")
    if odds and type(odds.MutationFactors) == "table" then
        for name in odds.MutationFactors do
            local present = false
            for _, existing in Pets.MUTATIONS do
                if existing == name then
                    present = true
                    break
                end
            end
            if not present then
                table.insert(Pets.MUTATIONS, name)
            end
        end
    end
    Hallow.LoadShop()
    Game.Module("IslandBreakableConfig")
    Lists.Mobs = Mobs.LoadTitles()
    Lists.Islands = World.Islands()
    Lists.Zones = World.Zones()
    local boostConfig = Game.Module("BoostConfig")
    Items.Boosts = {}
    if boostConfig and type(boostConfig.Definitions) == "table" then
        for name in boostConfig.Definitions do
            if name ~= "FriendBoost" then
                table.insert(Items.Boosts, name)
            end
        end
        table.sort(Items.Boosts)
    end
    local brew = Game.Module("PotionBrewConfig")
    Items.Brewable = brew and type(brew.Potions) == "table" and brew.Potions or {}
    local honey = Game.Module("HoneyPotConfig")
    Items.Recipes = {}
    if honey and type(honey.ByKey) == "table" then
        for key in honey.ByKey do
            table.insert(Items.Recipes, key)
        end
        table.sort(Items.Recipes)
    end
    local catalog = Game.Module("ItemCatalog")
    Items.PetItems = {}
    if catalog then
        local all = Util.Fn(catalog, "GetAll")
        if type(all) == "table" then
            for name in all do
                if type(name) == "string" and (name:find("Treat", 1, true) or name:find("Fruit", 1, true)
                    or name:find("Apple", 1, true) or name:find("Strawberry", 1, true) or name:sub(1, 3) == "Pet") then
                    table.insert(Items.PetItems, name)
                end
            end
            table.sort(Items.PetItems)
        end
    end
    local shrine = Game.Module("ShrineConfig")
    Events.Blessings = {}
    if shrine and type(shrine.Order) == "table" and type(shrine.Blessings) == "table" then
        for _, key in shrine.Order do
            local entry = shrine.Blessings[key]
            table.insert(Events.Blessings, { Key = key, Name = (type(entry) == "table" and entry.Name) or key })
        end
    end
    local enchant = Game.Module("EnchantConfig")
    Enchant.Names = {}
    if enchant and type(enchant.Enchants) == "table" then
        for name in enchant.Enchants do
            if type(enchant.IsFilterable) ~= "function" or Util.Fn(enchant, "IsFilterable", name) == true then
                table.insert(Enchant.Names, name)
            end
        end
        table.sort(Enchant.Names)
    end
    Game.Module("EnchantSpins")
    Lists.Rebirth = Rebirth.Labels()
end

function Lists.Names(cards)
    local out = {}
    for _, card in cards do
        table.insert(out, card.Name)
    end
    return out
end


--== Interface (Lumin, tabboxed groupboxes) ==--

do
    local done = false
    task.spawn(function()
        local ok, err = pcall(Lists.Load)
        if not ok then
            warn("[Lumin] lists: " .. tostring(err))
        end
        done = true
    end)
    local started = os.clock()
    while not done and os.clock() - started < 20 do
        task.wait(0.05)
    end
end

local Window = Library:CreateWindow({
    Title = Config.Title,
    Footer = Config.Footer .. "  |  v" .. Version,
    Icon = hubIcon(),
    Size = UDim2.fromOffset(960, 680),
    MobileSize = UDim2.fromOffset(610, 450),
    Compact = true,
    ToggleKeybind = Enum.KeyCode.RightShift,
    Center = true,
    AutoShow = true,
    CornerRadius = 10,
})

do
    local host = Library.Host
    local view = type(host) == "table" and type(host.Views) == "table" and host.Views[2] or nil
    local layouts = type(view) == "table" and view.MobileLayouts or nil
    if typeof(layouts) == "Instance" then
        for _, layout in ipairs(layouts:GetChildren()) do
            if layout.Name ~= "Landscape" and layout.Name ~= "Portrait" then
                layout:Destroy()
            end
        end
    end
end

local Tabs = {
    Dashboard = Window:AddTab("Dashboard", "square-user", "Session, stats and activity."),
    Farm = Window:AddTab("Farm", "hand", "The core loop: tap, hatch income, rebirth, buy, claim."),
    Pets = Window:AddTab("Pets", "paw-print", "Hatching, pets, delete and the index."),
    Workshop = Window:AddTab("Workshop", "sparkles", "Machines, enchanting and consumables."),
    Activities = Window:AddTab("Activities", "gamepad-2", "Minigames and seasonal events."),
    World = Window:AddTab("World", "map", "Islands, zones and unlocks."),
    Visuals = Window:AddTab("Visuals", "eye", "ESP and performance."),
    Webhook = Window:AddTab("Webhook", "bell", "Discord webhook posts."),
    System = Window:AddTab("System", "settings", "Player, server, menu, themes and configs."),
}

local function groupTabs(tab, side, title, icon)
    local box = side == "R" and tab:AddRightGroupbox(title, icon) or tab:AddLeftGroupbox(title, icon)
    return box:AddTabbox()
end

local function sub(box, name, icon)
    return box:AddTab({ Name = name, Icon = icon })
end

local pillColors = {
    idle = "rgb(150, 150, 150)", info = "rgb(120, 180, 255)", running = "rgb(80, 220, 120)",
    success = "rgb(80, 220, 120)", warning = "rgb(255, 200, 80)", error = "rgb(255, 90, 90)",
}

local Pills, Bars, Boards, Labels = {}, {}, {}, {}

local function makePill(parent, id, text)
    local label = parent:AddLabel(text .. ": off", true)
    Pills[id] = {
        Set = function(_, status, kind)
            local color = pillColors[kind] or pillColors.info
            pcall(label.SetText, label, ('%s: <font color="%s">%s</font>'):format(text, color, tostring(status)))
        end,
    }
end

local function makeBar(parent, id, text, formatFn)
    local label = parent:AddLabel(text .. ": 0 / 0", true)
    Bars[id] = {
        Set = function(_, labelText, value, max)
            local frac = max > 0 and math.clamp(value / max, 0, 1) or 0
            local filled = math.floor(frac * 12 + 0.5)
            local shown = formatFn and formatFn(value, max) or (Util.Short(value) .. " / " .. Util.Short(max))
            pcall(label.SetText, label, ("%s: %s  [%s]"):format(labelText, shown, string.rep("#", filled) .. string.rep("-", 12 - filled)))
        end,
    }
end

local function makeBoard(parent, id, title, empty)
    local label = parent:AddLabel(title and (title .. ":\n" .. empty) or empty, true)
    Boards[id] = {
        SetRows = function(_, rows)
            local out = {}
            if title then
                table.insert(out, title .. ":")
            end
            if not rows or #rows == 0 then
                table.insert(out, empty)
            else
                for _, row in rows do
                    local cells = {}
                    for _, cell in row do
                        table.insert(cells, type(cell) == "table" and tostring(cell.Text) or tostring(cell))
                    end
                    table.insert(out, table.concat(cells, "  |  "))
                end
            end
            pcall(label.SetText, label, table.concat(out, "\n"))
        end,
    }
end

local function makeLabel(parent, id)
    Labels[id] = parent:AddLabel("", true)
    return Labels[id]
end

local HomeStats = {}

-- Dashboard ----------------------------------------------------------------------------------
do
    local hasThumb, thumbUrl = pcall(function()
        return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    pcall(function()
        Tabs.Dashboard:AddPlayerPanel({
            AssetId = hasThumb and thumbUrl or nil,
            ImageSize = UDim2.fromOffset(64, 64),
            AvatarBoxSize = UDim2.fromOffset(72, 72),
            Height = 100,
            TopOffset = 10,
            Title = string.format('<b>Welcome To <font color="rgb(199, 0, 255)">Lumin</font>, @%s!</b>', LocalPlayer.Name),
            Subtitle = "",
            Lines = {
                'Hub: <b><font color="rgb(199, 0, 255)">Lumin Hub</font></b>',
                string.format('Game: <b><font color="rgb(199, 0, 255)">%s</font></b>', GameName),
                string.format('Version: <b><font color="rgb(199, 0, 255)">v%s</font></b>', Version),
            },
        })
    end)

    local session = groupTabs(Tabs.Dashboard, "L", "Session", "activity")
    local stats = sub(session, "Stats", "chart-bar")
    HomeStats.Coins = stats:AddLabel("Coins: 0", true)
    HomeStats.Gems = stats:AddLabel("Gems: 0", true)
    HomeStats.Rebirths = stats:AddLabel("Rebirths: 0", true)
    HomeStats.Earned = stats:AddLabel("Coins This Session: 0", true)
    HomeStats.Hatched = stats:AddLabel("Hatched: 0", true)
    HomeStats.Secrets = stats:AddLabel("Secrets: 0", true)
    local activity = sub(session, "Activity", "list")
    makePill(activity, "Job", "Job loop")
    makeLabel(activity, "Log")

    local about = groupTabs(Tabs.Dashboard, "R", "About", "sparkle")
    local overview = sub(about, "Overview", "square-user")
    overview:AddLabel("Game: " .. GameName .. "\nScript: Lumin Hub v" .. Version .. "\nDiscord: discord.gg/luminhub\nPlace Version: " .. tostring(game.PlaceVersion), true)
    local news = sub(about, "Changelog", "history")
    for _, entry in News do
        news:AddLabel(("<b>%s</b>  (%s)\n%s"):format(tostring(entry.Title), tostring(entry.Date), tostring(entry.Text)), true)
    end
end

-- Farm ---------------------------------------------------------------------------------------
do
    local core = groupTabs(Tabs.Farm, "L", "Core Loop", "hand")
    local click = sub(core, "Clicking", "mouse-pointer-click")
    makePill(click, "Tap", "Auto click")
    click:AddToggle("AutoTap", { Text = "Auto Click", Default = false,
        Tooltip = "Always taps with the hub's own clicker; the game auto clicker is left alone.", Callback = Auto.OnTap })
    makePill(click, "Chests", "World chests")
    click:AddToggle("AutoChests", { Text = "Auto Break Chests", Default = false, Callback = Auto.WakeMove })
    click:AddToggle("TapBestIsland", { Text = "Tap On Best Island", Default = false, Callback = Auto.WakeMove })
    makeLabel(click, "Tap")

    local rebirth = sub(core, "Rebirth", "rotate-cw")
    makePill(rebirth, "Rebirth", "Auto rebirth")
    rebirth:AddDropdown("RebirthPick", { Text = "Rebirth", Values = Lists.Rebirth, Default = "Best Unlocked", AllowNull = false, Callback = Auto.WakeJob("rebirth") })
    rebirth:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = Auto.OnRebirth })
    makeBar(rebirth, "Rebirth", "Next rebirth", function(value, max)
        return ("%s / %s"):format(Util.Short(value), Util.Short(max))
    end)
    makeBoard(rebirth, "Rebirth", "Slots", "loading")

    local support = groupTabs(Tabs.Farm, "R", "Support", "shopping-cart")
    local buy = sub(support, "Auto Buy", "shopping-cart")
    makePill(buy, "Shop", "Auto buy")
    buy:AddToggle("AutoBuy", { Text = "Auto Buy", Default = false, Callback = Auto.WakeJob("shop") })
    buy:AddDropdown("AutoBuyPick", { Text = "Buy", Values = Shop.KINDS, Multi = true, NoMode = true, AllowNull = true, Default = { ["Skill Nodes"] = true, Upgrades = true }, Callback = Auto.WakeJob("shop") })
    makeLabel(buy, "Shop")

    local claim = sub(support, "Auto Claim", "gift")
    makePill(claim, "Claim", "Auto claim")
    claim:AddToggle("AutoClaim", { Text = "Auto Claim", Default = false, Callback = function() Bg:Wake("claims") Mover:Wake("move") end })
    claim:AddDropdown("ClaimPick", { Text = "Claim", Values = Claims.KINDS, Multi = true, NoMode = true, AllowNull = true,
        Default = { Quests = true, ["Index Rewards"] = true, Gifts = true, ["Offline Rewards"] = true, ["Shiny Stars"] = true },
        Callback = function() Bg:Wake("claims") Mover:Wake("move") end })
    makeBar(claim, "Stars", "Shiny stars")

    local prio = sub(support, "Priority", "list")
    prio:AddLabel("0 = auto (current order)\n1 = first", true)
    local trips = {}
    for _, def in Brain.TASKS do
        if not def.Quick then
            table.insert(trips, def)
        end
    end
    for _, def in trips do
        prio:AddSlider("Prio" .. def.Key, { Text = def.Title, Min = 0, Max = #trips, Default = 0, Rounding = 0, Callback = Auto.WakeMove })
    end
    prio:AddButton("Reset All To Auto", function()
        for _, def in trips do
            local option = Options["Prio" .. def.Key]
            if option then
                pcall(option.SetValue, option, 0)
            end
        end
    end)
end

-- Pets ---------------------------------------------------------------------------------------
do
    local hatchSide = groupTabs(Tabs.Pets, "L", "Hatching", "egg")
    local hatch = sub(hatchSide, "Auto Hatch", "egg")
    makePill(hatch, "Hatch", "Auto hatch")
    hatch:AddDropdown("HatchEgg", { Text = "Egg", Values = Lists.Eggs, Default = Eggs.AUTO, AllowNull = false, Searchable = true, Callback = Auto.WakeMove })
    hatch:AddToggle("AutoHatch", { Text = "Auto Hatch", Default = false, Callback = Auto.OnHatch })
    hatch:AddToggle("HideHatch", { Text = "Hide Hatch Animation", Default = false, Callback = Eggs.Hide })
    hatch:AddToggle("AutoHoldSecret", { Text = "Auto Hold Secret Pop-Up", Default = true })
    makeLabel(hatch, "Hatch")
    local eggList = sub(hatchSide, "Egg List", "list")
    makeBoard(eggList, "Eggs", nil, "loading")

    local petSide = groupTabs(Tabs.Pets, "R", "Pets", "paw-print")
    local pets = sub(petSide, "Equip", "paw-print")
    makePill(pets, "Equip", "Equip best")
    pets:AddToggle("AutoEquip", { Text = "Auto Equip Best", Default = false, Callback = Auto.WakeJob("equip") })
    pets:AddDropdown("EquipMode", { Text = "Best For", Values = Pets.MODES, Default = "Clicks", AllowNull = false, Callback = Auto.WakeJob("equip") })
    makeBar(pets, "Storage", "Storage")

    local delete = sub(petSide, "Auto Delete", "trash-2")
    makePill(delete, "Delete", "Auto delete")
    delete:AddDropdown("DeleteRarities", { Text = "Rarities", Values = Pets.RARITIES, Multi = true, NoMode = true, AllowNull = true, Default = {}, Callback = Auto.WakeJob("delete") })
    delete:AddDropdown("DeleteTiers", { Text = "Tiers (none = Normal)", Values = Pets.TIERS, Multi = true, NoMode = true, AllowNull = true, Default = {}, Callback = Auto.WakeJob("delete") })
    delete:AddDropdown("DeleteMutations", { Text = "Mutations (none = keep)", Values = Pets.MUTATIONS, Multi = true, NoMode = true, AllowNull = true, Default = { Shiny = true, Void = true, Galaxy = true, Bloodmoon = true, Ghost = true }, Callback = Auto.WakeJob("delete") })
    delete:AddInput("DeleteBelow", { Text = "Delete Below 1 In", Default = "", Placeholder = "e.g. 1k, 1m", Finished = true, Callback = Auto.WakeJob("delete") })
    delete:AddToggle("AutoDelete", { Text = "Auto Delete", Default = false, Tooltip = "Deletes pets matching the filters. Equipped, locked and Secret pets are never touched.", Callback = Auto.WakeJob("delete") })

    local index = sub(petSide, "Index & Mastery", "list")
    makePill(index, "Index", "Index farm")
    index:AddToggle("AutoIndex", { Text = "Auto Farm Index", Default = false, Callback = function() Pets.IndexAt = 0 Auto.WakeMove() Bg:Wake("claims") end })
    index:AddInput("IndexMaxOdds", { Text = "Skip Rarer Than 1 In", Default = "", Placeholder = "10k", Finished = true, Callback = function() Pets.IndexAt = 0 Auto.WakeMove() end })
    index:AddToggle("GoldenMastery", { Text = "Farm Golden Mastery", Default = false, Callback = Auto.WakeMove })
    index:AddToggle("AutoRelic", { Text = "Auto Equip Mastery Relic", Default = false, Callback = Auto.WakeJob("relic") })
    makeLabel(index, "Index")

    local rare = sub(petSide, "Rare Hatches", "sparkles")
    makeBoard(rare, "Recent", nil, "nothing rare yet")
    makeBoard(rare, "Pity", "Secret pity", "no pity yet")
end

-- Workshop -----------------------------------------------------------------------------------
do
    local craftSide = groupTabs(Tabs.Workshop, "L", "Machines", "sparkles")
    local craft = sub(craftSide, "Crafting", "sparkles")
    makePill(craft, "Craft", "Auto craft")
    craft:AddToggle("AutoCraft", { Text = "Auto Craft", Default = false, Callback = Auto.WakeMove })
    craft:AddDropdown("CraftPick", { Text = "Machines", Values = Craft.MACHINES, Multi = true, NoMode = true, AllowNull = true, Default = { Golden = true, Diamond = true }, Callback = Auto.WakeMove })
    craft:AddDropdown("RainbowPets", { Text = "Rainbow Pets", Values = Craft.RAINBOW, Default = Craft.RAINBOW[1], AllowNull = false, Callback = Auto.WakeMove })
    craft:AddToggle("AutoFusionClaim", { Text = "Auto Claim Fusion Egg", Default = false, Callback = Auto.WakeMove })
    craft:AddToggle("CraftMutated", { Text = "Craft Mutated Pets", Default = false, Callback = Auto.WakeMove })
    craft:AddToggle("CraftWhenFull", { Text = "Craft When Storage Full", Default = false, Callback = Auto.WakeMove })
    craft:AddDropdown("CraftSpecies", { Text = "Pets (none = all)", Values = Pets.Species, Multi = true, NoMode = true, AllowNull = true, Searchable = true, Default = {}, Callback = Auto.WakeMove })
    makeLabel(craft, "Craft")

    local enchant = sub(craftSide, "Enchanting", "gem")
    makePill(enchant, "Enchant", "Auto enchant")
    enchant:AddToggle("AutoEnchant", { Text = "Auto Enchant", Default = false, Callback = Auto.WakeMove })
    local enchantPets = table.clone(Enchant.TARGETS)
    for _, name in Pets.Species do
        table.insert(enchantPets, name)
    end
    enchant:AddDropdown("EnchantPet", { Text = "Pet", Values = enchantPets, Default = Enchant.FIRST, AllowNull = false, Searchable = true, Callback = Auto.WakeMove })
    enchant:AddDropdown("EnchantSlot", { Text = "Slot", Values = { "1", "2" }, Default = "1", AllowNull = false, Callback = Auto.WakeMove })
    enchant:AddDropdown("EnchantWants", { Text = "Stop On", Values = Enchant.Names, Multi = true, NoMode = true, AllowNull = true, Default = {}, Callback = Auto.WakeMove })
    enchant:AddInput("EnchantMaxPrice", { Text = "Max Roll Price (0 = none)", Default = "", Placeholder = "e.g. 5m, 1b", Finished = true, Callback = Auto.WakeMove })

    local useSide = groupTabs(Tabs.Workshop, "R", "Consumables", "flask-conical")
    local boosts = sub(useSide, "Boosts", "zap")
    makePill(boosts, "Boosts", "Auto boosts")
    boosts:AddToggle("BoostsWhileHatching", { Text = "Only While Hatching", Default = true, Callback = Auto.WakeJob("boosts") })
    boosts:AddToggle("AutoBoosts", { Text = "Auto Use Boosts", Default = false, Callback = Auto.WakeJob("boosts") })
    boosts:AddDropdown("BoostPick", { Text = "Boosts", Values = Items.Boosts, Multi = true, NoMode = true, AllowNull = true, Searchable = true, Default = {}, Callback = Auto.WakeJob("boosts") })
    makeBoard(boosts, "Boosts", nil, "no boosts")

    local feed = sub(useSide, "Pet Items", "cookie")
    makePill(feed, "Feed", "Pet items")
    feed:AddToggle("AutoPetItems", { Text = "Auto Use Pet Items", Default = false, Callback = Auto.WakeJob("items") })
    feed:AddDropdown("PetItemPick", { Text = "Items", Values = Items.PetItems, Multi = true, NoMode = true, AllowNull = true, Searchable = true, Default = {}, Callback = Auto.WakeJob("items") })

    local potions = sub(useSide, "Potions & Honey", "beaker")
    makePill(potions, "Potion", "Potions")
    potions:AddToggle("AutoBrew", { Text = "Auto Brew + Claim", Default = false, Callback = Auto.WakeMove })
    potions:AddDropdown("BrewPick", { Text = "Brew", Values = Items.Brewable, Default = Items.Brewable[1], AllowNull = false, Callback = Auto.WakeMove })
    potions:AddToggle("AutoMerge", { Text = "Auto Merge Potions", Default = false, Callback = Auto.WakeMove })
    makePill(potions, "Honey", "Honey pot")
    potions:AddToggle("AutoHoney", { Text = "Auto Honey Pot", Default = false, Callback = Auto.WakeMove })
    potions:AddDropdown("HoneyPick", { Text = "Recipe", Values = Items.Recipes, Default = Items.Recipes[1], AllowNull = false, Callback = Auto.WakeMove })

    local totems = sub(useSide, "Totems", "landmark")
    totems:AddToggle("AutoTotems", { Text = "Auto Place Totems (while hatching)", Default = false, Callback = Auto.WakeJob("totems") })
    totems:AddDropdown("TotemPick", { Text = "Totems", Values = { "TotemOfLuck", "TotemOfSecretLuck", "TotemOfHatchSpeed", "TotemOfRebirths", "TotemOfClicks" },
        Multi = true, NoMode = true, AllowNull = true, Default = { TotemOfLuck = true, TotemOfSecretLuck = true, TotemOfHatchSpeed = true }, Callback = Auto.WakeJob("totems") })
end

-- Activities ---------------------------------------------------------------------------------
do
    local games = groupTabs(Tabs.Activities, "L", "Minigames", "gamepad-2")
    local arena = sub(games, "Pet Defense", "swords")
    makePill(arena, "Arena", "Pet defense")
    arena:AddToggle("AutoArena", { Text = "Auto Pet Defense", Default = false, Callback = Auto.WakeMove })
    arena:AddDropdown("ArenaRelic", { Text = "Relic Offer", Values = Arena.RELICS, Default = "Take Better Relic", AllowNull = false })
    makeLabel(arena, "Arena")

    local memory = sub(games, "Memory & Dig", "layout-grid")
    makePill(memory, "Memory", "Memory match")
    memory:AddToggle("AutoMemory", { Text = "Auto Memory Match", Default = false, Callback = Auto.WakeMove })
    makePill(memory, "Dig", "Dig")
    memory:AddToggle("AutoDig", { Text = "Auto Dig", Default = false, Callback = Auto.WakeMove })

    local mine = sub(games, "Mining", "pickaxe")
    makePill(mine, "Mine", "Mining")
    mine:AddToggle("AutoMine", { Text = "Auto Mine", Default = false, Callback = Auto.WakeMove })
    mine:AddToggle("MineSell", { Text = "Auto Sell", Default = true })
    mine:AddToggle("MineGear", { Text = "Auto Buy Pickaxes + Bags", Default = true })
    mine:AddToggle("MineDaily", { Text = "Auto Buy Daily Shop", Default = false })
    mine:AddDropdown("MineDailyPick", { Text = "Daily Items (none = all packs)", Values = Mine.DailyNames, Multi = true, NoMode = true, AllowNull = true, Default = {} })
    makeLabel(mine, "Mine")

    local seasonal = groupTabs(Tabs.Activities, "R", "Seasonal", "ghost")
    local boss = sub(seasonal, "Hallow Lord", "skull")
    makePill(boss, "Boss", "Hallow Lord")
    boss:AddToggle("AutoBoss", { Text = "Auto Fight Hallow Lord", Default = false, Callback = Auto.WakeMove })
    boss:AddToggle("BossDodge", { Text = "Dodge Bombs", Default = true })

    local trick = sub(seasonal, "Trick-or-Treat", "candy")
    makePill(trick, "Trick", "Trick-or-treat")
    trick:AddToggle("AutoTrick", { Text = "Auto Trick-or-Treat", Default = false, Callback = Auto.WakeMove })
    trick:AddToggle("AutoWitch", { Text = "Auto Accept Candy Witch Quests", Default = false, Callback = Auto.WakeMove })

    local moon = sub(seasonal, "Blood Moon & Shop", "moon")
    makePill(moon, "Moon", "Blood Moon")
    moon:AddToggle("AutoDial", { Text = "Auto Use Blood Moon Dial", Default = false, Callback = Auto.WakeJob("dial") })
    moon:AddToggle("MoonFocus", { Text = "Only Hatch During Blood Moon", Default = false, Callback = Auto.WakeMove })
    makePill(moon, "HShop", "Halloween shop")
    moon:AddToggle("AutoHallowShop", { Text = "Auto Buy", Default = false, Callback = Auto.WakeJob("hallowshop") })
    moon:AddDropdown("HallowShopPick", { Text = "Items", Values = Hallow.ShopNames, Multi = true, NoMode = true, AllowNull = true, Searchable = true,
        Default = { BloodMoonDial = true, ["Octo Incubator"] = true, TotemOfSecretLuck = true, TotemOfLuck = true }, Callback = Auto.WakeJob("hallowshop") })
    makeLabel(moon, "HShop")

    local wild = sub(seasonal, "Wild Events", "bird")
    makePill(wild, "Balloons", "Balloon party")
    wild:AddToggle("AutoBalloons", { Text = "Auto Pop Balloons", Default = false, Callback = function() Events.BalloonKick:Fire() end })
    makePill(wild, "Mobs", "Island mobs")
    wild:AddToggle("AutoMobs", { Text = "Auto Kill Mobs", Default = false, Callback = Auto.WakeMove })
    wild:AddDropdown("MobPick", { Text = "Mobs (none = all)", Values = Lists.Mobs, Multi = true, NoMode = true, AllowNull = true, Default = {}, Callback = Auto.WakeMove })
    makePill(wild, "Duck", "Lucky ducky")
    wild:AddToggle("AutoDucky", { Text = "Auto Catch Lucky Ducky", Default = false, Callback = Auto.WakeJob("ducky") })
    makePill(wild, "Shrine", "Shrine")
    wild:AddDropdown("ShrinePick", { Text = "Blessing", Values = Lists.Names(Events.Blessings), Default = (Events.Blessings[1] or {}).Name, AllowNull = false, Callback = Auto.WakeMove })
    wild:AddToggle("AutoShrine", { Text = "Auto Shrine Blessing", Default = false, Callback = Auto.WakeMove })
end

-- World --------------------------------------------------------------------------------------
do
    local travel = groupTabs(Tabs.World, "L", "Travel", "map-pin")
    local islands = sub(travel, "Islands", "map-pin")
    makePill(islands, "Unlock", "Auto unlock")
    islands:AddToggle("AutoUnlock", { Text = "Auto Unlock Islands + Zones", Default = false, Callback = Auto.WakeMove })
    islands:AddToggle("SaveForUnlock", { Text = "Save For Next Island", Default = false, Callback = function() Mover:Wake("move") Bg:Wake("rebirth") end })
    islands:AddDropdown("IslandPick", { Text = "Island", Values = Lists.Islands, Default = "Spawn", AllowNull = false })
    islands:AddButton("Travel", function()
        task.spawn(function()
            Util.AsIdentity(2)
            World.Travel(tostring(Library.Flags.IslandPick or "Spawn"))
        end)
    end)
    makeBar(islands, "Islands", "Islands")

    local zonesSide = groupTabs(Tabs.World, "R", "Travel", "map")
    local zones = sub(zonesSide, "Zones", "map")
    zones:AddDropdown("ZonePick", { Text = "Zone", Values = Lists.Zones, Default = Lists.Zones[1], AllowNull = false })
    zones:AddButton("Travel", function()
        task.spawn(function()
            Util.AsIdentity(2)
            World.TravelZone(tostring(Library.Flags.ZonePick or "Spawn"))
        end)
    end)
    makeLabel(zones, "World")
end

-- Visuals ------------------------------------------------------------------------------------
do
    local visual = groupTabs(Tabs.Visuals, "L", "Visuals", "eye")
    local esp = sub(visual, "ESP", "eye")
    esp:AddToggle("EspOn", { Text = "ESP", Default = false, Callback = Esp.Apply })
    esp:AddDropdown("EspShow", { Text = "Show", Values = Esp.ShowNames, Multi = true, NoMode = true, AllowNull = true, Default = { ["Shiny Stars"] = true }, Callback = Esp.Apply })
    esp:AddDropdown("EspDraw", { Text = "Draw", Values = Esp.DrawNames, Multi = true, NoMode = true, AllowNull = true, Default = { Names = true, Distance = true }, Callback = Esp.Apply })

    local perf = sub(visual, "Performance", "monitor")
    perf:AddToggle("FpsBoost", { Text = "Ultra FPS Boost", Default = false, Callback = Boost.Apply })
    perf:AddToggle("NoRender", { Text = "Disable 3D Rendering", Default = false, Callback = Boost.Render })
    perf:AddToggle("HidePopups", { Text = "Hide Popups", Default = false, Callback = Boost.Popups })
    perf:AddToggle("AutoClose", { Text = "Auto Close Popups", Default = true, Callback = Popup.Apply })
    perf:AddButton({
        Text = "Stop Everything",
        Func = Auto.StopAll,
        WarningPopup = true,
        WarningText = "This turns every automation toggle off.",
    })
end

-- Webhook ------------------------------------------------------------------------------------
do
    local hookSide = groupTabs(Tabs.Webhook, "L", "Webhook", "bell")
    local hook = sub(hookSide, "Webhook", "bell")
    hook:AddToggle("Webhook", { Text = "Enable Webhook", Default = false })
    hook:AddInput("WebhookUrl", { Text = "Webhook URL", Default = "", Placeholder = "https://discord.com/api/webhooks/...", Finished = true })
    hook:AddInput("WebhookUser", { Text = "Discord User ID (ping)", Default = "", Placeholder = "123456789012345678", Numeric = true, Finished = true })
    hook:AddToggle("WhEveryone", { Text = "Mention @everyone", Default = false })
    hook:AddToggle("WhHatch", { Text = "Hatch Webhook", Default = true })
    hook:AddToggle("WhArena", { Text = "Pet Defense Webhook", Default = false })
    hook:AddToggle("WhKick", { Text = "Kick Webhook", Default = true })
    hook:AddButton("Send Test Post", function()
        Webhook.Test()
    end)
    makeLabel(hook, "Webhook")

    local filterSide = groupTabs(Tabs.Webhook, "R", "Webhook", "search")
    local filter = sub(filterSide, "Notify Filter", "search")
    filter:AddDropdown("WhRarities", { Text = "Rarities", Values = Webhook.RARITIES, Multi = true, NoMode = true, AllowNull = true, Default = { Secret = true, Mythical = true } })
    filter:AddDropdown("WhTiers", { Text = "Tiers", Values = Pets.TIERS, Multi = true, NoMode = true, AllowNull = true, Default = {} })
    filter:AddDropdown("WhEggs", { Text = "Eggs", Values = Eggs.Names(), Multi = true, NoMode = true, AllowNull = true, Searchable = true, Default = {} })
    filter:AddInput("WhMinOdds", { Text = "Min Odds 1 In (0 = any)", Default = "", Placeholder = "e.g. 10k, 1m", Finished = true })
end

-- System -------------------------------------------------------------------------------------
local MenuGB
do
    local systemSide = groupTabs(Tabs.System, "L", "System", "wrench")
    local player = sub(systemSide, "Player", "user")
    player:AddToggle("WalkSpeedOn", { Text = "WalkSpeed", Default = false, Callback = Move.ApplySpeed })
    player:AddSlider("WalkSpeed", { Text = "Walk Speed", Min = 16, Max = 200, Default = 50, Rounding = 0, Callback = Move.ApplySpeed })
    player:AddToggle("InfiniteJump", { Text = "Infinite Jump", Default = false })

    local server = sub(systemSide, "Server", "server")
    server:AddLabel("Job ID: " .. tostring(game.JobId), true)
    server:AddButton("Copy Job ID", Server.CopyJobId)
    server:AddInput("JoinJobId", { Text = "Join Job ID", Default = "", Placeholder = "paste a Job ID", Finished = false, Callback = Server.OnJobId })
    server:AddButton("Join Server", Server.Join)
    server:AddButton("Rejoin", Server.Rejoin)
    server:AddButton("Server Hop", Server.Hop)

    local settingsSide = groupTabs(Tabs.System, "R", "Settings", "settings")
    MenuGB = sub(settingsSide, "Menu", "align-center")
    MenuGB:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        Mode = "Toggle",
        Modes = { "Toggle" },
        NoUI = true,
    })
    Library.ToggleKeybind = Options.MenuKeybind
    MenuGB:AddToggle("AntiAfk", { Text = "Anti AFK", Default = true })
    MenuGB:AddToggle("AutoExecute", { Text = "Auto Execute", Default = false, Callback = Session.OnExecute })
    MenuGB:AddToggle("AutoReconnect", { Text = "Auto Reconnect", Default = false, Callback = Session.OnReconnect })
    MenuGB:AddToggle("ShowWatermark", {
        Text = "Show Watermark",
        Default = true,
        Callback = function(value)
            Library:SetWatermarkVisibility(value)
        end,
    })
    MenuGB:AddDropdown("DPIDropdown", {
        Text = "DPI Scale",
        Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Default = "100%",
        AllowNull = false,
        Callback = function(value)
            Library:SetDPIScale(tonumber((value:gsub("%%", ""))))
        end,
    })
    MenuGB:AddDivider()
    MenuGB:AddButton("Unload", function()
        Library:Unload()
    end)
end

local Appearance = Library:BuildAppearanceSection(Tabs.System, {
    Menu = MenuGB,
    Theme = Tabs.System:AddRightGroupbox("Theme", "paintbrush"),
    ManagedTheme = true,
})

task.spawn(function()
    local frames, lastTick = 0, os.clock()
    local stats = game:GetService("Stats")
    -- Tracked: an untracked counter keeps ticking after unload, and re-executing
    -- the hub would leave one running per generation.
    pcall(function()
        FrameLink = RunService.RenderStepped:Connect(function()
            frames += 1
        end)
    end)
    while not Library.Unloaded do
        task.wait(1)
        local now = os.clock()
        local fps = math.floor(frames / math.max(now - lastTick, 0.001) + 0.5)
        frames, lastTick = 0, now
        local ping = 0
        pcall(function()
            ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        pcall(Library.SetWatermark, Library, ("Lumin Hub | %d fps | %d ms"):format(fps, ping))
    end
end)

Library:SetWatermarkVisibility(true)
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind", "JoinJobId" })
ThemeManager:SetFolder(Config.ThemeFolder)
SaveManager:SetFolder(Config.Folder)
SaveManager:SetSubFolder(Config.SubFolder)
SaveManager:BuildConfigSection(Tabs.System)
ThemeManager:ApplyToGroupbox(Appearance.ThemeTabs:AddTab({ Name = "Saved themes", Icon = "swatch-book" }), {
    Colors = Appearance.Colors,
    Typography = Appearance.Typography,
})
pcall(function()
    SaveManager:LoadAutoloadConfig()
end)

pcall(function()
    game:GetService("GuiService").ErrorMessageChanged:Connect(function()
        task.spawn(function()
            Util.AsIdentity(2)
            pcall(Webhook.OnError)
            pcall(Session.OnError)
        end)
    end)
end)


--== Sampler and painter ==--
-- The sampler reads game state into plain values; the painter only touches
-- those values and the UI, so UI writes never call game code.

local View = { Pill = {}, Bar = {}, Rows = {}, RowSig = {}, Text = {}, TapAt = os.clock(), TapCount = 0, TapRate = 0 }

local function pill(name, text, kind)
    View.Pill[name] = { tostring(text), kind or "info" }
end

local function pillKind(text)
    local lower = tostring(text or ""):lower()
    if lower == "" or lower == "off" then
        return "idle"
    end
    for _, word in { "refused", "failed", "no answer", " star: ", "brew: ", "claim: ", "craft: ", "merge: ", "shrine: " } do
        if lower:find(word, 1, true) then
            return "error"
        end
    end
    for _, word in { "paused", "saving for", "pick a", "equip a", "out of", "needs ", "not loaded", "not here", "is locked" } do
        if lower:find(word, 1, true) then
            return "warning"
        end
    end
    for _, word in { "claimed", "bought", "unlocked", "caught", "won", "found", "rebirthed", "opened", "deleted", "took", "equipped", "merged", "crafts sent", "drank", "fed" } do
        if lower:find(word, 1, true) then
            return "success"
        end
    end
    for _, word in { "waiting", "next ", "travelling", "back in", "ready in", "loading" } do
        if lower:find(word, 1, true) then
            return "info"
        end
    end
    return "running"
end

local function switch(name, on, text)
    if not on then
        pill(name, "off", "idle")
    else
        text = (text ~= nil and text ~= "") and text or "on"
        pill(name, text, pillKind(text))
    end
end

local function board(name, rows)
    local parts = {}
    for _, row in rows do
        local cells = {}
        for _, cell in row do
            table.insert(cells, type(cell) == "table" and (tostring(cell.Text) .. tostring(cell.Color)) or tostring(cell))
        end
        table.insert(parts, table.concat(cells, ","))
    end
    View.Rows[name] = rows
    View.RowSig[name] = table.concat(parts, "|")
end

local function bar(name, text, value, max)
    View.Bar[name] = { Text = text, Value = math.min(value, math.max(max, 1)), Max = math.max(max, 1) }
end

local function Sample()
    local flags, save = Library.Flags, Data.Save
    if not save then
        pill("Job", "loading", "info")
        return
    end
    local coins, gems = Data.Coins(), Data.Gems()
    World.Rate()
    State.StartCoins = State.StartCoins or Data.Stat("LifetimeCoins")
    local now = os.clock()
    if now - View.TapAt >= 2 then
        View.TapRate = (State.Taps - View.TapCount) / (now - View.TapAt)
        View.TapAt, View.TapCount = now, State.Taps
    end

    if flags.AutoTap == true and Tap.Blocked ~= "" then
        pill("Tap", "paused (" .. Tap.Blocked .. ")", "warning")
    else
        switch("Tap", flags.AutoTap == true, ("%.1f clicks/s"):format(View.TapRate))
    end
    switch("Chests", flags.AutoChests == true, Brain.Doing == "breaking chests" and "breaking chests" or Brk.Note)
    View.Text.Tap = ("Hub taps this session: %s\nChests broken: %d   (+%s coins)"):format(Util.Commas(State.Taps), State.Chests or 0,
        Util.Short(State.ChestCoins or 0))
    switch("Rebirth", flags.AutoRebirth == true, Rebirth.Note)
    do
        local slot = Rebirth.Target()
        local price, amount = Rebirth.Price(slot)
        bar("Rebirth", ("Slot %d  +%s"):format(slot, Util.Short(amount)), coins, price == math.huge and 1 or price)
        local rows = {}
        for index = 1, Rebirth.Slots() do
            local slotPrice, slotAmount = Rebirth.Price(index)
            table.insert(rows, {
                { Text = tostring(index), Color = index == slot and "Accent" or nil },
                "+" .. Util.Short(slotAmount),
                { Text = Util.Short(slotPrice), Color = slotPrice > coins and "Risky" or nil },
            })
        end
        board("Rebirth", rows)
    end
    switch("Shop", flags.AutoBuy == true, Shop.Note)
    do
        local node, price = Shop.NextNode()
        View.Text.Shop = ("Gems: %s%s"):format(Util.Short(gems), node and ("\nNext node: %s (%s)"):format(node, Util.Short(price)) or "")
    end
    switch("Claim", flags.AutoClaim == true, Claims.Note)
    bar("Stars", "Shiny stars", Util.Count(save.ShinyStars and save.ShinyStars.Found), 15)

    switch("Hatch", flags.AutoHatch == true, Eggs.Note)
    View.Text.Hatch = ("Hatched this session: %s   secrets: %d\nLifetime eggs: %s"):format(Util.Commas(State.Hatched), State.Secrets, Util.Commas(Data.Stat("EggsOpened")))
    board("Eggs", Eggs.Rows())
    board("Recent", Eggs.Recent)
    board("Pity", Eggs.PityRows())
    switch("Index", flags.AutoIndex == true, Pets.IndexNote)
    View.Text.Index = Pets.MasteryText()
    switch("Equip", flags.AutoEquip == true, Pets.Note)
    do
        local count, limit = Pets.Count()
        bar("Storage", ("Storage %d/%d"):format(count, limit), count, limit)
    end
    if flags.AutoDelete == true and not Util.PickSet("DeleteRarities") and Util.Amount(flags.DeleteBelow) <= 0 then
        pill("Delete", "pick a rarity or odds", "warning")
    else
        switch("Delete", flags.AutoDelete == true, Pets.DeleteNote ~= "" and Pets.DeleteNote or "waiting for pets")
    end

    switch("Craft", flags.AutoCraft == true, Craft.Note)
    do
        local counts = { Normal = 0, Golden = 0, Diamond = 0 }
        local held = Pets.Held()
        for id, entry in Pets.Owned() do
            if Pets.Spare(id, entry, held) and counts[tostring(entry.Tier or "Normal")] then
                counts[entry.Tier or "Normal"] += 1
            end
        end
        local _, queue = Craft.Ready()
        View.Text.Craft = ("Spare pets: %d normal, %d golden, %d diamond\nRainbow pods: %d/3"):format(counts.Normal, counts.Golden, counts.Diamond, queue)
    end
    switch("Enchant", flags.AutoEnchant == true, Enchant.Note)

    switch("Boosts", flags.AutoBoosts == true, Items.BoostNote)
    do
        local rows, active = {}, save.ActiveBoosts or {}
        for name, count in (save.Boosts or {}) do
            local owned = Util.Num(count, 0)
            if (owned > 0 or Util.Num(active[name], 0) > 0) and name ~= "TapMultiplier" then
                table.insert(rows, { tostring(name), Util.Commas(owned), Util.Num(active[name], 0) > 0 and "yes" or "-" })
            end
        end
        table.sort(rows, function(a, b)
            return a[1] < b[1]
        end)
        board("Boosts", rows)
    end
    switch("Feed", flags.AutoPetItems == true, Items.Note)
    switch("Potion", flags.AutoBrew == true or flags.AutoMerge == true, Items.PotionNote)
    switch("Honey", flags.AutoHoney == true, Items.HoneyNote)
    do
        local readyIn = Events.BalloonIn()
        switch("Balloons", flags.AutoBalloons == true, readyIn <= 0 and (Events.BalloonNote ~= "" and Events.BalloonNote or "party on: popping")
            or ((Events.BalloonNote ~= "" and (Events.BalloonNote .. "   ") or "") .. "next party in " .. Util.Clock(readyIn)))
    end
    do
        local startsIn = Hallow.BossIn()
        switch("Boss", flags.AutoBoss == true, Hallow.Fighting and Hallow.Note or (startsIn <= 0 and "fight on now" or ("next fight in " .. Util.Clock(startsIn)))
            .. (Hallow.Candy > 0 and ("   +" .. Util.Short(Hallow.Candy) .. " candy") or ""))
        local ready = 0
        for id in Hallow.HOUSES do
            if Hallow.HouseReady(id) then
                ready += 1
            end
        end
        switch("Trick", flags.AutoTrick == true or flags.AutoWitch == true, (Hallow.Note ~= "" and not Hallow.Fighting and (Hallow.Note .. "   ") or "") .. ("%d/11 houses ready"):format(ready))
        local moonIn = Hallow.MoonIn()
        switch("Moon", flags.AutoDial == true or flags.MoonFocus == true, moonIn <= 0 and "Blood Moon is up" or ("next Blood Moon in " .. Util.Clock(moonIn)))
        local candy = Util.Num(save.Currencies and save.Currencies.CandyCorn, 0)
        switch("HShop", flags.AutoHallowShop == true, Hallow.ShopNote ~= "" and Hallow.ShopNote or ("Candy Corn " .. Util.Short(candy)))
        View.Text.HShop = "Candy Corn: " .. Util.Commas(candy)
    end
    switch("Mobs", flags.AutoMobs == true, Mobs.Note ~= "" and Mobs.Note or (Mobs.Killed > 0 and ("killed %d"):format(Mobs.Killed) or "waiting for a mob"))
    switch("Duck", flags.AutoDucky == true, State.Ducks > 0 and ("caught %d"):format(State.Ducks) or (Events.Note ~= "" and Events.Note or "waiting for a duck"))
    do
        local held = LocalPlayer:GetAttribute("ShrineBlessing")
        switch("Shrine", flags.AutoShrine == true, Events.ShrineNote ~= "" and Events.ShrineNote or (held and ("holding " .. tostring(held)) or "no blessing"))
    end

    switch("Unlock", flags.AutoUnlock == true, World.Note)
    do
        local owned = 0
        for _, on in Data.Islands() do
            if on == true then
                owned += 1
            end
        end
        bar("Islands", ("Islands %d/%d"):format(owned, #Lists.Islands - 1), owned, #Lists.Islands - 1)
        View.Text.World = ("On %s   income %s/s"):format(Data.Island(), Util.Short(World.CoinRate or 0))
    end

    do
        local wait = Arena.ReadyIn()
        switch("Arena", flags.AutoArena == true, Brain.Doing == "pet defense" and Arena.Note or (wait > 0 and ("next run in " .. Util.Clock(wait)) or (Arena.Note ~= "" and Arena.Note or "ready")))
        View.Text.Arena = ("Best wave: %s"):format(tostring(save.Colosseum and save.Colosseum.BestWave or 0))
        local boardWait = Memory.ReadyIn()
        switch("Memory", flags.AutoMemory == true, boardWait > 0 and ("next board in " .. Util.Clock(boardWait)) or (Memory.Note ~= "" and Memory.Note or "ready"))
        switch("Dig", flags.AutoDig == true, Data.Islands().Autumn ~= true and "needs the Autumn island" or Dig.Note)
        local cave = Data.Islands()["Crystal Cave"] == true
        switch("Mine", flags.AutoMine == true, not cave and "needs the Crystal Cave island" or (Mine.Note ~= "" and Mine.Note or "ready"))
        local mining = save.Mining
        if type(mining) == "table" then
            local mods = Mine.M
            local tool = mods and mods.Config and mods.Config.Tools[Util.Num(mining.Tool, 1)]
            local count, capacity = Mine.Bag()
            View.Text.Mine = ("Mining coins %s   bag %d/%d\n%s   %s blocks mined"):format(Util.Short(Util.Num(mining.Coins, 0)),
                count, capacity == math.huge and 0 or capacity, tool and tool.Name or "Wooden Pickaxe", Util.Short(Util.Num(mining.BlocksMined, 0)))
        else
            View.Text.Mine = cave and "" or "Unlock the Crystal Cave island first"
        end
    end

    View.Text.Webhook = flags.Webhook ~= true and "Off" or (("%d posted   %d queued%s"):format(Webhook.Posted, #Webhook.Queue,
        Webhook.Note ~= "" and ("\n" .. tostring(Webhook.Note)) or ""))
    local jobs = {}
    if Brain.Doing ~= "" then
        table.insert(jobs, Brain.Doing)
    end
    if Bg.Current ~= "" then
        table.insert(jobs, Bg.Current)
    end
    if not Game.Ready then
        pill("Job", "loading", "info")
    elseif #jobs > 0 then
        pill("Job", table.concat(jobs, " + "), "running")
    else
        pill("Job", "waiting for a signal", "info")
    end
    View.Text.Log = table.concat(State.Log, "\n")

    View.StatCoins = Util.Short(coins)
    View.StatGems = Util.Short(gems)
    View.StatRebirths = Util.Short(Data.Rebirths())
    View.StatEarned = Util.Short(math.max(0, Data.Stat("LifetimeCoins") - (State.StartCoins or 0)))
    View.StatHatched = Util.Commas(State.Hatched)
    View.StatSecrets = tostring(State.Secrets)
end

local painted = { Pill = {}, Bar = {}, Rows = {}, Text = {}, At = 0 }
local function Paint()
    local now = os.clock()
    if now - painted.At < 0.25 then
        return
    end
    painted.At = now
    for name, element in Pills do
        local want = View.Pill[name]
        if want then
            local sig = want[1] .. "|" .. want[2]
            if painted.Pill[name] ~= sig then
                painted.Pill[name] = sig
                pcall(element.Set, element, want[1], want[2])
            end
        end
    end
    for name, element in Bars do
        local want = View.Bar[name]
        if want then
            local sig = ("%s|%s|%s"):format(want.Text, tostring(want.Value), tostring(want.Max))
            if painted.Bar[name] ~= sig then
                painted.Bar[name] = sig
                pcall(element.Set, element, want.Text, want.Value, want.Max)
            end
        end
    end
    for name, element in Boards do
        local sig = View.RowSig[name]
        if sig and painted.Rows[name] ~= sig then
            painted.Rows[name] = sig
            pcall(element.SetRows, element, View.Rows[name])
        end
    end
    for name, element in Labels do
        local text = View.Text[name]
        if text ~= nil and painted.Text[name] ~= text then
            painted.Text[name] = text
            pcall(element.SetText, element, text)
        end
    end
    local function stat(element, prefix, value)
        if element and value ~= nil and painted.Text[prefix] ~= value then
            painted.Text[prefix] = value
            pcall(element.SetText, element, prefix .. ": " .. tostring(value))
        end
    end
    stat(HomeStats.Coins, "Coins", View.StatCoins)
    stat(HomeStats.Gems, "Gems", View.StatGems)
    stat(HomeStats.Rebirths, "Rebirths", View.StatRebirths)
    stat(HomeStats.Earned, "Coins This Session", View.StatEarned)
    stat(HomeStats.Hatched, "Hatched", View.StatHatched)
    stat(HomeStats.Secrets, "Secrets", View.StatSecrets)
end
-- Connect straight to the signal, the way the Lumin template does, rather than
-- through Library:Connect: that method is not part of the documented surface, so
-- its argument order is a guess, and a wrong guess here silently costs every
-- dashboard update. Tracked so Cleanup can drop it; otherwise the loop outlives
-- the window and each re-execute stacks another one.
PaintLink = RunService.PostSimulation:Connect(Paint)

--== Startup and cleanup ==--

local function Cleanup()
    Watch.Stop()
    for _, link in { PaintLink, FrameLink } do
        pcall(link.Disconnect, link)
    end
    PaintLink, FrameLink = nil, nil
    if AntiAfk.Connection then
        pcall(AntiAfk.Connection.Disconnect, AntiAfk.Connection)
        AntiAfk.Connection = nil
    end
    task.spawn(function()
        Boost.PetsRun(true)
    end)
    Move.Stop()
    Boost.Stop()
    Boost.Render()
    Boost.Popups()
    Esp.Apply()
    Eggs.Hide()
    Popup.Apply()
    task.spawn(function()
        Util.AsIdentity(2)
        if Library.Flags.AutoHatch == true then
            Eggs.Stop()
        end
        if Library.Flags.AutoRebirth == true then
            Rebirth.Release()
        end
    end)
    for _, event in { Mover.Kick, Bg.Kick, Tap.Kick, Webhook.Kick, Events.BalloonKick } do
        pcall(event.Fire, event)
    end
end
Auto.Cleanup = Cleanup
Library:OnUnload(Cleanup)

if Library.Unloaded then
    if AntiAfk.Connection then
        pcall(AntiAfk.Connection.Disconnect, AntiAfk.Connection)
        AntiAfk.Connection = nil
    end
else
    if Library.Flags.AutoExecute == true then
        Session.QueueLoader(false)
    end
    if Library.Flags.AutoReconnect == true then
        Session.Watch()
    end
    AntiAfk.Bind()
    Boost.Apply()
    Boost.Render()
    Boost.Popups()
    Esp.Apply()
    Eggs.Hide()
    Popup.Apply()
end

local function step(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        warn("[Lumin] " .. name .. ": " .. tostring(err))
        Note(name .. " failed: " .. tostring(err))
    end
    return ok
end

local function Sampler()
    Util.AsIdentity(2)
    while not Library.Unloaded do
        local ok, err = pcall(Sample)
        if not ok then
            warn("[Lumin] sample: " .. tostring(err))
        end
        task.wait(0.5)
    end
end

Auto.Sampler = Sampler
Auto.Background = function()
    Util.AsIdentity(2)
    Bg:Loop()
end
Auto.Webhook = function()
    Util.AsIdentity(2)
    Webhook.Drain()
end

local function Start()
    Util.AsIdentity(2)
    if Library.Unloaded then
        return
    end
    step("game modules", Game.Load)
    if Library.Unloaded then
        return
    end
    step("signals", Watch.Bind)
    step("popups", Popup.ApplyRun)
    step("pets", function()
        Boost.PetsRun()
    end)
    Note(Game.Ready and "ready" or "game modules missing")
    -- Say out loud whether the game layer actually connected. Every feature is
    -- gated on Game.Ready, so without this a failure here is indistinguishable
    -- from "the menu opened and nothing happens".
    if Game.Ready then
        Toast({ Title = "Lumin Hub", Description = GameName .. " ready", Time = 4 })
    else
        Toast({
            Title = "Lumin Hub",
            Description = "Not ready: " .. State.Note .. "\nFeatures stay off until the game layer connects.",
            Time = 10,
        })
    end
    local env = (type(getgenv) == "function" and getgenv()) or _G
    env.__TAPSIM_DBG = {
        State = State, Game = Game, Data = Data, Net = Net, Char = Char, Tap = Tap, Brk = Brk, Eggs = Eggs,
        Rebirth = Rebirth, Shop = Shop, World = World, Claims = Claims, Pets = Pets, Craft = Craft, Items = Items,
        Events = Events, Dig = Dig, Memory = Memory, Arena = Arena, Brain = Brain, Need = Need, Webhook = Webhook,
        Boost = Boost, Server = Server, Esp = Esp, Lists = Lists, View = View, Watch = Watch, Auto = Auto,
        Library = Library, Util = Util, Mover = Mover, Bg = Bg, Enchant = Enchant, Popup = Popup, Mine = Mine,
        Mobs = Mobs, Move = Move, Hallow = Hallow,
    }
    task.spawn(Sampler)
    task.spawn(function()
        Util.AsIdentity(2)
        Bg:Loop()
    end)
    task.spawn(function()
        Util.AsIdentity(2)
        Webhook.Drain()
    end)
    task.spawn(Tap.Loop)
    task.spawn(Events.BalloonLoop)
    Mover:Loop()
end

task.spawn(Start)

-- Start() is still connecting the game layer at this point; it posts the result itself.
Toast({ Title = "Lumin Hub", Description = GameName .. " loading...", Time = 3 })
