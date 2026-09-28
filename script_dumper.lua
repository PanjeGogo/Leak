local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "Script Dumper",
    Footer = "Script Dumper | By PanjeGogo",
    AutoShow = true,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Dumper = Window:AddTab("Dumper", "file-code"),
    Result = Window:AddTab("Result", "file-text"),
    Settings = Window:AddTab("Settings", "sliders-horizontal"),
}

local ScriptGroup = Tabs.Dumper:AddLeftGroupbox("Script Dumper", "download")
local URLGroup = Tabs.Dumper:AddRightGroupbox("URL Dumper", "link")
local ResultGroup = Tabs.Result:AddLeftGroupbox("Dump Result", "file-text")
local SettingsGroup = Tabs.Settings:AddLeftGroupbox("Settings", "settings")

-- Make the Result tab full-width instead of Obsidian's default 50/50 columns.
do
    local DefaultRefreshSides = Tabs.Result.RefreshSides

    function Tabs.Result:RefreshSides()
        DefaultRefreshSides(self)

        if self.Sides[1] then
            self.Sides[1].Size = UDim2.new(1, -3, 1, self.Sides[1].Size.Y.Offset)
        end

        if self.Sides[2] then
            self.Sides[2].Visible = false
        end
    end
end

ScriptGroup:AddInput("ScriptURL", {
    Text = "Script URL",
    Placeholder = "https://raw.githubusercontent.com/...",
    Default = "",
})

ScriptGroup:AddButton("Dump Script", function()
    local url = Library.Options.ScriptURL.Value

    if type(url) ~= "string" or url:gsub("%s+", "") == "" then
        Library:Notify("URL masih kosong!", 3)
        return
    end

    Library:Notify("Mengambil script...", 2)

    task.spawn(function()
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)

        if Library.Unloaded then
            return
        end

        if not success then
            Library:Notify("HTTP Error: " .. tostring(result), 5)
            return
        end

        if type(result) ~= "string" or result == "" then
            Library:Notify("Response kosong.", 4)
            return
        end

        Library.Options.DumpOutput:SetValue(result)

        print("========== SCRIPT DUMP ==========")
        print(result)
        print("========== END DUMP =============")

        if type(writefile) == "function" then
            local saved = pcall(function()
                writefile("script_dump.lua", result)
            end)

            if saved then
                Library:Notify("Dump berhasil dan disimpan.", 4)
            else
                Library:Notify(string.format("Dump berhasil! %d karakter.", #result), 4)
            end
        else
            Library:Notify(string.format("Dump berhasil! %d karakter.", #result), 4)
        end
    end)
end)

ScriptGroup:AddButton("Clear", function()
    Library.Options.ScriptURL:SetValue("")
    Library.Options.DumpOutput:SetValue("")
end)

URLGroup:AddInput("URLDumperURL", {
    Text = "URL",
    Placeholder = "Masukkan URL script yang ingin dianalisis...",
    Default = "",
})

URLGroup:AddButton("Dump URLs", function()
    local url = Library.Options.URLDumperURL.Value

    if type(url) ~= "string" or url:gsub("%s+", "") == "" then
        Library:Notify("URL Dumper masih kosong!", 3)
        return
    end

    Library:Notify("Mengambil source untuk mencari URL...", 2)

    task.spawn(function()
        local success, source = pcall(function()
            return game:HttpGet(url)
        end)

        if Library.Unloaded then
            return
        end

        if not success then
            Library:Notify("HTTP Error: " .. tostring(source), 5)
            return
        end

        if type(source) ~= "string" or source == "" then
            Library:Notify("Response kosong.", 4)
            return
        end

        local urls = {}
        local seen = {}

        for foundUrl in source:gmatch("https?://[^%s%\"']+") do
            foundUrl = foundUrl:gsub("[%),;]+$", "")

            if not seen[foundUrl] then
                seen[foundUrl] = true
                table.insert(urls, foundUrl)
            end
        end

        if #urls == 0 then
            Library.Options.DumpOutput:SetValue("Tidak ada URL ditemukan.")
            Library:Notify("Tidak ada URL ditemukan.", 3)
            return
        end

        local output = table.concat(urls, "\n")
        Library.Options.DumpOutput:SetValue(output)

        print("========== URL DUMP ==========")
        print(output)
        print("========== END URL DUMP ======")

        if type(writefile) == "function" then
            pcall(function()
                writefile("url_dump.txt", output)
            end)
        end

        Library:Notify(string.format("%d URL ditemukan.", #urls), 4)
    end)
end)

URLGroup:AddButton("Clear", function()
    Library.Options.URLDumperURL:SetValue("")
end)

ResultGroup:AddButton("Copy Result", function()
    local result = Library.Options.DumpOutput.Value

    if type(result) ~= "string" or result == "" then
        Library:Notify("Belum ada hasil dump!", 3)
        return
    end

    if type(setclipboard) ~= "function" then
        Library:Notify("Executor tidak mendukung setclipboard.", 4)
        return
    end

    local success = pcall(function()
        setclipboard(result)
    end)

    if success then
        Library:Notify("Hasil berhasil dicopy!", 3)
    else
        Library:Notify("Gagal copy hasil.", 4)
    end
end)

local ResultInput = ResultGroup:AddInput("DumpOutput", {
    Text = "Result",
    Placeholder = "Hasil dump akan muncul di sini...",
    Default = "",
})

-- AddInput bawaan Obsidian hanya membuat textbox 1 baris.
-- Ubah textbox Result menjadi multiline dan lebih tinggi.
do
    local Holder = ResultInput.Holder
    local Box = Holder and Holder:FindFirstChildOfClass("TextBox")

    if Holder and Box then
        Holder.Size = UDim2.new(1, 0, 0, 260)

        Box.AnchorPoint = Vector2.new(0, 0)
        Box.Position = UDim2.fromOffset(0, 14)
        Box.Size = UDim2.new(1, 0, 1, -14)
        Box.MultiLine = true
        Box.TextScaled = false
        Box.TextSize = 13
        Box.TextWrapped = false
        Box.TextYAlignment = Enum.TextYAlignment.Top
        Box.ClearTextOnFocus = false
    end

    ResultGroup:Resize()
end

SettingsGroup:AddButton("Unload Script", function()
    Library:Unload()
end)

Library:Notify("Script Dumper loaded.", 3)
