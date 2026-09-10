-- Runtime URL Capture Emulator
-- Executes Lua in a restricted, offline sandbox and records HTTP URLs.
-- No network requests are made and intercepted response bodies are never executed.

local input = arg[1] or "output/upstream.lua"
local fh = assert(io.open(input, "rb"))
local source = fh:read("*a")
fh:close()

local captured, seen = {}, {}
local function record(kind, url)
    if type(url) ~= "string" or url == "" then return end
    local key = kind .. "|" .. url
    if not seen[key] then
        seen[key] = true
        captured[#captured + 1] = { kind = kind, url = url }
        io.write("[CAPTURE] [", kind, "] ", url, "\n")
    end
end

local function proxy(path)
    local p = { __path = path }
    return setmetatable(p, {
        __index = function(self, key)
            if key == "Name" then return path end
            if key == "ClassName" then return "Instance" end
            if key == "Parent" then return nil end
            return proxy(path .. "." .. tostring(key))
        end,
        __newindex = function() end,
        __call = function(self, ...) return proxy(path .. "()") end,
        __tostring = function() return path end,
        __concat = function(a, b) return tostring(a) .. tostring(b) end,
        __len = function() return 0 end,
    })
end

local function http_get(url)
    record("HttpGet", url)
    return ""
end
local function http_post(url, ...)
    record("HttpPost", url)
    return ""
end
local function request(req)
    if type(req) == "string" then
        record("request", req)
    elseif type(req) == "table" then
        record("request", req.Url or req.URL or req.url)
    end
    return { StatusCode = 204, StatusMessage = "Intercepted", Body = "", Headers = {} }
end

local http_service = proxy("game:GetService(HttpService)")
http_service.GetAsync = http_get
http_service.PostAsync = http_post
http_service.RequestAsync = request

local game = proxy("game")
game.HttpGet = http_get
game.HttpGetAsync = http_get
game.HttpPost = http_post
game.HttpPostAsync = http_post
game.GetService = function(_, name)
    if tostring(name) == "HttpService" then return http_service end
    return proxy("game:GetService(" .. tostring(name) .. ")")
end

local env = {}
for k, v in pairs(_G) do env[k] = v end

env.game = game
env.workspace = proxy("workspace")
env.Workspace = env.workspace
env.Instance = { new = function(className) return proxy("Instance.new(" .. tostring(className) .. ")") end }
env.request = request
env.http_request = request
env.syn = { request = request }
env.http = { request = request }
env.fluxus = { request = request }
env.krnl = { request = request }
env.Electron = { request = request }

env.getgenv = function() return env end
env.getrenv = function() return env end
env.getfenv = function() return env end
env.setfenv = function(_, e) return e end
env.typeof = function(v)
    if type(v) == "table" and v.__path then return "Instance" end
    return type(v)
end

env.wait = function() return 0 end
env.delay = function(_, fn) if type(fn) == "function" then pcall(fn) end end
env.task = {
    wait = function() return 0 end,
    spawn = function(fn) if type(fn) == "function" then pcall(fn) end end,
    defer = function(fn) if type(fn) == "function" then pcall(fn) end end,
    delay = function(_, fn) if type(fn) == "function" then pcall(fn) end end,
}

-- Compile remote strings in the same sandbox, but do not make network calls.
local function safe_load(code, chunkname)
    if type(code) ~= "string" then return nil, "expected string" end
    return load(code, chunkname or "=(intercepted)", "t", env)
end
env.loadstring = function(code) return safe_load(code, "=(loadstring-intercepted)") end
env.load = safe_load

env.fireclickdetector = function() end
env.fireproximityprompt = function() end
env.getconnections = function() return {} end
env.hookfunction = function(original) return original end
env.hookmetamethod = function(_, _, original) return original end
env.newcclosure = function(fn) return fn end
env.checkcaller = function() return false end
env.identifyexecutor = function() return "RuntimeCapture", "2.0" end
env.isexecutorclosure = function() return false end
env.cloneref = function(x) return x end
env.gethui = function() return proxy("gethui()") end
env.gethiddenproperty = function() return nil end
env.sethiddenproperty = function() end
env.getrawmetatable = function(x) return getmetatable(x) or {} end
env.setreadonly = function() end
env.isreadonly = function() return false end

env.Enum = proxy("Enum")
env.UserSettings = function() return proxy("UserSettings()") end
env.settings = function() return proxy("settings()") end
env.Vector2 = { new = function(x, y) return { X=x or 0, Y=y or 0 } end }
env.Vector3 = { new = function(x, y, z) return { X=x or 0, Y=y or 0, Z=z or 0 } end }
env.CFrame = { new = function(...) return proxy("CFrame") end }
env.Color3 = { new = function(...) return proxy("Color3") end, fromRGB = function(...) return proxy("Color3.fromRGB") end }

env._G = env
-- Do not expose host filesystem/process modules to the analyzed script.
env.os = nil
env.io = nil
env.package = nil
env.debug = nil

env.table.clone = env.table.clone or function(t)
    local r = {}
    for k, v in pairs(t) do r[k] = v end
    return r
end

env.table.clear = env.table.clear or function(t)
    for k in pairs(t) do t[k] = nil end
end

env.table.find = env.table.find or function(t, value)
    for i, v in ipairs(t) do if v == value then return i end end
    return nil
end

env.table.create = env.table.create or function(count, value)
    local t = {}
    for i = 1, count or 0 do t[i] = value end
    return t
end

local chunk, err = load(source, "@" .. input, "t", env)
if not chunk then
    io.stderr:write("[LOAD-ERROR] ", tostring(err), "\n")
    os.exit(2)
end

local ok, runtime_err = pcall(chunk)
if not ok then
    io.stderr:write("[RUNTIME-STOP] ", tostring(runtime_err), "\n")
end

io.write("\nCaptured URLs: ", tostring(#captured), "\n")
for i, item in ipairs(captured) do
    io.write(i, ". ", item.kind, " -> ", item.url, "\n")
end
if #captured == 0 then
    io.write("No HTTP URL reached an intercepted API.\n")
end
