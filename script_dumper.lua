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
    Settings = Window:AddTab("Settings", "sliders-horizontal"),
}

local DumpGroup = Tabs.Dumper:AddLeftGroupbox("Script Dumper", "download")
local OutputGroup = Tabs.Dumper:AddRightGroupbox("Dump Result", "file-text")

DumpGroup:AddInput("ScriptURL", {
    Text = "Script URL",
    Placeholder = "https://raw.githubusercontent.com/...",
    Default = "",
})

DumpGroup:AddButton("Dump Script", function()
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

DumpGroup:AddButton("Clear", function()
    Library.Options.ScriptURL:SetValue("")
    Library.Options.DumpOutput:SetValue("")
end)

OutputGroup:AddInput("DumpOutput", {
    Text = "Result",
    Placeholder = "Hasil dump akan muncul di sini...",
    Default = "",
    MultiLine = true,
})

OutputGroup:AddButton("Copy Result", function()
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

Library:Notify("Script Dumper loaded.", 3)
