-- PanjeGogo Script Dumper
-- Native Roblox UI; no external UI library.

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
if not Player then
    warn("[Script Dumper] LocalPlayer belum tersedia.")
    return
end

local function GetUIParent()
    local pg = Player:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end

    local ok, hui = pcall(function()
        if type(gethui) == "function" then
            return gethui()
        end
    end)
    if ok and hui then return hui end

    local ok2, cg = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok2 and cg then return cg end

    return Player:WaitForChild("PlayerGui", 10)
end

local UIParent = GetUIParent()
if not UIParent then
    warn("[Script Dumper] UI parent tidak ditemukan.")
    return
end

local old = UIParent:FindFirstChild("PanjeGogoScriptDumper")
if old then old:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "PanjeGogoScriptDumper"
Gui.ResetOnSpawn = false
Gui.DisplayOrder = 10000
Gui.Parent = UIParent

local function make(class, props, parent)
    local x = Instance.new(class)
    for k,v in pairs(props or {}) do x[k] = v end
    x.Parent = parent
    return x
end

local function corner(x, r)
    make("UICorner", {CornerRadius = UDim.new(0, r or 6)}, x)
end

local function label(parent, text, pos, size, fontSize)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Position = pos,
        Size = size,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Color3.fromRGB(230,230,235),
        TextSize = fontSize or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, parent)
end

local function button(parent, text, pos, size)
    local b = make("TextButton", {
        BackgroundColor3 = Color3.fromRGB(42,42,50),
        BorderSizePixel = 0,
        Position = pos,
        Size = size,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = Color3.fromRGB(235,235,240),
        TextSize = 13
    }, parent)
    corner(b,6)
    return b
end

local Main = make("Frame", {
    AnchorPoint = Vector2.new(.5,.5),
    Position = UDim2.fromScale(.5,.5),
    Size = UDim2.fromOffset(720,500),
    BackgroundColor3 = Color3.fromRGB(22,22,27),
    BorderSizePixel = 0
}, Gui)
corner(Main,10)

local Header = make("Frame", {
    Size = UDim2.new(1,0,0,44),
    BackgroundColor3 = Color3.fromRGB(29,29,35),
    BorderSizePixel = 0
}, Main)
corner(Header,10)
label(Header,"Script Dumper",UDim2.fromOffset(16,0),UDim2.new(1,-60,1,0),15)

local Close = button(Header,"X",UDim2.new(1,-42,0,7),UDim2.fromOffset(32,30))
Close.Activated:Connect(function() Gui:Destroy() end)

local Tabs = make("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(12,50),
    Size = UDim2.fromOffset(110,108)
}, Main)

local TabDumper = button(Tabs,"Dumper",UDim2.fromOffset(0,0),UDim2.fromOffset(110,34))
local TabResult = button(Tabs,"Result",UDim2.fromOffset(0,40),UDim2.fromOffset(110,34))
local TabSettings = button(Tabs,"Settings",UDim2.fromOffset(0,80),UDim2.fromOffset(110,28))

local Dumper = make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(134,50),Size=UDim2.new(1,-146,1,-62)},Main)
local Result = make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(134,50),Size=UDim2.new(1,-146,1,-62),Visible=false},Main)
local Settings = make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(134,50),Size=UDim2.new(1,-146,1,-62),Visible=false},Main)

local function show(page)
    Dumper.Visible = page == Dumper
    Result.Visible = page == Result
    Settings.Visible = page == Settings
    TabDumper.BackgroundColor3 = page == Dumper and Color3.fromRGB(70,70,85) or Color3.fromRGB(42,42,50)
    TabResult.BackgroundColor3 = page == Result and Color3.fromRGB(70,70,85) or Color3.fromRGB(42,42,50)
    TabSettings.BackgroundColor3 = page == Settings and Color3.fromRGB(70,70,85) or Color3.fromRGB(42,42,50)
end

TabDumper.Activated:Connect(function() show(Dumper) end)
TabResult.Activated:Connect(function() show(Result) end)
TabSettings.Activated:Connect(function() show(Settings) end)

local Left = make("Frame", {
    BackgroundColor3=Color3.fromRGB(29,29,35), BorderSizePixel=0,
    Position=UDim2.fromOffset(0,0), Size=UDim2.new(.5,-6,1,0)
},Dumper)
local Right = make("Frame", {
    BackgroundColor3=Color3.fromRGB(29,29,35), BorderSizePixel=0,
    Position=UDim2.new(.5,6,0,0), Size=UDim2.new(.5,-6,1,0)
},Dumper)
corner(Left,8); corner(Right,8)

label(Left,"Script Dumper",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,26),14)
label(Right,"URL Dumper",UDim2.fromOffset(14,10),UDim2.new(1,-28,0,26),14)

local ScriptURL = make("TextBox", {
    BackgroundColor3=Color3.fromRGB(17,17,21), BorderSizePixel=0,
    Position=UDim2.fromOffset(14,48), Size=UDim2.new(1,-28,0,96),
    Font=Enum.Font.Code, Text="", TextSize=12, TextColor3=Color3.fromRGB(235,235,240),
    PlaceholderText='loadstring(game:HttpGet("..."))', ClearTextOnFocus=false,
    MultiLine=true, TextWrapped=false,
    TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top
},Left)
corner(ScriptURL)

local URLInput = make("TextBox", {
    BackgroundColor3=Color3.fromRGB(17,17,21), BorderSizePixel=0,
    Position=UDim2.fromOffset(14,48), Size=UDim2.new(1,-28,0,42),
    Font=Enum.Font.Code, Text="", TextSize=12, TextColor3=Color3.fromRGB(235,235,240),
    PlaceholderText="https://raw.githubusercontent.com/...", ClearTextOnFocus=false
},Right)
corner(URLInput)

local DumpScript = button(Left,"Dump Script",UDim2.fromOffset(14,154),UDim2.new(1,-28,0,38))
local ClearScript = button(Left,"Clear",UDim2.fromOffset(14,200),UDim2.new(1,-28,0,38))
local ScriptStatus = label(Left,"Ready",UDim2.fromOffset(14,248),UDim2.new(1,-28,0,60),12)
ScriptStatus.TextWrapped=true
ScriptStatus.TextYAlignment=Enum.TextYAlignment.Top

local DumpURLs = button(Right,"Dump URLs",UDim2.fromOffset(14,100),UDim2.new(1,-28,0,38))
local ClearURL = button(Right,"Clear",UDim2.fromOffset(14,146),UDim2.new(1,-28,0,38))
local URLStatus = label(Right,"Ready",UDim2.fromOffset(14,194),UDim2.new(1,-28,0,60),12)
URLStatus.TextWrapped=true
URLStatus.TextYAlignment=Enum.TextYAlignment.Top

local ResultPanel = make("Frame",{BackgroundColor3=Color3.fromRGB(29,29,35),BorderSizePixel=0,Size=UDim2.fromScale(1,1)},Result)
corner(ResultPanel,8)

label(ResultPanel,"Dump Result",UDim2.fromOffset(14,8),UDim2.new(1,-150,0,32),14)
local Copy = button(ResultPanel,"Copy Result",UDim2.new(1,-130,0,8),UDim2.fromOffset(116,32))

local Output = make("TextBox", {
    BackgroundColor3=Color3.fromRGB(15,15,19), BorderSizePixel=0,
    Position=UDim2.fromOffset(14,48), Size=UDim2.new(1,-28,1,-62),
    Font=Enum.Font.Code, Text="", TextSize=12, TextColor3=Color3.fromRGB(225,225,230),
    MultiLine=true, TextWrapped=false, TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top, ClearTextOnFocus=false,
    PlaceholderText="Hasil dump akan muncul di sini..."
},ResultPanel)
corner(Output)

local SettingsPanel = make("Frame",{BackgroundColor3=Color3.fromRGB(29,29,35),BorderSizePixel=0,Size=UDim2.fromScale(1,1)},Settings)
corner(SettingsPanel,8)
label(SettingsPanel,"Settings",UDim2.fromOffset(14,8),UDim2.new(1,-28,0,32),14)
local Unload = button(SettingsPanel,"Unload Script Dumper",UDim2.fromOffset(14,52),UDim2.fromOffset(210,38))

local function clean(value)
    value = tostring(value or ""):match("^%s*(.-)%s*$")

    -- Terima URL langsung.
    local direct = value:gsub("^['\"]",""):gsub("['\"]$","")
    direct = direct:match("^%s*(.-)%s*$")
    if direct:match("^https?://[^%s]+$") then
        return direct
    end

    -- Kalau user paste kode Lua/loader, ambil URL dari HttpGet(...)
    local extracted =
        value:match("HttpGet%s*%(%s*[\"'](https?://[^\"']+)")
        or value:match("HttpGet%s*%(%s*(https?://[^%s%)\"']+)")

    if extracted then
        extracted = extracted:gsub("^[\"']",""):gsub("[\"']$","")
        extracted = extracted:gsub("[,;]+$","")
        if extracted:match("^https?://") then
            return extracted
        end
    end

    return nil
end

local function httpGet(url)
    return pcall(function()
        return game:HttpGet(url)
    end)
end

DumpScript.Activated:Connect(function()
    local url = clean(ScriptURL.Text)
    if not url then ScriptStatus.Text="URL tidak valid."; return end
    ScriptStatus.Text="Mengambil script..."
    task.spawn(function()
        local ok, data = httpGet(url)
        if not ok then ScriptStatus.Text="HTTP Error: "..tostring(data); return end
        if type(data)~="string" or data=="" then ScriptStatus.Text="Response kosong."; return end
        Output.Text=data
        ScriptStatus.Text="Berhasil: "..#data.." karakter"
        if type(writefile)=="function" then pcall(function() writefile("script_dump.lua",data) end) end
        show(Result)
    end)
end)

DumpURLs.Activated:Connect(function()
    local url = clean(URLInput.Text)
    if not url then URLStatus.Text="URL tidak valid."; return end
    URLStatus.Text="Mengambil source..."
    task.spawn(function()
        local ok, source = httpGet(url)
        if not ok then URLStatus.Text="HTTP Error: "..tostring(source); return end
        if type(source)~="string" or source=="" then URLStatus.Text="Response kosong."; return end
        local list, seen = {}, {}
        for u in source:gmatch("https?://[^%s%\"']+") do
            u=u:gsub("[%),;]+$","")
            if not seen[u] then seen[u]=true; table.insert(list,u) end
        end
        local output = #list > 0 and table.concat(list,"\n") or "Tidak ada URL ditemukan."
        Output.Text=output
        URLStatus.Text=#list.." URL ditemukan."
        if type(writefile)=="function" and #list>0 then pcall(function() writefile("url_dump.txt",output) end) end
        show(Result)
    end)
end)

ClearScript.Activated:Connect(function() ScriptURL.Text=""; ScriptStatus.Text="Ready" end)
ClearURL.Activated:Connect(function() URLInput.Text=""; URLStatus.Text="Ready" end)

Copy.Activated:Connect(function()
    if Output.Text~="" and type(setclipboard)=="function" then
        pcall(function() setclipboard(Output.Text) end)
    end
end)

Unload.Activated:Connect(function() Gui:Destroy() end)

show(Dumper)
print("[Script Dumper] Native UI loaded.")
