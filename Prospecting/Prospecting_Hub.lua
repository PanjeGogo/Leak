-- Prospecting Hub
-- Built from the MaM UI/template style and Prospecting logic found in 1212_clean.lua.txt.

local UI_URL = "https://raw.githubusercontent.com/TokyoYoo/gga2/refs/heads/main/gg.lua"
local SaveManager_URL = "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
local Interface_URL = "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local UI = loadstring(game:HttpGet(UI_URL, true))()
local SaveManager = loadstring(game:HttpGet(SaveManager_URL, true))()
local InterfaceManager = loadstring(game:HttpGet(Interface_URL, true))()

local Window = UI:CreateWindow({
    Title = "Prospecting Hub",
    SubTitle = "Template build",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 390),
    Acrylic = true,
    Theme = "Cloud",
    MinimizeKey = Enum.KeyCode.End,
})

local Tabs = {
    Farm = Window:AddTab({Title = "Auto Farm", Icon = "home"}),
    Geode = Window:AddTab({Title = "Geode", Icon = "gem"}),
    Positions = Window:AddTab({Title = "Positions", Icon = "map"}),
    Sell = Window:AddTab({Title = "Auto Sell", Icon = "shopping-cart"}),
    Events = Window:AddTab({Title = "Events", Icon = "flame"}),
    Misc = Window:AddTab({Title = "Misc", Icon = "settings"}),
}

local Options = UI.Options
local Settings = {
    Farm = {Enabled=false, AutoEquip=false, InstantPerfectDig=false, AutoDig=false, AutoPan=true, AutoCollect=true},
    Geode = {ESP=false, AutoCollect=false, Hatch=false, Range=1000},
    Sell = {Enabled=false, Amount=500, SellAll=false},
    Events = {Void=false, Infernal=false, Totem=false},
    Misc = {Speed=16, SpeedEnabled=false, AntiAFK=true},
    Positions = {Sand=nil, Water=nil, Panning=nil, Shaking=nil, Sell=nil},
}

local function getCharacter()
    local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return c, c:WaitForChild("HumanoidRootPart",5)
end
local function notify(title,content) pcall(function() Window:Notify({Title=title,Content=content,Duration=3}) end) end
local function posTable(v) return {math.round(v.X),math.round(v.Y),math.round(v.Z)} end
local function toVector3(p) if type(p)=="table" and #p>=3 then return Vector3.new(p[1],p[2],p[3]) end end

local function moveToPosition(p,callback,forceTeleport)
    local target=toVector3(p); if not target then if callback then callback(false) end return end
    local c,root=getCharacter(); if not root then if callback then callback(false) end return end
    local method=forceTeleport and "Teleport" or "Walk"
    if Options.MoveMethod and Options.MoveMethod.Value then method=Options.MoveMethod.Value end
    if method=="Teleport" then root.CFrame=CFrame.new(target); task.wait(.15); if callback then callback(true) end return end
    local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then if callback then callback(false) end return end
    local finished=false; local conn
    conn=hum.MoveToFinished:Connect(function(ok) finished=true; conn:Disconnect(); if callback then callback(ok) end end)
    hum:MoveTo(target)
    task.delay(15,function() if not finished then finished=true; if conn then conn:Disconnect() end; if callback then callback(false) end end end)
end

local function getEquippedTool() local c=LocalPlayer.Character; return c and c:FindFirstChildOfClass("Tool") end
local function getPanTool()
    local tool=getEquippedTool()
    if tool and tool.Name:lower():find("pan") then return tool end
    local backpack=LocalPlayer:FindFirstChild("BackpackTwo") or LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then for _,item in ipairs(backpack:GetChildren()) do if item:IsA("Tool") and item.Name:lower():find("pan") then return item end end end
end
local function equipPan()
    local tool=getPanTool(); if not tool then return false end
    local c=LocalPlayer.Character
    if c and tool.Parent~=c then pcall(function() c:FindFirstChildOfClass("Humanoid"):EquipTool(tool) end); task.wait(.2) end
    return getEquippedTool()==tool or getEquippedTool()~=nil
end
local function callToolScript(name,...)
    local tool=getEquippedTool(); if not tool then return false end
    local scripts=tool:FindFirstChild("Scripts"); if not scripts then return false end
    local obj=scripts:FindFirstChild(name); if not obj then return false end
    local args={...}
    return pcall(function()
        if obj:IsA("RemoteFunction") then obj:InvokeServer(table.unpack(args))
        elseif obj:IsA("RemoteEvent") then obj:FireServer(table.unpack(args))
        elseif obj:IsA("BindableFunction") then obj:Invoke(table.unpack(args))
        elseif obj:IsA("BindableEvent") then obj:Fire(table.unpack(args))
        else tool:Activate() end
    end)
end
local function digOnce() local tool=getEquippedTool(); if not tool then return false end; return pcall(function() tool:Activate() end) end

Tabs.Positions:AddParagraph({Title="Saved Farm Positions",Content="Save your current location for each stage of the farm."})
local function savePosition(name,label)
    local _,root=getCharacter(); if not root then notify("Position","Character not ready."); return end
    Settings.Positions[name]=posTable(root.Position); notify("Position Saved",label.." saved.")
end
for _,v in ipairs({
    {"Sand","Save Sand Position","Save the current position as the sand/dig location."},
    {"Water","Save Water Position","Save the current position as the water/panning area."},
    {"Panning","Save Panning Position","Matches the PanningPos pattern from the supplied Prospecting script."},
    {"Shaking","Save Shaking Position","Matches the ShakingPos pattern from the supplied Prospecting script."},
    {"Sell","Save Sell Position","Save a single sell location."},
}) do Tabs.Positions:AddButton({Title=v[2],Description=v[3],Callback=function() savePosition(v[1],v[1]) end}) end
Tabs.Positions:AddButton({Title="Clear Saved Positions",Callback=function() for k in pairs(Settings.Positions) do Settings.Positions[k]=nil end notify("Positions","Saved positions cleared.") end})

Tabs.Farm:AddToggle("AutoFarm",{Title="Auto Farm",Default=false}):OnChanged(function(v) Settings.Farm.Enabled=v end)
Tabs.Farm:AddToggle("AutoEquip",{Title="Auto Equip Pan",Default=false}):OnChanged(function(v) Settings.Farm.AutoEquip=v end)
Tabs.Farm:AddToggle("AutoDig",{Title="Auto Dig",Description="Uses the equipped tool's native activation.",Default=false}):OnChanged(function(v) Settings.Farm.AutoDig=v end)
Tabs.Farm:AddToggle("AutoPan",{Title="Auto Pan",Default=true}):OnChanged(function(v) Settings.Farm.AutoPan=v end)
Tabs.Farm:AddToggle("AutoCollect",{Title="Auto Collect",Default=true}):OnChanged(function(v) Settings.Farm.AutoCollect=v end)
Tabs.Farm:AddToggle("InstantPerfectDig",{Title="Instant Perfect Dig",Description="Uses the SetCombo remote path present in 1212_clean.lua.txt.",Default=false}):OnChanged(function(v) Settings.Farm.InstantPerfectDig=v end)
Tabs.Farm:AddDropdown("MoveMethod",{Title="Movement Method",Values={"Walk","Teleport"},Multi=false,Default="Walk"})
Tabs.Farm:AddParagraph({Title="Workflow",Content="Sand -> collect/fill -> water/pan -> shake."})

local geodeESP={}
local function clearGeodeESP() for obj,gui in pairs(geodeESP) do if gui then pcall(function() gui:Destroy() end) end geodeESP[obj]=nil end end
local function addGeodeESP(part)
    if geodeESP[part] or not part:IsA("BasePart") then return end
    local gui=Instance.new("BillboardGui"); gui.Name="ProspectingGeodeESP"; gui.Size=UDim2.fromOffset(180,42); gui.StudsOffset=Vector3.new(0,3,0); gui.AlwaysOnTop=true; gui.Adornee=part
    local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text="GEODE"; label.TextColor3=Color3.fromRGB(0,255,255); label.TextStrokeTransparency=0; label.Font=Enum.Font.GothamBold; label.TextSize=16; label.Parent=gui
    gui.Parent=(gethui and gethui()) or game:GetService("CoreGui"); geodeESP[part]=gui
end
local function scanGeodes()
    clearGeodeESP(); local folder=workspace:FindFirstChild("Geode"); if not folder then return end
    local _,root=getCharacter(); local origin=root and root.Position
    for _,obj in ipairs(folder:GetDescendants()) do
        if obj.Name=="TouchInterest" then local part=obj.Parent
            if part and part:IsA("BasePart") and (not origin or (part.Position-origin).Magnitude<=Settings.Geode.Range) then addGeodeESP(part) end
        end
    end
end
Tabs.Geode:AddToggle("GeodeESP",{Title="ESP Geode",Default=false}):OnChanged(function(v) Settings.Geode.ESP=v; if not v then clearGeodeESP() end end)
Tabs.Geode:AddToggle("AutoGeode",{Title="Auto Collect Geode",Description="Uses the TouchInterest collection method from 1212_clean.lua.txt.",Default=false}):OnChanged(function(v) Settings.Geode.AutoCollect=v end)
Tabs.Geode:AddToggle("HatchGeode",{Title="Auto Hatch Geode",Description="Experimental: activates exposed ProximityPrompt/ClickDetector objects.",Default=false}):OnChanged(function(v) Settings.Geode.Hatch=v end)
Tabs.Geode:AddInput("GeodeRange",{Title="Geode Range",Default="1000",Numeric=true,Finished=true,Callback=function(v) Settings.Geode.Range=tonumber(v) or 1000 end})
Tabs.Geode:AddButton({Title="Refresh Geode ESP",Callback=scanGeodes})
local function collectGeodes()
    local folder=workspace:FindFirstChild("Geode"); if not folder then return end
    local _,root=getCharacter(); if not root then return end
    for _,obj in ipairs(folder:GetDescendants()) do
        if obj.Name=="TouchInterest" then local part=obj.Parent
            if part and part:IsA("BasePart") and (part.Position-root.Position).Magnitude<=Settings.Geode.Range then
                pcall(function() firetouchinterest(root,part,0); firetouchinterest(root,part,1) end); task.wait(.1)
            end
        end
    end
end
local function hatchGeodes()
    local folder=workspace:FindFirstChild("Geode"); if not folder then return end
    for _,obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(obj) end)
        elseif obj:IsA("ClickDetector") then pcall(function() fireclickdetector(obj) end) end
    end
end

Tabs.Sell:AddInput("SellAmount",{Title="Sell Amount",Default="500",Numeric=true,Finished=true,Callback=function(v) Settings.Sell.Amount=tonumber(v) or 500 end})
Tabs.Sell:AddToggle("AutoSell",{Title="Auto Sell",Default=false}):OnChanged(function(v) Settings.Sell.Enabled=v end)
Tabs.Sell:AddToggle("SellAll",{Title="Use SellAll",Description="Matches the SellAll remote path in 1212_clean.lua.txt.",Default=false}):OnChanged(function(v) Settings.Sell.SellAll=v end)
local function sellAll() pcall(function() ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop"):WaitForChild("SellAll"):InvokeServer() end) end

Tabs.Events:AddToggle("AutoVoid",{Title="Auto Void",Default=false}):OnChanged(function(v) Settings.Events.Void=v end)
Tabs.Events:AddToggle("AutoInfernal",{Title="Auto Infernal",Default=false}):OnChanged(function(v) Settings.Events.Infernal=v end)
Tabs.Events:AddToggle("AutoTotem",{Title="Auto Totem",Default=false}):OnChanged(function(v) Settings.Events.Totem=v end)
Tabs.Events:AddParagraph({Title="Source-supported event logic",Content="Void/Infernal/Totem logic exists in 1212_clean.lua.txt."})

Tabs.Misc:AddToggle("SpeedEnabled",{Title="Custom WalkSpeed",Default=false}):OnChanged(function(v) Settings.Misc.SpeedEnabled=v end)
Tabs.Misc:AddInput("WalkSpeed",{Title="Walk Speed",Default="16",Numeric=true,Finished=true,Callback=function(v) Settings.Misc.Speed=math.min(22,tonumber(v) or 16) end})
Tabs.Misc:AddToggle("AntiAFK",{Title="Anti-AFK",Default=true}):OnChanged(function(v) Settings.Misc.AntiAFK=v end)

task.spawn(function()
    while task.wait(.15) do
        if Settings.Farm.Enabled then pcall(function()
            if Settings.Farm.AutoEquip then equipPan() end
            if Settings.Farm.InstantPerfectDig then
                ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Inventory"):WaitForChild("ShovelEnchantManager"):WaitForChild("Combo"):WaitForChild("Remotes"):WaitForChild("SetCombo"):FireServer()
            end
            if Settings.Farm.AutoDig and Settings.Positions.Sand then moveToPosition(Settings.Positions.Sand,nil,false); digOnce() end
            local tool=getEquippedTool(); if not tool or not tool:FindFirstChild("Scripts") then return end
            local fill=tool:GetAttribute("Fill"); local stats=LocalPlayer:FindFirstChild("Stats"); local capacity=stats and stats:GetAttribute("Capacity"); local panning=tool:GetAttribute("Panning")
            if Settings.Farm.AutoCollect and Settings.Positions.Panning and fill and capacity and fill<capacity then
                moveToPosition(Settings.Positions.Panning,function(ok) if ok then callToolScript("Collect",1) end end,false)
            elseif Settings.Farm.AutoPan and Settings.Positions.Shaking and fill and capacity and fill>=capacity then
                moveToPosition(Settings.Positions.Shaking,function(ok) if ok then callToolScript("Pan") end end,false)
            elseif Settings.Farm.AutoPan and Settings.Positions.Shaking and panning then callToolScript("Shake") end
        end) end
    end
end)
task.spawn(function() while task.wait(5) do if Settings.Geode.AutoCollect then pcall(collectGeodes) end; if Settings.Geode.Hatch then pcall(hatchGeodes) end; if Settings.Geode.ESP then pcall(scanGeodes) end end end)
task.spawn(function() while task.wait(2) do if Settings.Sell.Enabled and Settings.Sell.SellAll then pcall(sellAll) end end end)
task.spawn(function() while task.wait(.25) do if Settings.Misc.SpeedEnabled then pcall(function() local c=LocalPlayer.Character; local h=c and c:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=Settings.Misc.Speed end end) end end end)

local antiAfkConnection
local function setAntiAFK(enabled)
    if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection=nil end
    if enabled then antiAfkConnection=LocalPlayer.Idled:Connect(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end) end
end
setAntiAFK(true)
Tabs.Misc:AddButton({Title="Reapply Anti-AFK",Callback=function() setAntiAFK(Settings.Misc.AntiAFK) end})

SaveManager:SetLibrary(UI); InterfaceManager:SetLibrary(UI); SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("ProspectingHub"); SaveManager:SetFolder("ProspectingHub/config"); InterfaceManager:BuildInterfaceSection(Tabs.Misc); SaveManager:BuildConfigSection(Tabs.Misc); SaveManager:LoadAutoloadConfig()
notify("Prospecting Hub","Loaded.")