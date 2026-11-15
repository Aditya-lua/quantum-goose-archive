--[[
    Noxen UI

    Stock Obsidian (github.com/deividcomsono/Obsidian) plus everything the Noxen hubs were written against,
    so a hub's code runs unchanged:
        Window:AddHomeTab -> Home:AddStat, Home:Pin      Window:AddTabSection, Window:AddSettingsTab
        Groupbox:AddStatus / AddProgress / AddTable      AddLabel { Dim = true }, Element.Label.Text
        Library.Flags, Library:Connect, Library:Thread   Library:SetFolder, Library.IgnoreConfigFlags
        Library:LoadConfigData, Library:WaitUntilLoaded  toggles listed in Library.Options as well
        Toggle:SetValue(Value, true) = repaint only      Library.SaveManager / Library.ThemeManager

    local Library = loadstring(game:HttpGet("<raw URL of this file>"))()

    Kept to syntax that Luau and Lua 5.4 both parse, so it can be checked outside Roblox.
]]

-- Obsidian ships several releases a week. Pinning the commit means an upstream change can never break a
-- live hub; move the hash on purpose and retest.
local OBSIDIAN_COMMIT = "c8dfe653304d0934ce651e156403e397467cb9a0"
local OBSIDIAN_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/" .. OBSIDIAN_COMMIT .. "/"

local NOXEN = {
    Name = "Noxen",
    Discord = "https://discord.gg/AcWg7RVPzw",
    ThemeFolder = "Noxen",
    Theme = {
        BackgroundColor = "0B0814", -- Void
        MainColor = "151022",
        AccentColor = "A855F7", -- Ultraviolet
        OutlineColor = "2A2140",
        FontColor = "EDE9F6", -- Frost
        FontFace = "Code",
    },
}

local function Fetch(Path)
    local Source = game:HttpGet(OBSIDIAN_URL .. Path)
    local Chunk, Problem = loadstring(Source)
    if not Chunk then
        error(("[Noxen] could not compile %s: %s"):format(Path, tostring(Problem)), 0)
    end
    return Chunk()
end

local Library = Fetch("Library.lua")
local ThemeManager = Fetch("addons/ThemeManager.lua")
local SaveManager = Fetch("addons/SaveManager.lua")
local Toggles, Options = Library.Toggles, Library.Options
local HttpService = game:GetService("HttpService")

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder(NOXEN.ThemeFolder)
ThemeManager:SetDefaultTheme(NOXEN.Theme)

SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()

Library.ThemeManager = ThemeManager
Library.SaveManager = SaveManager

-- Library.Flags[Idx] is the current value of the toggle or option registered under Idx
Library.Flags = setmetatable({}, {
    __index = function(_, Idx)
        local Element = Toggles[Idx] or Options[Idx]
        if Element ~= nil then
            return Element.Value
        end
        return nil
    end,
})

-- a connection that Library:Unload disconnects
function Library:Connect(Signal, Callback)
    return self:GiveSignal(Signal:Connect(Callback))
end

function Library:Thread(Callback, ...)
    return task.spawn(function(...)
        local Ok, Problem = pcall(Callback, ...)
        if not Ok then
            warn("[Noxen] " .. tostring(Problem))
        end
    end, ...)
end

-- config ------------------------------------------------------------------------------------------------
-- SaveManager keeps the files and the config menu. Loading goes through Library:LoadConfigData with
-- { [Flag] = { Type, Value } }: the shape the hubs hook to restore values before switches and to retry
-- switches while the client still refuses GUI writes after a join. Changes save themselves.

local CONFIG_TYPES = { Toggle = true, Slider = true, Dropdown = true, Input = true }
local AUTOSAVE_DELAY = 3

local Config = {
    Loading = false, -- a load is running: changes are the load's own writes
    Ready = false, -- the settings tab is built and its autoload finished: autosave may run
    Loaded = true, -- WaitUntilLoaded returns at once until a settings tab starts an autoload
    Waiting = {},
    Private = false, -- toggles Noxen UI builds itself stay out of Library.Options
    Current = nil, -- the config autosave writes to (the last one loaded or saved)
    Scheduled = false,
    Claimed = false, -- autoload was pointed at "autosave" this session
}

Library.IgnoreConfigFlags = SaveManager.Ignore

function Library:SetFolder(Folder, Hub)
    if type(Folder) == "string" and Folder ~= "" then
        SaveManager:SetFolder(Folder)
    end
    if type(Hub) == "string" and Hub ~= "" then
        ThemeManager:SetFolder(Hub)
    end
end

local function Apply(Flag, Entry)
    if SaveManager.Ignore[Flag] or type(Entry) ~= "table" then
        return
    end
    local Element = Options[Flag] or Toggles[Flag]
    if not Element or Element.Type ~= Entry.Type or type(Element.SetValue) ~= "function" then
        return
    end
    local Ok, Problem = pcall(Element.SetValue, Element, Entry.Value)
    if not Ok then
        warn(("[Noxen] config %s: %s"):format(tostring(Flag), tostring(Problem)))
    end
end

-- values first, switches last: a farm the config switches on must see its restored picks
function Library:LoadConfigData(Data)
    if type(Data) ~= "table" then
        return
    end
    local Switches = {}
    for Flag, Entry in pairs(Data) do
        if type(Entry) == "table" and Entry.Type == "Toggle" then
            Switches[Flag] = Entry
        else
            Apply(Flag, Entry)
        end
    end
    for Flag, Entry in pairs(Switches) do
        Apply(Flag, Entry)
    end
end

local function Decode(Content)
    if type(Content) ~= "string" then
        return nil
    end
    local Ok, Decoded = pcall(HttpService.JSONDecode, HttpService, Content)
    if Ok and type(Decoded) == "table" and type(Decoded.objects) == "table" then
        return Decoded
    end
    return nil
end

-- Toggles, sliders, dropdowns and inputs go through LoadConfigData (synchronous, hookable). Keybinds, colours
-- and groupbox state keep Obsidian's own deferred path; one yield lets those land before returning.
local LoadJSON = SaveManager.LoadJSON
function SaveManager:LoadJSON(Content)
    local Decoded = Decode(Content)
    if not Decoded then
        return LoadJSON(self, Content)
    end
    local Data, Rest, Any = {}, {}, false
    for _, Object in ipairs(Decoded.objects) do
        if type(Object) == "table" and CONFIG_TYPES[Object.type] and Object.idx ~= nil then
            local Value = Object.value
            if Object.type == "Input" then
                Value = Object.text
            end
            -- SaveManager writes toggles twice (Toggles and the Options mirror): keyed by flag, once each
            Data[Object.idx] = { Type = Object.type, Value = Value }
            Any = true
        else
            table.insert(Rest, Object)
        end
    end
    Decoded.objects = Rest

    Config.Loading = true
    local Ok, Problem = pcall(function()
        if Any then
            Library:LoadConfigData(Data)
        end
        LoadJSON(self, HttpService:JSONEncode(Decoded))
        task.wait()
    end)
    Config.Loading = false
    if not Ok then
        return false, tostring(Problem)
    end
    return true
end

local Save, Load = SaveManager.Save, SaveManager.Load
function SaveManager:Save(Name)
    local Ok, Problem = Save(self, Name)
    if Ok then
        Config.Current = Name
    end
    return Ok, Problem
end
function SaveManager:Load(Name)
    local Ok, Problem = Load(self, Name)
    if Ok then
        Config.Current = Name
    end
    return Ok, Problem
end

local function AutoSave()
    Config.Scheduled = false
    if Config.Loading or not Config.Ready or Library.Unloaded then
        return
    end
    local Name = Config.Current or "autosave"
    local Ok, Problem = SaveManager:Save(Name)
    if not Ok then
        warn("[Noxen] autosave: " .. tostring(Problem))
        return
    end
    if Name == "autosave" and not Config.Claimed then
        Config.Claimed = true
        local _, HasAutoload = SaveManager:GetAutoloadConfig()
        if not HasAutoload then
            SaveManager:SaveAutoloadConfig("autosave")
        end
    end
end

-- one pending save at a time; it writes whatever the state is when it fires
local function Changed()
    if Config.Loading or not Config.Ready or Config.Scheduled or Library.Unloaded then
        return
    end
    Config.Scheduled = true
    task.delay(AUTOSAVE_DELAY, AutoSave)
end

function Library:WaitUntilLoaded()
    if Config.Loaded then
        return
    end
    local Thread = coroutine.running()
    table.insert(Config.Waiting, Thread)
    coroutine.yield()
end

-- elements ------------------------------------------------------------------------------------------------

local ROW = 18
local DIM = 0.4

local FIXED = {
    info = Color3.fromRGB(192, 132, 252), -- Orchid
    success = Color3.fromRGB(74, 222, 128),
    warning = Color3.fromRGB(251, 191, 36),
}

-- running/error/idle follow the active theme, the rest are fixed
local function KindColor(Kind)
    local Scheme = Library.Scheme
    if Kind == "running" then
        return Scheme.AccentColor
    elseif Kind == "error" then
        return Scheme.RedColor
    elseif Kind == "idle" then
        return Scheme.FontColor
    end
    return FIXED[Kind] or FIXED.info
end

local function Number(Value, Default)
    Value = tonumber(Value)
    if Value == nil or Value ~= Value or Value == math.huge or Value == -math.huge then
        return Default
    end
    return Value
end

local function Str(Value)
    if Value == nil then
        return ""
    end
    return tostring(Value)
end

-- Element.Label.Text the way the hubs write it: reads the element's text, writes go through its SetText
local function TextProxy(Owner, Target)
    return setmetatable({}, {
        __index = function(_, Key)
            if Key == "Text" then
                return Owner.Text
            end
            return Target[Key]
        end,
        __newindex = function(_, Key, Value)
            if Key == "Text" then
                Owner:SetText(Value)
            else
                Target[Key] = Value
            end
        end,
    })
end

-- Theme maps a property to a Scheme key or to a function returning the colour; the registry re-applies it
-- whenever the theme changes. Themed objects go in Owned so their registry entries leave with the element.
local function Make(ClassName, Properties, Theme, Owned)
    local Object = Instance.new(ClassName)
    for Property, Value in pairs(Properties) do
        if Property ~= "Parent" then
            Object[Property] = Value
        end
    end
    if Theme then
        for Property, Index in pairs(Theme) do
            local Value
            if type(Index) == "function" then
                Value = Index()
            else
                Value = Library.Scheme[Index]
            end
            if Value ~= nil then
                Object[Property] = Value
            end
        end
        Library:AddToRegistry(Object, Theme)
        table.insert(Owned, Object)
    end
    Object.Parent = Properties.Parent
    return Object
end

local ALIGN = {
    Right = Enum.TextXAlignment.Right,
    Center = Enum.TextXAlignment.Center,
}

local function Text(Properties, Theme, Owned)
    if Properties.BackgroundTransparency == nil then
        Properties.BackgroundTransparency = 1
    end
    Properties.Text = Properties.Text or ""
    Properties.TextSize = Properties.TextSize or 14
    Properties.TextXAlignment = Properties.TextXAlignment or Enum.TextXAlignment.Left
    Properties.TextTruncate = Properties.TextTruncate or Enum.TextTruncate.AtEnd
    Theme = Theme or {}
    Theme.FontFace = "Font"
    Theme.TextColor3 = Theme.TextColor3 or "FontColor"
    return Make("TextLabel", Properties, Theme, Owned)
end

local Serial = 0

-- hosts Holder in the groupbox through Obsidian's UIPassthrough; nil when the groupbox is gone
local function Mount(Box, Kind, Idx, Holder, Height, Owned)
    Serial = Serial + 1
    local Key = ("Noxen%s_%s_%d"):format(Kind, Str(Idx), Serial)
    local Element = Box:AddUIPassthrough(Key, { Instance = Holder, Height = Height })
    if not Element then
        Holder:Destroy()
        return nil
    end
    local Destroy = Element.Destroy
    function Element:Destroy()
        for _, Object in ipairs(Owned) do
            Library:RemoveFromRegistry(Object)
        end
        return Destroy(self)
    end
    return Element
end

local function Frame(Parent)
    return Make("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Parent = Parent })
end

local function AddStatus(Box, Idx, Info)
    Info = Info or {}
    local Owned = {}
    local State = { Text = Str(Info.Text), Status = Str(Info.Status or "off"), Kind = Info.Kind or "idle" }
    local function Colour()
        return KindColor(State.Kind)
    end

    local Holder = Frame()
    local Title = Text({ Text = State.Text, Size = UDim2.fromScale(1, 1), Parent = Holder }, nil, Owned)
    local Pill = Text({
        Text = State.Status,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(0, ROW),
        Parent = Holder,
    }, { TextColor3 = Colour, BackgroundColor3 = Colour }, Owned)
    Make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Pill })
    Make("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7), Parent = Pill })
    Make("UISizeConstraint", { MaxSize = Vector2.new(150, ROW), Parent = Pill })
    local Stroke = Make("UIStroke", { Thickness = 1, Parent = Pill }, { Color = Colour }, Owned)

    local function Paint()
        local Idle = State.Kind == "idle"
        local Colour_ = Colour()
        Pill.TextColor3 = Colour_
        Pill.BackgroundColor3 = Colour_
        Stroke.Color = Colour_
        Pill.TextTransparency = Idle and 0.35 or 0
        Pill.BackgroundTransparency = Idle and 0.94 or 0.86
        Stroke.Transparency = Idle and 0.8 or 0.55
    end

    local Element = Mount(Box, "Status", Idx, Holder, ROW + 2, Owned)
    if not Element then
        return nil
    end
    Element.Text, Element.Status, Element.Kind = State.Text, State.Status, State.Kind

    -- the title gives up whatever width the pill needs
    local function Fit()
        Title.Size = UDim2.new(1, -(Pill.AbsoluteSize.X / (Library.DPIScale or 1) + 8), 1, 0)
    end
    table.insert(Element.Connections, Pill:GetPropertyChangedSignal("AbsoluteSize"):Connect(Fit))
    Fit()
    Paint()

    function Element:SetStatus(Status, Kind)
        Status = Str(Status)
        Kind = Kind or State.Kind
        if Status == State.Status and Kind == State.Kind then
            return
        end
        State.Status, State.Kind = Status, Kind
        self.Status, self.Kind = Status, Kind
        Pill.Text = Status
        Paint()
    end
    Element.Set = Element.SetStatus

    function Element:SetKind(Kind)
        self:SetStatus(State.Status, Kind)
    end

    function Element:SetText(Value)
        Value = Str(Value)
        if Value == State.Text then
            return
        end
        State.Text = Value
        self.Text = Value
        Title.Text = Value
    end

    return Element
end

local function AddProgress(Box, Idx, Info)
    Info = Info or {}
    local Owned = {}
    local State = {
        Text = Str(Info.Text),
        Min = Number(Info.Min, 0),
        Max = Number(Info.Max, 100),
        Value = Number(Info.Default, 0),
        Rounding = math.max(0, math.floor(Number(Info.Rounding, 0))),
        Format = type(Info.Format) == "function" and Info.Format or nil,
    }

    local Holder = Frame()
    local Title = Text({ Text = State.Text, Size = UDim2.new(0.55, 0, 0, 16), Parent = Holder }, nil, Owned)
    local Amount = Text({
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0.45, 0, 0, 16),
        Parent = Holder,
    }, nil, Owned)
    local Track = Make("Frame", {
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 21),
        Size = UDim2.new(1, 0, 0, 6),
        Parent = Holder,
    }, { BackgroundColor3 = "OutlineColor" }, Owned)
    Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })
    local Fill = Make("Frame", { BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), Parent = Track }, { BackgroundColor3 = "AccentColor" }, Owned)
    Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })

    local function Shown()
        if State.Format then
            local Ok, Result = pcall(State.Format, State.Value, State.Max, State.Min)
            if Ok and Result ~= nil then
                return tostring(Result)
            end
        end
        local Pattern = "%." .. State.Rounding .. "f"
        return Pattern:format(State.Value) .. " / " .. Pattern:format(State.Max)
    end

    local function Render()
        local Span = State.Max - State.Min
        local Alpha = 0
        if Span > 0 then
            Alpha = math.clamp((State.Value - State.Min) / Span, 0, 1)
        end
        Fill.Size = UDim2.fromScale(Alpha, 1)
        Amount.Text = Shown()
    end

    local Element = Mount(Box, "Progress", Idx, Holder, 30, Owned)
    if not Element then
        return nil
    end
    Element.Text, Element.Min, Element.Max, Element.Value = State.Text, State.Min, State.Max, State.Value
    Render()

    function Element:SetValue(Value)
        Value = Number(Value, State.Value)
        if Value == State.Value then
            return
        end
        State.Value = Value
        self.Value = Value
        Render()
    end

    function Element:SetRange(Min, Max)
        Min, Max = Number(Min, State.Min), Number(Max, State.Max)
        if Min == State.Min and Max == State.Max then
            return
        end
        State.Min, State.Max = Min, Max
        self.Min, self.Max = Min, Max
        Render()
    end

    function Element:SetText(Value)
        Value = Str(Value)
        if Value == State.Text then
            return
        end
        State.Text = Value
        self.Text = Value
        Title.Text = Value
    end

    return Element
end

-- AddTable(Info) or AddTable(Idx, Info); Columns = { { Name, Width, Align } } or Headers = { Name, ... }.
-- Rows are arrays of cells; past MaxVisible the body scrolls.
local function AddTable(Box, Idx, Info)
    if type(Idx) == "table" and Info == nil then
        Idx, Info = nil, Idx
    end
    Info = Info or {}
    local Owned = {}

    local Given = Info.Columns
    if type(Given) ~= "table" and type(Info.Headers) == "table" then
        Given = {}
        for _, Name in ipairs(Info.Headers) do
            table.insert(Given, { Name = Name })
        end
    end
    if type(Given) ~= "table" then
        Given = {}
    end

    local Columns, Sum = {}, 0
    for _, Column in ipairs(Given) do
        local Width = Number(Column.Width, 0)
        if Width <= 0 then
            Width = 1 / #Given
        end
        table.insert(Columns, { Name = Str(Column.Name), Width = Width, Align = ALIGN[Column.Align] or Enum.TextXAlignment.Left })
        Sum = Sum + Width
    end
    if #Columns == 0 then
        Columns[1] = { Name = "", Width = 1, Align = Enum.TextXAlignment.Left }
        Sum = 1
    end
    local X = 0
    for _, Column in ipairs(Columns) do
        Column.Width = Column.Width / Sum
        Column.X = X
        X = X + Column.Width
    end

    local MaxVisible = math.max(1, math.floor(Number(Info.MaxVisible, 5)))
    local Holder = Frame()
    local Top = 0
    if Str(Info.Text) ~= "" then
        Text({ Text = Str(Info.Text), Size = UDim2.new(1, 0, 0, 16), Parent = Holder }, nil, Owned)
        Top = 18
    end

    local function Cells(Parent, Size)
        local List = {}
        for Index, Column in ipairs(Columns) do
            List[Index] = Text({
                TextSize = Size,
                TextXAlignment = Column.Align,
                Position = UDim2.new(Column.X, 2, 0, 0),
                Size = UDim2.new(Column.Width, -4, 1, 0),
                Parent = Parent,
            }, nil, Owned)
        end
        return List
    end

    local Header = Make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, Top), Size = UDim2.new(1, 0, 0, ROW), Parent = Holder })
    for Index, Label in ipairs(Cells(Header, 12)) do
        Label.Text = Columns[Index].Name
        Label.TextTransparency = DIM
    end
    Make("Frame", {
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, Top + ROW),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = Holder,
    }, { BackgroundColor3 = "OutlineColor" }, Owned)

    local BodyTop = Top + ROW + 2
    local Body = Make("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, BodyTop),
        Size = UDim2.new(1, 0, 1, -BodyTop),
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = Holder,
    }, { ScrollBarImageColor3 = "AccentColor" }, Owned)
    local Empty = Text({
        Text = Str(Info.Empty or "nothing yet"),
        TextSize = 13,
        Position = UDim2.fromOffset(2, 0),
        Size = UDim2.new(1, -4, 0, ROW),
        Parent = Body,
    }, nil, Owned)
    Empty.TextTransparency = DIM

    local function Height(Count)
        return BodyTop + math.clamp(Count, 1, MaxVisible) * ROW + 2
    end

    local Element = Mount(Box, "Table", Idx, Holder, Height(0), Owned)
    if not Element then
        return nil
    end

    local Pool, Shown, Visible = {}, 0, 1

    function Element:SetRows(Rows)
        if type(Rows) ~= "table" then
            Rows = {}
        end
        local Count = #Rows
        for Index = 1, Count do
            local Line = Pool[Index]
            if not Line then
                local Row = Make("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, (Index - 1) * ROW),
                    Size = UDim2.new(1, 0, 0, ROW),
                    Parent = Body,
                })
                Line = { Frame = Row, Cells = Cells(Row, 13) }
                Pool[Index] = Line
            end
            Line.Frame.Visible = true
            local Row = Rows[Index]
            for Column, Label in ipairs(Line.Cells) do
                local Value
                if type(Row) == "table" then
                    Value = Row[Column]
                elseif Column == 1 then
                    Value = Row
                end
                Value = Str(Value)
                if Label.Text ~= Value then
                    Label.Text = Value
                end
            end
        end
        for Index = Count + 1, Shown do
            Pool[Index].Frame.Visible = false
        end
        Shown = Count
        Empty.Visible = Count == 0
        Body.CanvasSize = UDim2.fromOffset(0, Count * ROW)
        local Want = math.clamp(Count, 1, MaxVisible)
        if Want ~= Visible then
            Visible = Want
            self:SetHeight(Height(Count))
        end
        self.Rows = Rows
    end

    Element:SetRows(Info.Rows)
    return Element
end

local function AddStat(Box, Name, Value)
    local Owned = {}
    local Holder = Frame()
    local Title = Text({ Text = Str(Name), Size = UDim2.fromScale(0.55, 1), Parent = Holder }, nil, Owned)
    Title.TextTransparency = DIM
    local Amount = Text({
        Text = Str(Value),
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.fromScale(0.45, 1),
        Parent = Holder,
    }, nil, Owned)

    local Element = Mount(Box, "Stat", Name, Holder, ROW, Owned)
    if not Element then
        return nil
    end
    Element.Value, Element.Text = Amount.Text, Amount.Text

    function Element:SetValue(New)
        New = Str(New)
        if New == self.Value then
            return
        end
        self.Value, self.Text = New, New
        Amount.Text = New
    end
    Element.SetText = Element.SetValue
    Element.Label = TextProxy(Element, Amount)

    return Element
end

-- groupbox methods ----------------------------------------------------------------------------------------
-- Obsidian keeps every groupbox's methods in one shared table (the __index of its metatable); adding to it
-- once reaches groupboxes, tabbox tabs and dependency boxes alike.

local Pinned = {} -- [Flag] = the Home tab copies of that toggle

-- every value change schedules an autosave; a toggle also repaints its Home pins
local function Watch(Element, Idx)
    local Own = Element.Changed
    Element.Changed = function(...)
        if Own then
            Own(...)
        end
        Changed()
        local Pins = Idx ~= nil and Pinned[Idx] or nil
        if Pins then
            for _, Pin in ipairs(Pins) do
                if Pin.Value ~= Element.Value then
                    Pin:SetValue(Element.Value, true)
                end
            end
        end
    end
end

local function AdaptToggle(Toggle, Idx)
    -- Obsidian runs the callback on every SetValue, even an unchanged one. The hubs probe whether the GUI
    -- accepts writes with SetValue(current, true), which must only repaint.
    local SetValue = Toggle.SetValue
    function Toggle:SetValue(Value, Silent)
        if Silent then
            self.Value = Value
            self:Display()
            return
        end
        return SetValue(self, Value)
    end
    -- the hubs find toggles in Library.Options (Stop Everything, the config probe, Options.OneClick)
    if Idx ~= nil and not Config.Private and Options[Idx] == nil then
        Options[Idx] = Toggle
    end
    Watch(Toggle, Idx)
end

local Patched = false

local function Extend(Funcs)
    function Funcs:AddStatus(Idx, Info)
        if self.Destroyed then return nil end
        return AddStatus(self, Idx, Info)
    end

    function Funcs:AddProgress(Idx, Info)
        if self.Destroyed then return nil end
        return AddProgress(self, Idx, Info)
    end

    function Funcs:AddTable(Idx, Info)
        if self.Destroyed then return nil end
        return AddTable(self, Idx, Info)
    end

    for _, Name in ipairs({ "AddToggle", "AddCheckbox" }) do
        local Base = Funcs[Name]
        if type(Base) == "function" then
            Funcs[Name] = function(self, Idx, Info)
                local Toggle = Base(self, Idx, Info)
                if type(Toggle) == "table" then
                    AdaptToggle(Toggle, Idx)
                end
                return Toggle
            end
        end
    end

    for _, Name in ipairs({ "AddSlider", "AddInput" }) do
        local Base = Funcs[Name]
        Funcs[Name] = function(self, Idx, Info)
            local Element = Base(self, Idx, Info)
            if type(Element) == "table" then
                Watch(Element, Idx)
            end
            return Element
        end
    end

    -- Obsidian reads a multi-dropdown Default by its values; the hubs write it as a set ({ Wood = true }),
    -- which would resolve to nothing picked. Turn a set into the list of its picked keys.
    local AddDropdown = Funcs.AddDropdown
    function Funcs:AddDropdown(Idx, Info)
        if type(Info) == "table" and type(Info.Default) == "table" and Info.Default[1] == nil then
            local Picked = {}
            for Key, On in pairs(Info.Default) do
                if On == true then
                    table.insert(Picked, Key)
                end
            end
            Info.Default = Picked
        end
        local Dropdown = AddDropdown(self, Idx, Info)
        if type(Dropdown) == "table" then
            Watch(Dropdown, Idx)
        end
        return Dropdown
    end

    -- Dim, nil text, Label.Text writes, and a SetText that skips unchanged text: Obsidian re-measures and
    -- resizes the whole groupbox on every SetText, and the painter rewrites every label a few times a second.
    local AddLabel = Funcs.AddLabel
    function Funcs:AddLabel(...)
        local First, Second = ...
        local Info = (type(First) == "table" and First) or (type(Second) == "table" and Second) or nil
        local Label = AddLabel(self, ...)
        if type(Label) ~= "table" then
            return Label
        end
        if Info and Info.Dim and Label.TextLabel then
            Label.TextLabel.TextTransparency = DIM
        end
        local SetText = Label.SetText
        function Label:SetText(Value)
            Value = Str(Value)
            if self.Text == Value then
                return
            end
            return SetText(self, Value)
        end
        if Label.TextLabel then
            Label.Label = TextProxy(Label, Label.TextLabel)
        end
        return Label
    end
end

local function Patch(Box)
    if Patched or type(Box) ~= "table" then
        return
    end
    local Meta = getmetatable(Box)
    local Funcs = type(Meta) == "table" and rawget(Meta, "__index") or nil
    if type(Funcs) ~= "table" or type(Funcs.AddUIPassthrough) ~= "function" then
        return
    end
    Patched = true
    Extend(Funcs)
end

-- window ----------------------------------------------------------------------------------------------------

local function Executor()
    if type(identifyexecutor) ~= "function" then
        return nil
    end
    local Ok, Name = pcall(identifyexecutor)
    return Ok and Name and tostring(Name) or nil
end

local function CopyInvite(Invite)
    local Clip = (type(setclipboard) == "function" and setclipboard) or (type(toclipboard) == "function" and toclipboard) or nil
    if Clip and pcall(Clip, Invite) then
        Library:Notify({ Title = NOXEN.Name, Description = "Discord invite copied", Time = 4 })
    else
        Library:Notify({ Title = NOXEN.Name, Description = Invite, Time = 10 })
    end
end

local CreateWindow = Library.CreateWindow
function Library:CreateWindow(Info)
    Info = type(Info) == "table" and Info or {}
    local Game, Footer = Str(Info.Game), Str(Info.Footer)
    Info.Title = Info.Title or Info.Hub or NOXEN.Name
    if Game ~= "" and Footer ~= "" then
        Info.Footer = Game .. "  |  " .. Footer
    else
        Info.Footer = Game ~= "" and Game or Footer
    end
    Info.Icon = Info.Logo or Info.Icon or "moon"
    if type(Info.Folder) == "string" and Info.Folder ~= "" then
        SaveManager:SetFolder(Info.Folder)
    end

    local Window = CreateWindow(self, Info)

    local AddTab = Window.AddTab
    function Window:AddTab(...)
        local Tab = AddTab(self, ...)
        local AddGroupbox = Tab.AddGroupbox
        -- Tab:AddLeftGroupbox / AddRightGroupbox go through this field too
        function Tab:AddGroupbox(...)
            local Box = AddGroupbox(self, ...)
            Patch(Box)
            return Box
        end
        return Tab
    end

    -- Obsidian's sidebar has no section headers
    function Window:AddTabSection()
        return nil
    end

    function Window:AddHomeTab(HomeInfo)
        HomeInfo = HomeInfo or {}
        local Home = self:AddTab("Home", "home")

        local About = Home:AddLeftGroupbox(NOXEN.Name, "moon")
        if Game ~= "" then
            About:AddLabel({ Text = Game, DoesWrap = true })
        end
        if Footer ~= "" then
            About:AddLabel({ Text = Footer, DoesWrap = true, Dim = true })
        end
        local Running = Executor()
        if Running then
            About:AddLabel({ Text = "Executor: " .. Running, DoesWrap = true, Dim = true })
        end
        local Invite = Str(HomeInfo.Discord or NOXEN.Discord)
        About:AddButton({ Text = "Copy Discord Invite", Callback = function()
            CopyInvite(Invite)
        end })

        -- entries are strings or { Title, Date, Text } ({ Title, Description } in older hubs)
        local News = HomeInfo.Announcements
        if type(News) == "string" then
            News = { News }
        end
        if type(News) == "table" and #News > 0 then
            local Board = Home:AddRightGroupbox("Announcements", "bell")
            for _, Entry in ipairs(News) do
                if type(Entry) == "table" then
                    local Head = Str(Entry.Title)
                    if Str(Entry.Date) ~= "" then
                        Head = Head .. "  ·  " .. Str(Entry.Date)
                    end
                    if Head ~= "" then
                        Board:AddLabel({ Text = Head, DoesWrap = true })
                    end
                    local Body = Str(Entry.Text or Entry.Description)
                    if Body ~= "" then
                        Board:AddLabel({ Text = Body, DoesWrap = true, Dim = true })
                    end
                else
                    Board:AddLabel({ Text = Str(Entry), DoesWrap = true })
                end
            end
        end

        local StatsBox, PinsBox
        function Home:AddStat(Name, Value)
            StatsBox = StatsBox or Home:AddLeftGroupbox("Session", "chart-bar")
            return AddStat(StatsBox, Name, Value)
        end

        -- a copy of a toggle on the Home tab; either one switches the other
        function Home:Pin(Flag)
            local Original = Toggles[Flag]
            if not Original then
                return nil
            end
            PinsBox = PinsBox or Home:AddLeftGroupbox("Quick Toggles", "zap")
            local Key = "NoxenPin_" .. tostring(Flag)
            SaveManager.Ignore[Key] = true
            Config.Private = true
            local Pin = PinsBox:AddToggle(Key, {
                Text = Original.Text or tostring(Flag),
                Default = Original.Value == true,
                Callback = function(Value)
                    if Original.Value ~= Value then
                        Original:SetValue(Value)
                    end
                end,
            })
            Config.Private = false
            Pinned[Flag] = Pinned[Flag] or {}
            table.insert(Pinned[Flag], Pin)
            return Pin
        end

        return Home
    end

    -- menu, themes and configs; starts the autoload that WaitUntilLoaded waits for
    local SettingsTab
    function Window:AddSettingsTab()
        if SettingsTab then
            return SettingsTab
        end
        Config.Private = true
        SettingsTab = self:AddTab("Settings", "wrench")

        local Menu = SettingsTab:AddLeftGroupbox("Menu", "monitor")
        Menu:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightControl", NoUI = true, Text = "Menu keybind" })
        Library.ToggleKeybind = Options.MenuKeybind
        Menu:AddToggle("NoxenCustomCursor", {
            Text = "Custom Cursor",
            Default = Library.ShowCustomCursor ~= false,
            Callback = function(Value)
                Library.ShowCustomCursor = Value
            end,
        })
        Menu:AddDropdown("NoxenNotifySide", {
            Text = "Notification Side",
            Values = { "Left", "Right" },
            Default = "Right",
            Callback = function(Value)
                Library:SetNotifySide(Value)
            end,
        })
        Menu:AddDropdown("NoxenDPIScale", {
            Text = "DPI Scale",
            Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
            Default = "100%",
            Callback = function(Value)
                local Scale = tonumber((Str(Value):gsub("%%", "")))
                if Scale then
                    Library:SetDPIScale(Scale)
                end
            end,
        })
        Menu:AddLabel({
            Text = "Settings save on their own and load on the next start. Load another config below to switch.",
            DoesWrap = true,
            Dim = true,
        })
        Menu:AddButton({ Text = "Unload", Callback = function()
            Library:Unload()
        end })

        ThemeManager:ApplyToTab(SettingsTab)
        SaveManager:BuildConfigSection(SettingsTab)
        Config.Private = false

        Config.Loaded = false
        Library:Thread(function()
            local Ok, Problem = pcall(SaveManager.LoadAutoloadConfig, SaveManager)
            if not Ok then
                warn("[Noxen] autoload: " .. tostring(Problem))
            end
            Config.Loaded, Config.Ready = true, true
            local Waiting = Config.Waiting
            Config.Waiting = {}
            for _, Thread in ipairs(Waiting) do
                task.spawn(Thread)
            end
        end)
        return SettingsTab
    end

    return Window
end

return Library
