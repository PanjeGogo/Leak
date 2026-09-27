-- Prospecting Hub
-- Obsidian UI build using the Prospecting logic found in 1212_clean.lua.txt.

local BASE = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Library = loadstring(game:HttpGet(BASE .. "Library.lua"))()
local SaveManager = loadstring(game:HttpGet(BASE .. "addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(BASE .. "addons/ThemeManager.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local POSITION_FOLDER = "ProspectingHub"
local POSITION_FILE = POSITION_FOLDER .. "/Positions.json"

local Window = Library:CreateWindow({
    Title = "Prospecting Hub",
    Footer = "Prospecting | PanjeGogo",
    Center = true,
    AutoShow = true,
    Resizable = true,
    Size = UDim2.fromOffset(650, 500),
    ToggleKeybind = Enum.KeyCode.RightControl,
})

local Tabs = {
    Farm = Window:AddTab("Auto Farm", "pickaxe"),
    Geode = Window:AddTab("Geode", "gem"),
    Sell = Window:AddTab("Auto Sell", "shopping-cart"),
    Events = Window:AddTab("Events", "flame"),
    Settings = Window:AddTab("Settings", "settings"),
}

local Settings = {
    Farm = {
        Enabled = false,
        InstantPerfectDig = false,
        AutoDig = false,
        AutoPan = false,
        AutoCollect = true,
    },
    Geode = {
        ESP = false,
        AutoCollect = false,
        Hatch = false,
        Range = 1000,
    },
    Sell = {
        Enabled = false,
        SellAll = false,
    },
    Events = {
        Void = false,
        Infernal = false,
        Totem = false,
    },
    Misc = {
        Speed = 16,
        SpeedEnabled = false,
        AntiAFK = true,
    },
    Positions = {
        Dig = nil,
        Panning = nil,
    },
}

local function notify(title, content)
    pcall(function()
        Library:Notify({
            Title = title,
            Description = content,
            Time = 3,
        })
    end)
end

local function getCharacter()
    local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return c, c:FindFirstChild("HumanoidRootPart")
end

local function posTable(v)
    return {math.round(v.X), math.round(v.Y), math.round(v.Z)}
end

local function toVector3(p)
    if type(p) == "table" and #p >= 3 then
        return Vector3.new(p[1], p[2], p[3])
    end
end

local function loadSavedPositions()
    if not (isfile and readfile and isfile(POSITION_FILE)) then
        return
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(POSITION_FILE))
    end)

    if ok and type(data) == "table" then
        if type(data.Dig) == "table" and #data.Dig >= 3 then
            Settings.Positions.Dig = data.Dig
        end
        if type(data.Panning) == "table" and #data.Panning >= 3 then
            Settings.Positions.Panning = data.Panning
        end
    end
end

local function saveSavedPositions()
    if not (writefile and makefolder) then
        return false
    end

    pcall(function()
        if not (isfolder and isfolder(POSITION_FOLDER)) then
            makefolder(POSITION_FOLDER)
        end
    end)

    local ok = pcall(function()
        writefile(POSITION_FILE, HttpService:JSONEncode({
            Dig = Settings.Positions.Dig,
            Panning = Settings.Positions.Panning,
        }))
    end)

    return ok
end

loadSavedPositions()

local function moveToPosition(p, callback, forceTeleport)
    local target = toVector3(p)
    if not target then
        if callback then callback(false) end
        return
    end

    local c, root = getCharacter()
    if not root then
        if callback then callback(false) end
        return
    end

    local method = forceTeleport and "Teleport" or "Walk"
    local moveOption = Library.Options.MoveMethod
    if not forceTeleport and moveOption and moveOption.Value then
        method = moveOption.Value
    end

    if method == "Teleport" then
        root.CFrame = CFrame.new(target)
        task.wait(0.12)
        if callback then callback(true) end
        return
    end

    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then
        if callback then callback(false) end
        return
    end

    hum:MoveTo(target)
    local started = os.clock()
    while os.clock() - started < 8 do
        if not root.Parent then break end
        if (root.Position - target).Magnitude <= 5 then
            if callback then callback(true) end
            return
        end
        task.wait(0.1)
    end

    if callback then callback(false) end
end

local FarmBox = Tabs.Farm:AddLeftGroupbox("Farm Controls", "pickaxe")
local PositionBox = Tabs.Farm:AddLeftGroupbox("Saved Positions", "map-pin")
local FarmStatusBox = Tabs.Farm:AddRightGroupbox("Workflow", "route")
local PositionMoveBox = Tabs.Farm:AddRightGroupbox("Teleport", "navigation")

-- Positions
local DigLocationLabel = FarmBox:AddLabel({
    Text = "Dig location: 0.0.0",
    DoesWrap = true,
})
local PanLocationLabel = FarmBox:AddLabel({
    Text = "Pan location: 0.0.0",
    DoesWrap = true,
})

local function updateFarmLocationLabels()
    local dig = Settings.Positions and Settings.Positions.Dig
    local pan = Settings.Positions and Settings.Positions.Panning

    local function fmt(p)
        if type(p) == "table" and #p >= 3 then
            return string.format("%.1f, %.1f, %.1f", p[1], p[2], p[3])
        end
        return "0.0.0"
    end

    pcall(function()
        DigLocationLabel:SetText("Dig location: " .. fmt(dig))
        PanLocationLabel:SetText("Pan location: " .. fmt(pan))
    end)
end

updateFarmLocationLabels()

-- Location labels are refreshed after saving/clearing positions.
PositionBox:AddLabel("Save Dig and Panning here. No extra positions are needed.", true)

local function savePosition(name, label)
    local _, root = getCharacter()
    if not root then
        notify("Position", "Character not ready.")
        return
    end
    Settings.Positions[name] = posTable(root.Position)
    saveSavedPositions()
    updateFarmLocationLabels()
    notify("Position Saved", label .. " saved: " ..
        string.format("%.1f, %.1f, %.1f",
            root.Position.X, root.Position.Y, root.Position.Z))
end

local function teleportSaved(name, label)
    local p = Settings.Positions[name]
    if not p then
        notify("Position", label .. " is not saved.")
        return
    end
    moveToPosition(p, nil, true)
end

PositionBox:AddButton({
    Text = "Save Dig Position",
    Func = function()
        savePosition("Dig", "Dig")
    end,
})

PositionBox:AddButton({
    Text = "Save Panning Position",
    Func = function()
        savePosition("Panning", "Panning")
    end,
})

PositionBox:AddDivider()

PositionBox:AddButton({
    Text = "Clear Saved Positions",
    Func = function()
        Settings.Positions.Dig = nil
        Settings.Positions.Panning = nil
        saveSavedPositions()
        DigLocationLabel:SetText("Dig location: 0.0.0")
        PanLocationLabel:SetText("Pan location: 0.0.0")
        notify("Positions", "Dig and Panning positions cleared.")
    end,
})

PositionMoveBox:AddDropdown("MoveMethod", {
    Text = "Movement Method",
    Values = {"Walk", "Teleport"},
    Default = "Teleport",
    Multi = false,
})

PositionMoveBox:AddButton({
    Text = "Go To Dig",
    Func = function()
        teleportSaved("Dig", "Dig")
    end,
})

PositionMoveBox:AddButton({
    Text = "Go To Panning",
    Func = function()
        teleportSaved("Panning", "Panning")
    end,
})


local GeodeBox = Tabs.Geode:AddLeftGroupbox("Geode", "gem")
local GeodeInfoBox = Tabs.Geode:AddRightGroupbox("Info", "info")
local SellBox = Tabs.Sell:AddLeftGroupbox("Selling", "shopping-cart")
local EventBox = Tabs.Events:AddLeftGroupbox("Events", "flame")
local MiscBox = Tabs.Settings:AddLeftGroupbox("Misc", "settings")
local ConfigBox = Tabs.Settings:AddRightGroupbox("Configuration", "save")
local ScriptBox = Tabs.Settings:AddRightGroupbox("Script", "power")


local function getEquippedTool()
    local c = LocalPlayer.Character
    local tool = c and c:FindFirstChildOfClass("Tool")
    if tool then
        return tool
    end

    local chars = workspace:FindFirstChild("Characters")
    local model = chars and chars:FindFirstChild(LocalPlayer.Name)
    return model and model:FindFirstChildOfClass("Tool")
end

local function callToolScript(name, ...)
    local tool = getEquippedTool()
    if not tool then return false end

    local scripts = tool:FindFirstChild("Scripts")
    if not scripts then return false end

    local obj = scripts:FindFirstChild(name)
    if not obj then return false end

    local args = {...}
    return pcall(function()
        if obj:IsA("RemoteFunction") then
            obj:InvokeServer(table.unpack(args))
        elseif obj:IsA("RemoteEvent") then
            obj:FireServer(table.unpack(args))
        elseif obj:IsA("BindableFunction") then
            obj:Invoke(table.unpack(args))
        elseif obj:IsA("BindableEvent") then
            obj:Fire(table.unpack(args))
        end
    end)
end

local function digOnce()
    local tool = getEquippedTool()
    if not tool then
        return false
    end

    -- Prospecting's supplied source primarily uses the equipped Tool.
    local activated = pcall(function()
        tool:Activate()
    end)

    -- Some tool builds expose a Dig remote; use it if present as a fallback.
    local scripts = tool:FindFirstChild("Scripts")
    local digRemote = scripts and scripts:FindFirstChild("Dig")
    if digRemote then
        pcall(function()
            if digRemote:IsA("RemoteFunction") then
                digRemote:InvokeServer()
            elseif digRemote:IsA("RemoteEvent") then
                digRemote:FireServer()
            end
        end)
    end

    return activated
end

-- Farm
FarmStatusBox:AddToggle("AutoDig", {
    Title = "Auto Dig",
    Default = false,
}):OnChanged(function(v)
    Settings.Farm.AutoDig = v
    Settings.Farm.Enabled = v or Settings.Farm.AutoPan
    if not v and not Settings.Farm.AutoPan then
        stopFarmMovement()
    end
    notify("Auto Dig", v and "Enabled" or "Disabled")
end)

FarmStatusBox:AddToggle("AutoPanning", {
    Title = "Auto Panning",
    Default = false,
}):OnChanged(function(v)
    Settings.Farm.AutoPan = v
    Settings.Farm.Enabled = v or Settings.Farm.AutoDig
    if not v and not Settings.Farm.AutoDig then
        stopFarmMovement()
    end
    notify("Auto Panning", v and "Enabled" or "Disabled")
end)

FarmStatusBox:AddToggle("AutoCollect", {
    Title = "Auto Collect",
    Default = true,
}):OnChanged(function(v)
    Settings.Farm.AutoCollect = v
end)

FarmStatusBox:AddLabel("Dig -> Collect -> Pan -> Shake.", true)
FarmStatusBox:AddLabel("One Panning position is used for collecting and shaking.", true)

-- Geode ESP
local geodeESP = {}

local function clearGeodeESP()
    for obj, gui in pairs(geodeESP) do
        if gui then
            pcall(function() gui:Destroy() end)
        end
        geodeESP[obj] = nil
    end
end

local function addGeodeESP(part)
    if geodeESP[part] or not part:IsA("BasePart") then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "ProspectingGeodeESP"
    gui.Size = UDim2.fromOffset(150, 36)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.Adornee = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "GEODE"
    label.TextColor3 = Color3.fromRGB(0, 255, 255)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.Parent = gui

    gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    geodeESP[part] = gui
end

local function scanGeodes()
    clearGeodeESP()

    local folder = workspace:FindFirstChild("Geode")
    if not folder then return 0 end

    local _, root = getCharacter()
    local origin = root and root.Position
    local count = 0

    for _, obj in ipairs(folder:GetDescendants()) do
        if obj.Name == "TouchInterest" then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                if not origin or (part.Position - origin).Magnitude <= Settings.Geode.Range then
                    addGeodeESP(part)
                    count += 1
                end
            end
        end
    end

    return count
end

local function collectGeodes()
    local folder = workspace:FindFirstChild("Geode")
    if not folder then return end

    local _, root = getCharacter()
    if not root then return end

    for _, obj in ipairs(folder:GetDescendants()) do
        if obj.Name == "TouchInterest" then
            local part = obj.Parent
            if part and part:IsA("BasePart") and
                (part.Position - root.Position).Magnitude <= Settings.Geode.Range then
                pcall(function()
                    firetouchinterest(root, part, 0)
                    firetouchinterest(root, part, 1)
                end)
                task.wait(0.08)
            end
        end
    end
end

local function hatchGeodes()
    local folder = workspace:FindFirstChild("Geode")
    if not folder then return end

    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            pcall(function()
                fireproximityprompt(obj)
            end)
        elseif obj:IsA("ClickDetector") then
            pcall(function()
                fireclickdetector(obj)
            end)
        end
    end
end

GeodeBox:AddToggle("GeodeESP", {
    Text = "ESP Geode",
    Default = false,
    Callback = function(v)
        Settings.Geode.ESP = v
        if not v then
            clearGeodeESP()
        else
            scanGeodes()
        end
    end,
})

GeodeBox:AddToggle("AutoGeode", {
    Text = "Auto Collect Geode",
    Default = false,
    Callback = function(v)
        Settings.Geode.AutoCollect = v
    end,
})

GeodeBox:AddToggle("HatchGeode", {
    Text = "Auto Hatch Geode",
    Default = false,
    Callback = function(v)
        Settings.Geode.Hatch = v
    end,
})

GeodeBox:AddInput("GeodeRange", {
    Text = "Geode Range",
    Default = "1000",
    Numeric = true,
    Finished = true,
    Callback = function(v)
        Settings.Geode.Range = tonumber(v) or 1000
    end,
})

GeodeBox:AddButton("Refresh Geode ESP", function()
    local count = scanGeodes()
    notify("Geode ESP", "Found " .. tostring(count) .. " geode touch parts.")
end)

GeodeInfoBox:AddLabel("Detection source: workspace.Geode -> TouchInterest", true)
GeodeInfoBox:AddLabel("Collection method follows the supplied 1212_clean.lua.txt.", true)
GeodeInfoBox:AddLabel("Hatch is experimental because no dedicated hatch remote was exposed.", true)

-- Sell
SellBox:AddToggle("AutoSell", {
    Text = "Auto Sell",
    Default = false,
    Callback = function(v)
        Settings.Sell.Enabled = v
    end,
})

SellBox:AddToggle("SellAll", {
    Text = "Use SellAll",
    Default = false,
    Callback = function(v)
        Settings.Sell.SellAll = v
    end,
})

local function sellAll()
    local ok, err = pcall(function()
        ReplicatedStorage:WaitForChild("Remotes")
            :WaitForChild("Shop")
            :WaitForChild("SellAll")
            :InvokeServer()
    end)

    if not ok then
        warn("[Prospecting Hub] SellAll:", err)
    end
end

SellBox:AddButton("Sell All Now", sellAll)

-- Events
EventBox:AddToggle("AutoVoid", {
    Text = "Auto Void",
    Default = false,
    Callback = function(v)
        Settings.Events.Void = v
    end,
})

EventBox:AddToggle("AutoInfernal", {
    Text = "Auto Infernal",
    Default = false,
    Callback = function(v)
        Settings.Events.Infernal = v
    end,
})

EventBox:AddToggle("AutoTotem", {
    Text = "Auto Totem",
    Default = false,
    Callback = function(v)
        Settings.Events.Totem = v
    end,
})

EventBox:AddLabel("The original source contains event logic, but this build does not invent new remotes for it.", true)

-- Misc
MiscBox:AddToggle("SpeedEnabled", {
    Text = "Custom WalkSpeed",
    Default = false,
    Callback = function(v)
        Settings.Misc.SpeedEnabled = v
    end,
})

MiscBox:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Default = 16,
    Min = 8,
    Max = 22,
    Rounding = 0,
    Callback = function(v)
        Settings.Misc.Speed = v
    end,
})

MiscBox:AddToggle("AntiAFK", {
    Text = "Anti-AFK",
    Default = true,
    Callback = function(v)
        Settings.Misc.AntiAFK = v
    end,
})

MiscBox:AddButton("Reapply Anti-AFK", function()
    if Settings.Misc.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- Farm loop
local farmState = "Idle"
local farmMoving = false
local farmGeneration = 0
local shakeRunning = false
local lastAction = 0

local function stopFarmMovement()
    farmGeneration += 1
    farmMoving = false
    shakeRunning = false
    farmState = "Idle"
end

local function atPosition(position, distance)
    local target = toVector3(position)
    local _, root = getCharacter()
    return target and root and (root.Position - target).Magnitude <= (distance or 6)
end

local function farmMove(position, onArrived)
    if not position or farmMoving then
        return false
    end

    farmMoving = true
    local generation = farmGeneration

    task.spawn(function()
        moveToPosition(position, function(ok)
            if generation ~= farmGeneration then
                return
            end
            farmMoving = false
            if ok and onArrived then
                pcall(onArrived)
            end
        end)
    end)

    return true
end

local function usePan()
    local tool = getEquippedTool()
    if not tool then return false end
    local scripts = tool:FindFirstChild("Scripts")
    local pan = scripts and scripts:FindFirstChild("Pan")
    if not pan then return false end

    return pcall(function()
        pan:InvokeServer()
    end)
end

local function collectPan()
    local tool = getEquippedTool()
    if not tool then return false end
    local scripts = tool:FindFirstChild("Scripts")
    local collect = scripts and scripts:FindFirstChild("Collect")
    if not collect then return false end

    return pcall(function()
        collect:InvokeServer(1)
    end)
end

local function shakePan()
    local tool = getEquippedTool()
    if not tool then return false end
    local scripts = tool:FindFirstChild("Scripts")
    local shake = scripts and scripts:FindFirstChild("Shake")
    if not shake then return false end

    return pcall(function()
        shake:FireServer()
    end)
end

local function startShakeLoop()
    if shakeRunning then return end
    shakeRunning = true

    task.spawn(function()
        while Settings.Farm.Enabled and Settings.Farm.AutoPan and shakeRunning do
            local tool = getEquippedTool()
            local panning = tool and tool:GetAttribute("Panning")

            if not panning then
                break
            end

            shakePan()
            task.wait(0.05)
        end
        shakeRunning = false
    end)
end

task.spawn(function()
    while task.wait(0.1) do
        if not Settings.Farm.Enabled then
            stopFarmMovement()
            continue
        end

        pcall(function()
            local tool = getEquippedTool()
            if not tool then
                farmState = "Waiting for tool"
                return
            end

            local fill = tonumber(tool:GetAttribute("Fill")) or 0
            local capacity = tonumber(LocalPlayer.Stats:GetAttribute("Capacity")) or 0
            local panning = tool:GetAttribute("Panning")

            -- While the pan is active, stay at Panning and shake repeatedly.
            if Settings.Farm.AutoPan and panning then
                farmState = "Shaking"

                if Settings.Positions.Panning then
                    if atPosition(Settings.Positions.Panning) then
                        startShakeLoop()
                    else
                        shakeRunning = false
                        farmMove(Settings.Positions.Panning, startShakeLoop)
                    end
                end
                return
            end

            -- Panning just finished: collect, then go back to Dig.
            if Settings.Farm.AutoPan and farmState == "Shaking" and not panning then
                shakeRunning = false
                farmState = "Collecting"

                if Settings.Farm.AutoCollect and Settings.Positions.Panning then
                    if atPosition(Settings.Positions.Panning) then
                        if os.clock() - lastAction > 0.5 then
                            lastAction = os.clock()
                            collectPan()
                        end
                    else
                        farmMove(Settings.Positions.Panning, function()
                            callToolScript("Collect", 1)
                        end)
                    end
                end
                return
            end

            -- Full bag: move to Panning and invoke Pan.
            if Settings.Farm.AutoPan and Settings.Positions.Panning and capacity > 0 and fill >= capacity then
                farmState = "Panning"

                if atPosition(Settings.Positions.Panning) then
                    if os.clock() - lastAction > 0.75 then
                        lastAction = os.clock()
                        usePan()
                    end
                else
                    farmMove(Settings.Positions.Panning, function()
                        callToolScript("Pan")
                    end)
                end
                return
            end

            -- Normal digging: move to Dig and repeatedly activate the shovel.
            if Settings.Farm.AutoDig and Settings.Positions.Dig then
                farmState = "Digging"

                if atPosition(Settings.Positions.Dig) then
                    if os.clock() - lastAction > 0.25 then
                        lastAction = os.clock()
                        digOnce()
                    end
                else
                    farmMove(Settings.Positions.Dig, function()
                        digOnce()
                    end)
                end
            end
        end)
    end
end

-- Geode loop
task.spawn(function()
    while task.wait(4) do
        if Settings.Geode.AutoCollect then
            pcall(collectGeodes)
        end

        if Settings.Geode.Hatch then
            pcall(hatchGeodes)
        end

        if Settings.Geode.ESP then
            pcall(scanGeodes)
        end
    end
end)

-- Sell loop
task.spawn(function()
    while task.wait(3) do
        if Settings.Sell.Enabled and Settings.Sell.SellAll then
            pcall(sellAll)
        end
    end
end)

-- Speed loop
task.spawn(function()
    while task.wait(0.25) do
        if Settings.Misc.SpeedEnabled then
            pcall(function()
                local c = LocalPlayer.Character
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.WalkSpeed = Settings.Misc.Speed
                end
            end)
        end
    end
end)

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    if not Settings.Misc.AntiAFK then return end

    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- Obsidian configuration
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("ProspectingHub")

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("ProspectingHub")
ThemeManager:ApplyToTab(Tabs.Settings)

ConfigBox:AddLabel("SaveManager configuration and Theme settings are stored here.", true)
ScriptBox:AddButton("Unload Script", function()
    pcall(function()
        clearGeodeESP()
    end)
    pcall(function()
        Library:Unload()
    end)
end)

ScriptBox:AddLabel("Unloads the UI and disconnects the script.", true)

SaveManager:BuildConfigSection(ConfigBox)
SaveManager:LoadAutoloadConfig()

Library.ToggleKeybind = Library.Options.MenuKeybind

notify("Prospecting Hub", "Loaded successfully.")
